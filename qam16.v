module qam16(
	input clk,
	input clk_div2,
	input clk_mul2,
	input reset,
	input start_run,
	input data_in,      	 	//输入编码后二进制序列,100MHz
	output wire [7:0] I_real, 	//输出16QAM信号,50MHz
	output wire [7:0] Q_imag,
	
	input sink_ready,     //FFT模块准备就绪,可以接收数据
	output wire sink_sop,  //输出数据起始标记
	output wire sink_eop,  //输出数据结束标记
	output wire sink_valid //拉高表示通知FFT即将有N个数据输入
);

//串并转换
reg [1:0] sp_cnt;
reg [3:0] store_cnt;
reg [2:0] delta_clk_cnt; //数据开始输入与开始存储之间相差的时钟数
reg [3:0] x_t,x_t_1;
reg store_vaild; //数据开始存储到RAM
always @(posedge clk_mul2 or negedge reset) begin
   if(!reset) begin
		x_t <= 0;
		x_t_1 <= 0;
		sp_cnt <= 0;
		store_cnt <= 0;
		delta_clk_cnt <= 0;
		store_vaild <= 0;
	end
	else if(start_run == 1) begin
		//串并转换
		sp_cnt <= sp_cnt + 1'b1;
		x_t_1[3:0] <= {x_t_1[2:0], data_in};
		if(sp_cnt == 0)
			x_t <= x_t_1;
		//存储标志位
		store_cnt <= store_cnt + 1'b1;
		if(store_cnt == 5)
			store_vaild <= 1'b1;
		//时钟差
		if(store_vaild == 0)
			delta_clk_cnt <= delta_clk_cnt + 1'b1;
	end
	else if(delta_clk_cnt > 1) begin
		delta_clk_cnt <= delta_clk_cnt - 1'b1;
		//串并转换
		sp_cnt <= sp_cnt + 1'b1;
		x_t_1[3:0] <= {x_t_1[2:0], data_in};
		if(sp_cnt == 0)
			x_t <= x_t_1;
		//存储标志位
		store_cnt <= store_cnt + 1'b1;
		if(store_cnt == 6)
			store_vaild <= 1'b1;
	end
	else begin
		x_t <= 0;
		x_t_1 <= 0;
		sp_cnt <= 0;
		store_cnt <= 0;
		delta_clk_cnt <= 0;
		store_vaild <= 0;
	end
end

//16QAM映射
reg signed[7:0] Isignal;
reg signed[7:0] Qsignal;
always @(posedge clk_mul2 or negedge reset) begin
   if(!reset) begin
     Isignal <= 0;
	  Qsignal <= 0;
	end
	else if(start_run == 1 || delta_clk_cnt > 1) begin	           
		   case(x_t)								//00 -- -1
		     4'b0000: begin						//01 -- -3
				 Isignal <= -8'd1;				//11 --  3
				 Qsignal <= -8'd1;				//10 --  1
			  end
		     4'b0001: begin  
				 Isignal <= -8'd1;
				 Qsignal <= -8'd3;
			  end
		     4'b0010: begin 
				 Isignal <= -8'd1;
				 Qsignal <=  8'd1;		  
			  end
		     4'b0011: begin 
				 Isignal <= -8'd1;
				 Qsignal <=  8'd3;			  
			  end
		     4'b0100: begin 
				 Isignal <= -8'd3;
				 Qsignal <= -8'd1;					  
			  end
		     4'b0101: begin 
				 Isignal <= -8'd3;
				 Qsignal <= -8'd3;
			  end
		     4'b0110: begin
				 Isignal <= -8'd3;
				 Qsignal <=  8'd1;			  
			  end
		     4'b0111: begin  
				 Isignal <= -8'd3;
				 Qsignal <=  8'd3;			  
			  end
		     4'b1000: begin
				 Isignal <=  8'd1;
				 Qsignal <= -8'd1;	  
			  end
		     4'b1001: begin 
				 Isignal <=  8'd1;
				 Qsignal <= -8'd3;				  
			  end
		     4'b1010: begin 
				 Isignal <=  8'd1;
				 Qsignal <=  8'd1;			  
			  end
		     4'b1011: begin
				 Isignal <=  8'd1;
				 Qsignal <=  8'd3;				  
			  end
		     4'b1100: begin 
				 Isignal <=  8'd3;
				 Qsignal <= -8'd1;	  
			  end
		     4'b1101: begin 
				 Isignal <=  8'd3;
				 Qsignal <= -8'd3;				  
			  end	
		     4'b1110: begin
				 Isignal <=  8'd3;
				 Qsignal <=  8'd1;				  
			  end	
		     4'b1111: begin 
				 Isignal <=  8'd3;
				 Qsignal <=  8'd3;	
			  end	
           default: begin
				 Isignal <=  8'd0;
				 Qsignal <=  8'd0;		
           end			  
		 endcase
	end
	else begin
		Isignal <= 0;
		Qsignal <= 0;
	end
end


//帧结构调整
//帧序号:      0,  1,  2,…,  63,     64,   65,…, 126, 127
//帧结构: Re[X0], X1, X2,…, X63, Im[X0], X63*,…, X2*, X1*
wire wren;
wire [6:0] wraddress;
wire [6:0] rdaddress_real;
wire [6:0] rdaddress_imag;
wire [7:0] RAM_real_out;
wire [7:0] RAM_imag_out;

//实部RAM-128字节
RAM_real RAM_real_m(
	.data(Isignal),
	.rdaddress(rdaddress_real),
	.rdclock(clk),
	.wraddress(wraddress),
	.wrclock(clk_div2),
	.wren(wren),
	.q(RAM_real_out)
);

//虚部RAM-128字节
RAM_imag RAM_imag_m(
	.data(Qsignal),
	.rdaddress(rdaddress_imag),
	.rdclock(clk),
	.wraddress(wraddress),
	.wrclock(clk_div2),
	.wren(wren),
	.q(RAM_imag_out)
);

//RAM控制模块
RAM_ctrl RAM_ctrl_m(
	.rdclock(clk),
	.wrclock(clk_div2),
	.reset(reset),
	.start_run(store_vaild),
	.data_real_in(RAM_real_out),
	.data_imag_in(RAM_imag_out),
	.wren(wren),
	.wraddress(wraddress),
	.rdaddress_real(rdaddress_real),
	.rdaddress_imag(rdaddress_imag),
	.data_real_out(I_real),
	.data_imag_out(Q_imag),
	.sink_ready(sink_ready),	//FFT模块准备就绪,可以接收数据
	.sink_sop(sink_sop),  		//输出数据起始标记
	.sink_eop(sink_eop),  		//输出数据结束标记
	.sink_valid(sink_valid) 	//拉高表示通知FFT即将有N个数据输入
);

endmodule
