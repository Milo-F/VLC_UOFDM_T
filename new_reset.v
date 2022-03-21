module new_reset(
	input clk,
	input reset,
	output reg reset_n,
	output reg clk_reset
);

reg [4:0] cnt;
always @(posedge clk or negedge reset) begin
   if(!reset) begin
		cnt <= 0;
		reset_n <= 0;
		clk_reset <= 0;
	end
	else begin
		cnt <= cnt +1'b1;
		if(cnt == 15)
			clk_reset <= 1'b1;
		else if(cnt == 31)
			reset_n <= 1'b1;
	end
end

endmodule

