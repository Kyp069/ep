//-------------------------------------------------------------------------------------------------
//  Elan Enterprise mouse
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
module mouse
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       cecpu,
	input  wire       ce1M0,

	input  wire       reset,
	input  wire       iorq,
	input  wire       wr,
	input  wire[ 7:0] a,
	input  wire[ 1:1] d,
	output reg [ 3:0] q,

	input  wire[ 7:0] xaxis,
	input  wire[ 7:0] yaxis
);
//-------------------------------------------------------------------------------------------------

wire ioB7 = !iorq && a == 8'hB7;

reg mrs;
always @(posedge clock, negedge reset)
	if(!reset) mrs <= 1'b0; else
	if(cecpu) if(ioB7 && !wr) mrs <= d;

reg mrsd, mrsp;
always @(posedge clock, negedge reset)
	if(!reset) { mrsd, mrsp } <= 1'd0; else
	if(ce1M0) begin mrsd <= mrs; mrsp <= mrs != mrsd; end

reg[10:0] mcc;
wire mccrs = mcc == 1499;
always @(posedge clock, negedge reset)
	if(!reset) mcc <= 1'd0; else
	if(ce1M0) if(mrsp) mcc <= 1'd0; else if(!mccrs) mcc <= mcc+1'd1;

reg[3:0] mrg;
always @(posedge clock, negedge reset)
	if(!reset) mrg <= 1'd0; else
	if(ce1M0) if(mrsp) if(mccrs) mrg <= 1'd0; else mrg <= mrg+1'd1;

reg[7:0] mxx1, mxx2;
always @(posedge clock, negedge reset)
	if(!reset) { mxx1, mxx2 } <= 1'd0; else
	if(ce1M0) if(mrsp) if(mccrs) { mxx2, mxx1 } <= { mxx1, xaxis };

reg[7:0] myy1, myy2;
always @(posedge clock, negedge reset)
	if(!reset) { myy1, myy2 } <= 1'd0; else
	if(ce1M0) if(mrsp) if(mccrs) { myy2, myy1 } <= { myy1, yaxis };

wire[7:0] mxx = mxx2-mxx1;
wire[7:0] myy = myy1-myy2;

always @(*)
	case(mrg)
		0: q <= mxx[7:4];
		1: q <= mxx[3:0];
		2: q <= myy[7:4];
		3: q <= myy[3:0];
		default: q <= 4'b0000;
	endcase

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
