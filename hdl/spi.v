//-------------------------------------------------------------------------------------------------
//  SPI interface
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
module spi
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      ce,
	input  wire      io,
	input  wire[7:0] d,
	output reg [7:0] q,
	output wire      ck,
	output wire      mosi,
	input  wire      miso
);
//-------------------------------------------------------------------------------------------------

reg[7:0] sd;
reg[4:0] count = 5'b10000;

always @(negedge clock) if(ce)
	if(count[4]) begin
		if(io) begin
			sd <= d;
			count <= 5'd0;
		end
	end
	else begin
		count <= count+5'd1;
		if(count[0]) sd <= { sd[6:0], miso };
		if(count == 5'b01111) q <= { sd[6:0], miso };
	end

//-------------------------------------------------------------------------------------------------

assign ck = count[0];
assign mosi = sd[7];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
