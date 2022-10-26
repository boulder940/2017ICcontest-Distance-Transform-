`timescale 1ns/10ps
module DT(
	input 			clk, 
	input			reset,
	output	reg		done ,
	output	reg		sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	input		[15:0]	sti_di,
	output	reg		res_wr ,
	output	reg		res_rd ,
	output	reg 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	input		[7:0]	res_di,
	output  reg fwpass_finish
	);
parameter idle=4'd0,sr_rom=4'd1,sw_ram=4'd2,sfr=4'd3,sforward=4'd4,sfw=4'd5;
parameter sbr=4'd6,sback=4'd7,sbw=4'd8,sDONE=4'd9,sFPASS=4'd10,empty1=4'd11,empty2=4'd12,empty3=4'd13;
reg [3:0]cs,ns;
reg [15:0]sti_di_reg;
reg [7:0]res_di_reg;
reg [7:0]res_reg;
reg [10:0]rom_addr;
reg [4:0]cnt_w_ram;
reg [13:0]fw_cnt;
reg [13:0]bw_cnt;
reg [3:0]fr_cnt;
reg [3:0]br_cnt;
reg [13:0]f_addr_cnt;
reg [13:0]b_addr_cnt;
reg [13:0]sw_addr_cnt;
reg [13:0]addr_cnt_temp;
integer i;
always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		cs<=idle;
	end
	else begin
		cs<=ns;
	end
end
always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		sti_rd<=1'd0;
	end
	else if(ns == sr_rom)
	begin
		sti_rd<=1'd1;
	end
	else begin
		sti_rd<=1'd0;
	end
end
always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		res_rd<=1'd0;
	end
	else if(ns == sfr|| ns==sbr)
	begin
		res_rd<=1'd1;
	end
	else begin
		res_rd<=1'd0;
	end
end

always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		res_wr<=1'd0;
	end
	else if(ns == sfw|| ns==sbw || ns== sw_ram)
	begin
		res_wr<=1'd1;
	end
	else begin
		res_wr<=1'd0;
	end
end

always@(*)
begin
	case(cs)
	idle:begin
		ns=sr_rom;
	end
	sr_rom:begin
		ns=sw_ram;
	end
	sw_ram:begin
			if( cnt_w_ram < 5'd16)
			begin
				ns=sw_ram;
			end	
			else begin
				ns=empty1;
			end
	end
	empty1:begin
		if(rom_addr<11'd1024)
		begin
			ns=sr_rom;
		end
		else begin
			ns=empty2;
		end
	end
	empty2:begin
		ns=sfr;
	end
	sfr:begin
		ns=sforward;
	end
	sforward:begin
		if(fr_cnt <4'd5)
		begin
			ns=sfr;
		end
		else begin
			ns=sfw;
		end
	end
	sfw:begin
		if(fw_cnt > 14'd16254)
		begin
			ns=sFPASS;
		end
		else begin
			ns=empty2;
		end
	end
	sFPASS:begin
		ns=empty3;
	end
	sbr:begin
		ns=sback;
	end
	sback:begin
		if(br_cnt <4'd5)
		begin
			ns=sbr;
		end
		else begin
			ns=sbw;
		end
	end
	sbw:begin
		if(bw_cnt == 14'd128)
		begin
			ns=sDONE;
		end
		else begin
			ns=empty3;
		end
	end
	empty3:begin
		ns=sbr;
	end
	default:begin
		ns=idle;
	end
	endcase
end

always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		rom_addr<=10'd0;
		addr_cnt_temp=14'd0;
	end
	else if( ns==sr_rom)
	begin
		sti_addr<=rom_addr;
		rom_addr<=rom_addr+10'd1;
		addr_cnt_temp<=sw_addr_cnt;
	end
	else if(ns==sw_ram)
	begin
		addr_cnt_temp<=addr_cnt_temp+14'd1;
	end
	else if(ns==empty2)
	begin
		addr_cnt_temp<=f_addr_cnt;
	end
	else if(cs==sfr)
	begin
		if( fr_cnt==4'd2)
		begin
			addr_cnt_temp<=addr_cnt_temp+14'd126;
		end
		else if(fr_cnt <4'd4 && fr_cnt!=4'd2)
		begin
			addr_cnt_temp<=addr_cnt_temp+14'd1;
		end
	end
	else if(cs==sbr)
	begin
		if( br_cnt==4'd2)
		begin
			addr_cnt_temp<=addr_cnt_temp-14'd126;
		end
		else if(br_cnt <4'd4 && br_cnt!=4'd2)
		begin
			addr_cnt_temp<=addr_cnt_temp-14'd1;
		end
	end
	else if(ns==empty3)
	begin
		addr_cnt_temp<=b_addr_cnt;
	end
		
end
always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		cnt_w_ram<=4'd0;
	end
	else if( ns==sr_rom)
	begin
		cnt_w_ram<=4'd0;
	end
	else if(ns==sw_ram)
	begin
		cnt_w_ram<=cnt_w_ram+4'd1;
	end
end

always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		sw_addr_cnt<=14'd0;
	end
	else if(ns==empty1)
	begin	
		sw_addr_cnt<=sw_addr_cnt+14'd16;
	end
end
//forward....................................
always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		f_addr_cnt<=14'd0;
	end
	else if(ns==sfw)
	begin	
		f_addr_cnt<=f_addr_cnt+14'd1;
		
	end
end
always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		fr_cnt<=4'd0;
	end
	else if(cs==sfr)
	begin	
		fr_cnt<=fr_cnt+4'd1;
	end
	else if(ns==empty2)
	begin
		fr_cnt<=4'd0;
	end
end
always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		fw_cnt<=14'd0;
	end
	else if(ns==sfw)
	begin
		fw_cnt<=fw_cnt+14'd1;
	end
end
//back.......................
always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		b_addr_cnt<=14'd16383;
	end
	else if(ns==sbw)
	begin	
		b_addr_cnt<=b_addr_cnt-14'd1;
	end
end
always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		br_cnt<=4'd0;
	end
	else if(cs==sbr)
	begin	
		br_cnt<=br_cnt+4'd1;
	end
	else if(ns==empty3)
	begin
		br_cnt<=4'd0;
	end
end
always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		bw_cnt<=14'd16383;
	end
	else if(ns==sbw)
	begin
		bw_cnt<=bw_cnt-14'd1;
	end
end
always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		res_di_reg<=14'd0;
	end
	else if(ns==sforward)
	begin
		if(fr_cnt==4'd0)
		begin
			res_di_reg<=res_di;
		end
		else begin
			if(res_di < res_di_reg)
			begin
				res_di_reg<=res_di;
			end
		end
	end
	else if(ns==sback)
	begin
		if(br_cnt==4'd0)
		begin
			res_di_reg<=res_di+8'd1;
		end
		else if(br_cnt <4'd4 && br_cnt!=4'd0)
		begin
			if(res_di+8'd1 < res_di_reg)
			begin
				res_di_reg<=res_di+8'd1;
			end
		end
		else if(br_cnt==4'd4)
		begin
			if(res_di < res_di_reg)
			begin
				res_di_reg<=res_di;
			end
		end
	end
end
always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		res_do<=8'd0;
	end
	else if(ns==sw_ram)
	begin
		res_do<={7'b0,sti_di[4'd15-cnt_w_ram]};
	end
	else if(ns==empty2)
	begin
		res_do<=8'd0;
	end
	else if(ns==sforward)
	begin
		if(fr_cnt==4'd4)
		begin
			if( res_di==8'd0)
			begin
				res_do<=res_di;
			end
			else begin
				res_do<=res_di_reg+8'd1;
			end
		end
	end
	else if(ns==empty3)
	begin
		res_do<=8'd0;
	end
	else if(cs==sback)
	begin
		if(br_cnt==4'd5)
		begin
			if( res_di==8'd0)
			begin
				res_do<=res_di;
			end
			else begin
				res_do<=res_di_reg;
			end
		end
	end
end

always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		res_addr<=14'd0;
	end
	else if(ns==sw_ram)
	begin
		res_addr<=addr_cnt_temp;
	end
	else if(ns==sfr)
	begin
		res_addr<=addr_cnt_temp;
	end
	else if(ns==sfw)	
	begin
		res_addr<=addr_cnt_temp;
	end
	else if(ns==sbr)
	begin
		res_addr<=addr_cnt_temp;
	end
	else if(ns==sbw)
	begin
		res_addr<=addr_cnt_temp;
	end
end

//output logic
always@(*)
begin
	case(cs)
	idle:begin
		done=1'd0;
		fwpass_finish=1'b0;
	end
	sFPASS:begin
		fwpass_finish=1'b1;
	end
	sDONE:begin
		done=1'b1;
	end
endcase
end

endmodule



