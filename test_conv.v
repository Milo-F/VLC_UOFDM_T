`timescale 1ns / 1ps
module test_conv;

reg clk;
reg reset;
wire m_seq;   //m序列
wire enc_out; //编码输出
wire conv_out_valid; //置高表示编码后的数据开始输出
wire dec_out;   //解码输出
wire dec_valid; //置高表示解码后的数据开始输出

initial 
begin
clk = 0;
reset = 0;
#200;
reset = 1;
end

//T=20ns,f=50MHz
always #10 clk = ~clk;

//(2,1,3)卷积码编码
conv_code conv_code_m
(
	.clk(clk), 
	.reset(reset), 
	.data_in(m_seq), 
	.data_out(enc_out),
	.conv_out_valid(conv_out_valid)
);

//维特比解码
viterbi viterbi_m
(
	.clk(clk), 
	.reset(reset), 
	.data_in(enc_out), 
	.dec_start(conv_out_valid), 
	.judge_out(), 
	.dec_out(dec_out), 
	.dec_valid(dec_valid)
);

//m序列
m_sequence m_sequence_m
(
	.clk(clk), 
	.reset(reset), 
	.out(m_seq)
);


endmodule
