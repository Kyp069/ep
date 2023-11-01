//-------------------------------------------------------------------------------------------------
//  Elan Enterprise main
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
module ep
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock32,
	input  wire       clock56,

	input  wire       power,
	input  wire       reset,
	input  wire[ 1:0] speed,

	output wire       cecpu,
	output wire       cep1x,
	output wire       cep2x,
	output wire       rfsh,

	output wire[15:0] memA1,
	input  wire[ 7:0] memQ1,

	output wire[21:0] memA2,
	output wire[ 7:0] memD2,
	input  wire[ 7:0] memQ2,
	output wire       memR2,
	output wire       memW2,

	output wire       hblank,
	output wire       vblank,
	output wire       hsync,
	output wire       vsync,
	output wire[ 2:0] r,
	output wire[ 2:0] g,
	output wire[ 1:0] b,

	input  wire       tape,

	output wire[ 8:0] left,
	output wire[ 8:0] right,

	input  wire       strb,
	input  wire       make,
	input  wire[ 7:0] code,

	input  wire[ 2:0] mbtns,
	input  wire[ 7:0] xaxis,
	input  wire[ 7:0] yaxis,

	input  wire[ 7:0] joy1,
	input  wire[ 7:0] joy2,

	output wire       fddCe,
	output wire       fddIo,
	output wire       fddRd,
	output wire       fddWr,
	output wire[ 1:0] fddA,
	output wire[ 7:0] fddD10,
	output reg [ 7:0] fddD18,
	input  wire[ 7:0] fddQ10,
	input  wire[ 7:0] fddQ18,

	output wire       cs,
	output wire       ck,
	output wire       mosi,
	input  wire       miso
);
//-------------------------------------------------------------------------------------------------

wire ioB4 = !iorq && a[7:0] == 8'hB4;
wire ioB5 = !iorq && a[7:0] == 8'hB5;
wire ioB6 = !iorq && a[7:0] == 8'hB6;
wire io10 = !iorq && a[7:4] == 4'h1 && !a[3];
wire io18 = !iorq && a[7:4] == 4'h1 &&  a[3];
wire ioSD = !mreq && memA2[21:14] == 8'h07 && a[13:0] >= 14'h3C00;

//-------------------------------------------------------------------------------------------------

reg ne28M;
reg ne14M;

reg[2:0] ce56 = 1'd1;
always @(negedge clock56) if(power) begin
	ce56 <= ce56+1'd1;
	ne28M <= ~ce56[0];
	ne14M <= ~ce56[0] & ~ce56[1];
end

reg ne16M, pe16M;
reg ne8M0, pe8M0;
reg ne4M0, pe4M0;
reg pe1M0;
reg ne2K5;

reg[6:0] ce32 = 1'd1;
always @(negedge clock32) if(power) begin
	ce32 <= ce32+1'd1;
	ne16M <= ~ce32[0];
	pe16M <=  ce32[0];
	ne8M0 <= ~ce32[0] & ~ce32[1];
	pe8M0 <= ~ce32[0] &  ce32[1];
	ne4M0 <= ~ce32[0] & ~ce32[1] & ~ce32[2];
	pe4M0 <= ~ce32[0] & ~ce32[1] &  ce32[2];
	pe1M0 <= ~ce32[0] & ~ce32[1] & ~ce32[2] & ~ce32[3] &  ce32[4];
	ne2K5 <= ~ce32[0] & ~ce32[1] & ~ce32[2] & ~ce32[3] & ~ce32[4] & ~ce32[5] & ~ce32[6];
end

wire necpu = speed[1] ? ne16M : speed[0] ? ne8M0 : ne4M0;
wire pecpu = speed[1] ? pe16M : speed[0] ? pe8M0 : pe4M0;

assign cecpu = pecpu;
assign cep1x = ne14M;
assign cep2x = ne28M;

//-------------------------------------------------------------------------------------------------

wire iorq, mreq, irq, rd, wr;
wire[15:0] a;
wire[ 7:0] d;
wire[ 7:0] q;

cpu cpu
(
	.clock  (clock32),
	.ne     (necpu  ),
	.pe     (pecpu  ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.mreq   (mreq   ),
	.rfsh   (rfsh   ),
	.irq    (irq    ),
	.rd     (rd     ),
	.wr     (wr     ),
	.a      (a      ),
	.d      (d      ),
	.q      (q      )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] memQ;

memory memory
(
	.clock  (clock32),
	.ce     (cecpu  ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.mreq   (mreq   ),
	.rd     (rd     ),
	.wr     (wr     ),
	.a      (a      ),
	.d      (q      ),
	.q      (memQ   ),
	.memA2  (memA2  ),
	.memD2  (memD2  ),
	.memQ2  (memQ2  ),
	.memR2  (memR2  ),
	.memW2  (memW2  )
);

//-------------------------------------------------------------------------------------------------

wire irqv;

video video
(
	.clock32(clock32),
	.clock56(clock56),
	.cecpu  (cecpu  ),
	.cepix  (ne14M  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.a      (a[7:0] ),
	.d      (q      ),
	.irq    (irqv   ),
	.va     (memA1  ),
	.vd     (memQ1  ),
	.hblank (hblank ),
	.vblank (vblank ),
	.hsync  (hsync  ),
	.vsync  (vsync  ),
	.r      (r      ),
	.g      (g      ),
	.b      (b      )
);

//-------------------------------------------------------------------------------------------------

wire irq0, irq1;

wire[7:0] intA = a[7:0];
wire[7:0] intD = q;
wire[7:0] intQ;

interrupts interrupts
(
	.clock  (clock32),
	.cecpu  (cecpu  ),
	.ceirq  (ne2K5  ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.a      (intA   ),
	.d      (intD   ),
	.q      (intQ   ),
	.irq0   (irq0   ),
	.irq1   (irq1   ),
	.irqv   (irqv   ),
	.int0   (irq    )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] audA = a[7:0];

audio audio
(
	.clock  (clock32),
	.cecpu  (cecpu  ),
	.ceaud  (ne2K5  ),
	.power  (power  ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.a      (audA   ),
	.d      (q      ),
	.irq0   (irq0   ),
	.irq1   (irq1   ),
	.l      (left   ),
	.r      (right  )
);

//-------------------------------------------------------------------------------------------------

reg [3:0] kbdA;
wire[7:0] kbdQ;
always @(posedge clock32) if(cecpu) if(ioB5 && !wr) kbdA <= q[3:0];

keyboard keyboard
(
	.clock  (clock32),
	.strb   (strb   ),
	.make   (make   ),
	.code   (code   ),
	.a      (kbdA   ),
	.q      (kbdQ   )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] mouseA = a[7:0];
wire[1:1] mouseD = q[1];
wire[3:0] mouseQ;

mouse mouse
(
	.clock  (clock32),
	.cecpu  (cecpu  ),
	.ce1M0  (pe1M0  ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.a      (mouseA ),
	.d      (mouseD ),
	.q      (mouseQ ),
	.xaxis  (xaxis  ),
	.yaxis  (yaxis  )
);

//-------------------------------------------------------------------------------------------------

wire[2:0] joyQ
	= kbdA == 4'h0 ? { ~mbtns[0] | joy1[6],  ~mbtns[1] | joy1[5], joy1[4] }
	: kbdA == 4'h1 ? {                1'b0,           ~mouseQ[0], joy1[3] }
	: kbdA == 4'h2 ? {                1'b0,           ~mouseQ[1], joy1[2] }
	: kbdA == 4'h3 ? {                1'b0,           ~mouseQ[2], joy1[1] }
	: kbdA == 4'h4 ? {                1'b0,           ~mouseQ[3], joy1[0] }
	: kbdA == 4'h5 ? {             joy2[6],              joy2[5], joy2[4] }
	: kbdA == 4'h6 ? {                1'b0,                 1'b0, joy2[3] }
	: kbdA == 4'h7 ? {                1'b0,                 1'b0, joy2[2] }
	: kbdA == 4'h8 ? {                1'b0,                 1'b0, joy2[1] }
	: kbdA == 4'h9 ? {                1'b0,                 1'b0, joy2[0] }
	: 1'b1;

//-------------------------------------------------------------------------------------------------

always @(posedge clock32) if(cecpu) if(io18 && !wr) fddD18 <= q;

assign fddCe   = pe8M0;
assign fddIo   = io10;
assign fddRd   = ~rd;
assign fddWr   = ~wr;
assign fddA    = a[1:0];
assign fddD10  = q;

//-------------------------------------------------------------------------------------------------

wire[7:0] usdA = a[7:0];
wire[7:0] usdD = q;
wire[7:0] usdQ;

usd usd
(
	.clock  (clock32),
	.cecpu  (cecpu  ),
	.cespi  (1'b1   ),
	.reset  (reset  ),
	.page   (       ),
	.ioSD   (ioSD   ),
	.rd     (rd     ),
	.wr     (wr     ),
	.a      (usdA   ),
	.d      (usdD   ),
	.q      (usdQ   ),
	.cs     (cs     ),
	.ck     (ck     ),
	.mosi   (mosi   ),
	.miso   (miso   )
);

//-------------------------------------------------------------------------------------------------

assign d
	= ioB4 ? intQ
	: ioB5 ? kbdQ
	: ioB6 ? { tape, tape, 3'b111, ~joyQ }
	: io10 ? fddQ10
	: io18 ? fddQ18
	: ioSD ? usdQ
	: memQ;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
