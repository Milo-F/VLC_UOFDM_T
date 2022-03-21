module add_CP(
	input clk, //100MHz
	input clk_addCP, //125MHz
	input reset,
	input start_run,       //开始标志位(ip核开始输出)
	input [7:0] data_in,   //ifft后的序列,50MHz
	output wire [7:0] data_out, //输出加入CP后的信号,62.5MHz
	output wire out_valid       //开始输出标志
);

wire wren;
wire [8:0] rdaddress;
wire [8:0] wraddress;
wire [3:0] synaddress;
wire [7:0] ROM_syn_out;
wire [7:0] RAM_addcp_out;

//ROM-13字节-巴克码
ROM_syn ROM_syn_m(
	.address(synaddress),
	.clock(clk_addCP),
	.q(ROM_syn_out)
);

//RAM-512字节-ifft输出序列
RAM_addcp RAM_addcp_m(
	.data(data_in),
	.rdaddress(rdaddress),
	.rdclock(clk_addCP),
	.wraddress(wraddress),
	.wrclock(clk),
	.wren(wren),
	.q(RAM_addcp_out)
);

//循环前缀控制模块
addcp_ctrl addcp_ctrl_m(
	.wrclock(clk),
	.rdclock(clk_addCP),
	.reset(reset),
	.start_run(start_run),
	.syn_data_in(ROM_syn_out),
	.addcp_data_in(RAM_addcp_out),
	.wren(wren),
	.wraddress(wraddress),
	.rdaddress(rdaddress),
	.synaddress(synaddress),
	.addcp_data_out(data_out),
	.addcp_vaild(out_valid)
);


endmodule
