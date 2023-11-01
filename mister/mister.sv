`default_nettype none
//-------------------------------------------------------------------------------------------------
//  Elan Enterprise MiSTer board adapter
//-------------------------------------------------------------------------------------------------
//  This file is part of the Elan Enterprise FPGA implementation project.
//  Copyright (C) 2023 Kyp069 <kyp069@gmail.com>
//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_SL = 0;
assign VGA_F1 = 0;
assign VGA_SCALER  = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;

assign AUDIO_S = 1'b0;
assign AUDIO_L = {  left, 7'd0 };
assign AUDIO_R = { right, 7'd0 };
assign AUDIO_MIX = 0;

assign LED_DISK  = { 1'b0, ~sdvCs };
assign LED_POWER = { 1'b0, 1'b0 };
assign LED_USER  = ~reset;

assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[122:121];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
	"Enterprise;;",
	"-;",
	"O[122:121],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"-;",
	"O[4:2],Available RAM,1 MB,2 MB,3 MB,64 KB,128 KB,256 KB,512 KB;",
	"O[6:5],CPU Speed,4 MHz,8 MHz,16 MHz;",
	"-;",
	"F0,ROM,Load ROM;",
	"-;",
	"S0,VHD,Mount SD;",
	"S1,IMGDSK,Mount A:;",
	"v,0;", // [optional] config version 0-99. 
	        // If CONF_STR options are changed in incompatible way, then change version number too,
			// so all options will get default values on first start.
	"V,v",`BUILD_DATE 
};

wire forced_scandoubler;
wire[  1:0] buttons;
wire[127:0] status;

wire[ 10:0] ps2_key;
wire[ 24:0] ps2_mouse;

wire[ 31:0] joystick_0;
wire[ 31:0] joystick_1;

wire        romIo;
wire[ 15:0] romIx;
wire[ 26:0] romA;
wire[  7:0] romD;
wire        romW;

wire[  1:0] sd_rd;
wire[  1:0] sd_wr;
wire[  1:0] sd_ack;
wire[ 31:0] sd_lba[2];
wire        sd_buff_wr;
wire[ 13:0] sd_buff_addr;
wire[  7:0] sd_buff_din[2];
wire[  7:0] sd_buff_dout;
wire[  1:0] img_mounted;
wire[ 63:0] img_size;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clock32),
	.HPS_BUS(HPS_BUS),

	.EXT_BUS(),
	.gamma_bus(),
	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({status[5]}),
	
	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),

	.ioctl_download(romIo),
	.ioctl_index(romIx),
	.ioctl_wait(!power && !ready && iniIo),
	.ioctl_addr(romA),
	.ioctl_dout(romD),
	.ioctl_wr(romW),

	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_lba(sd_lba),
	.sd_buff_wr(sd_buff_wr),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_din(sd_buff_din),
	.sd_buff_dout(sd_buff_dout),
	.img_mounted(img_mounted),
	.img_size(img_size)
);

sd_card sd_card
(
	.clk_sys     (clock32),
	.clk_spi     (clock32),
	.reset       (!reset),
	.sdhc        (1'b1),
	.sd_rd       (sd_rd[0]),
	.sd_wr       (sd_wr[0]),
	.sd_ack      (sd_ack[0]),
	.sd_lba      (sd_lba[0]),
	.sd_buff_wr  (sd_buff_wr),
	.sd_buff_addr(sd_buff_addr[8:0]),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din (sd_buff_din[0]),
	.img_mounted (img_mounted[0]),
	.img_size    (img_size),
	.ss          (sdvCs),
	.sck         (sdvCk),
	.mosi        (sdvMosi),
	.miso        (sdvMiso)
);

reg fddImg = 0;
always @(posedge clock32) if(img_mounted[1]) fddImg <= |img_size;

reg[2:0] fddCode = 0;
always @(posedge clock32) if(img_mounted[1]) fddCode <= img_size[18] ? 3'd4 : 3'd2; // 4: 10x512, 2: 9x512

wire fddEna = fddD18[3:0] == 4'b0001 && fddImg && !fddPrep;
wire fddDrq;
wire fddIrq;
wire fddRdy;
wire fddDchg;
wire fddPrep;
wire fddDgRs = ~fddD18[6];
wire fddSide = fddD18[4];
wire[7:0] fddQ;

wd17xx fdd0
(
	.clk_sys            (clock32 ),
	.ce                 (fddCe   ),
	.reset              (~reset  ),
	.io_en              (fddIo   ),
	.rd                 (fddRd   ),
	.wr                 (fddWr   ),
	.addr               (fddA    ),
	.din                (fddD10  ),
	.dout               (fddQ    ),
	.drq                (fddDrq  ),
	.intrq              (fddIrq  ),
	.ready_n            (fddRdy  ),
	.wp                 (1'b0    ),
	.ready              (fddEna  ),
	.side               (fddSide ),
	.disk_change_n      (fddDchg ),
	.disk_change_reset_n(fddDgRs ),
	.layout             (1'b0    ),
	.size_code          (fddCode ),
	.busy               (        ),
	.prepare            (fddPrep ),
	.sd_rd              (sd_rd[1]),
	.sd_wr              (sd_wr[1]),
	.sd_ack             (sd_ack[1]),
	.sd_lba             (sd_lba[1]),
	.sd_buff_addr       (sd_buff_addr),
	.sd_buff_din        (sd_buff_din[1]),
	.sd_buff_dout       (sd_buff_dout),
	.sd_buff_wr         (sd_buff_wr),
	.img_mounted        (img_mounted[1]),
	.img_size           (img_size[20:0])
);

assign CLK_VIDEO = clock56;
assign CE_PIXEL = cepix;

assign VGA_DE = ~(hblank|vblank);
assign VGA_HS = hsync;
assign VGA_VS = vsync;
assign VGA_R  = { r, r, r[2:1] };
assign VGA_G  = { g, g, g[2:1] };
assign VGA_B  = { b, b, b, b   };

//-------------------------------------------------------------------------------------------------

wire clock32, sdramck, locked32;
pll32 pll32(CLK_50M, RESET, clock32, sdramck, SDRAM_CLK, locked32);

wire clock56, locked56;
pll56 pll56(CLK_50M, RESET, clock56, locked56);

wire power = locked32 & locked56;

//-------------------------------------------------------------------------------------------------

reg ps2k10d;
always @(posedge clock32) ps2k10d <= ps2_key[10];

reg strb;
always @(posedge clock32) strb <= ps2_key[10] != ps2k10d;

wire make = ~ps2_key[9];
wire[7:0] code = ps2_key[7:0];

reg ps2m24d;
always @(posedge clock32) ps2m24d <= ps2_mouse[24];

reg ps2m24p;
always @(posedge clock32) ps2m24p <= ps2_mouse[24] != ps2m24d;

reg[8:0] xdata;
always @(posedge clock32) if(ps2m24p) xdata <= xdata + { ps2_mouse[4], ps2_mouse[15:8] };

reg[8:0] ydata;
always @(posedge clock32) if(ps2m24p) ydata <= ydata + { ps2_mouse[5], ps2_mouse[23:16] };

reg[2:0] mbtns = 3'b111;
always @(posedge clock32) if(ps2m24p) mbtns <= ~{ ps2_mouse[2], ps2_mouse[0], ps2_mouse[1] };

wire[7:0] xaxis = xdata[8:1];
wire[7:0] yaxis = ydata[8:1];

wire[7:0] joy1 = joystick_0[7:0];
wire[7:0] joy2 = joystick_1[7:0];

reg F9 = 1'b1;
always @(posedge clock32) if(strb) case(code) 8'h01: F9 <= make; endcase

//-------------------------------------------------------------------------------------------------

wire reset = power && ready && F9 && !romIo && !RESET && !status[0] && !buttons[1];
wire[1:0] speed = status[6:5];

wire cecpu;
wire cepix;
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

wire tape = 1'b0;

wire[8:0] left;
wire[8:0] right;

wire      fddCe;
wire      fddIo;
wire      fddRd;
wire      fddWr;
wire[1:0] fddA;
wire[7:0] fddD10;
wire[7:0] fddD18;
wire[7:0] fddQ10 = fddImg ? fddQ : 8'hFF;
wire[7:0] fddQ18 = fddImg ? { fddDrq, fddDchg, 4'b1111, fddIrq, fddRdy } : 8'hFF;

wire sdvCs;
wire sdvCk;
wire sdvMosi;
wire sdvMiso;

ep ep
(
	.clock32(clock32),
	.clock56(clock56),
	.power  (power  ),
	.reset  (reset  ),
	.speed  (speed  ),
	.cecpu  (cecpu  ),
	.cep1x  (cepix  ),
	.cep2x  (       ),
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
	.cs     (sdvCs  ),
	.ck     (sdvCk  ),
	.mosi   (sdvMosi),
	.miso   (sdvMiso)
);

//-------------------------------------------------------------------------------------------------

wire[7:0] maxram
	= status[4:2] == 3'd1 ? 8'h80  //  2MB
	: status[4:2] == 3'd2 ? 8'h40  //  3MB
	: status[4:2] == 3'd3 ? 8'hFC  //  64K
	: status[4:2] == 3'd4 ? 8'hF8  // 128K
	: status[4:2] == 3'd5 ? 8'hF0  // 256K
	: status[4:2] == 3'd6 ? 8'hE0  // 512K
	:                       8'hC0; //  1MB
//	= status[4:2] == 3'd0 ? 8'hC0  //  1MB

reg[7:0] romP = 8'h07;
always @(posedge clock32) if(romIo) romP <= { 2'd0, romA[19:14] };

wire[7:0] memP2 = memA2[21:14];
wire vmm = memP2 >= 8'hFC;
wire ram = memP2 >= maxram;
wire rom = memP2 <= romP;

reg[18:0] ic;
always @(posedge clock32, negedge ready) if(!ready) ic <= 1'd0; else if(cecpu) if(iniIo) ic <= ic+1'd1;

wire       iniIo = !ic[18];
wire[16:0] iniA  = ic[17:1];
wire[ 7:0] iniD;
wire       iniW  = ic[0];

rom #(128) rom8(clock32, iniA, iniD);
dprs #(64) dpr(clock56, memA1, memQ1, clock32, memA2[15:0], memD2, memW2 && vmm);

wire ready;
wire sdrRf = iniIo ? 1'b1 : rfsh;
wire sdrRd = iniIo ? 1'b0 : memR2 && (ram || rom);
wire sdrWr = iniIo ? iniW : romIo ? romW : memW2 && (ram || (memP2 == 8'h07 && memA2[13]));

wire[24:0] sdrA = { 3'd0, iniIo ? { 5'd0, iniA } : romIo ? romA[21:0] : memA2 };
wire[15:0] sdrD = { 8'd0, iniIo ? iniD : romIo ? romD : memD2 };
wire[15:0] sdrQ;

sdram sdram
(
	.clock  (sdramck),
	.reset  (power  ),
	.ready  (ready  ),
	.rfsh   (sdrRf  ),
	.rd     (sdrRd  ),
	.wr     (sdrWr  ),
	.a      (sdrA   ),
	.d      (sdrD   ),
	.q      (sdrQ   ),
	.dramCs (SDRAM_nCS ),
	.dramRas(SDRAM_nRAS),
	.dramCas(SDRAM_nCAS),
	.dramWe (SDRAM_nWE ),
	.dramDQM({ SDRAM_DQMH, SDRAM_DQML }),
	.dramDQ (SDRAM_DQ  ),
	.dramBA (SDRAM_BA  ),
	.dramA  (SDRAM_A   )
);

assign memQ2 = rom || ram ? sdrQ[7:0] : 8'hFF;

assign SDRAM_CKE = 1'b1;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
