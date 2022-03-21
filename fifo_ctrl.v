module fifo_ctrl(
	input rdclk,
	input wrclk,
	input reset,
	input rdempty, 	 //fifo已读完
	input wrfull,  	 //fifo已写满
	input rx_done, 	 //串口写完一帧数据
	output wire rdreq, //给出读请求信号
	output wire wrreq, //给出写请求信号
	output reg fifo_read_valid //置高,表示从fifo中读出的数据开始输出
);

reg rdflag;
reg [3:0] rdcnt;
always @(posedge wrclk or negedge reset) begin
   if(!reset) begin
		rdcnt <= 0;
		rdflag <= 0;
	end
	else begin
		if(rx_done == 1) begin
			rdcnt <= 0;
		end
		else
			rdcnt <= rdcnt + 1'b1;
		if(rdcnt > 4'd10)    //等待时间超过一个帧周期(10个读时钟周期),说明已无数据可接收
			rdflag <= 1'b1; //数据接收完成,开始准备读取
		if(rdempty == 1)	 //读完fifo之后,rdflag置为0,进行下一个循环
			rdflag <= 1'b0;
	end
end

always @(posedge rdclk or negedge reset) begin
   if(!reset)
		fifo_read_valid <= 0;
	else
		fifo_read_valid <= rdreq;
end

assign wrreq = rx_done;
assign rdreq = ((rdflag || wrfull)&&(~rdempty)) ? 1'b1 : 1'b0;


endmodule
