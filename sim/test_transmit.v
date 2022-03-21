`timescale 1ns/1ps
module test_transmit;

reg clk;
reg reset;
reg send_en;
reg [7:0] tx_data;
reg continue_send;
wire txd;
wire [7:0] data_out;

initial begin
clk = 0;
reset = 0;
send_en = 0;
tx_data = 0;
continue_send = 0;
#200  //由于fft ip核需要初始化,所以将reset时间设为时钟周期的10倍
reset = 1;
#100 
tx_data = 8'b10011001;
#100 
send_en = 1'b1;
#100 
tx_data = 8'b01100110;
#86820 
tx_data = 8'b00000000;
continue_send = 1'b1;
send_en = 1'b0;
end

//T=20ns,f=50MHz
always #10 clk = ~clk;

//生成发送数据
always #86820
if(continue_send == 1)
	tx_data = tx_data + 8'd1;
	
//读取输出数据
integer transmit_out;
integer transmit_out_int;
reg vlc_transmit_out;
initial begin
vlc_transmit_out = 0;
transmit_out = $fopen("vlc_transmit_output.txt");
#302140 vlc_transmit_out = 1;
end

//写入数据,50MHz
parameter MAXVAL_c = 2**7;
parameter OFFSET_c = 2**8;
always #20 begin
	if(vlc_transmit_out == 1) begin
		transmit_out_int = data_out;
		$fdisplay(transmit_out, "%d", (transmit_out_int < MAXVAL_c) ? transmit_out_int : transmit_out_int - OFFSET_c);
	end
end
	
//模拟串口发送数据
uart_tx uart_tx_m(
	.clk(clk),
	.reset(reset),
	.baud_set(3'd0), 		//波特率设置
	.send_en(send_en),   //发送使能
	.tx_data(tx_data),   //待传输8bit数据
	.txd(txd),		 		//输出信号
	.tx_done() 		 		//一次发送数据完成标志
);

//ofdm调制模块
vlc_transmit vlc_transmit_m(
	.clk(clk), 
	.reset(reset),  
	.rx_data(txd), 
	.data_out(data_out)
);


endmodule
