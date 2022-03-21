module Fre_Division(
	input CP_in,       	//输入时钟
	input reset,       	//复位信号
	input [15:0] fre_div, //分频值
	output reg CP_out 	//输出时钟
);

reg [15:0] clk_cnt;
always @(posedge CP_in or negedge reset) begin
	if(!reset) begin
		clk_cnt <= 0;
	end
	else if(clk_cnt == fre_div/2-1)
		clk_cnt <= 0;
	else
		clk_cnt <= clk_cnt + 1'b1;
end

always @(posedge CP_in or negedge reset) begin
	if(!reset) begin
		 CP_out <= 0;
	end
	else begin
		if(clk_cnt == 0)
			CP_out = ~CP_out;
		else
			CP_out = CP_out;
	end
end

endmodule
