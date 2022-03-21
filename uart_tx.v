module uart_tx(
	input clk,
	input reset,
	input [2:0] baud_set, //波特率设置
	input send_en,    	 //发送使能
	input [7:0] tx_data,  //待传输8bit数据
	output reg txd,		 //输出信号
	output tx_done 		 //一次发送数据完成标志
);

//设置状态机
reg [3:0] state;
parameter S_IDLE  = 4'd0;
parameter S_START = 4'd1;
parameter S_BIT0  = 4'd2;
parameter S_BIT1  = 4'd3;
parameter S_BIT2  = 4'd4;
parameter S_BIT3  = 4'd5;
parameter S_BIT4  = 4'd6;
parameter S_BIT5  = 4'd7;
parameter S_BIT6  = 4'd8;
parameter S_BIT7  = 4'd9;
parameter S_STOP  = 4'd10;

reg[15:0] bit_cnt;      //状态计数器
reg[7:0] tx_data_latch; //锁存器,保存待传输8bit数据
assign tx_done = (state == S_IDLE);

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

always@(posedge clk or negedge reset) begin
	if(!reset) begin
		state <= S_IDLE;
		bit_cnt <= 16'd0;
		txd <= 1'b1;
		tx_data_latch <= 8'h00;
	end
	else begin
		case(state)
			S_IDLE: begin
				txd <= 1'b1;
				bit_cnt <= 16'd0;
				if(send_en) begin
					state <= S_START;
					tx_data_latch <= tx_data;
				end
				else
					state <= state;
			end
			
			S_START: begin
				txd <= 1'b0;
				if(bit_cnt == bps_DR) begin
					state <= S_BIT0;
					bit_cnt <= 16'd0;
				end
				else begin
					state <= state;
					bit_cnt <= bit_cnt + 16'd1;
				end
			end
			
			S_BIT0: begin
				txd <= tx_data_latch[0];
				if(bit_cnt == bps_DR) begin
					state <= S_BIT1;
					bit_cnt <= 16'd0;
				end
				else begin
					state <= state;
					bit_cnt <= bit_cnt + 16'd1;
				end
			end

			S_BIT1: begin
				txd <= tx_data_latch[1];
				if(bit_cnt == bps_DR) begin
					state <= S_BIT2;
					bit_cnt <= 16'd0;
				end
				else begin
					state <= state;
					bit_cnt <= bit_cnt + 16'd1;
				end
			end
	
			S_BIT2: begin
				txd <= tx_data_latch[2];
				if(bit_cnt == bps_DR) begin
					state <= S_BIT3;
					bit_cnt <= 16'd0;
				end
				else begin
					state <= state;
					bit_cnt <= bit_cnt + 16'd1;
				end
			end
		
			S_BIT3: begin
				txd <= tx_data_latch[3];
				if(bit_cnt == bps_DR) begin
					state <= S_BIT4;
					bit_cnt <= 16'd0;
				end
				else begin
					state <= state;
					bit_cnt <= bit_cnt + 16'd1;
				end
			end
		
			S_BIT4: begin
				txd <= tx_data_latch[4];
				if(bit_cnt == bps_DR) begin
					state <= S_BIT5;
					bit_cnt <= 16'd0;
				end
				else begin
					state <= state;
					bit_cnt <= bit_cnt + 16'd1;
				end
			end
		
			S_BIT5: begin
				txd <= tx_data_latch[5];
				if(bit_cnt == bps_DR) begin
					state <= S_BIT6;
					bit_cnt <= 16'd0;
				end
				else begin
					state <= state;
					bit_cnt <= bit_cnt + 16'd1;
				end
			end
		
			S_BIT6: begin
				txd <= tx_data_latch[6];
				if(bit_cnt == bps_DR) begin
					state <= S_BIT7;
					bit_cnt <= 16'd0;
				end
				else begin
					state <= state;
					bit_cnt <= bit_cnt + 16'd1;
				end
			end
		
			S_BIT7: begin
				txd <= tx_data_latch[7];
				if(bit_cnt == bps_DR) begin
					state <= S_STOP;
					bit_cnt <= 16'd0;
				end
				else begin
					state <= state;
					bit_cnt <= bit_cnt + 16'd1;
				end
			end
	
			S_STOP: begin
				txd <= 1'b1;
				if(bit_cnt == bps_DR) begin
					state <= S_IDLE;
					bit_cnt <= 16'd0;
				end
				else begin
					state <= state;
					bit_cnt <= bit_cnt + 16'd1;
				end
			end
			default:
				state <= S_IDLE;
		endcase
	end
end
endmodule 
