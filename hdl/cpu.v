//-------------------------------------------------------------------------------------------------
//  T80pa adapter
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
module cpu
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       pe,
	input  wire       ne,
	input  wire       reset,
	output wire       iorq,
	output wire       mreq,
	output wire       rfsh,
	input  wire       irq,
	output wire       rd,
	output wire       wr,
	output wire[15:0] a,
	input  wire[ 7:0] d,
	output wire[ 7:0] q
);

T80pa Cpu
(
	.CLK    (clock  ),
	.CEN_p  (pe     ),
	.CEN_n  (ne     ),
	.RESET_n(reset  ),
	.BUSRQ_n(1'b1   ),
	.WAIT_n (1'b1   ),
	.BUSAK_n(       ),
	.HALT_n (       ),
	.IORQ_n (iorq   ),
	.MREQ_n (mreq   ),
	.RFSH_n (rfsh   ),
	.NMI_n  (1'b1   ),
	.INT_n  (irq    ),
	.M1_n   (       ),
	.RD_n   (rd     ),
	.WR_n   (wr     ),
	.A      (a      ),
	.DI     (d      ),
	.DO     (q      ),
	.REG    (       ),
	.OUT0   (1'b0   ),
    .DIRSet (1'b0   ),
    .DIR    (212'd0 )
);

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
