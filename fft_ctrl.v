module fft_ctrl(
	input clk,
	input reset,
	input start_run,      //开始进行fft运算
	input sink_ready,     //FFT模块准备就绪,可以接收数据
	output reg sink_sop,  //输出数据起始标记
	output reg sink_eop,  //输出数据结束标记
	output reg sink_valid //拉高表示通知FFT即将有N个数据输入
);
		
reg [7:0] count;
reg [2:0] state;
parameter Sampling_num = 10'd128; //采样点数
		
parameter 	idle			= 3'b000,
				assert_sop	= 3'b001,
				assert_run	= 3'b010,
				assert_eop	= 3'b100;
	
always@(posedge clk or negedge reset) begin
	if(!reset) begin
		state <= idle;
		count <= 0;
		sink_sop <= 1'b0;
		sink_eop <= 1'b0;
		sink_valid <= 1'b0;
	end
	else if(start_run == 1) begin
		case(state)
		idle: begin
			if(sink_ready == 1)
				state <= assert_sop;
			else
				state <= idle;
				sink_sop <= 1'b0;
				sink_eop <= 1'b0;
				sink_valid <= 1'b0;
		end
		
		assert_sop: begin
			state <= assert_run;
			count <= count + 1'b1;
			sink_sop <= 1'b1;
			sink_eop <= 1'b0;
			sink_valid <= 1'b1;
		end
		
		assert_run: begin
			if(count < Sampling_num-2) begin
				state <= assert_run;
				count <= count + 1'b1;
			end
			else begin
				state <= assert_eop;
				count <= count + 1'b1;
			end
			sink_sop <= 1'b0;
			sink_eop <= 1'b0;
			sink_valid <= 1'b1;
		end
		
		assert_eop: begin
			state <= assert_sop;
			count <= 0;
			sink_sop <= 1'b0;
			sink_eop <= 1'b1;
			sink_valid <= 1'b1;
		end
	endcase
	end
end 
	
endmodule




