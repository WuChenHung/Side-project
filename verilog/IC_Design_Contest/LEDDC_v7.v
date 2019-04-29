`timescale 1ns/10ps
module LEDDC( DCK, DAI, DEN, GCK, Vsync, mode, rst, OUT);
input           DCK;
input           DAI;
input           DEN;
input           GCK;
input           Vsync;
input           mode;
input           rst;
output reg[15:0]   OUT;

integer i;
wire [15:0] ram1_data_out,ram2_data_out;
reg ram1_r_en,ram1_w_en,ram2_w_en,ram2_r_en;
reg [8:0] ram1_r_addr,ram2_r_addr;//0~511
reg [8:0] ram1_w_addr;
reg [7:0] ram2_w_addr;//0~255
reg [15:0] ram1_data_in,ram2_data_in;
reg [3:0] write_data_count;
reg [95:0] read_data;
reg [95:0] read_data_temp; 
reg [15:0] read_data_count;
reg [3:0] ram1_w_addr_reuse;
reg [4:0] ram1_w_addr_scanline_count;
reg round_count;
reg	round;

	sram_512x16 ram1(//for 0~511
   .AA(ram1_r_addr[8:0]),
   .AB(ram1_w_addr[8:0]),
   .DB(ram1_data_in),
   .CLKA(GCK),
   .CLKB(GCK),
   .CENA(ram1_r_en),
   .CENB(ram1_w_en),
   .QA(ram1_data_out)
);

	sram_256x16 ram2(
   .AA(ram2_r_addr[7:0]),
   .AB(ram2_w_addr),
   .DB(ram2_data_in),
   .CLKA(GCK),
   .CLKB(DCK),
   .CENA(ram2_r_en),
   .CENB(ram2_w_en),
   .QA(ram2_data_out)
);
///////////////////write to ram2///////////////////
always @(posedge DCK or posedge rst) begin
	if (rst) begin
		write_data_count <= 0;
	end
	else if ( (write_data_count == 15) && (DEN == 1) ) begin
		write_data_count <= 0;
	end
	else if (DEN == 1)begin
		write_data_count <= write_data_count + 1;
	end
	else begin
		write_data_count <= 0;
	end
end

always @(posedge DCK or posedge rst) begin
	if (rst) begin
		ram2_w_addr <= 0;	
	end
	else if ( ~ram2_w_en ) begin
		ram2_w_addr <= ram2_w_addr+1;
	end
	else begin
		ram2_w_addr <= ram2_w_addr;
	end
end

always @(posedge DCK or posedge rst) begin
	if (rst) begin
		ram2_w_en <= 1;
	end
	else if ( (write_data_count == 15) && (DEN == 1)) begin
		ram2_w_en <= 0;
	end
	else begin
		ram2_w_en <= 1;
	end
end

always @(posedge DCK or posedge rst) begin
	if (rst) begin
		ram2_data_in <= 0;		
	end
	else if (DEN == 1) begin
		ram2_data_in[15] <= DAI;
		ram2_data_in[14:0] <= ram2_data_in>>1;
	end
end
//////////////////read from ram2///////////////////////////

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		ram2_r_en <= 1;
	end
	else if (Vsync==1 && read_data_count[4:0]<8 && ((read_data_count<1024 && ram1_w_addr_scanline_count==0)|| ( (read_data_count>19388) && (read_data_count <20408) && ram1_w_addr_scanline_count==20))) begin
		ram2_r_en <= 0;
	end
	else begin
		ram2_r_en <= 1;
	end
end

always @(posedge GCK or posedge rst) begin//用9bit 表示512 address可以同時給ram1_w_addr 使用
	if (rst) begin
		ram2_r_addr <= 256;	
	end
	else if ( ~ram2_r_en ) begin
		ram2_r_addr <= ram2_r_addr+1;
	end
	else begin
		ram2_r_addr <= ram2_r_addr;
	end
end

////////////////////write to ram1///////////////////////
always @(posedge GCK or posedge rst) begin
	if (rst) begin
		ram1_w_addr_scanline_count <= 0;	
	end
	else if (Vsync==1 && (read_data_count == 65504) ) begin
		ram1_w_addr_scanline_count <= ram1_w_addr_scanline_count+1; 
	end
	else begin
		ram1_w_addr_scanline_count <= ram1_w_addr_scanline_count;
	end
end

always @(posedge GCK or posedge rst) begin//0~15
	if (rst) begin
		ram1_w_addr_reuse <=0;
	end
	else if (Vsync==1) begin
		ram1_w_addr_reuse <= ram1_w_addr_reuse +1 ; 
	end
end

wire [3:0] ww;
assign ww = read_data_count[3:0]+1;
always @(posedge GCK or posedge rst) begin//0~15
	if (rst) begin
		ram1_w_addr <= 0;
	end
	else if ( ~ram1_r_en ) begin
		ram1_w_addr <= ram1_r_addr; 
	end
	else begin
		ram1_w_addr <= ram2_r_addr;
	end
end


always @(posedge GCK or posedge rst) begin
	if (rst) begin
		ram1_w_en <= 1;
	end
	else if ((read_data_count[4:0]>0 && read_data_count[4:0]<9) && ((read_data_count<1024 && ram1_w_addr_scanline_count==0)|| ( (read_data_count>19388) && (read_data_count <20408) && ram1_w_addr_scanline_count==20))) begin //data move from ram2
		ram1_w_en <= 0;
	end
	/*else if ((read_data_count[4:0]>13 && read_data_count[4:0]<30) && read_data_count!=65535 ) begin //reload
		ram1_w_en <= 0;
	end*/
	else begin
		ram1_w_en <= 1;
	end
end

always @(*) begin
	if (read_data_count[4:0]<15||read_data_count[4:0]>30) begin
		ram1_data_in = ram2_data_out;
	end
	else begin
		ram1_data_in = ram1_data_out>32 ? ram1_data_out-32 : /*(ram1_data_out==32) ? 1 : */0 ;
	end
end
wire [4:0] tt;
assign tt = ram1_w_addr_scanline_count+1;
wire [3:0] dd;
assign dd = read_data_count[3:0]+3;
////////////////////read from ram1///////////////////////
always @(posedge GCK or posedge rst) begin//0~15
	if (rst) begin
		ram1_r_addr <= 0; 
	end
	else if (Vsync==1 && read_data_count==65504) begin
		ram1_r_addr <= {tt,ram1_w_addr_reuse}; 
	end
	else if (~ram1_r_en) begin
		ram1_r_addr <= {ram1_w_addr_scanline_count,dd}; 
	end
	else begin
		ram1_r_addr <= ram1_r_addr;
	end
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		ram1_r_en <= 1;
	end
	else if ((read_data_count[4:0]>12 && read_data_count[4:0]<29) && (read_data_count!=0) && Vsync==1) begin 
		ram1_r_en <= 0;
	end
	else begin
		ram1_r_en <= 1;
	end
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		read_data_count <= 0;
	end
	else if (mode==1 && Vsync==1 && read_data_count==32767) begin
		read_data_count <= 0;
	end
	else if (Vsync == 1) begin
		read_data_count <= read_data_count +1;
	end
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		read_data_temp <= 0;
	end
	else if ( read_data_count[4:0]>14 && read_data_count[4:0]<31 ) begin
		read_data_temp[95:90] <= (ram1_data_out>31) ? 32 : ram1_data_out[4:0] ;
		read_data_temp[89:0] <= read_data_temp>>6;
	end
end
//16 8 4 2 1
//4  3 2 1 0

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		read_data <= 0;
	end
	else if ( Vsync==1 && read_data_count[4:0]==5'b11111)begin
		read_data <= read_data_temp;
		OUT[0]  <= (read_data_temp[5:0]   > 0)||(read_data[5:0]  ==32 && read_data_temp[5:0]  ==0) ;
		OUT[1]  <= (read_data_temp[11:6]  > 0)||(read_data[11:6] ==32 && read_data_temp[11:6] ==0) ;
		OUT[2]  <= (read_data_temp[17:12] > 0)||(read_data[17:12]==32 && read_data_temp[17:12]==0) ;
		OUT[3]  <= (read_data_temp[23:18] > 0)||(read_data[23:18]==32 && read_data_temp[23:18]==0) ;
		OUT[4]  <= (read_data_temp[29:24] > 0)||(read_data[29:24]==32 && read_data_temp[29:24]==0) ;
		OUT[5]  <= (read_data_temp[35:30] > 0)||(read_data[35:30]==32 && read_data_temp[35:30]==0) ;
		OUT[6]  <= (read_data_temp[41:36] > 0)||(read_data[41:36]==32 && read_data_temp[41:36]==0) ;
		OUT[7]  <= (read_data_temp[47:42] > 0)||(read_data[47:42]==32 && read_data_temp[47:42]==0) ;
		OUT[8]  <= (read_data_temp[53:48] > 0)||(read_data[53:48]==32 && read_data_temp[53:48]==0) ;
		OUT[9]  <= (read_data_temp[59:54] > 0)||(read_data[59:54]==32 && read_data_temp[59:54]==0) ;
		OUT[10] <= (read_data_temp[65:60] > 0)||(read_data[65:60]==32 && read_data_temp[65:60]==0) ;
		OUT[11] <= (read_data_temp[71:66] > 0)||(read_data[71:66]==32 && read_data_temp[71:66]==0) ;
		OUT[12] <= (read_data_temp[77:72] > 0)||(read_data[77:72]==32 && read_data_temp[77:72]==0) ;
		OUT[13] <= (read_data_temp[83:78] > 0)||(read_data[83:78]==32 && read_data_temp[83:78]==0) ;
		OUT[14] <= (read_data_temp[89:84] > 0)||(read_data[89:84]==32 && read_data_temp[89:84]==0) ;
		OUT[15] <= (read_data_temp[95:90] > 0)||(read_data[95:90]==32 && read_data_temp[95:90]==0) ;
	end
	else if ( Vsync ==1)begin
		OUT[0]  <= (read_data[5:0]   > read_data_count[4:0]);
		OUT[1]  <= (read_data[11:6]  > read_data_count[4:0]);
		OUT[2]  <= (read_data[17:12] > read_data_count[4:0]);
		OUT[3]  <= (read_data[23:18] > read_data_count[4:0]);
		OUT[4]  <= (read_data[29:24] > read_data_count[4:0]);
		OUT[5]  <= (read_data[35:30] > read_data_count[4:0]);
		OUT[6]  <= (read_data[41:36] > read_data_count[4:0]);
		OUT[7]  <= (read_data[47:42] > read_data_count[4:0]);
		OUT[8]  <= (read_data[53:48] > read_data_count[4:0]);
		OUT[9]  <= (read_data[59:54] > read_data_count[4:0]);
		OUT[10] <= (read_data[65:60] > read_data_count[4:0]);
		OUT[11] <= (read_data[71:66] > read_data_count[4:0]);
		OUT[12] <= (read_data[77:72] > read_data_count[4:0]);
		OUT[13] <= (read_data[83:78] > read_data_count[4:0]);
		OUT[14] <= (read_data[89:84] > read_data_count[4:0]);
		OUT[15] <= (read_data[95:90] > read_data_count[4:0]);
	end
	else begin
		OUT <= 0;
	end
	/*else if (mode==1 && Vsync ==1 && read_data_count==32767 )begin
		read_data[15:0]    <= (read_data_temp[15:1]   +(read_data_temp[0]  &(~round)));
		read_data[31:16]   <= (read_data_temp[31:17]  +(read_data_temp[16] &(~round)));
		read_data[47:32]   <= (read_data_temp[47:33]  +(read_data_temp[32] &(~round)));
		read_data[63:48]   <= (read_data_temp[63:49]  +(read_data_temp[48] &(~round)));
		read_data[79:64]   <= (read_data_temp[79:65]  +(read_data_temp[64] &(~round)));
		read_data[95:80]   <= (read_data_temp[95:81]  +(read_data_temp[80] &(~round)));
		read_data[111:96]  <= (read_data_temp[111:97] +(read_data_temp[96] &(~round)));
		read_data[127:112] <= (read_data_temp[127:113]+(read_data_temp[112]&(~round)));
		read_data[143:128] <= (read_data_temp[143:129]+(read_data_temp[128]&(~round)));
		read_data[159:144] <= (read_data_temp[159:145]+(read_data_temp[144]&(~round)));
		read_data[175:160] <= (read_data_temp[175:161]+(read_data_temp[160]&(~round)));
		read_data[191:176] <= (read_data_temp[191:177]+(read_data_temp[176]&(~round)));
		read_data[207:192] <= (read_data_temp[207:193]+(read_data_temp[192]&(~round)));
		read_data[223:208] <= (read_data_temp[223:209]+(read_data_temp[208]&(~round)));
		read_data[239:224] <= (read_data_temp[239:225]+(read_data_temp[224]&(~round)));
		read_data[255:240] <= (read_data_temp[255:241]+(read_data_temp[240]&(~round)));
		OUT[0]  <= ((read_data_temp[15:1]   +(read_data_temp[0]  &(~round)))>read_data_count);
		OUT[1]  <= ((read_data_temp[31:17]  +(read_data_temp[16] &(~round)))>read_data_count);
		OUT[2]  <= ((read_data_temp[47:33]  +(read_data_temp[32] &(~round)))>read_data_count);
		OUT[3]  <= ((read_data_temp[63:49]  +(read_data_temp[48] &(~round)))>read_data_count);
		OUT[4]  <= ((read_data_temp[79:65]  +(read_data_temp[64] &(~round)))>read_data_count);
		OUT[5]  <= ((read_data_temp[95:81]  +(read_data_temp[80] &(~round)))>read_data_count);
		OUT[6]  <= ((read_data_temp[111:97] +(read_data_temp[96] &(~round)))>read_data_count);
		OUT[7]  <= ((read_data_temp[127:113]+(read_data_temp[112]&(~round)))>read_data_count);
		OUT[8]  <= ((read_data_temp[143:129]+(read_data_temp[128]&(~round)))>read_data_count);
		OUT[9]  <= ((read_data_temp[159:145]+(read_data_temp[144]&(~round)))>read_data_count);
		OUT[10] <= ((read_data_temp[175:161]+(read_data_temp[160]&(~round)))>read_data_count);
		OUT[11] <= ((read_data_temp[191:177]+(read_data_temp[176]&(~round)))>read_data_count);
		OUT[12] <= ((read_data_temp[207:193]+(read_data_temp[192]&(~round)))>read_data_count);
		OUT[13] <= ((read_data_temp[223:209]+(read_data_temp[208]&(~round)))>read_data_count);
		OUT[14] <= ((read_data_temp[239:225]+(read_data_temp[224]&(~round)))>read_data_count);
		OUT[15] <= ((read_data_temp[255:241]+(read_data_temp[240]&(~round)))>read_data_count);
	end*/
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		round_count <= 0;
		round <= 0;
	end
	else if (mode==1 && Vsync==1 && read_data_count==32766 && ram1_r_addr[7:0]==16 && round_count==1) begin
		round_count <= ~round_count;
		round <= ~round;
	end
	else if (mode==1 && Vsync==1 && read_data_count==32766 && ram1_r_addr[7:0]==16 ) begin
		round_count <= ~round_count;
		round <= round;
	end
end

endmodule
