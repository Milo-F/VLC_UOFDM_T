module u_ofdm(
	input clkin,  //50MHz
	input clkout, //100MHz
	input reset,
	input start_run,
	input  signed[7:0] data_in,
	output reg [7:0] data_out,
	output reg uofdm_valid
);

reg [7:0] enc_reg[1:0];    //编码输出寄存器
always@(posedge clkin or negedge reset) begin 
	if(!reset) begin
		enc_reg[1] <= 8'd0;
		enc_reg[0] <= 8'd0;
	end
	else if(start_run == 1) begin
		if(data_in > 0) begin
			enc_reg[1] <= data_in;
			enc_reg[0] <= 8'd0;
		end
		else if(data_in == -128) begin
			enc_reg[1] <= 8'd0;
			enc_reg[0] <= 8'd127;
		end
		else begin
			enc_reg[1] <= 8'd0;
			enc_reg[0] <= -data_in;
		end
	end
	else begin
		enc_reg[1] <= 8'd0;
		enc_reg[0] <= 8'd0;
	end
end

reg out_cnt;
reg uofdm_valid_aux; //辅助标志
reg [2:0] delta_clk_cnt; //数据开始输入与开始输出之间相差的时钟数
always@(posedge clkout or negedge reset) begin 
	if(!reset) begin	
		out_cnt <= 0;
		data_out <= 0;
		uofdm_valid <= 0;
		uofdm_valid_aux <= 0;
		delta_clk_cnt <= 0;
	end
	else if(start_run == 1) begin
		out_cnt <= out_cnt + 1'b1;
		if(out_cnt == 0)
			data_out <= enc_reg[1];
		else
			data_out <= enc_reg[0];
		uofdm_valid_aux <= 1'b1;
		if(out_cnt == 0 && uofdm_valid_aux == 1'b1)
			uofdm_valid <= 1'b1;
		if(uofdm_valid == 0)
			delta_clk_cnt <= delta_clk_cnt + 1'b1;
	end
	else if(delta_clk_cnt > 1) begin
		delta_clk_cnt <= delta_clk_cnt - 1'b1;
		out_cnt <= out_cnt + 1'b1;
		if(out_cnt == 0)
			data_out <= enc_reg[1];
		else
			data_out <= enc_reg[0];
	end
	else begin
		out_cnt <= 0;
		data_out <= 0;
		uofdm_valid <= 0;
		uofdm_valid_aux <= 0;
		delta_clk_cnt <= 0;
	end
end

endmodule
