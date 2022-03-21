//(n,k,N)=(2,1,3)卷积码,生成矩阵g0=111,g1=101
//码率=1/2,约束长度为3
//未加删余,可使用无删余卷积编码，2/3码率删余卷积编码，3/4码率删余卷积编码
module conv_code(
	input conv_clk,  //编码时钟,50MHz 
	input out_clk,   //数据输出时钟,100MHz
	input reset,	  // 异步复位，低电平有效
	input data_in,	  //待编码数据
	input conv_en,   //置高开始编码
	output reg data_out,
	output reg conv_out_valid //置高表示编码后的数据开始输出
);

reg [2:1] shift_reg;  //编码移位寄存器
reg [1:0] enc_reg;    //编码输出寄存器
reg out_cnt;
reg [2:0] delta_clk_cnt; //数据开始输入与开始输出之间相差的时钟数
reg conv_out_valid_aux;  //辅助输出
always@(posedge out_clk or negedge reset) begin
	if(!reset) begin
		out_cnt <= 0;
		data_out <= 0;
		delta_clk_cnt <= 0;
		conv_out_valid <= 0;
		conv_out_valid_aux <= 0;
	end
	else if(conv_en == 1) begin //输出时B在前,A在后
		out_cnt <= out_cnt + 1'b1;
		if(out_cnt == 0)
			data_out <= enc_reg[1];
		else
			data_out <= enc_reg[0];
		conv_out_valid_aux <= 1'b1;
		if(out_cnt == 0 && conv_out_valid_aux == 1)
			conv_out_valid <= 1'b1;		
		if(conv_out_valid == 0)
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
		delta_clk_cnt <= 0;
		conv_out_valid <= 0;
		conv_out_valid_aux <= 0;
	end
end

always@(posedge conv_clk or negedge reset) begin 
	if(!reset) begin
		shift_reg <= 2'b00;
		enc_reg <= 2'b00;
	end
	else if(conv_en == 1) begin
		enc_reg[0] <= data_in + shift_reg[1] + shift_reg[2];	  //数据A多项式：g0(x) = 1 + x + x^2
		enc_reg[1] <= data_in + shift_reg[2]; 	              //数据B多项式：g1(x) = 1 + x^2
		shift_reg <= {shift_reg[1], data_in};
	end
	else begin
		shift_reg <= 2'b00;
		enc_reg <= 2'b00;
	end
end

endmodule
