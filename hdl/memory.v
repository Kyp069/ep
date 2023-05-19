//-------------------------------------------------------------------------------------------------
//  Elan Enterprise memory
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
module memory
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       ce,

	input  wire       reset,
	input  wire       iorq,
	input  wire       mreq,
	input  wire       rd,
	input  wire       wr,
	input  wire[15:0] a,
	input  wire[ 7:0] d,
	output wire[ 7:0] q,

	output wire[21:0] memA2,
	output wire[ 7:0] memD2,
	input  wire[ 7:0] memQ2,
	output wire       memR2,
	output wire       memW2
);
//-------------------------------------------------------------------------------------------------

wire ioB0 = !iorq && a[7:0] == 8'hB0;
wire ioB1 = !iorq && a[7:0] == 8'hB1;
wire ioB2 = !iorq && a[7:0] == 8'hB2;
wire ioB3 = !iorq && a[7:0] == 8'hB3;

reg[7:0] regB0;
reg[7:0] regB1;
reg[7:0] regB2;
reg[7:0] regB3;

always @(posedge clock, negedge reset)
	if(!reset) begin
		regB0 <= 8'h00;
		regB1 <= 8'h00;
		regB2 <= 8'h00;
		regB3 <= 8'h00;
	end
	else if(ce) begin
		if(ioB0 && !wr) regB0 <= d;
		if(ioB1 && !wr) regB1 <= d;
		if(ioB2 && !wr) regB2 <= d;
		if(ioB3 && !wr) regB3 <= d;
	end

reg[7:0] page;

always @(*) case(a[15:14])
	0: page = regB0;
	1: page = regB1;
	2: page = regB2;
	3: page = regB3;
endcase

//-------------------------------------------------------------------------------------------------

assign q
	= ioB0 ? regB0
	: ioB1 ? regB1
	: ioB2 ? regB2
	: ioB3 ? regB3
	:        memQ2;

assign memA2 = { page, a[13:0] };
assign memD2 = d;
assign memR2 = !mreq && !rd;
assign memW2 = !mreq && !wr;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
