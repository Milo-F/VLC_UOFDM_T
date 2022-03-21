module addcp_ctrl (
	input wrclock, //100MHz
	input rdclock, //125MHz
	input reset,
	input start_run,
	input [7:0] syn_data_in,
	input [7:0] addcp_data_in,
	output wire wren,
	output reg [8:0] wraddress,
	output reg [8:0] rdaddress,
	output reg [3:0] synaddress,
	output reg [7:0] addcp_data_out,
	output reg addcp_vaild
);

assign wren = start_run;

reg read_valid; //开始读取
reg [8:0] wr_byte_cnt;
always @(posedge wrclock or negedge reset) begin
   if(!reset) begin
		read_valid <= 0;
		wraddress <= 0;
		wr_byte_cnt <= 0;
	end
	else if(start_run == 1) begin
		wraddress <= wraddress + 1'b1;		
		if(wraddress == 195 && read_valid == 0) begin //使读写不重叠的最小wraddress
			read_valid <= 1'b1;
			wr_byte_cnt <= 9'd256 + 9'd10;
		end
		if(read_valid == 1) begin
			wr_byte_cnt <= wr_byte_cnt - 1'b1;
			if(wr_byte_cnt == 0)
				wr_byte_cnt <= 9'd255;
		end
	end
	else if(wr_byte_cnt > 0) begin
		wraddress <= 0;
		wr_byte_cnt <= wr_byte_cnt - 1'b1;
		if(wr_byte_cnt == 1)
			read_valid <= 0;
	end
	else begin
		wraddress <= 0;
		read_valid <= 0;
		wr_byte_cnt <= 0;
	end
end


reg [3:0] syn_cnt; 		 //读取同步码计数器
reg [8:0] addcp_cnt; 	 //读取数据帧计数器
reg [2:0] delta_clk_cnt; //数据开始输出与读使能之间相差的时钟数
reg start_read_addcp; 	 //读取数据帧
reg start_out_addcp;     //连续输出加入循环前缀的结果
reg read_end_syn_valid;  //读取尾同步标志
always @(posedge rdclock or negedge reset) begin
   if(!reset) begin
		syn_cnt <= 0; 
		addcp_cnt <= 0;
		delta_clk_cnt <= 0;
		start_read_addcp <= 0;
		start_out_addcp <= 0;
		read_end_syn_valid <= 0;
		rdaddress <= 9'd511;
		synaddress <= 0;
		addcp_data_out <= 0;
		addcp_vaild <= 0;
	end
	else if(read_valid == 1) begin
		if(addcp_vaild == 0)
			delta_clk_cnt <= delta_clk_cnt + 1'b1;
		if(syn_cnt < 4'd15) begin
			syn_cnt <= syn_cnt + 1'b1;
		end
		casex(syn_cnt)
		4'b000x: begin //4'd0 ~ 4'd1
			synaddress <= synaddress + 1'b1;
			addcp_data_out <= syn_data_in;
		end
		4'b0010: begin //4'd2
			addcp_vaild <= 1'b1;
			synaddress <= synaddress + 1'b1;
			addcp_data_out <= syn_data_in;
		end
		4'b0011, 4'b01xx, 4'b100x, 4'b1010: begin //4'd3 ~ 4'd10
			synaddress <= synaddress + 1'b1;
			addcp_data_out <= syn_data_in;
		end
		4'b1011: begin //4'd11
			start_read_addcp <= 1'b1;
			synaddress <= synaddress + 1'b1;
			addcp_data_out <= syn_data_in;
		end
		4'b110x, 4'b1110: begin //4'd12 ~ 4'd14
			synaddress <= 0;
			addcp_data_out <= syn_data_in;
		end
		4'b1111: //4'd15
			synaddress <= 0;
		endcase
		
		if(start_read_addcp == 1) begin
			if(addcp_cnt == 9'd319)
				addcp_cnt <= 0;
			else
				addcp_cnt <= addcp_cnt + 1'b1;
			if(addcp_cnt == 9'd3 || start_out_addcp == 1) begin
				addcp_data_out <= addcp_data_in;
				start_out_addcp <= 1;
			end
			casex(addcp_cnt)
			9'b000000000: begin //9'd0
				rdaddress <= rdaddress + 9'd193;
			end
			9'b000000001, 9'b00000001x, 9'b0000001xx, 9'b000001xxx, 9'b00001xxxx, 9'b0001xxxxx: begin //9'd1 ~ 9'd63
				rdaddress <= rdaddress + 1'b1;
			end
			9'b001000000: begin //9'd64
				rdaddress <= rdaddress - 8'd255;
			end
			9'b001000001, 9'b00100001x, 9'b0010001xx, 9'b001001xxx, 9'b00101xxxx, 9'b0011xxxxx, 9'b01xxxxxxx, 9'b100xxxxxx: begin //9'd65 ~ 9'd319
				rdaddress <= rdaddress + 1'b1;
			end
			endcase
		end
	end
	else if(delta_clk_cnt > 0) begin
		delta_clk_cnt <= delta_clk_cnt - 1'b1;  
		read_end_syn_valid <= 1'b1; 		//帧后同步
		if(syn_cnt < 4'd15) begin
			syn_cnt <= syn_cnt + 1'b1;
			synaddress <= synaddress + 1'b1;
		end
		else begin
			syn_cnt <= 4'd0;	
			synaddress <= 0;
		end
		
		if(start_read_addcp == 1) begin
			if(addcp_cnt == 9'd319)
				addcp_cnt <= 0;
			else
				addcp_cnt <= addcp_cnt + 1'b1;
			if(addcp_cnt == 9'd3 || start_out_addcp == 1) begin
				addcp_data_out <= addcp_data_in;
				start_out_addcp <= 1;
			end
			casex(addcp_cnt)
			9'b000000000: begin //9'd0
				rdaddress <= rdaddress + 9'd193;
			end
			9'b000000001, 9'b00000001x, 9'b0000001xx, 9'b000001xxx, 9'b00001xxxx, 9'b0001xxxxx: begin //9'd1 ~ 9'd63
				rdaddress <= rdaddress + 1'b1;
			end
			9'b001000000: begin //9'd64
				rdaddress <= rdaddress - 8'd255;
			end
			9'b001000001, 9'b00100001x, 9'b0010001xx, 9'b001001xxx, 9'b00101xxxx, 9'b0011xxxxx, 9'b01xxxxxxx, 9'b100xxxxxx: begin //9'd65 ~ 9'd319
				rdaddress <= rdaddress + 1'b1;
			end
			endcase
		end
	end
	else if(read_end_syn_valid == 1) begin //帧后同步
		if(syn_cnt < 4'd15) begin
			syn_cnt <= syn_cnt + 1'b1;
		end
		casex(syn_cnt)
		4'b000x, 4'b001x, 4'b01xx, 4'b10xx: begin //4'd0 ~ 4'd11
			synaddress <= synaddress + 1'b1;
			addcp_data_out <= syn_data_in;
		end
		4'b110x: begin //4'd12 ~ 4'd13
			synaddress <= 0;
			addcp_data_out <= syn_data_in;
		end
		4'b1110: begin //4'd14
			synaddress <= 0;
			addcp_data_out <= syn_data_in;
			read_end_syn_valid <= 0;
		end
		4'b1111: //4'd15
			synaddress <= 0;
		endcase
	end
	else begin
		syn_cnt <= 0; 
		addcp_cnt <= 0;
		delta_clk_cnt <= 0;
		start_read_addcp <= 0;
		start_out_addcp <= 0;
		read_end_syn_valid <= 0;
		rdaddress <= 9'd511;
		synaddress <= 0;
		addcp_data_out <= 0;
		addcp_vaild <= 0;
	end
end


endmodule
