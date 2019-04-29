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

wire [15:0] ram1_data_out,ram2_data_out,ram1_data_in;
reg ram1_r_en,ram1_w_en,ram2_w_en,ram2_r_en;
reg [8:0] ram1_r_addr,ram2_r_addr;//0~511
reg [8:0] ram1_w_addr;
reg [7:0] ram2_w_addr;//0~255
reg [15:0] ram2_data_in;
reg [3:0] write_data_count;
reg [95:0] read_data;
reg [95:0] read_data_temp; 
reg [15:0] read_data_count;
reg [4:0] ram1_w_addr_scanline_count;
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
wire move_data_from_ram2;
assign  move_data_from_ram2 =(( mode==0 && read_data_count<1024 && ram1_w_addr_scanline_count==0) || 
				              ( mode==0 && read_data_count>19388 && read_data_count <20408 && ram1_w_addr_scanline_count==20) ||
				              ( mode==1 && round==0 && read_data_count<48 && ram1_w_addr_scanline_count<16) ||
				              ( mode==1 && round==1 && read_data_count>19388 && read_data_count <19436 && ram1_w_addr_scanline_count>=8 && ram1_w_addr_scanline_count<=23) ) ;

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		ram2_r_en <= 1;
	end
	else if (Vsync==1 && read_data_count[4:0]<8 && move_data_from_ram2==1) begin
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
	else if ( (mode==0 && read_data_count == 65504) || (mode==1 && read_data_count == 32736) ) begin
		ram1_w_addr_scanline_count <= ram1_w_addr_scanline_count+1; 
	end
	else begin
		ram1_w_addr_scanline_count <= ram1_w_addr_scanline_count;
	end
end

always @(posedge GCK or posedge rst) begin//0~15
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

/*reg[3:0] ram1_w_addr_reuse;
always @(posedge GCK or posedge rst) begin//0~15
	if (rst) begin
		ram1_w_addr_reuse <=0;
	end
	else if (Vsync==1) begin
		ram1_w_addr_reuse <= ram1_w_addr_reuse +1 ; 
	end
end*/

assign  ram1_data_in = ram2_data_out;


wire [4:0] tt;
assign tt = ram1_w_addr_scanline_count+1;
wire [3:0] dd;
assign dd = read_data_count[3:0]+3;
////////////////////read from ram1///////////////////////
always @(posedge GCK or posedge rst) begin//0~15
	if (rst) begin
		ram1_r_addr <= 0; 
	end
	else if ((read_data_count==65504)||(mode==1 && read_data_count==32736)) begin
		ram1_r_addr <= {tt,read_data_count[3:0]}; 
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

wire [15:0] compared_data;
assign compared_data = (mode==1 ? ram1_data_out[15:1] : ram1_data_out);
wire [10:0] next_read_data_count;
assign next_read_data_count = ( (mode==1&&read_data_count[14:5]==10'b1111111111) ? 0 : read_data_count[15:5]+1);
wire [16:0] subtraction;
assign  subtraction = (  {1'b0,compared_data} - {1'b0,next_read_data_count,5'b00000} );
wire [5:0] debug;
assign debug = read_data_temp[95:90];
reg [15:0] temp_try;
wire[5:0] result;
assign result = subtraction[5:0]+ (mode==1 && round==0 && ram1_data_out[0]==1 );
always @(posedge GCK or posedge rst) begin
	if (rst) begin
		read_data_temp <= 0;
		temp_try <= 0;
	end
	else if ( read_data_count[4:0]>14 && read_data_count[4:0]<31 ) begin

		if( (next_read_data_count==11'b00000000000) )begin //for the last cycle update
			read_data_temp[95:90] <=  (compared_data>32) ? 32 :( compared_data[5:0]>0 ? compared_data[5:0]-1 : 0);
			temp_try[15] <= compared_data[5:0]>0;
		end
		else if( 32>=subtraction[15:0] && subtraction[16]==0)begin//dataout end in the next cycle
			read_data_temp[95:90] <= result>0 ? result-1 : 0;
			temp_try[15] <= result>0;
		end
		else if( (subtraction[15:0]>=32 && subtraction[16]==1) )begin//negative means already exceeded data count
			read_data_temp[95:90] <= 0 ;
			temp_try[15] <= 0; 
		end
		else begin
			read_data_temp[95:90] <= 32;//positive and >32
			temp_try[15] <= 1;
		end

		read_data_temp[89:0] <= read_data_temp>>6;
		temp_try[14:0] <= temp_try>>1;
	end
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		read_data <= 0;
	end
	else if ( (Vsync==1 && read_data_count[4:0]==5'b11111)||Vsync==0)begin
		read_data <= read_data_temp;
		OUT[0 ]  <= temp_try[0 ]|(read_data_temp[5:0]   > 0);//|(read_data[5:0]  ==32 && read_data_temp[5:0]  ==0) ;
		OUT[1 ]  <= temp_try[1 ]|(read_data_temp[11:6]  > 0);//|(read_data[11:6] ==32 && read_data_temp[11:6] ==0) ;
		OUT[2 ]  <= temp_try[2 ]|(read_data_temp[17:12] > 0);//|(read_data[17:12]==32 && read_data_temp[17:12]==0) ;
		OUT[3 ]  <= temp_try[3 ]|(read_data_temp[23:18] > 0);//|(read_data[23:18]==32 && read_data_temp[23:18]==0) ;
		OUT[4 ]  <= temp_try[4 ]|(read_data_temp[29:24] > 0);//|(read_data[29:24]==32 && read_data_temp[29:24]==0) ;
		OUT[5 ]  <= temp_try[5 ]|(read_data_temp[35:30] > 0);//|(read_data[35:30]==32 && read_data_temp[35:30]==0) ;
		OUT[6 ]  <= temp_try[6 ]|(read_data_temp[41:36] > 0);//|(read_data[41:36]==32 && read_data_temp[41:36]==0) ;
		OUT[7 ]  <= temp_try[7 ]|(read_data_temp[47:42] > 0);//|(read_data[47:42]==32 && read_data_temp[47:42]==0) ;
		OUT[8 ]  <= temp_try[8 ]|(read_data_temp[53:48] > 0);//|(read_data[53:48]==32 && read_data_temp[53:48]==0) ;
		OUT[9 ]  <= temp_try[9 ]|(read_data_temp[59:54] > 0);//|(read_data[59:54]==32 && read_data_temp[59:54]==0) ;
		OUT[10]  <= temp_try[10]|(read_data_temp[65:60] > 0);//|(read_data[65:60]==32 && read_data_temp[65:60]==0) ;
		OUT[11]  <= temp_try[11]|(read_data_temp[71:66] > 0);//|(read_data[71:66]==32 && read_data_temp[71:66]==0) ;
		OUT[12]  <= temp_try[12]|(read_data_temp[77:72] > 0);//|(read_data[77:72]==32 && read_data_temp[77:72]==0) ;
		OUT[13]  <= temp_try[13]|(read_data_temp[83:78] > 0);//|(read_data[83:78]==32 && read_data_temp[83:78]==0) ;
		OUT[14]  <= temp_try[14]|(read_data_temp[89:84] > 0);//|(read_data[89:84]==32 && read_data_temp[89:84]==0) ;
		OUT[15]  <= temp_try[15]|(read_data_temp[95:90] > 0);//|(read_data[95:90]==32 && read_data_temp[95:90]==0) ;
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
end

always @(posedge GCK or posedge rst) begin
	if (rst) begin
		round <= 0;
	end
	else if (mode==1 && read_data_count==32736 && ram1_w_addr_scanline_count==31) begin
		round <= ~round;
	end
end

endmodule
