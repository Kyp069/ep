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
module rom8
//-------------------------------------------------------------------------------------------------
#
(
	parameter KB = 128
)
(
	input  wire                      clock,
	input  wire[$clog2(KB*1024)-1:0] a,
	input  wire[                7:0] d,
	output reg [                7:0] q,
	input  wire                      w
);
//-------------------------------------------------------------------------------------------------

(* ram_init_file = "../rom/exos_exdos_isdos_file_sdext.mif" *) reg[7:0] mem[0:(KB*1024)-1];

always @(posedge clock) if(w) begin q <= d; mem[a] <= d; end else q <= mem[a];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
