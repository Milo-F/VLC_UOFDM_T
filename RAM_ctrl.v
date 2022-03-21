module RAM_ctrl (
	input rdclock,
	input wrclock,
	input reset,
	input start_run,
	input [7:0] data_real_in,
	input [7:0] data_imag_in,
	output wire wren,
	output reg [6:0] wraddress,
	output reg [6:0] rdaddress_real,
	output reg [6:0] rdaddress_imag,
	output reg [7:0] data_real_out,
	output reg [7:0] data_imag_out,
	
	input sink_ready,     //FFT模块准备就绪,可以接收数据
	output reg sink_sop,  //输出数据起始标记
	output reg sink_eop,  //输出数据结束标记
	output reg sink_valid //拉高表示通知FFT即将有N个数据输入
);

assign wren = start_run;

reg rd_en; 			//写入不满一帧时辅助输出
reg still_rd; 		//写入不满半帧时,避免漏读帧
reg read_valid; 	//开始读取
reg [6:0] wr_byte_cnt;
reg [6:0] wr_stop_address; //数据写完时的写地址
always @(posedge wrclock or negedge reset) begin 
   if(!reset) begin
		rd_en <= 0;
		still_rd <= 0;
		wraddress <= 0;
		read_valid <= 0;
		wr_byte_cnt <= 0;
		wr_stop_address <= 0;
	end
	else if(wren == 1) begin //开始写入
		rd_en <= 1'b1;
		wraddress <= wraddress + 1'b1;
		if(wraddress >= 64)
			wr_stop_address <= wraddress - 7'd64;
		else
			wr_stop_address <= wraddress;
		case(wraddress)
		7'd0: begin //避免漏读帧
			if(rd_en == 1)
				still_rd <= 1'b1;
			else
				still_rd <= 1'b0;
		end
		7'd32: begin //存完半帧(32byte)后,边读边写
			still_rd <= 1'b0;
			read_valid <= 1'b1;
			if(read_valid == 0)
				wr_byte_cnt <= 7'd64;
		end
		7'd64: begin 
			still_rd <= 1'b1;
		end
		7'd96: begin
			still_rd <= 1'b0;
		end
		endcase
		if(read_valid == 1) begin	
			if(wr_byte_cnt == 0)
				wr_byte_cnt <= 7'd63;
			else
				wr_byte_cnt <= wr_byte_cnt - 1'b1;
		end
	end
	else if(rd_en == 1 && read_valid == 0) begin
		rd_en <= 0;
		wraddress <= 0;
		read_valid <= 1'b1; //数据写完后开始读
		wr_byte_cnt <= 7'd64;
	end
	else if(wr_byte_cnt > 0 || still_rd == 1) begin
		rd_en <= 0;
		wraddress <= 0;
		if(wr_byte_cnt == 0) begin
			still_rd <= 1'b0;
			wr_byte_cnt <= 7'd63;
		end
		else
			wr_byte_cnt <= wr_byte_cnt - 1'b1;
		if(wr_byte_cnt == 1 && still_rd == 0)
			read_valid <= 0;
	end
	else begin
		rd_en <= 0;
		still_rd <= 0;
		wraddress <= 0;
		read_valid <= 0;
		wr_byte_cnt <= 0;
		wr_stop_address <= 0;
	end
end

reg [6:0] rdcnt; //读取状态计数
reg [2:0] delta_clk_cnt; //数据开始读出与开始进行ifft之间相差的时钟数
always @(posedge rdclock or negedge reset) begin
   if(!reset) begin
		rdcnt <= 0;
		delta_clk_cnt <= 0;
		rdaddress_real <= 0;
		rdaddress_imag <= 0;	 
		data_real_out <= 0;
		data_imag_out <= 0;
		sink_sop <= 0;
		sink_eop <= 0;
		sink_valid <= 0;
	end
	else if(read_valid == 1) begin		
		if(sink_valid == 0)
			delta_clk_cnt <= delta_clk_cnt + 1'b1;
		rdcnt <= rdcnt + 1'b1;
		casex(rdcnt)
		7'b00xxxxx, 7'b010xxxx, 7'b0110xxx, 7'b01110xx, 7'b011110x, 7'b0111110: begin //7'd0 ~ 7'd62
			rdaddress_real <= rdaddress_real + 1'b1;
			rdaddress_imag <= rdaddress_imag + 1'b1;
		end
		7'b0111111: begin //7'd63
			rdaddress_real <= rdaddress_real;
			rdaddress_imag <= rdaddress_imag - 7'd63;
		end
		7'b1000000: begin //7'd64
			rdaddress_real <= rdaddress_real;
			rdaddress_imag <= rdaddress_real;
		end
		7'b1000001, 7'b100001x, 7'b10001xx, 7'b1001xxx, 7'b101xxxx, 7'b110xxxx, 7'b1110xxx, 7'b11110xx, 7'b111110x, 7'b1111110: begin //7'd65 ~ 7'd126
			rdaddress_real <= rdaddress_real - 1'b1;
			rdaddress_imag <= rdaddress_imag - 1'b1;
		end
		7'b1111111: begin //7'd127
			rdaddress_real <= rdaddress_real + 7'd63;
			rdaddress_imag <= rdaddress_imag + 7'd63;
		end
		endcase

		casex(rdcnt)
		7'b0000001: begin //7'd1
			if(rd_en == 0 && still_rd == 0 && ((rdcnt > wr_stop_address + 2 && rdcnt < 66) || (rdcnt > 66 && rdcnt < 130 - wr_stop_address))) begin
				data_real_out <= 0; //当数据未写满一帧时,防止读出以前写入的数据
				data_imag_out <= 0;
			end
			else begin
				data_real_out <=  data_real_in;
				data_imag_out <= -data_imag_in;
			end
			if(sink_ready == 1) begin
				sink_sop <= 1'b0;
				sink_eop <= 1'b1;
			end
		end
		7'b0000010: begin //7'd2
			if(rd_en == 0 && still_rd == 0 && ((rdcnt > wr_stop_address + 2 && rdcnt < 66) || (rdcnt > 66 && rdcnt < 130 - wr_stop_address))) begin
				data_real_out <= 0;
				data_imag_out <= 0;
			end
			else begin
				data_real_out <= data_real_in;
				data_imag_out <= 0;
			end
			if(sink_ready == 1) begin
				sink_sop <= 1'b1;
				sink_eop <= 1'b0;
				sink_valid <= 1'b1;
			end
		end
		7'b0000011: begin //7'd3
			if(rd_en == 0 && still_rd == 0 && ((rdcnt > wr_stop_address + 2 && rdcnt < 66) || (rdcnt > 66 && rdcnt < 130 - wr_stop_address))) begin
				data_real_out <= 0;
				data_imag_out <= 0;
			end
			else begin
				data_real_out <= data_real_in;
				data_imag_out <= data_imag_in;
			end
			if(sink_ready == 1) begin
				sink_sop <= 1'b0;
				sink_eop <= 1'b0;
			end
		end
		7'b0000011, 7'b00001xx, 7'b0001xxx, 7'b001xxxx, 7'b01xxxxx, 7'b100000x: begin //7'd4 ~ 7'd65
			if(rd_en == 0 && still_rd == 0 && ((rdcnt > wr_stop_address + 2 && rdcnt < 66) || (rdcnt > 66 && rdcnt < 130 - wr_stop_address))) begin
				data_real_out <= 0;
				data_imag_out <= 0;
			end
			else begin
				data_real_out <= data_real_in;
				data_imag_out <= data_imag_in;
			end
			if(sink_ready == 1) begin
				sink_sop <= 1'b0;
				sink_eop <= 1'b0;
			end
		end
		7'b1000010: begin //7'd66
			if(rd_en == 0 && still_rd == 0 && ((rdcnt > wr_stop_address + 2 && rdcnt < 66) || (rdcnt > 66 && rdcnt < 130 - wr_stop_address))) begin
				data_real_out <= 0;
				data_imag_out <= 0;
			end
			else begin
				data_real_out <= data_imag_in;
				data_imag_out <= 0;
			end
			if(sink_ready == 1) begin
				sink_sop <= 1'b0;
				sink_eop <= 1'b0;
			end
		end
		7'b0000000, 7'b1000011, 7'b10001xx, 7'b1001xxx, 7'b101xxxx, 7'b11xxxxx: begin //7'd0, 7'd67 ~ 7'd127
			if(rd_en == 0 && still_rd == 0 && ((rdcnt > wr_stop_address + 2 && rdcnt < 66) || (rdcnt > 66 && rdcnt < 130 - wr_stop_address))) begin
				data_real_out <= 0;
				data_imag_out <= 0;
			end
			else begin
				data_real_out <=  data_real_in;
				data_imag_out <= -data_imag_in;
			end
			if(sink_ready == 1) begin
				sink_sop <= 1'b0;
				sink_eop <= 1'b0;
			end
		end
		endcase
	end
	else if(delta_clk_cnt > 1) begin
		delta_clk_cnt <= delta_clk_cnt - 1'b1;
		rdcnt <= rdcnt + 1'b1;
		casex(rdcnt)
		7'b00xxxxx, 7'b010xxxx, 7'b0110xxx, 7'b01110xx, 7'b011110x, 7'b0111110: begin //7'd0 ~ 7'd62
			rdaddress_real <= rdaddress_real + 1'b1;
			rdaddress_imag <= rdaddress_imag + 1'b1;
		end
		7'b0111111: begin //7'd63
			rdaddress_real <= rdaddress_real;
			rdaddress_imag <= rdaddress_imag - 7'd63;
		end
		7'b1000000: begin //7'd64
			rdaddress_real <= rdaddress_real;
			rdaddress_imag <= rdaddress_real;
		end
		7'b1000001, 7'b100001x, 7'b10001xx, 7'b1001xxx, 7'b101xxxx, 7'b110xxxx, 7'b1110xxx, 7'b11110xx, 7'b111110x, 7'b1111110: begin //7'd65 ~ 7'd126
			rdaddress_real <= rdaddress_real - 1'b1;
			rdaddress_imag <= rdaddress_imag - 1'b1;
		end
		7'b1111111: begin //7'd127
			rdaddress_real <= rdaddress_real + 7'd63;
			rdaddress_imag <= rdaddress_imag + 7'd63;
		end
		endcase
		
		casex(rdcnt)
		7'b0000001: begin //7'd1
			if(rd_en == 0 && still_rd == 0 && ((rdcnt > wr_stop_address + 2 && rdcnt < 66) || (rdcnt > 66 && rdcnt < 130 - wr_stop_address))) begin
				data_real_out <= 0;
				data_imag_out <= 0;
			end
			else begin
				data_real_out <=  data_real_in;
				data_imag_out <= -data_imag_in;
			end
			if(sink_ready == 1) begin
				sink_sop <= 1'b0;
				sink_eop <= 1'b1;
			end
		end
		7'b0000010: begin //7'd2
			if(rd_en == 0 && still_rd == 0 && ((rdcnt > wr_stop_address + 2 && rdcnt < 66) || (rdcnt > 66 && rdcnt < 130 - wr_stop_address))) begin
				data_real_out <= 0;
				data_imag_out <= 0;
			end
			else begin
				data_real_out <= data_real_in;
				data_imag_out <= 0;
			end
			if(sink_ready == 1) begin
				sink_sop <= 1'b1;
				sink_eop <= 1'b0;
				sink_valid <= 1'b1;
			end
		end
		7'b0000011: begin //7'd3
			if(rd_en == 0 && still_rd == 0 && ((rdcnt > wr_stop_address + 2 && rdcnt < 66) || (rdcnt > 66 && rdcnt < 130 - wr_stop_address))) begin
				data_real_out <= 0;
				data_imag_out <= 0;
			end
			else begin
				data_real_out <= data_real_in;
				data_imag_out <= data_imag_in;
			end
			if(sink_ready == 1) begin
				sink_sop <= 1'b0;
				sink_eop <= 1'b0;
			end
		end
		7'b0000011, 7'b00001xx, 7'b0001xxx, 7'b001xxxx, 7'b01xxxxx, 7'b100000x: begin //7'd4 ~ 7'd65
			if(rd_en == 0 && still_rd == 0 && ((rdcnt > wr_stop_address + 2 && rdcnt < 66) || (rdcnt > 66 && rdcnt < 130 - wr_stop_address))) begin
				data_real_out <= 0;
				data_imag_out <= 0;
			end
			else begin
				data_real_out <= data_real_in;
				data_imag_out <= data_imag_in;
			end
			if(sink_ready == 1) begin
				sink_sop <= 1'b0;
				sink_eop <= 1'b0;
			end
		end
		7'b1000010: begin //7'd66
			if(rd_en == 0 && still_rd == 0 && ((rdcnt > wr_stop_address + 2 && rdcnt < 66) || (rdcnt > 66 && rdcnt < 130 - wr_stop_address))) begin
				data_real_out <= 0;
				data_imag_out <= 0;
			end
			else begin
				data_real_out <= data_imag_in;
				data_imag_out <= 0;
			end
			if(sink_ready == 1) begin
				sink_sop <= 1'b0;
				sink_eop <= 1'b0;
			end
		end
		7'b0000000, 7'b1000011, 7'b10001xx, 7'b1001xxx, 7'b101xxxx, 7'b11xxxxx: begin //7'd0, 7'd67 ~ 7'd127
			if(rd_en == 0 && still_rd == 0 && ((rdcnt > wr_stop_address + 2 && rdcnt < 66) || (rdcnt > 66 && rdcnt < 130 - wr_stop_address))) begin
				data_real_out <= 0;
				data_imag_out <= 0;
			end
			else begin
				data_real_out <=  data_real_in;
				data_imag_out <= -data_imag_in;
			end
			if(sink_ready == 1) begin
				sink_sop <= 1'b0;
				sink_eop <= 1'b0;
			end
		end
		endcase
	end
	else begin
		rdcnt <= 0;
		delta_clk_cnt <= 0;
		rdaddress_real <= 0;
		rdaddress_imag <= 0;	 
		data_real_out <= 0;
		data_imag_out <= 0;
		sink_sop <= 0;
		sink_eop <= 0;
		sink_valid <= 0;
	end
end

endmodule
