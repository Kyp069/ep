//-------------------------------------------------------------------------------------------------
//  Single port ROM
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
module rom
//-------------------------------------------------------------------------------------------------
#
(
	parameter KB = 0,
	parameter FN = ""
)
(
	input  wire                      clock,
	input  wire[$clog2(KB*1024)-1:0] a,
	output reg [                7:0] q
);
//-------------------------------------------------------------------------------------------------
/*
(* ram_init_file = "../rom/exos_exdos_isdos_file_sdext.mif" *) reg[7:0] mem[(KB*1024)-1:0];

wire w = 1'b0;
wire[7:0] d = 8'hFF;
always @(posedge clock) if(w) begin q <= d; mem[a] <= d; end else q <= mem[a];
*/
/*
reg[7:0] mem[(KB*1024)-1:0];
initial if(FN != "") $readmemh(FN, mem);

always @(posedge clock) q <= mem[a];
*/
(* ram_init_file = "../rom/exos_exdos_isdos_file_sdext.mif" *) reg[7:0] mem[(KB*1024)-1:0];
always @(posedge clock) q <= mem[a];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
