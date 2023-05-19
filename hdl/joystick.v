//-------------------------------------------------------------------------------------------------
//  Joystick deserializer
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
module joystick
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,

	output reg        joyCk,
	output reg        joyLd,
	output wire       joyS,
	input  wire       joyD,

	output reg [ 7:0] joy1,
	output reg [ 7:0] joy2
);
//-------------------------------------------------------------------------------------------------

reg[5:0] cc;
wire ce = cc == 49;
always @(posedge clock) if(ce) cc <= 1'd0; else cc <= cc+1'd1;

//-------------------------------------------------------------------------------------------------

initial joy1 = 8'h00;
initial joy2 = 8'h00;
initial joyCk = 1'b0;

reg[15:0] joyQ = 16'hFFFF;

always @(posedge clock) if(ce)
if(joyQ[15:14] == 2'b00) begin
	joyCk <= 1'b0;
	joyLd <= 1'b0;
	joyQ <= 16'hFFFF;
	joy1 <= { 2'b00, joyQ[ 5], joyQ[ 4], joyQ[0], joyQ[1], joyQ[ 2], joyQ[ 3] };
	joy2 <= { 2'b00, joyQ[13], joyQ[12], joyQ[8], joyQ[9], joyQ[10], joyQ[11] };
end
else begin
	joyCk <= ~joyCk;
	if(!joyLd) joyLd <= 1'b1;
	if(joyCk) joyQ <= { joyQ[14:0], ~joyD };
end

//-------------------------------------------------------------------------------------------------

assign joyS = 1'b1;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
