//-------------------------------------------------------------------------------------------------
//  Dual port RAM, port 1 read only, port 2 read/write
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
module dprf
//-------------------------------------------------------------------------------------------------
#
(
	parameter KB = 0
)
(
	input  wire                      clock1,
	input  wire[$clog2(KB*1024)-1:0] a1,
	output reg [                7:0] q1,
	input  wire                      clock2,
	input  wire[$clog2(KB*1024)-1:0] a2,
	input  wire[                7:0] d2,
	output reg [                7:0] q2,
	input  wire                      w2
);
//-------------------------------------------------------------------------------------------------

reg[7:0] mem[(KB*1024)-1:0];

wire w1 = 1'b0;
wire[7:0] d1 = 8'hFF;
always @(posedge clock1) if(w1) begin q1 <= d1; mem[a1] <= d1; end else q1 <= mem[a1];
always @(posedge clock2) if(w2) begin q2 <= d2; mem[a2] <= d2; end else q2 <= mem[a2];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
