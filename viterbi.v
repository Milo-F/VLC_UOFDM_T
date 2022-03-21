//维特比译码,(2,1,3)卷积码
//一帧14bit
module viterbi(
	input clk, //100MHz
	input reset,
	input data_in,    //输入
	input dec_start,  //拉高表示数据开始输入
	output wire judge_out, //判定码元序列结果
	output wire dec_out,   //译码路径,即输出,50MHz
	output reg dec_valid  //开始输出标志
);

wire clk_mul2;     	 //二倍频
pll_mul2 pll_mul2_m(
	.areset(~reset),
	.inclk0(clk),
	.c0(clk_mul2),
	.locked()
);

reg [13:0] x_t, x_t1; //接收的码元
reg [3:0] cnt;
reg [2:0] cnt2;
reg [13:0] a_out, a_out1, a1, a2, a3, a4; //保存译码后的码元
reg [3:0] c1, c2, c3, c4; //码距
reg [6:0] c_t, c_ts, c_t1, c_t2, c_t3, c_t4; //记录路径
reg [1:0] start_state; //解码时每帧的初始状态

//串并转换
always @(posedge clk_mul2 or negedge reset) begin
	if(!reset) begin 
		x_t <= 0;
		x_t1 <= 0;
		cnt <= 0;
	end
	else if(dec_start == 1) begin
		if(cnt == 4'd13)
			cnt <= 4'd0;
		else
			cnt <= cnt + 1'b1;
		x_t1 <= {x_t1[12:0], data_in};
		if(cnt == 0)
			x_t <= x_t1;
	end 
end

always @(posedge clk or negedge reset) begin
   if(!reset) begin
        cnt2 <= 0;
        a1 <= 0;
        a2 <= 0;
        a3 <= 0;
        a4 <= 0;  

        c1 <= 0;
        c2 <= 0;
        c3 <= 0;
        c4 <= 0;    

        c_t1 <= 0;
        c_t2 <= 0;
        c_t3 <= 0;
        c_t4 <= 0; 
		  
		  a_out <= 0;
		  c_ts  <= 0;
		  
		  start_state <= 0;
    end
    else if(dec_start == 1) begin
       cnt2 <= cnt2 + 1'b1;
		 if(cnt2 == 3'd6)
			cnt2 <= 3'd0;
        case(cnt2)  
            3'd0: begin
							//路径筛选,选取码距最小的那条路径
							if(c1 <= c2 && c1 <= c3 && c1 <= c4) begin
								a_out <= a1;
								c_ts <= c_t1;
								start_state <= 2'd0;
								
								a1[13:12] <= 2'b00;
								a2[13:12] <= 2'b00;
								a3[13:12] <= 2'b11;
								a4[13:12] <= 2'b11;  
								a1[11:0] <= 0;
								a2[11:0] <= 0;
								a3[11:0] <= 0;
								a4[11:0] <= 0; 

								c1 <= 0;
								c2 <= 0;
								c3 <= 0;
								c4 <= 0;       

								c_t1[6] <= 0;
								c_t2[6] <= 0;
								c_t3[6] <= 1;
								c_t4[6] <= 1;
							end
							else if(c2 <= c1 && c2 <= c3 && c2 <= c4) begin
								a_out <= a2;
								c_ts <= c_t2;
								start_state <= 2'd1;
								
								a1[13:12] <= 2'b01;
								a2[13:12] <= 2'b01;
								a3[13:12] <= 2'b10;
								a4[13:12] <= 2'b10;  
								a1[11:0] <= 0;
								a2[11:0] <= 0;
								a3[11:0] <= 0;
								a4[11:0] <= 0; 

								c1 <= 0;
								c2 <= 0;
								c3 <= 0;
								c4 <= 0;       

								c_t1[6] <= 0;
								c_t2[6] <= 0;
								c_t3[6] <= 1;
								c_t4[6] <= 1;
							end
							else if(c3 <= c1 && c3 <= c2 && c3 <= c4) begin
								a_out <= a3;
								c_ts <= c_t3;
								start_state <= 2'd2;
								
								a1[13:12] <= 2'b11;
								a2[13:12] <= 2'b11;
								a3[13:12] <= 2'b00;
								a4[13:12] <= 2'b00;  
								a1[11:0] <= 0;
								a2[11:0] <= 0;
								a3[11:0] <= 0;
								a4[11:0] <= 0; 

								c1 <= 0;
								c2 <= 0;
								c3 <= 0;
								c4 <= 0;       

								c_t1[6] <= 0;
								c_t2[6] <= 0;
								c_t3[6] <= 1;
								c_t4[6] <= 1;
							end
							else if(c4 <= c1 && c4 <= c2 && c4 <= c3) begin
								a_out <= a4;
								c_ts <= c_t4;
								start_state <= 2'd3;
								
								a1[13:12] <= 2'b10;
								a2[13:12] <= 2'b10;
								a3[13:12] <= 2'b01;
								a4[13:12] <= 2'b01;  
								a1[11:0] <= 0;
								a2[11:0] <= 0;
								a3[11:0] <= 0;
								a4[11:0] <= 0; 

								c1 <= 0;
								c2 <= 0;
								c3 <= 0;
								c4 <= 0;       

								c_t1[6] <= 0;
								c_t2[6] <= 0;
								c_t3[6] <= 1;
								c_t4[6] <= 1;
							end        
            end

            3'd1: begin 
					case(start_state)
						2'd0: begin
                     a1[11:10] <= 2'b00;
                     a2[11:10] <= 2'b11;
                     a3[11:10] <= 2'b01;
                     a4[11:10] <= 2'b10;

                     c1 <= {3'b000,x_t[13]^1'b0} + {3'b000,x_t[12]^1'b0} + {3'b000,x_t[11]^1'b0} 
                             + {3'b000,x_t[10]^1'b0};                
                     c2 <= {3'b000,x_t[13]^1'b0} + {3'b000,x_t[12]^1'b0} + {3'b000,x_t[11]^1'b1} 
                             + {3'b000,x_t[10]^1'b1};  
                     c3 <= {3'b000,x_t[13]^1'b1} + {3'b000,x_t[12]^1'b1} + {3'b000,x_t[11]^1'b0} 
                             + {3'b000,x_t[10]^1'b1};   
                     c4 <= {3'b000,x_t[13]^1'b1} + {3'b000,x_t[12]^1'b1} + {3'b000,x_t[11]^1'b1} 
                             + {3'b000,x_t[10]^1'b0};
						end
						
						2'd1: begin
							a1[11:10] <= 2'b11;
							a2[11:10] <= 2'b00;
							a3[11:10] <= 2'b10;
							a4[11:10] <= 2'b01;

							c1 <= {3'b000,x_t[13]^1'b0} + {3'b000,x_t[12]^1'b1} + {3'b000,x_t[11]^1'b1} 
									  + {3'b000,x_t[10]^1'b1};                
							c2 <= {3'b000,x_t[13]^1'b0} + {3'b000,x_t[12]^1'b1} + {3'b000,x_t[11]^1'b0} 
									  + {3'b000,x_t[10]^1'b0};  
							c3 <= {3'b000,x_t[13]^1'b1} + {3'b000,x_t[12]^1'b0} + {3'b000,x_t[11]^1'b1} 
									  + {3'b000,x_t[10]^1'b0};   
							c4 <= {3'b000,x_t[13]^1'b1} + {3'b000,x_t[12]^1'b0} + {3'b000,x_t[11]^1'b0} 
									  + {3'b000,x_t[10]^1'b1};
						end
						
						2'd2: begin
							a1[11:10] <= 2'b00;
							a2[11:10] <= 2'b11;
							a3[11:10] <= 2'b01;
							a4[11:10] <= 2'b10;

							c1 <= {3'b000,x_t[13]^1'b1} + {3'b000,x_t[12]^1'b1} + {3'b000,x_t[11]^1'b0} 
									  + {3'b000,x_t[10]^1'b0};                
							c2 <= {3'b000,x_t[13]^1'b1} + {3'b000,x_t[12]^1'b1} + {3'b000,x_t[11]^1'b1} 
									  + {3'b000,x_t[10]^1'b1};  
							c3 <= {3'b000,x_t[13]^1'b0} + {3'b000,x_t[12]^1'b0} + {3'b000,x_t[11]^1'b0} 
									  + {3'b000,x_t[10]^1'b1};   
							c4 <= {3'b000,x_t[13]^1'b0} + {3'b000,x_t[12]^1'b0} + {3'b000,x_t[11]^1'b1} 
									  + {3'b000,x_t[10]^1'b0};
						end
						
						2'd3: begin
							a1[11:10] <= 2'b11;
							a2[11:10] <= 2'b00;
							a3[11:10] <= 2'b10;
							a4[11:10] <= 2'b01;

							c1 <= {3'b000,x_t[13]^1'b1} + {3'b000,x_t[12]^1'b0} + {3'b000,x_t[11]^1'b1} 
									  + {3'b000,x_t[10]^1'b1};                
							c2 <= {3'b000,x_t[13]^1'b1} + {3'b000,x_t[12]^1'b0} + {3'b000,x_t[11]^1'b0} 
									  + {3'b000,x_t[10]^1'b0};  
							c3 <= {3'b000,x_t[13]^1'b0} + {3'b000,x_t[12]^1'b1} + {3'b000,x_t[11]^1'b1} 
									  + {3'b000,x_t[10]^1'b0};   
							c4 <= {3'b000,x_t[13]^1'b0} + {3'b000,x_t[12]^1'b1} + {3'b000,x_t[11]^1'b0} 
									  + {3'b000,x_t[10]^1'b1};
						end
					endcase

                     c_t1[5] <= 0;
                     c_t2[5] <= 1;
                     c_t3[5] <= 0;
                     c_t4[5] <= 1;                       
            end

            3'd2: begin  
                     // S1:00  
                     if((c1+{3'b000,x_t[9]^1'b0}+{3'b000,x_t[8]^1'b0})>
                         (c3+{3'b000,x_t[9]^1'b1}+{3'b000,x_t[8]^1'b1})) begin
                        c1 <= c3+{3'b000,x_t[9]^1'b1}+{3'b000,x_t[8]^1'b1};
                        a1[13:10] <= a3[13:10];
                        a1[9:8] <= 2'b11;
                        c_t1[4] <= 0;
                        c_t1[6:5] <= c_t3[6:5];
                     end                  
                     else begin
                        c1 <= c1+{3'b000,x_t[9]^1'b0}+{3'b000,x_t[8]^1'b0};
                        a1[13:10] <= a1[13:10];
                        a1[9:8] <= 2'b00;
                        c_t1[4] <= 0;
                        c_t1[6:5] <= c_t1[6:5];
                     end

                     // S2:01 
                     if((c1+{3'b000,x_t[9]^1'b1}+{3'b000,x_t[8]^1'b1})>
                         (c3+{3'b000,x_t[9]^1'b0}+{3'b000,x_t[8]^1'b0})) begin
                        c2 <= c3+{3'b000,x_t[9]^1'b0}+{3'b000,x_t[8]^1'b0};
                        a2[13:10] <= a3[13:10];
                        a2[9:8] <= 2'b00;
                        c_t2[4] <= 1;
                        c_t2[6:5] <= c_t3[6:5];
                     end                  
                     else begin
                        c2 <= c1+{3'b000,x_t[9]^1'b1}+{3'b000,x_t[8]^1'b1};
                        a2[13:10] <= a1[13:10];
                        a2[9:8] <= 2'b11;
                        c_t2[4] <= 1;
                        c_t2[6:5] <= c_t1[6:5];
                     end                    

                     // S3:10
                     if((c2+{3'b000,x_t[9]^1'b0}+{3'b000,x_t[8]^1'b1})>
                         (c4+{3'b000,x_t[9]^1'b1}+{3'b000,x_t[8]^1'b0})) begin
                        c3 <= c4+{3'b000,x_t[9]^1'b1}+{3'b000,x_t[8]^1'b0};
								a3[13:10] <= a4[13:10];
                        a3[9:8] <= 2'b10;
                        c_t3[4] <= 0;
                        c_t3[6:5] <= c_t4[6:5];
                     end                  
                     else begin
                        c3 <= c2+{3'b000,x_t[9]^1'b0}+{3'b000,x_t[8]^1'b1};
                        a3[13:10] <= a2[13:10];
                        a3[9:8] <= 2'b01;
                        c_t3[4] <= 0;
                        c_t3[6:5] <= c_t2[6:5];
                     end    

                     // S4:11
                     if((c2+{3'b000,x_t[9]^1'b1}+{3'b000,x_t[8]^1'b0})>
                        (c4+{3'b000,x_t[9]^1'b0}+{3'b000,x_t[8]^1'b1})) begin
                        c4 <= c4+{3'b000,x_t[9]^1'b0}+{3'b000,x_t[8]^1'b1};
                        a4[13:10] <= a4[13:10];
                        a4[9:8] <= 2'b01;
                        c_t4[4] <= 1;
                        c_t4[6:5] <= c_t4[6:5];
                     end                  
                     else begin
                        c4 <= c2+{3'b000,x_t[9]^1'b1}+{3'b000,x_t[8]^1'b0};
                        a4[13:10] <= a2[13:10];
                        a4[9:8] <= 2'b10;
                        c_t4[4] <= 1;
                        c_t4[6:5] <= c_t2[6:5];
                     end                                                
            end

            3'd3: begin
                      // S1:00  
                     if((c1+{3'b000,x_t[7]^1'b0}+{3'b000,x_t[6]^1'b0})>
                         (c3+{3'b000,x_t[7]^1'b1}+{3'b000,x_t[6]^1'b1})) begin
                        c1 <= c3+{3'b000,x_t[7]^1'b1}+{3'b000,x_t[6]^1'b1};
                        a1[13:8] <= a3[13:8];
                        a1[7:6] <= 2'b11;
                        c_t1[3] <= 0;
                        c_t1[6:4] <= c_t3[6:4];
                     end                  
                     else begin
                        c1 <= c1+{3'b000,x_t[7]^1'b0}+{3'b000,x_t[6]^1'b0};
                        a1[13:8] <= a1[13:8];
                        a1[7:6] <= 2'b00;
                        c_t1[3] <= 0;
                        c_t1[6:4] <= c_t1[6:4];
                     end

                     // S2:01 
                     if((c1+{3'b000,x_t[7]^1'b1}+{3'b000,x_t[6]^1'b1})>
                         (c3+{3'b000,x_t[7]^1'b0}+{3'b000,x_t[6]^1'b0})) begin
                        c2 <= c3+{3'b000,x_t[7]^1'b0}+{3'b000,x_t[6]^1'b0};
                        a2[13:8] <= a3[13:8];
                        a2[7:6] <= 2'b00;
                        c_t2[3] <= 1;
                        c_t2[6:4] <= c_t3[6:4];
                     end                  
                     else begin
                        c2 <= c1+{3'b000,x_t[7]^1'b1}+{3'b000,x_t[6]^1'b1};
                        a2[13:8] <= a1[13:8];
                        a2[7:6] <= 2'b11;
                        c_t2[3] <= 1;
                        c_t2[6:4] <= c_t1[6:4];
                     end                    

                     // S3:10
                     if((c2+{3'b000,x_t[7]^1'b0}+{3'b000,x_t[6]^1'b1})>
                         (c4+{3'b000,x_t[7]^1'b1}+{3'b000,x_t[6]^1'b0})) begin
                        c3 <= c4+{3'b000,x_t[7]^1'b1}+{3'b000,x_t[6]^1'b0};
								a3[13:8] <= a4[13:8];
                        a3[7:6] <= 2'b10;
                        c_t3[3] <= 0;
                        c_t3[6:4] <= c_t4[6:4];
                     end                  
                     else begin
                        c3 <= c2+{3'b000,x_t[7]^1'b0}+{3'b000,x_t[6]^1'b1};
                        a3[13:8] <= a2[13:8];
                        a3[7:6] <= 2'b01;
                        c_t3[3] <= 0;
                        c_t3[6:4] <= c_t2[6:4];
                     end    

                     // S4:11
                     if((c2+{3'b000,x_t[7]^1'b1}+{3'b000,x_t[6]^1'b0})>
                        (c4+{3'b000,x_t[7]^1'b0}+{3'b000,x_t[6]^1'b1})) begin
                        c4 <= c4+{3'b000,x_t[7]^1'b0}+{3'b000,x_t[6]^1'b1};
                        a4[13:8] <= a4[13:8];
                        a4[7:6] <= 2'b01;
                        c_t4[3] <= 1;
                        c_t4[6:4] <= c_t4[6:4];
                     end                  
                     else begin
                        c4 <= c2+{3'b000,x_t[7]^1'b1}+{3'b000,x_t[6]^1'b0};
                        a4[13:8] <= a2[13:8];
                        a4[7:6] <= 2'b10;
                        c_t4[3] <= 1;
                        c_t4[6:4] <= c_t2[6:4];
                     end                        
            end

            3'd4: begin
                      // S1:00  
                     if((c1+{3'b000,x_t[5]^1'b0}+{3'b000,x_t[4]^1'b0})>
                         (c3+{3'b000,x_t[5]^1'b1}+{3'b000,x_t[4]^1'b1})) begin
                        c1 <= c3+{3'b000,x_t[5]^1'b1}+{3'b000,x_t[4]^1'b1};
                        a1[13:6] <= a3[13:6];
                        a1[5:4] <= 2'b11;
                        c_t1[2] <= 0;
                        c_t1[6:3] <= c_t3[6:3];
                     end                  
                     else begin
                        c1 <= c1+{3'b000,x_t[5]^1'b0}+{3'b000,x_t[4]^1'b0};
                        a1[13:6] <= a1[13:6];
                        a1[5:4] <= 2'b00;
                        c_t1[2] <= 0;
                        c_t1[6:3] <= c_t1[6:3];
                     end

                     // S2:01 
                     if((c1+{3'b000,x_t[5]^1'b1}+{3'b000,x_t[4]^1'b1})>
                         (c3+{3'b000,x_t[5]^1'b0}+{3'b000,x_t[4]^1'b0})) begin
                        c2 <= c3+{3'b000,x_t[5]^1'b0}+{3'b000,x_t[4]^1'b0};
                        a2[13:6] <= a3[13:6];
                        a2[5:4] <= 2'b00;
                        c_t2[2] <= 1;
                        c_t2[6:3] <= c_t3[6:3];
                     end                  
                     else begin
                        c2 <= c1+{3'b000,x_t[5]^1'b1}+{3'b000,x_t[4]^1'b1};
                        a2[13:6] <= a1[13:6];
                        a2[5:4] <= 2'b11;
                        c_t2[2] <= 1;
                        c_t2[6:3] <= c_t1[6:3];
                     end                    

                     // S3:10
                     if((c2+{3'b000,x_t[5]^1'b0}+{3'b000,x_t[4]^1'b1})>
                         (c4+{3'b000,x_t[5]^1'b1}+{3'b000,x_t[4]^1'b0})) begin
                        c3 <= c4+{3'b000,x_t[5]^1'b1}+{3'b000,x_t[4]^1'b0};
								a3[13:6] <= a4[13:6];
                        a3[5:4] <= 2'b10;
                        c_t3[2] <= 0;
                        c_t3[6:3] <= c_t4[6:3];
                     end                  
                     else begin
                        c3 <= c2+{3'b000,x_t[5]^1'b0}+{3'b000,x_t[4]^1'b1};
                        a3[13:6] <= a2[13:6];
                        a3[5:4] <= 2'b01;
                        c_t3[2] <= 0;
                        c_t3[6:3] <= c_t2[6:3];
                     end    

                     // S4:11
                     if((c2+{3'b000,x_t[5]^1'b1}+{3'b000,x_t[4]^1'b0})>
                        (c4+{3'b000,x_t[5]^1'b0}+{3'b000,x_t[4]^1'b1})) begin
                        c4 <= c4+{3'b000,x_t[5]^1'b0}+{3'b000,x_t[4]^1'b1};
                        a4[13:6] <= a4[13:6];
                        a4[5:4] <= 2'b01;
                        c_t4[2] <= 1;
                        c_t4[6:3] <= c_t4[6:3];
                     end                  
                     else begin
                        c4 <= c2+{3'b000,x_t[5]^1'b1}+{3'b000,x_t[4]^1'b0};
                        a4[13:6] <= a2[13:6];
                        a4[5:4] <= 2'b10;
                        c_t4[2] <= 1;
                        c_t4[6:3] <= c_t2[6:3];
                     end                        
            end

            3'd5: begin
                      // S1:00  
                     if((c1+{3'b000,x_t[3]^1'b0}+{3'b000,x_t[2]^1'b0})>
                         (c3+{3'b000,x_t[3]^1'b1}+{3'b000,x_t[2]^1'b1})) begin
                        c1 <= c3+{3'b000,x_t[3]^1'b1}+{3'b000,x_t[2]^1'b1};
                        a1[13:4] <= a3[13:4];
                        a1[3:2] <= 2'b11;
                        c_t1[1] <= 0;
                        c_t1[6:2] <= c_t3[6:2];
                     end                  
                     else begin
                        c1 <= c1+{3'b000,x_t[3]^1'b0}+{3'b000,x_t[2]^1'b0};
                        a1[13:4] <= a1[13:4];
                        a1[3:2] <= 2'b00;
                        c_t1[1] <= 0;
                        c_t1[6:2] <= c_t1[6:2];
                     end

                     // S2:01 
                     if((c1+{3'b000,x_t[3]^1'b1}+{3'b000,x_t[2]^1'b1})>
                         (c3+{3'b000,x_t[3]^1'b0}+{3'b000,x_t[2]^1'b0})) begin
                        c2 <= c3+{3'b000,x_t[3]^1'b0}+{3'b000,x_t[2]^1'b0};
                        a2[13:4] <= a3[13:4];
                        a2[3:2] <= 2'b00;
                        c_t2[1] <= 1;
                        c_t2[6:2] <= c_t3[6:2];
                     end                  
                     else begin
                        c2 <= c1+{3'b000,x_t[3]^1'b1}+{3'b000,x_t[2]^1'b1};
                        a2[13:4] <= a1[13:4];
                        a2[3:2] <= 2'b11;
                        c_t2[1] <= 1;
                        c_t2[6:2] <= c_t1[6:2];
                     end                    

                     // S3:10
                     if((c2+{3'b000,x_t[3]^1'b0}+{3'b000,x_t[2]^1'b1})>
                         (c4+{3'b000,x_t[3]^1'b1}+{3'b000,x_t[2]^1'b0})) begin
                        c3 <= c4+{3'b000,x_t[3]^1'b1}+{3'b000,x_t[2]^1'b0};
								a3[13:4] <= a4[13:4];
                        a3[3:2] <= 2'b10;
                        c_t3[1] <= 0;
                        c_t3[6:2] <= c_t4[6:2];
                     end                  
                     else begin
                        c3 <= c2+{3'b000,x_t[3]^1'b0}+{3'b000,x_t[2]^1'b1};
                        a3[13:4] <= a2[13:4];
                        a3[3:2] <= 2'b01;
                        c_t3[1] <= 0;
                        c_t3[6:2] <= c_t2[6:2];
                     end    

                     // S4:11
                     if((c2+{3'b000,x_t[3]^1'b1}+{3'b000,x_t[2]^1'b0})>
                        (c4+{3'b000,x_t[3]^1'b0}+{3'b000,x_t[2]^1'b1})) begin
                        c4 <= c4+{3'b000,x_t[3]^1'b0}+{3'b000,x_t[2]^1'b1};
                        a4[13:4] <= a4[13:4];
                        a4[3:2] <= 2'b01;
                        c_t4[1] <= 1;
                        c_t4[6:2] <= c_t4[6:2];
                     end                  
                     else begin
                        c4 <= c2+{3'b000,x_t[3]^1'b1}+{3'b000,x_t[2]^1'b0};
                        a4[13:4] <= a2[13:4];
                        a4[3:2] <= 2'b10;
                        c_t4[1] <= 1;
                        c_t4[6:2] <= c_t2[6:2];
                     end 
            end

            3'd6: begin
                      // S1:00  
                     if((c1+{3'b000,x_t[1]^1'b0}+{3'b000,x_t[0]^1'b0})>
                         (c3+{3'b000,x_t[1]^1'b1}+{3'b000,x_t[0]^1'b1})) begin
                        c1 <= c3+{3'b000,x_t[1]^1'b1}+{3'b000,x_t[0]^1'b1};
                        a1[13:2] <= a3[13:2];
                        a1[1:0] <= 2'b11;
                        c_t1[0] <= 0;
                        c_t1[6:1] <= c_t3[6:1];
                     end                  
                     else begin
                        c1 <= c1+{3'b000,x_t[1]^1'b0}+{3'b000,x_t[0]^1'b0};
                        a1[13:2] <= a1[13:2];
                        a1[1:0] <= 2'b00;
                        c_t1[0] <= 0;
                        c_t1[6:1] <= c_t1[6:1];
                     end

                     // S2:01 
                     if((c1+{3'b000,x_t[1]^1'b1}+{3'b000,x_t[0]^1'b1})>
                         (c3+{3'b000,x_t[1]^1'b0}+{3'b000,x_t[0]^1'b0})) begin
                        c2 <= c3+{3'b000,x_t[1]^1'b0}+{3'b000,x_t[0]^1'b0};
                        a2[13:2] <= a3[13:2];
                        a2[1:0] <= 2'b00;
                        c_t2[0] <= 1;
                        c_t2[6:1] <= c_t3[6:1];
                     end                  
                     else begin
                        c2 <= c1+{3'b000,x_t[1]^1'b1}+{3'b000,x_t[0]^1'b1};
                        a2[13:2] <= a1[13:2];
                        a2[1:0] <= 2'b11;
                        c_t2[0] <= 1;
                        c_t2[6:1] <= c_t1[6:1];
                     end                    

                     // S3:10
                     if((c2+{3'b000,x_t[1]^1'b0}+{3'b000,x_t[0]^1'b1})>
                         (c4+{3'b000,x_t[1]^1'b1}+{3'b000,x_t[0]^1'b0})) begin
                        c3 <= c4+{3'b000,x_t[1]^1'b1}+{3'b000,x_t[0]^1'b0};
								a3[13:2] <= a4[13:2];
                        a3[1:0] <= 2'b10;
                        c_t3[0] <= 0;
                        c_t3[6:1] <= c_t4[6:1];
                     end                  
                     else begin
                        c3 <= c2+{3'b000,x_t[1]^1'b0}+{3'b000,x_t[0]^1'b1};
                        a3[13:2] <= a2[13:2];
                        a3[1:0] <= 2'b01;
                        c_t3[0] <= 0;
                        c_t3[6:1] <= c_t2[6:1];
                     end    

                     // S4:11
                     if((c2+{3'b000,x_t[1]^1}+{3'b000,x_t[0]^0})>
                        (c4+{3'b000,x_t[1]^0}+{3'b000,x_t[0]^1})) begin
                        c4 <= c4+{3'b000,x_t[1]^1'b0}+{3'b000,x_t[0]^1'b1};
                        a4[13:2] <= a4[13:2];
                        a4[1:0] <= 2'b01;
                        c_t4[0] <= 1;
                        c_t4[6:1] <= c_t4[6:1];
                     end                  
                     else begin
                        c4 <= c2+{3'b000,x_t[1]^1'b1}+{3'b000,x_t[0]^1'b0};
                        a4[13:2] <= a2[13:2];
                        a4[1:0] <= 2'b10;
                        c_t4[0] <= 1;
                        c_t4[6:1] <= c_t2[6:1];
                     end                              
            end
        endcase
    end
end

reg [1:0] out_cnt; //辅助得出dec_valid
always @(posedge clk_mul2 or negedge reset) begin
	if(!reset) begin
      c_t <= 0;
		a_out1 <= 0;
		out_cnt <= 0;
		dec_valid <= 0;
	end
   else if(dec_start == 1) begin   
      if(cnt == 2) begin
			c_t <= c_ts;
			a_out1 <= a_out;
			out_cnt <= out_cnt + 1'b1;
			if(out_cnt == 2)
				dec_valid <= 1;
      end
      else begin
			a_out1[13:0] <= {a_out1[12:0], a_out1[13]};    
			if(cnt[0] == 0)
				c_t[6:0] <={c_t[5:0], c_t[6]};
		end          
	end
end

assign judge_out = a_out1[13];
assign dec_out = c_t[6];

endmodule
