module vlc_transmit(
	input clk,
	input reset,
	input rx_data,         		 //串口接收数据
	output wire DACLK,
	output wire [7:0] data_out  //输出OFDM信号,50MHz
);

//SignalTap II配置采样深度,确定RAM的大小
//所能显示的被测信号波形的时间长度为Tx
//计算公式如下：  Tx=N×Ts  N为缓存中存储的采样点数，Ts为采样时钟的周期

//DA转换时钟
Fre_Division Fre_Division_m0(
	.CP_in(clk), 
	.reset(reset), 
	.fre_div(16'd2), 
	.CP_out(DACLK)
);

//产生新的reset信号,用于缓冲pll输出的不稳定态
wire reset_n;
wire clk_reset;
new_reset new_reset_m(
	.clk(clk),
	.reset(reset),
	.reset_n(reset_n),
	.clk_reset(clk_reset)
);

wire clk_1MHz;   //加入CP后的时钟
wire clk_800kHz; //二倍频
wire clk_400kHz; //数据速率
wire clk_200kHz; //二分频
wire signaltap_clk; //signaltap采样时钟

//signaltap采样时钟
Fre_Division Fre_Division_m4(
	.CP_in(clk), 
	.reset(reset), 
	.fre_div(16'd20), 
	.CP_out(signaltap_clk)
);

//加入CP后的时钟
Fre_Division Fre_Division_m1(
	.CP_in(clk), 
	.reset(reset), 
	.fre_div(16'd50), 
	.CP_out(clk_1MHz)
);

//二倍频
clk_800kHz clk_800kHz_m(
	.areset(~reset),
	.inclk0(clk),
	.c0(clk_800kHz),
	.locked()
);

//数据速率
Fre_Division Fre_Division_m2(
	.CP_in(clk_800kHz), 
	.reset(clk_reset), 
	.fre_div(16'd2), 
	.CP_out(clk_400kHz)
);

//二分频
Fre_Division Fre_Division_m3(
	.CP_in(clk_800kHz), 
	.reset(clk_reset), 
	.fre_div(16'd4), 
	.CP_out(clk_200kHz)
);

//串口接收
wire bps_clk;
wire rx_done;
wire [7:0] rx_data_out;
uart_rx uart_rx_m(
	.clk(clk),
	.reset(reset),
	.baud_set(3'd0),  			 //波特率设置
	.rx_data_in(rx_data), 		 //接收数据
	.bps_clk(bps_clk),			 //写fifo时钟
	.rx_data_out(rx_data_out),  //并行输出字节数据
	.rx_done(rx_done) 			 //一次数据接收完成标志
);

//fifo输入数据缓冲
//最多存储256字节
//8位写入,1位读出
wire rdreq;
wire wrreq;
wire fifo_rddata;
wire rdempty;
wire wrfull;
fifo_rx fifo_rx_m(
	.data(rx_data_out),
	.rdclk(clk_400kHz),
	.rdreq(rdreq),
	.wrclk(bps_clk),
	.wrreq(wrreq),
	.q(fifo_rddata),
	.rdempty(rdempty),
	.wrfull(wrfull)
);

//fifo读写控制
wire fifo_read_valid; 
fifo_ctrl fifo_ctrl_m(
	.rdclk(clk_400kHz),
	.wrclk(bps_clk),
	.reset(reset_n),
	.rdempty(rdempty),
	.wrfull(wrfull),
	.rx_done(rx_done),
	.rdreq(rdreq), //给出读请求信号
	.wrreq(wrreq), //给出写请求信号
	.fifo_read_valid(fifo_read_valid) //置高,表示从fifo中读出的数据开始输出
);

//(2,1,3)卷积码编码,码速加倍
wire enc_out; 			//卷积码编码输出,100MHz
wire conv_out_valid; //编码完成,数据开始输出
conv_code conv_code_m(
	.conv_clk(clk_400kHz), 
	.out_clk(clk_800kHz),
	.reset(reset_n), 
	.data_in(fifo_rddata), 
	.conv_en(fifo_read_valid),
	.data_out(enc_out),
	.conv_out_valid(conv_out_valid)
);

//16QAM映射
wire [7:0] I_real; //16QAM实部信号
wire [7:0] Q_imag; //16QAM虚部信号
wire sink_valid;   //拉高表示通知FFT即将有N个数据输入
wire sink_sop;     //输入数据起始标记脉冲
wire sink_eop;     //输入数据结束标记脉冲
wire sink_ready;   //FFT模块准备就绪,可以接收数据 
qam16 qam16_m(
	.clk(clk_400kHz), 
	.clk_div2(clk_200kHz), 
	.clk_mul2(clk_800kHz), 
	.reset(reset_n), 
	.start_run(conv_out_valid),
	.data_in(enc_out), 
	.I_real(I_real), 
	.Q_imag(Q_imag), 
	.sink_ready(sink_ready),
	.sink_sop(sink_sop), 
	.sink_eop(sink_eop), 
	.sink_valid(sink_valid)
);

//fft模块参数
//注意：输入输出均为有符号定点数
wire inverse;               //调制or解调标志,inverse==1?ifft:fft                                
wire [1:0] source_error;    //指示数据流的错误信息
wire source_sop;            //输出数据起始标记
wire source_eop;            //输出数据结束标记
wire source_valid;       	 //置高，准备输出结果      
wire [15:0] source_real_16; //输出数据实部
wire [15:0] source_imag_16; //输出数据虚部

//输入初始化
assign inverse = 1'b1; //inverse==1?ifft:fft
parameter sink_error = 2'b00;    //指示数据流的错误信息
parameter source_ready = 1'b1;   //可以接收数据

//fft ip核 定点
//128点ifft
wire [7:0] source_real;
wire [7:0] source_imag;
assign source_real = source_real_16[7:0];
assign source_imag = source_imag_16[7:0];
fft_ip fft_ip_m(
	.clk(clk_400kHz),          	//    clk.clk 
	.reset_n(reset_n),      		//    rst.reset_n
	.sink_valid(sink_valid),   	//   sink.sink_valid
	.sink_ready(sink_ready),   	//       .sink_ready
	.sink_error(sink_error),   	//       .sink_error
	.sink_sop(sink_sop),     		//       .sink_sop
	.sink_eop(sink_eop),    		//       .sink_eop
	.sink_real(I_real),   			//       .sink_real
	.sink_imag(Q_imag),    			//       .sink_imag
	.fftpts_in(128),    				//       .fftpts_in
	.inverse(inverse),      		//       .inverse
	.source_valid(source_valid), 	// source.source_valid
	.source_ready(source_ready), 	//       .source_ready
	.source_error(source_error), 	//       .source_error
	.source_sop(source_sop),   	//       .source_sop
	.source_eop(source_eop),   	//       .source_eop
	.source_real(source_real_16), //       .source_real
	.source_imag(source_imag_16), //       .source_imag
	.fftpts_out()    					//       .fftpts_out
);

//U_OFDM映射
//输出每帧256字节
wire [7:0] uofdm_out;
wire uofdm_valid;
u_ofdm u_ofdm_m(
	.clkin(clk_400kHz),
	.clkout(clk_800kHz),
	.reset(reset_n),
	.start_run(source_valid),
	.data_in(source_real),
	.data_out(uofdm_out),
	.uofdm_valid(uofdm_valid)
);

//添加循环前缀
//CP长度设为帧长的1/4,即64byte
wire out_valid; //调制完成,开始输出标志
add_CP add_CP_m(
	.clk(clk_800kHz), 
	.clk_addCP(clk_1MHz), 
	.reset(reset_n), 
	.start_run(uofdm_valid),
	.data_in(uofdm_out), 
	.data_out(data_out),
	.out_valid(out_valid)
);

	
endmodule

