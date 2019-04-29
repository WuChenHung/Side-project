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
reg [9:0] ram1_r_addr,ram1_w_addr;//0~1023
reg [15:0] ram1_data_in;
reg [3:0] write_data_count;
reg [255:0] read_data;
reg [255:0] read_data_temp; 
reg [15:0] read_data_count;
reg round_count;
reg	round;

	sram_512x16 ram1(//for 0~511
   .AA(ram1_r_addr[8:0]),
   .AB(ram1_w_addr[8:0]),
   .DB(ram1_data_in),
   .CLKA(GCK),
   .CLKB(DCK),
   .CENA(ram1_r_en),
   .CENB(ram1_w_en),
   .QA(ram1_data_out)
);

	sram_256x16 ram2(//for 512~767
   .AA(ram1_r_addr[7:0]),
   .AB(ram1_w_addr[7:0]),
   .DB(ram1_data_in),
   .CLKA(GCK),
   .CLKB(DCK),
   .CENA(ram2_r_en),
   .CENB(ram2_w_en),
   .QA(ram2_data_out)
);
///////////////////write///////////////////
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
		ram1_w_addr <= 0;	
	end
	else if ( ((~ram1_w_en) || (~ram2_w_en)) ) begin
		ram1_w_addr <= ram1_w_addr==767 ? 0 : ram1_w_addr+1 ;
	end
	else begin
		ram1_w_addr <= ram1_w_addr;
	end
end

always @(posedge DCK or posedge rst) begin
	if (rst) begin
		ram1_w_en <= 1;
	end
	else if ( (write_data_count == 15) && (DEN == 1) && (ram1_w_addr[9]==0) ) begin
		ram1_w_en <= 0;
	end
	else begin
		ram1_w_en <= 1;
	end
end

always @(posedge DCK or posedge rst) begin
	if (rst) begin
		ram2_w_en <= 1;
	end
	else if ( (write_data_count == 15) && (DEN == 1) && (ram1_w_addr[9]==1) ) begin
		ram2_w_en <= 0;
	end
	else begin
		ram2_w_en <= 1;
	end
end


always @(posedge DCK or posedge rst) begin
	if (rst) begin
		ram1_data_in <= 0;		
	end
	else if (DEN == 1) begin
		ram1_data_in[15] <= DAI;
		ram1_data_in[14:0] <= ram1_data_in>>1;
	end
end

///////////////////read///////////////////
always @(posedge GCK or posedge rst) begin
	if (rst) begin
		ram1_r_addr <= (256+16);	
	end
	else if (mode==1 && ((~ram1_r_en) || (~ram2_r_en)) && Vsync == 1 && read_data_count==(32767-2) && ram1_r_addr[7:0]==255 && round_count==1 && round==0) begin
		ram1_r_addr <= ( ram1_r_addr==255 ? 512 : ( ram1_r_addr==511 ? 0 : 256 ) );//255->512 511->0 767->256   
	end
	else if ( (~ram1_r_en) || (~ram2_r_en) ) begin
		ram1_r_addr <= ram1_r_addr==767 ? 0 : ram1_r_addr+1 ;
	end
	else begin
		ram1_r_addr <= ram1_r_addr;
	end
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		ram1_r_en <= 1;
	end
	else if (Vsync==1 && (ram1_r_addr[9]==0) && read_data_count<(65535-2) && read_data_count>(65518-2) ) begin //mode 0 
		ram1_r_en <= 0;
	end
	else if (Vsync==1 && (ram1_r_addr[9]==0) && mode==1 && read_data_count<(32767-2) && read_data_count>(32750-2) ) begin //mode 1
		ram1_r_en <= 0;
	end
	else begin
		ram1_r_en <= 1;
	end
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		ram2_r_en <= 1;
	end
	else if (Vsync==1 && (ram1_r_addr[9]==1) && read_data_count<(65535-2) && read_data_count>(65518-2) ) begin //mode 0 
		ram2_r_en <= 0;
	end
	else if (Vsync==1 && (ram1_r_addr[9]==1) && mode==1 && read_data_count<(32767-2) && read_data_count>(32750-2)) begin //mode 1
		ram2_r_en <= 0;
	end
	else begin
		ram2_r_en <= 1;
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

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		read_data_temp <= 0;
	end
	else if (mode==1 && round_count==1 && round==0 && read_data_count>32750 && Vsync==1 && ram1_r_addr[7:0]==0) begin//mode 1  255->512 511->0 767->256
		read_data_temp[255:240] <= (ram1_r_addr==256 ? ram2_data_out : ram1_data_out);
		read_data_temp[239:0] <= read_data_temp>>16;
	end
	else if (Vsync==1 && (read_data_count>65518||(mode==1 && read_data_count>32750))) begin//mode 0
		read_data_temp[255:240] <= (ram1_r_addr<=512 && ram1_r_addr !=0) ? ram1_data_out : ram2_data_out;
		read_data_temp[239:0] <= read_data_temp>>16;
	end
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		read_data[255:0] <= 0;
	end
	else if (mode==0 && Vsync ==1 && read_data_count==65535 )begin
		read_data <= read_data_temp;
		OUT[0]  <= (read_data_temp[15:0]   >read_data_count);
		OUT[1]  <= (read_data_temp[31:16]  >read_data_count);
		OUT[2]  <= (read_data_temp[47:32]  >read_data_count);
		OUT[3]  <= (read_data_temp[63:48]  >read_data_count);
		OUT[4]  <= (read_data_temp[79:64]  >read_data_count);
		OUT[5]  <= (read_data_temp[95:80]  >read_data_count);
		OUT[6]  <= (read_data_temp[111:96] >read_data_count);
		OUT[7]  <= (read_data_temp[127:112]>read_data_count);
		OUT[8]  <= (read_data_temp[143:128]>read_data_count);
		OUT[9]  <= (read_data_temp[159:144]>read_data_count);
		OUT[10] <= (read_data_temp[175:160]>read_data_count);
		OUT[11] <= (read_data_temp[191:176]>read_data_count);
		OUT[12] <= (read_data_temp[207:192]>read_data_count);
		OUT[13] <= (read_data_temp[223:208]>read_data_count);
		OUT[14] <= (read_data_temp[239:224]>read_data_count);
		OUT[15] <= (read_data_temp[255:240]>read_data_count);
	end
	else if (mode==1 && Vsync ==1 && read_data_count==32767 )begin
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
	end
	else if (Vsync ==1)begin
		OUT[0]  <= (read_data[15:0]   >read_data_count);
		OUT[1]  <= (read_data[31:16]  >read_data_count);
		OUT[2]  <= (read_data[47:32]  >read_data_count);
		OUT[3]  <= (read_data[63:48]  >read_data_count);
		OUT[4]  <= (read_data[79:64]  >read_data_count);
		OUT[5]  <= (read_data[95:80]  >read_data_count);
		OUT[6]  <= (read_data[111:96] >read_data_count);
		OUT[7]  <= (read_data[127:112]>read_data_count);
		OUT[8]  <= (read_data[143:128]>read_data_count);
		OUT[9]  <= (read_data[159:144]>read_data_count);
		OUT[10] <= (read_data[175:160]>read_data_count);
		OUT[11] <= (read_data[191:176]>read_data_count);
		OUT[12] <= (read_data[207:192]>read_data_count);
		OUT[13] <= (read_data[223:208]>read_data_count);
		OUT[14] <= (read_data[239:224]>read_data_count);
		OUT[15] <= (read_data[255:240]>read_data_count);
	end
end

endmodule
