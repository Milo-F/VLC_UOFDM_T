//功能：产生m序列
//本原多项式 f(x) = x^25 + x^3 + 1
module m_sequence (
	input clk,
	input reset,
	output wire out //最终输出
);

reg[24:0] shift; //25位移位寄存器
wire C0;

assign C0 = shift[24]^shift[2]; //中间节点
assign out = shift[24];

always @(posedge clk or negedge reset)
if(~reset)
	shift[24:0] <= 25'b0110101000101101011100101;
else 
	shift[24:0] <= {shift[23:0],C0};

endmodule
