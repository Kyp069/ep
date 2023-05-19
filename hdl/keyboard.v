//-------------------------------------------------------------------------------------------------
//  Elan Enterprise keyboard matrix
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
module keyboard
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      strb,
	input  wire      make,
	input  wire[7:0] code,
	input  wire[3:0] a,
	output wire[7:0] q
);
//-------------------------------------------------------------------------------------------------

reg[7:0] key[9:0];
initial begin
	key[0] = 8'hFF; key[1] = 8'hFF; key[2] = 8'hFF; key[3] = 8'hFF; key[4] = 8'hFF;
	key[5] = 8'hFF; key[6] = 8'hFF; key[7] = 8'hFF; key[8] = 8'hFF; key[9] = 8'hFF;
end

always @(posedge clock) if(strb) case(code)

	8'h12: key[0][7] <= make; // left shift
	8'h1A: key[0][6] <= make; // Z
	8'h22: key[0][5] <= make; // X
	8'h2A: key[0][4] <= make; // V
	8'h21: key[0][3] <= make; // C
	8'h32: key[0][2] <= make; // B
	8'h61: key[0][1] <= make; // \ (<>)
	8'h0E: key[0][1] <= make; // \ (ºª)
	8'h31: key[0][0] <= make; // N

	8'h14: key[1][7] <= make; // ctrl (l-ctrl)
	8'h1C: key[1][6] <= make; // A
	8'h1B: key[1][5] <= make; // S
	8'h2B: key[1][4] <= make; // F
	8'h23: key[1][3] <= make; // D
	8'h34: key[1][2] <= make; // G
	8'h58: key[1][1] <= make; // lock (caps-lock)
	8'h33: key[1][0] <= make; // H

	8'h0D: key[2][7] <= make; // tab
	8'h1D: key[2][6] <= make; // W
	8'h24: key[2][5] <= make; // E
	8'h2C: key[2][4] <= make; // T
	8'h2D: key[2][3] <= make; // R
	8'h35: key[2][2] <= make; // Y
	8'h15: key[2][1] <= make; // Q
	8'h3C: key[2][0] <= make; // U

	8'h76: key[3][7] <= make; // esc
	8'h1E: key[3][6] <= make; // 2
	8'h26: key[3][5] <= make; // 3
	8'h2E: key[3][4] <= make; // 5
	8'h25: key[3][3] <= make; // 4
	8'h36: key[3][2] <= make; // 6
	8'h16: key[3][1] <= make; // 1
	8'h3D: key[3][0] <= make; // 7

	8'h05: key[4][7] <= make; // F1
	8'h06: key[4][6] <= make; // F2
	8'h83: key[4][5] <= make; // F7
	8'h03: key[4][4] <= make; // F5
	8'h0B: key[4][3] <= make; // F6
	8'h04: key[4][2] <= make; // F3
	8'h0A: key[4][1] <= make; // F8
	8'h0C: key[4][0] <= make; // F4

	8'h66: key[5][6] <= make; // erase (backspace)
	8'h55: key[5][5] <= make; // ~ (¡¿)
	8'h45: key[5][4] <= make; // 0
	8'h4E: key[5][3] <= make; // - ('?)
	8'h46: key[5][2] <= make; // 9
	8'h3E: key[5][0] <= make; // 8

	8'h5D: key[6][6] <= make; // ] (çÇ)
	8'h52: key[6][5] <= make; // : (´¨)
	8'h4B: key[6][4] <= make; // L
	8'h4C: key[6][3] <= make; // ; (ñÑ)
	8'h42: key[6][2] <= make; // K
	8'h3B: key[6][0] <= make; // J

	8'h11: key[7][7] <= make; // alt
	8'h5A: key[7][6] <= make; // enter
	8'h6B: key[7][5] <= make; // left
	8'h6C: key[7][4] <= make; // hold (inicio)
	8'h75: key[7][3] <= make; // up
	8'h74: key[7][2] <= make; // right
	8'h72: key[7][1] <= make; // down
	8'h69: key[7][0] <= make; // stop (fin)

	8'h70: key[8][7] <= make; // ins
	8'h29: key[8][6] <= make; // space
	8'h59: key[8][5] <= make; // right shift
	8'h49: key[8][4] <= make; // . (.:)
	8'h4A: key[8][3] <= make; // / (-_)
	8'h41: key[8][2] <= make; // , (,;)
	8'h71: key[8][1] <= make; // delete
	8'h3A: key[8][0] <= make; // M

	8'h5B: key[9][5] <= make; // [ (+*)
	8'h4D: key[9][4] <= make; // P
	8'h54: key[9][3] <= make; // @ (`^)
	8'h44: key[9][2] <= make; // O
	8'h43: key[9][0] <= make; // I
endcase

//-------------------------------------------------------------------------------------------------

assign q = key[a];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
