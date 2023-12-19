`default_nettype none
//-------------------------------------------------------------------------------------------------
//  Elan Enterprise ZXTRES++ board adapter
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
module zx3
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire[ 1:0] sync,
	output wire[23:0] rgb,

	input  wire       ear,
	output wire[ 1:0] dsg,
	output wire[ 2:0] i2s,

	input  wire       ps2kCk,
	input  wire       ps2kDQ,

	inout  wire       ps2mDQ,
	inout  wire       ps2mCk,

	output wire       joyCk,
	output wire       joyLd,
	output wire       joyS,
	input  wire       joyD,

	output wire       sdcCs,
	output wire       sdcCk,
	output wire       sdcMosi,
	input  wire       sdcMiso,

	output wire       dramCk,
	output wire       dramCe,
	output wire       dramCs,
	output wire       dramWe,
	output wire       dramRas,
	output wire       dramCas,
	output wire[ 1:0] dramDQM,
	inout  wire[15:0] dramDQ,
	output wire[ 1:0] dramBA,
	output wire[12:0] dramA,

	output wire       sramUb,
	output wire       sramLb,
	output wire       sramOe,
	output wire       sramWe,
	//inout  wire[15:8] sramDQ,
	//output wire[19:0] sramA,

	output wire[ 1:0] led
);
//-------------------------------------------------------------------------------------------------

wire clock56, clock32, clock64, power;
mmcm mmcm(clock50, clock56, clock32, clock64, power);

//-------------------------------------------------------------------------------------------------

wire strb;
wire make;
wire[7:0] code;
ps2k ps2k(clock32, { ps2kDQ, ps2kCk }, strb, make, code);

wire[2:0] mbtns;
wire[7:0] xaxis;
wire[7:0] yaxis;
ps2m ps2m(clock32, reset, ps2mDQ, ps2mCk, mbtns, xaxis, yaxis);

wire[7:0] joy1;
wire[7:0] joy2;
joystick joystick(clock32, joyCk, joyLd, joyS, joyD, joy1, joy2);

reg F9 = 1'b1;
reg vga = 1'b0;
always @(posedge clock32) if(strb)
	case(code)
		8'h01: F9 <= make;
		8'h7E: if(make) vga <= ~vga;
	endcase

//-------------------------------------------------------------------------------------------------

wire reset = power && ready && F9;
wire speed = 1'b0;

wire cecpu;
wire cep1x;
wire cep2x;
wire rfsh;

wire[15:0] memA1;
wire[ 7:0] memQ1;
wire[21:0] memA2;
wire[ 7:0] memD2;
wire[ 7:0] memQ2;
wire       memR2;
wire       memW2;

wire hblank;
wire vblank;
wire hsync;
wire vsync;
wire[2:0] r;
wire[2:0] g;
wire[1:0] b;

wire tape = ~ear;

wire[8:0] left;
wire[8:0] right;

wire      fddCe;
wire      fddIo;
wire      fddRd;
wire      fddWr;
wire[1:0] fddA;
wire[7:0] fddD10;
wire[7:0] fddD18;
wire[7:0] fddQ10 = 8'hFF; // fddImg ? fddQ : 8'hFF;
wire[7:0] fddQ18 = 8'hFF; // fddImg ? { fddDrq, fddDchg, 4'b1111, fddIrq, fddRdy } : 8'hFF;

ep ep
(
	.clock32(clock32),
	.clock56(clock56),
	.power  (power  ),
	.reset  (reset  ),
	.speed  (speed  ),
	.cecpu  (cecpu  ),
	.cep1x  (cep1x  ),
	.cep2x  (cep2x  ),
	.rfsh   (rfsh   ),
	.memA1  (memA1  ),
	.memQ1  (memQ1  ),
	.memA2  (memA2  ),
	.memD2  (memD2  ),
	.memQ2  (memQ2  ),
	.memR2  (memR2  ),
	.memW2  (memW2  ),
	.hblank (hblank ),
	.vblank (vblank ),
	.hsync  (hsync  ),
	.vsync  (vsync  ),
	.r      (r      ),
	.g      (g      ),
	.b      (b      ),
	.tape   (tape   ),
	.left   (left   ),
	.right  (right  ),
	.strb   (strb   ),
	.make   (make   ),
	.code   (code   ),
	.mbtns  (mbtns  ),
	.xaxis  (xaxis  ),
	.yaxis  (yaxis  ),
	.joy1   (joy1   ),
	.joy2   (joy2   ),
	.fddCe  (fddCe  ),
	.fddIo  (fddIo  ),
	.fddRd  (fddRd  ),
	.fddWr  (fddWr  ),
	.fddA   (fddA   ),
	.fddD10 (fddD10 ),
	.fddD18 (fddD18 ),
	.fddQ10 (fddQ10 ),
	.fddQ18 (fddQ18 ),
	.cs     (sdcCs  ),
	.ck     (sdcCk  ),
	.mosi   (sdcMosi),
	.miso   (sdcMiso)
);

//-------------------------------------------------------------------------------------------------

wire[1:0] oblank;
wire[7:0] orgb;

scandoubler #(.RGBW(8)) scandoubler
(
	.clock  (clock56),
	.enable (vga    ),
	.ice    (cep1x  ),
	.iblank ({ vblank, hblank }),
	.isync  ({  vsync,  hsync }),
	.irgb   ({ r, g, b }),
	.oce    (cep2x  ),
	.oblank (oblank ),
	.osync  (sync   ),
	.orgb   (orgb   )
);

assign rgb = oblank ? 1'd0 : { orgb[7:5],orgb[7:5],orgb[7:6], orgb[4:2],orgb[4:2],orgb[4:3], orgb[1:0],orgb[1:0],orgb[1:0],orgb[1:0] };

//-------------------------------------------------------------------------------------------------

dsg #(8) dsg1(clock32, reset,  left, dsg[1]);
dsg #(8) dsg0(clock32, reset, right, dsg[0]);
i2s i2so(clock32, i2s, { 1'b0,  left, 6'd0 }, { 1'b0, right, 6'd0 });

//-------------------------------------------------------------------------------------------------

wire[7:0] memP2 = memA2[21:14];
wire vmm = memP2 >= 8'hFC;
wire ram = (memP2 >= 8'hBC && memP2 < 8'hFC) || (memP2 == 8'h07 && memA2[13]);
wire rom = memP2 <  8'h08;

wire[7:0] romQ;
rom #(128, "../rom/exos_exdos_isdos_file_sdext.hex") rom(clock32, memA2[16:0], romQ);

wire[7:0] dprQ;
dprf #(64) dpr(clock56, memA1, memQ1, clock32, memA2[15:0], memD2, dprQ, memW2 && vmm);

wire ready;
wire sdrRd = memR2 && ram;
wire sdrWr = memW2 && ram;

wire[24:0] sdrA = { 3'd0, memA2 };
wire[15:0] sdrD = { memD2, memD2 };
wire[15:0] sdrQ;

sdram sdram
(
	.clock  (clock64),
	.reset  (power  ),
	.ready  (ready  ),
	.rfsh   (rfsh   ),
	.rd     (sdrRd  ),
	.wr     (sdrWr  ),
	.a      (sdrA   ),
	.d      (sdrD   ),
	.q      (sdrQ   ),
	.dramCs (dramCs ),
	.dramWe (dramWe ),
	.dramRas(dramRas),
	.dramCas(dramCas),
	.dramDQM(dramDQM),
	.dramDQ (dramDQ ),
	.dramBA (dramBA ),
	.dramA  (dramA  )
);

ODDR oddr
(
	.C(clock64),
	.CE(1'b1  ),
	.D1(1'b0  ),
	.D2(1'b1  ),
	.Q(dramCk ),
	.R(1'b0   ),
	.S(1'b0   )
);

assign dramCe = 1'b1;

//-------------------------------------------------------------------------------------------------

assign sramUb = 1'b1;
assign sramLb = 1'b1;
assign sramOe = 1'b1;
assign sramWe = 1'b1;

assign memQ2 = vmm ? dprQ : ram ? sdrQ[7:0] : rom ? romQ : 8'hFF;

assign led = { 1'b0, ~sdcCs };

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
