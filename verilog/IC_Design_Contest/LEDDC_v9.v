`timescale 1ns/10ps
module LEDDC( DCK, DAI, DEN, GCK, Vsync, mode, rst, OUT);
input           DCK;
input           DAI;
input           DEN;
input           GCK;
input           Vsync;
input           mode;
input           rst;
output reg[15:0]  OUT;

wire [15:0] ram1_data_out,ram2_data_out,ram1_data_in;
reg ram1_r_en,ram1_w_en,ram2_w_en,ram2_r_en;
reg [8:0] ram1_r_addr,ram2_r_addr;//0~511
reg [8:0] ram1_w_addr;
reg [7:0] ram2_w_addr;//0~255
reg [15:0] ram2_data_in;
reg [3:0] write_data_count;
reg [79:0] read_data;
reg [79:0] read_data_temp; 
reg [15:0] read_data_count;
reg [4:0] read_scanline_count;
reg [15:0] first_data_OUT;
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
	else if ( (write_data_count==15) && (DEN==1) ) begin
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
	else if ( (write_data_count==15) && (DEN==1) ) begin
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
	else if ( DEN==1 ) begin
		ram2_data_in[15] <= DAI;
		ram2_data_in[14:0] <= ram2_data_in>>1;
	end
end
//////////////////read from ram2///////////////////////////
wire move_data_from_ram2;
assign  move_data_from_ram2 =(( mode==0 && read_data_count[15:10]==0 && read_scanline_count==0) || //read_data_count<1024
				              ( mode==0 && read_data_count>19376 && read_data_count<20400 && read_scanline_count==20) ||
				              ( mode==1 && round==0 && read_data_count<48 && read_scanline_count[4]==0) ||//read_scanline_count from 0~7
				              ( mode==1 && round==1 && read_data_count>19388 && read_data_count <19436 && read_scanline_count>7 && read_scanline_count<24) ) ;

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		ram2_r_en <= 1;
	end
	else if ( Vsync==1 && read_data_count[4:0]<8 && move_data_from_ram2==1 ) begin
		ram2_r_en <= 0;
	end
	else begin
		ram2_r_en <= 1;
	end
end

always @(posedge GCK or posedge rst) begin//use 9bit to represent 512 address can be used by ram1_w_addr at the same time
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
always @(posedge GCK or posedge rst) begin//0~31
	if (rst) begin
		read_scanline_count <= 0;	
	end
	else if ( (read_data_count == 65504) || (mode==1 && read_data_count == 32736) ) begin
		read_scanline_count <= read_scanline_count+1; 
	end
	else begin
		read_scanline_count <= read_scanline_count;
	end
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		ram1_w_addr <= 0;
	end
	else begin
		ram1_w_addr <= ram2_r_addr;
	end
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		ram1_w_en <= 1;
	end
	else if ( read_data_count[4:0]>0 && read_data_count[4:0]<9 && move_data_from_ram2==1 ) begin //data move from ram2
		ram1_w_en <= 0;
	end
	else begin
		ram1_w_en <= 1;
	end
end

assign  ram1_data_in = ram2_data_out;

wire [4:0] read_scanline_count_add;
assign read_scanline_count_add = read_scanline_count+1;
wire [3:0] read_data_count_add;
assign read_data_count_add = read_data_count[3:0]+3;
////////////////////read from ram1///////////////////////
always @(posedge GCK or posedge rst) begin//0~15
	if (rst) begin
		ram1_r_addr <= 0; 
	end
	else if ( read_data_count==65504 || (mode==1 && read_data_count==32736) ) begin
		ram1_r_addr <= { read_scanline_count_add,read_data_count[3:0]}; 
	end
	else if ( ~ram1_r_en ) begin
		ram1_r_addr <= {read_scanline_count,read_data_count_add}; 
	end
	else begin
		ram1_r_addr <= ram1_r_addr;
	end
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		ram1_r_en <= 1;
	end
	else if ( read_data_count[4:0]>12 && read_data_count[4:0]<29 && read_data_count!=0 ) begin 
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
	else if ( mode==1 && Vsync==1 && read_data_count==32767 ) begin
		read_data_count <= 0;
	end
	else if ( Vsync == 1 ) begin
		read_data_count <= read_data_count +1;
	end
end

wire [15:0] processed_data;
assign processed_data = (mode==1 ? ram1_data_out[15:1] : ram1_data_out);

wire [10:0] next_read_data_count;
assign next_read_data_count = ( (mode==1&&read_data_count[14:5]==10'b1111111111) ? 0 : read_data_count[15:5]+1);

wire [16:0] compared_data;
assign compared_data = (  {1'b0,processed_data} - {1'b0,next_read_data_count,5'b00000} )+ (mode==1 && round==0 && ram1_data_out[0]==1 );

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		read_data_temp <= 0;
		first_data_OUT <= 0;
	end
	else if ( read_data_count[4:0]>14 && read_data_count[4:0]<31 ) begin

		if( 32>=compared_data[15:0] && compared_data[16]==0 )begin//dataout end in the next cycle
			read_data_temp[79:75] <= (compared_data[5:0]!=0) ? compared_data[5:0]-1 : 0;
			first_data_OUT[15] <= compared_data[5:0]!=0 ;
		end
		else if( compared_data[15:5]!=0 && compared_data[16]==1 )begin//negative means already exceeded data count compared_data[15:0]>=32
			read_data_temp[79:75] <= 0 ;
			first_data_OUT[15] <= 0; 
		end
		else begin
			read_data_temp[79:75] <= 31;//positive and >32 ,so keepgoing~
			first_data_OUT[15] <= 1;
		end
		read_data_temp[74:0] <= read_data_temp>>5;
		first_data_OUT[14:0] <= first_data_OUT>>1;
	end
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		read_data <= 0;
	end
	else if ( read_data_count[4:0]==5'b11111 )begin
		read_data <= read_data_temp;
		OUT[0 ] <= first_data_OUT[0 ]|(read_data_temp[4:0]  !=0);
		OUT[1 ] <= first_data_OUT[1 ]|(read_data_temp[9:5]  !=0);
		OUT[2 ] <= first_data_OUT[2 ]|(read_data_temp[14:10]!=0);
		OUT[3 ] <= first_data_OUT[3 ]|(read_data_temp[19:15]!=0);
		OUT[4 ] <= first_data_OUT[4 ]|(read_data_temp[24:20]!=0);
		OUT[5 ] <= first_data_OUT[5 ]|(read_data_temp[29:25]!=0);
		OUT[6 ] <= first_data_OUT[6 ]|(read_data_temp[34:30]!=0);
		OUT[7 ] <= first_data_OUT[7 ]|(read_data_temp[39:35]!=0);
		OUT[8 ] <= first_data_OUT[8 ]|(read_data_temp[44:40]!=0);
		OUT[9 ] <= first_data_OUT[9 ]|(read_data_temp[49:45]!=0);
		OUT[10] <= first_data_OUT[10]|(read_data_temp[54:50]!=0);
		OUT[11] <= first_data_OUT[11]|(read_data_temp[59:55]!=0);
		OUT[12] <= first_data_OUT[12]|(read_data_temp[64:60]!=0);
		OUT[13] <= first_data_OUT[13]|(read_data_temp[69:65]!=0);
		OUT[14] <= first_data_OUT[14]|(read_data_temp[74:70]!=0);
		OUT[15] <= first_data_OUT[15]|(read_data_temp[79:75]!=0);
	end
	else if ( Vsync ==1 )begin
		OUT[0]  <= (read_data[4:0]   > read_data_count[4:0]);
		OUT[1]  <= (read_data[9:5]   > read_data_count[4:0]);
		OUT[2]  <= (read_data[14:10] > read_data_count[4:0]);
		OUT[3]  <= (read_data[19:15] > read_data_count[4:0]);
		OUT[4]  <= (read_data[24:20] > read_data_count[4:0]);
		OUT[5]  <= (read_data[29:25] > read_data_count[4:0]);
		OUT[6]  <= (read_data[34:30] > read_data_count[4:0]);
		OUT[7]  <= (read_data[39:35] > read_data_count[4:0]);
		OUT[8]  <= (read_data[44:40] > read_data_count[4:0]);
		OUT[9]  <= (read_data[49:45] > read_data_count[4:0]);
		OUT[10] <= (read_data[54:50] > read_data_count[4:0]);
		OUT[11] <= (read_data[59:55] > read_data_count[4:0]);
		OUT[12] <= (read_data[64:60] > read_data_count[4:0]);
		OUT[13] <= (read_data[69:65] > read_data_count[4:0]);
		OUT[14] <= (read_data[74:70] > read_data_count[4:0]);
		OUT[15] <= (read_data[79:75] > read_data_count[4:0]);
	end
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		round <= 0;
	end
	else if (mode==1 && read_data_count==32736 && read_scanline_count==31) begin
		round <= ~round;
	end
end

endmodule
