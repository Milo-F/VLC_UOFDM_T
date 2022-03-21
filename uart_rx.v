module uart_rx(
	input clk,
	input reset,
	input [2:0] baud_set,   		 //波特率设置
	input rx_data_in,  				 //接收数据
	output wire bps_clk,				 //产生波特率对应的时钟
	output reg [7:0] rx_data_out,  //并行输出字节数据
	output reg rx_done 				 //一次数据接收完成标志
);

//设置状态机
reg[3:0] state;
parameter S_IDLE   = 4'd0;
parameter S_START  = 4'd1;
parameter S_BIT0   = 4'd2;
parameter S_BIT1   = 4'd3;
parameter S_BIT2   = 4'd4;
parameter S_BIT3   = 4'd5;
parameter S_BIT4   = 4'd6;
parameter S_BIT5   = 4'd7;
parameter S_BIT6   = 4'd8;
parameter S_BIT7   = 4'd9;
parameter S_STOP   = 4'd10;

reg [15:0] bit_cnt; //状态计数器
reg [15:0] out_cnt; //辅助输出rx_done计数器
reg rx_data_in_d0;  //接收数据寄存器
reg rx_data_in_d1;
reg [7:0] rx_data_byte; //并行输出字节数据
wire rx_data_negedge; //下降沿-判定起始位
assign rx_data_negedge = rx_data_in_d1 & ~rx_data_in_d0; //d0=0且d1=1时下降沿有效

always@(posedge clk or negedge reset) begin
	if(~reset) begin
		rx_data_in_d0 <= 1'b0;
		rx_data_in_d1 <= 1'b0;
	end 
	else begin
		rx_data_in_d0 <= rx_data_in;
		rx_data_in_d1 <= rx_data_in_d0;
	end
end

//设置波特率, bps_DR = 50M/baud_rate, 即每bps_DR个时钟脉冲传送1bit数据
reg [15:0] bps_DR;//波特率分频值
always@(posedge clk or negedge reset) begin
	if(!reset)
		bps_DR <= 16'd5207;
	else
		case(baud_set)
			0:bps_DR <= 16'd5207; //9600
			1:bps_DR <= 16'd2603; //19200
			2:bps_DR <= 16'd1301; //38400
			3:bps_DR <= 16'd867;  //57600
			4:bps_DR <= 16'd433;  //115200
			default:bps_DR <= 16'd5207;			
		endcase
end

//产生写fifo时钟
wire [15:0] fre_div;
assign fre_div = bps_DR+16'd1;
Fre_Division Fre_Division_m(
	.CP_in(clk), 
	.reset(reset), 
	.fre_div(fre_div), 
	.CP_out(bps_clk)
);

always@(posedge clk or negedge reset) begin
	if(~reset) begin
		bit_cnt <= 16'd0;
		out_cnt <= 16'd0;
		state <= S_IDLE;
		rx_data_byte <= 8'd0;
		rx_data_out <= 8'd0;
		rx_done <= 1'b0;
	end
	else begin
		case(state)
			S_IDLE: begin
				if(rx_data_negedge)
					state <= S_START;
				if(out_cnt == bps_DR) begin
					rx_done <= 1'b0;
					out_cnt <= 16'd0;
				end
				else
					out_cnt <= out_cnt + 16'd1;
			end
			
			S_START: begin
				if(bit_cnt == bps_DR) begin 
					state <= S_BIT0;
					bit_cnt <= 16'd0;
				end
				else
					bit_cnt <= bit_cnt + 16'd1;
				if(out_cnt == bps_DR) begin
					rx_done <= 1'b0;
					out_cnt <= 16'd0;
				end
				else
					out_cnt <= out_cnt + 16'd1;
			end
			
			S_BIT0: begin
				if(bit_cnt == bps_DR) begin
					state <= S_BIT1;
					bit_cnt <= 16'd0;
				end
				else
					bit_cnt <= bit_cnt + 16'd1; 
				
				if(bit_cnt == bps_DR>>1) //在每bit数据的中间位置读取
					rx_data_byte[0] <= rx_data_in_d1; 
			end

			S_BIT1: begin
				if(bit_cnt == bps_DR) begin
					state <= S_BIT2;
					bit_cnt <= 16'd0;
				end
				else 
					bit_cnt <= bit_cnt + 16'd1;
				
				if(bit_cnt == bps_DR>>1)
					rx_data_byte[1] <= rx_data_in_d1;
			end

			S_BIT2: begin
				if(bit_cnt == bps_DR) begin
					state <= S_BIT3;
					bit_cnt <= 16'd0;
				end
				else 
					bit_cnt <= bit_cnt + 16'd1;
				
				if(bit_cnt == bps_DR>>1)
					rx_data_byte[2] <= rx_data_in_d1;
			end

			S_BIT3: begin
				if(bit_cnt == bps_DR) begin
					state <= S_BIT4;
					bit_cnt <= 16'd0;
				end
				else 
					bit_cnt <= bit_cnt + 16'd1;
				
				if(bit_cnt == bps_DR>>1)
					rx_data_byte[3] <= rx_data_in_d1;
			end

			S_BIT4: begin
				if(bit_cnt == bps_DR) begin
					state <= S_BIT5;
					bit_cnt <= 16'd0;
				end
				else 
					bit_cnt <= bit_cnt + 16'd1;
				
				if(bit_cnt == bps_DR>>1)
					rx_data_byte[4] <= rx_data_in_d1;
			end

			S_BIT5: begin
				if(bit_cnt == bps_DR) begin
					state <= S_BIT6;
					bit_cnt <= 16'd0;
				end
				else 
					bit_cnt <= bit_cnt + 16'd1;
				
				if(bit_cnt == bps_DR>>1)
					rx_data_byte[5] <= rx_data_in_d1;
			end

			S_BIT6: begin
				if(bit_cnt == bps_DR) begin
					state <= S_BIT7;
					bit_cnt <= 16'd0;
				end
				else 
					bit_cnt <= bit_cnt + 16'd1;
				
				if(bit_cnt == bps_DR>>1)
					rx_data_byte[6] <= rx_data_in_d1;
			end

			S_BIT7: begin
				if(bit_cnt == bps_DR) begin
					state <= S_STOP;
					bit_cnt <= 16'd0;
				end
				else
					bit_cnt <= bit_cnt + 16'd1;
				
				if(bit_cnt == bps_DR>>1)
					rx_data_byte[7] <= rx_data_in_d1;
			end

			S_STOP: begin
				if(bit_cnt == bps_DR>>1) begin
					state <= S_IDLE;
					bit_cnt <= 16'd0;
				end
				else begin
					bit_cnt <= bit_cnt + 16'd1;
					out_cnt <= out_cnt + 16'd1;
				end
				
				if((bit_cnt == bps_DR>>2) & rx_data_in_d1) begin
					rx_data_out <= rx_data_byte;
					rx_done <= 1'b1;
					out_cnt <= 16'd0;
				end
			end
			
			default:
				state <= S_IDLE;		
		endcase
	end
end
endmodule 
