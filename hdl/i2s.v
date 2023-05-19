//-------------------------------------------------------------------------------------------------
//  I2S audio encoder
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
module i2s
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	output wire[ 2:0] i2s,
	input  wire[15:0] l,
	input  wire[15:0] r
);
//-------------------------------------------------------------------------------------------------

reg[8:0] ce;
always @(negedge clock) ce <= ce+1'd1;

wire ce4 = &ce[3:0];
wire ce5 = &ce[4:0];
wire ce9a = ce[8] & ce[7] & ce[6] &  ce[5] & ce[4] & ce[3] & ce[2] & ce[1] & ce[0];
wire ce9b = ce[8] & ce[7] & ce[6] & ~ce[5] & ce[4] & ce[3] & ce[2] & ce[1] & ce[0];

reg ck;
always @(posedge clock) if(ce4) ck <= ~ck;

reg lr;
always @(posedge clock) if(ce9b) lr <= ~lr;

reg q;
reg[14:0] sr;
always @(posedge clock) if(ce9a) { q, sr } <= lr ? r : l; else if(ce5) { q, sr } <= { sr, 1'b0 };

assign i2s = { q, lr, ck };

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
