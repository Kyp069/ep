//-------------------------------------------------------------------------------------------------
//  Elan Enterprise video
//-------------------------------------------------------------------------------------------------
//  This file is part of the Elan Enterprise FPGA implementation project.
//  Copyright (C) 2023 Kyp069 <kyp069@gmail.com>
//
//  This program is free software; you can redistribute it and/or modify it under the terms 
//  of the GNU General Public License as published by the Free Software Foundation;
//  either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program;
//  if not, If not, see <https://www.gnu.org/licenses/>.
//-------------------------------------------------------------------------------------------------
module video
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock56,
	input  wire       clock32,
	input  wire       cepix,
	input  wire       cecpu,

	input  wire       iorq,
	input  wire       wr,
	input  wire[ 7:0] a,
	input  wire[ 7:0] d,

	output reg        irq,
	output wire[15:0] va,
	input  wire[ 7:0] vd,

	output wire       hblank,
	output wire       vblank,
	output wire       hsync,
	output reg        vsync,
	output wire[ 2:0] r,
	output wire[ 2:0] g,
	output wire[ 1:0] b
);
//-------------------------------------------------------------------------------------------------

reg[7:0] reg80 = 8'h00;
reg[7:0] reg81 = 8'h00;
reg[7:0] reg82 = 8'h00;
reg[7:0] reg83 = 8'h00;

always @(posedge clock32) if(cecpu)
	if(!iorq && !wr && a[7:4] == 4'h8 && a[3:2] == 2'b00)
		case(a[1:0])
			0: reg80 <= d;
			1: reg81 <= d;
			2: reg82 <= d;
			3: reg83 <= d;
		endcase

wire[ 4:0] bias = reg80[4:0];
wire[ 7:0] back = reg81[7:0];
wire[15:4] lpbp = { reg83[3:0], reg82[7:0] };

wire count = reg83[6]; // 1'b1; //
wire forceload = reg83[7];

//-------------------------------------------------------------------------------------------------

reg[3:0] ne;
reg[5:0] ce = 1'd1;
always @(negedge clock56)
	if(hReset) ce <= 1'b1;
	else if(cepix) begin
		ce <= ce+1'd1;
		ne[3] <= ~ce[0];
		ne[2] <= ~ce[0] & ~ce[1];
		ne[1] <= ~ce[0] & ~ce[1] & ~ce[2];
		ne[0] <= ~ce[0] & ~ce[1] & ~ce[2] & ~ce[3];
	end

//-------------------------------------------------------------------------------------------------

reg[9:0] hCount = 0;
wire hReset = hCount >= 911 || !count;
always @(posedge clock56) if(cepix) if(hReset) hCount <= 1'd0; else hCount <= hCount+1'd1;

//reg[8:0] vCount = 0;
//wire vReset = vCount >= 311 || !count;
//always @(posedge clock56) if(cepix) if(hReset) if(vReset) vCount <= 1'd0; else vCount <= vCount+1'd1;

//-------------------------------------------------------------------------------------------------

wire[5:0] hc = hCount[9:4];
wire[3:0] hs = hCount[3:0];
wire[3:0] hp = { hCount[6:4], ul2 };

wire load1 = hs == 4;
wire load2 = hs == 9;
wire loadP = hCount == 127;

wire ul1 = hs >= 0 && hs <  5;
wire ul2 = hs >= 5 && hs < 10;

//-------------------------------------------------------------------------------------------------

reg[ 7:0] lpb[0:15];

wire      reload  = lpb[1][0] && &sc;
wire[2:0] vmode   = lpb[1][3:1];
wire      vres    = lpb[1][4];
wire[1:0] cmode   = lpb[1][6:5];
wire      vint    = lpb[1][7];

wire[5:0] lm      = lpb[2][5:0];
wire      lsbalt  = lpb[2][6];
wire      msbalt  = lpb[2][7];

wire[5:0] rm      = lpb[3][5:0];
wire      altind1 = lpb[3][6];
wire      altind0 = lpb[3][7];

wire      fetch = hc >= lm && hc < rm;

reg[15:4] lpa;
always @(posedge clock56) if(cepix)
	if(!forceload) lpa <= lpbp;
	else
		if(hReset) if(reload) lpa <= lpbp; else if(&sc) lpa <= lpa+1'd1;

reg params;
always @(posedge clock56) if(cepix)
	if(!forceload) params <= 1'b1;
	else begin
		if(loadP) params <= 1'b0;
		if(hReset) if(reload || &sc) params <= 1'b1;
	end

always @(posedge clock56) if(cepix)
	if(params) if(load1 || load2) lpb[hp] <= vd;

reg[7:0] sc;
always @(posedge clock56) if(cepix)
	if(loadP) if(params) sc <= lpb[0]; else sc <= sc+1'd1;

reg[15:0] a1;
always @(posedge clock56) if(cepix) begin
	if(loadP) if(params || !vres) a1 <= { lpb[5], lpb[4] };
	if(fetch && load1) a1 <= a1+1'd1;
	if(fetch && load2 && vmode == 3'b001) a1 <= a1+1'd1;
end

reg[15:0] a2;
always @(posedge clock56) if(cepix) begin
	if(loadP) if(params || (vmode == 3'b010 && !vres)) a2 <= { lpb[7], lpb[6] };
	if(fetch && load2) if(vmode == 3'b010) a2 <= a2+1'd1;
	if(hReset) if(vmode == 3'b011 || vmode == 3'b100 || vmode == 3'b101) a2 <= a2+1'd1;
end

reg[7:0] d1;
always @(posedge clock56) if(cepix)
	if(fetch && load1) d1 <= vd;

reg[7:0] d2;
always @(posedge clock56) if(cepix)
	if(fetch && load2) d2 <= vd;

assign va
	= params ? { lpa, hp }
	: ul1 ? a1
	: vmode == 3'b001 ? a1
	: vmode == 3'b111 ? a1
	: vmode == 3'b011 ? { a2[7:0], d1[7:0] }
	: vmode == 3'b100 ? { a2[8:0], d1[6:0] }
	: vmode == 3'b101 ? { a2[9:0], d1[5:0] }
//	: vmode == 3'b010 ? a2
	: a2;

//-------------------------------------------------------------------------------------------------

wire pCe
	= vmode == 3'b001 ? (cmode == 2'b00 ? cepix : cmode == 2'b01 ? ne[3] : cmode == 2'b10 ? ne[2] : 1'b0)
	:                   (cmode == 2'b00 ? ne[3] : cmode == 2'b01 ? ne[2] : cmode == 2'b10 ? ne[1] : 1'b0);

reg[7:0] sr, attr;
reg msb, lsb, ai1, ai0;
always @(posedge clock56) if(cepix) begin
	if(hs == 7) case(vmode)
		3'b001: begin
			msb <= msbalt && d2[7];
			lsb <= lsbalt && d2[0];
			sr <= { d2[7] && !(cmode == 2'b00 && msbalt), d2[6:1], d2[0] && !(cmode == 2'b00 && lsbalt) };
		end
		default:
			if(pCe) sr <= { sr[6:0], 1'b0 };
	endcase else
	if(hs == 15) case(vmode)
		3'b001, 3'b111: begin
			msb <= msbalt & d1[7];
			lsb <= lsbalt & d1[0];
			sr <= { d1[7] && !(cmode == 2'b00 && msbalt), d1[6:1], d1[0] && !(cmode == 2'b00 && lsbalt) };
		end
		3'b010: begin
			attr <= d1;
			sr <= d2;
		end
		3'b011, 3'b100, 3'b101: begin
			ai1 <= altind1 & d1[7];
			ai0 <= altind0 & d1[6];
			sr <= d2;
		end
	endcase else
	if(pCe) sr <= { sr[6:0], 1'b0 };
end

//-------------------------------------------------------------------------------------------------

wire pvm = vmode == 3'b001 || vmode == 3'b111;
wire cvm = vmode == 3'b011 || vmode == 3'b100 || vmode == 3'b101;

wire pm1 = (pvm && msb) || (cvm && ai1);
wire pl0 = (pvm && lsb) || (cvm && ai0);

wire[3:0] pnum
	= vmode == 3'b010 ? { sr[7] ? attr[3:0] : attr[7:4] }
	: cmode == 2'b00 ? {  1'b0,   pl0,   pm1, sr[7] }
	: cmode == 2'b01 ? {  1'b0,   pl0, sr[3], sr[7] }
	: cmode == 2'b10 ? { sr[1], sr[5], sr[3], sr[7] }
	: 4'b0000;

wire[7:0] pval = lpb[{ 1'b1, pnum[2:0] }];
wire[7:0] color = hc <= lm || hc > rm ? back : cmode == 2'b11 ? sr : pnum[3] ? { bias, pnum[2:0] } : pval;

//-------------------------------------------------------------------------------------------------

always @(posedge clock56) if(cepix) if(hReset) irq <= vint;

//-------------------------------------------------------------------------------------------------

assign hblank = hc <= 10;
assign vblank = vmode == 3'b000;

assign hsync = hc >= 1 && hc <= 4;
always @(posedge clock56) if(cepix)
	if(!vblank) vsync <= 1'b0;
	else if(hc == rm) vsync <= 1'b0;
	else if(hc == lm) vsync <= 1'b1;
//assign vsync = vblank && (lm <= rm);

//assign vblank = vCount >= 304;
//assign vsync = vCount >= 304 && vCount <= 307;

assign r = { color[0], color[3], color[6] };
assign g = { color[1], color[4], color[7] };
assign b = { color[2], color[5] };

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
