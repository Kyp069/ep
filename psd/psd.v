`default_nettype none
//-------------------------------------------------------------------------------------------------
//  Elan Enterprise QMTech 150K LEs with Poseidon board adapter
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
module psd
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire[ 1:0] sync,
	output wire[VGA_BITS-1:0] vgaR,
	output wire[VGA_BITS-1:0] vgaG,
	output wire[VGA_BITS-1:0] vgaB,

	input  wire       ear,
	output wire[ 2:0] i2s,

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

	input  wire       spiCk,   // SPI_SCK
	input  wire       spiSs2,  // SPI_SS2
	input  wire       spiSs3,  // SPI_SS3
	input  wire       spiSsIo, // CONF_DATA0
	input  wire       spiMosi, // SPI_DI
	output wire       spiMiso, // SPI_DO

`ifdef USE_HDMI
	output        HDMI_RST,
	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_PCLK,
	output        HDMI_DE,
	input         HDMI_INT,
	inout         HDMI_SDA,
	inout         HDMI_SCL,
`endif
`ifdef DUAL_SDRAM
	output [12:0] SDRAM2_A,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_DQML,
	output        SDRAM2_DQMH,
	output        SDRAM2_nWE,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nCS,
	output  [1:0] SDRAM2_BA,
	output        SDRAM2_CLK,
	output        SDRAM2_CKE,
`endif
`ifdef I2S_AUDIO_HDMI
	output        HDMI_MCLK,
	output reg    HDMI_BCK,
	output reg    HDMI_LRCK,
	output reg    HDMI_SDATA,
`endif
`ifdef SPDIF_AUDIO
	output        SPDIF,
`endif
	output wire       led
);

`ifdef VGA_8BIT
localparam VGA_BITS = 8;
`else
localparam VGA_BITS = 6;
`endif

`ifdef USE_HDMI
localparam HDMI = 1'b1;
assign HDMI_RST = 1'b1;
`else
localparam bit HDMI = 0;
`endif

`ifdef BIG_OSD
localparam BIG_OSD = 1'b1;
`define SEP "-;",
`else
localparam BIG_OSD = 1'b0;
`define SEP
`endif

`ifdef DUAL_SDRAM
assign SDRAM2_A = 13'hZZZZ;
assign SDRAM2_BA = 0;
assign SDRAM2_DQML = 1;
assign SDRAM2_DQMH = 1;
assign SDRAM2_CKE = 0;
assign SDRAM2_CLK = 0;
assign SDRAM2_nCS = 1;
assign SDRAM2_DQ = 16'hZZZZ;
assign SDRAM2_nCAS = 1;
assign SDRAM2_nRAS = 1;
assign SDRAM2_nWE = 1;
`endif

//-------------------------------------------------------------------------------------------------

localparam confStr =
{
	"Enterprise;;",
	"O24,Available RAM,1 MB,2 MB,3 MB,64 KB,128 KB,256 KB,512 KB;",
	"O5,CPU Speed,4 MHz,8 MHz;",
	"F,ROM,Load ROM;",
	"S0,IMGDSK,Mount A:;",
	"S1,VHD,Mount SD;",
	"V,V1.0;"
};

wire[31:0] joystick_0;
wire[31:0] joystick_1;

wire[ 1:0] sdRd;
wire[ 1:0] sdWr;
wire       sdAck;
wire[31:0] sdLba = sdBusy ? sdLba1 : sdLba0;
wire       sdBusy;
wire       sdConf;
wire       sdSdhc;
wire       sdAckCf;
wire[ 8:0] sdBuffA;
wire[ 7:0] sdBuffD = sdBusy ? sdBuffD1 : sdBuffD0;
wire[ 7:0] sdBuffQ;
wire       sdBuffW;
wire[ 1:0] imgMntd;
wire[63:0] imgSize;
wire[ 1:0] ps2ko;
wire[63:0] status;
wire[ 1:0] buttons;
wire       vgab;

wire[8:0] mouse_x;
wire[8:0] mouse_y;
wire[7:0] mouse_flags;  // YOvfl, XOvfl, dy8, dx8, 1, mbtn, rbtn, lbtn
wire      mouse_strobe; // mouse data is valid on mouse_strobe

`ifdef USE_HDMI
wire        i2c_start;
wire        i2c_read;
wire  [6:0] i2c_addr;
wire  [7:0] i2c_subaddr;
wire  [7:0] i2c_dout;
wire  [7:0] i2c_din;
wire        i2c_ack;
wire        i2c_end;
`endif

user_io #(.STRLEN(154), .SD_IMAGES(2), .FEATURES(32'h0 | (BIG_OSD << 13) | (HDMI << 14))) user_io
(
	.conf_str        (confStr),
	.conf_addr       (       ),
	.conf_chr        (8'd0   ),
	.clk_sys         (clock32),
	.clk_sd          (clock32),
	.SPI_CLK         (spiCk  ),
	.SPI_SS_IO       (spiSsIo),
	.SPI_MOSI        (spiMosi),
	.SPI_MISO        (spiMiso),
	.ps2_kbd_clk     (ps2ko[0]),
	.ps2_kbd_data    (ps2ko[1]),
	.ps2_kbd_clk_i   (1'b0),
	.ps2_kbd_data_i  (1'b0),
	.ps2_mouse_clk   (),
	.ps2_mouse_data  (),
	.ps2_mouse_clk_i (1'b0),
	.ps2_mouse_data_i(1'b0),
	.sd_rd           (sdRd   ),
	.sd_wr           (sdWr   ),
	.sd_ack          (sdAck  ),
	.sd_ack_conf     (sdAckCf),
	.sd_ack_x        (),
	.sd_lba          (sdLba  ),
    .sd_conf         (sdConf ),
	.sd_sdhc         (sdSdhc ),
	.sd_buff_addr    (sdBuffA),
	.sd_din          (sdBuffD),
	.sd_din_strobe   (),
	.sd_dout         (sdBuffQ),
	.sd_dout_strobe  (sdBuffW),
	.img_mounted     (imgMntd),
	.img_size        (imgSize),
`ifdef USE_HDMI
	.i2c_start       (i2c_start  ),
	.i2c_read        (i2c_read   ),
	.i2c_addr        (i2c_addr   ),
	.i2c_subaddr     (i2c_subaddr),
	.i2c_dout        (i2c_dout   ),
	.i2c_din         (i2c_din    ),
	.i2c_ack         (i2c_ack    ),
	.i2c_end         (i2c_end    ),
`endif
	.rtc             (),
	.ypbpr           (),
	.status          (status),
	.buttons         (buttons),
	.switches        (),
	.no_csync        (),
	.core_mod        (),
	.key_pressed     (),
	.key_extended    (),
	.key_code        (),
	.key_strobe      (),
	.kbd_out_data    (8'd0),
	.kbd_out_strobe  (1'b0),
	.mouse_x         (mouse_x),
	.mouse_y         (mouse_y),
	.mouse_flags     (mouse_flags),
	.mouse_strobe    (mouse_strobe),
	.mouse_z         (),
	.mouse_idx       (),
	.joystick_0      (joystick_0),
	.joystick_1      (joystick_1),
	.joystick_2      (),
	.joystick_3      (),
	.joystick_4      (),
	.serial_data     (8'd0),
	.serial_strobe   (1'd0),
	.joystick_analog_0(),
	.joystick_analog_1(),
	.scandoubler_disable(vgab)
);

wire       romIo;
wire[24:0] romA;
wire[ 7:0] romD;
wire       romW;

data_io	data_io
(
	.clk_sys       (clock32),
	.SPI_SCK       (spiCk  ),
	.SPI_SS2       (spiSs2 ),
	.SPI_SS4       (1'b1   ),
	.SPI_DI        (spiMosi),
	.SPI_DO        (spiMiso),
	.clkref_n      (1'b0   ),
	.ioctl_download(romIo  ),
	.ioctl_addr    (romA   ),
	.ioctl_din     (8'd0   ),
	.ioctl_dout    (romD   ),
	.ioctl_wr      (romW   ),
	.ioctl_upload  (),
	.ioctl_index   (),
	.ioctl_fileext (),
	.ioctl_filesize(),
	.QCSn          (1'b1),
	.QSCK          (1'b1),
	.QDAT          (4'hF),
	.hdd_clk       (1'b0),
	.hdd_cmd_req   (1'b0),
	.hdd_cdda_req  (1'b0),
	.hdd_dat_req   (1'b0),
	.hdd_cdda_wr   (),
	.hdd_status_wr (),
	.hdd_addr      (),
	.hdd_wr        (),
	.hdd_data_out  (),
	.hdd_data_in   (16'd0),
	.hdd_data_rd   (),
	.hdd_data_wr   (),
	.hdd0_ena      (),
	.hdd1_ena      ()
);

reg fddImg = 0;
always @(posedge clock32) if(imgMntd[0]) fddImg <= |imgSize;

reg[2:0] fddCode = 0;
always @(posedge clock32) if(imgMntd[0]) fddCode <= imgSize[18] ? 3'd4 : 3'd2; // 4: 10x512, 2: 9x512

wire fddEna = fddD18[3:0] == 4'b0001 && fddImg && !fddPrep;
wire fddPrep;

wire[31:0] sdLba0;
wire[ 7:0] sdBuffD0;

wire fddDrq;
wire fddIrq;
wire fddRdy;
wire fddDchg;
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
	.sd_rd              (sdRd[0] ),
	.sd_wr              (sdWr[0] ),
	.sd_ack             (sdAck   ),
	.sd_lba             (sdLba0  ),
	.sd_buff_addr       (sdBuffA ),
	.sd_buff_din        (sdBuffD0),
	.sd_buff_dout       (sdBuffQ ),
	.sd_buff_wr         (sdBuffW ),
	.img_mounted        (imgMntd[0]),
	.img_size           (imgSize[20:0])
);

wire[31:0] sdLba1;
wire[ 7:0] sdBuffD1;

sd_card sd_card
(
	.clk_sys     (clock32   ),
	.sd_rd       (sdRd[1]   ),
	.sd_wr       (sdWr[1]   ),
	.sd_ack      (sdAck     ),
	.sd_lba      (sdLba1    ),
	.sd_busy     (sdBusy    ),
	.sd_conf     (sdConf    ),
	.sd_sdhc     (sdSdhc    ),
	.sd_ack_conf (sdAckCf   ),
	.sd_buff_dout(sdBuffQ   ),
	.sd_buff_wr  (sdBuffW   ),
	.sd_buff_din (sdBuffD1  ),
	.sd_buff_addr(sdBuffA   ),
	.img_mounted (imgMntd[1]),
	.img_size    (imgSize   ),
	.allow_sdhc  (1'b1      ),
	.sd_cs       (sdvCs     ),
	.sd_sck      (sdvCk     ),
	.sd_sdi      (sdvMosi   ),
	.sd_sdo      (sdvMiso   )
);


wire [VGA_BITS-1:0] ro, go, bo;
wire [VGA_BITS-1:0] ri, gi, bi;
assign ri = VGA_BITS == 8 ? {r, r, r[2:1]} : {r, r};
assign gi = VGA_BITS == 8 ? {g, g, g[2:1]} : {g, g};
assign bi = VGA_BITS == 8 ? {4{b}} : {3{b}};
wire [1:0] oblank;

scandoubler #(.RGBW(3*VGA_BITS)) scandoubler
(
	.clock   (clock56),
	.enable  (~vgab  ),
	.ice     (cep1x  ),
	.iblank  ({ vblank, hblank }),
	.isync   ({  vsync,  hsync }),
	.irgb    ({ ri, gi, bi }),
	.oce     (cep2x  ),
	.oblank  (oblank ),
	.osync   (sync   ),
	.orgb    ({ro, go, bo} )
);

osd #(.OUT_COLOR_DEPTH(VGA_BITS), .BIG_OSD(BIG_OSD), .USE_BLANKS(1'b1)) osd
(
	.clk_sys(clock56),
	.SPI_SCK(spiCk  ),
	.SPI_SS3(spiSs3 ),
	.SPI_DI (spiMosi),
	.rotate (2'd0   ),
	.HSync  (sync[0]),
	.VSync  (sync[1]),
	.HBlank (oblank[0]),
	.VBlank (oblank[1]),
	.R_in   (ro     ),
	.G_in   (go     ),
	.B_in   (bo     ),
	.R_out  (vgaR   ),
	.G_out  (vgaG   ),
	.B_out  (vgaB   )
);
//-------------------------------------------------------------------------------------------------
`ifdef USE_HDMI
i2c_master #(32_000_000) i2c_master (
	.CLK         (clock32),

	.I2C_START   (i2c_start),
	.I2C_READ    (i2c_read),
	.I2C_ADDR    (i2c_addr),
	.I2C_SUBADDR (i2c_subaddr),
	.I2C_WDATA   (i2c_dout),
	.I2C_RDATA   (i2c_din),
	.I2C_END     (i2c_end),
	.I2C_ACK     (i2c_ack),

	//I2C bus
	.I2C_SCL     (HDMI_SCL),
	.I2C_SDA     (HDMI_SDA)
);

wire [1:0] hoblank;
wire [7:0] hro, hgo, hbo;
wire [7:0] hri, hgi, hbi;
assign hri = {r, r, r[2:1]};
assign hgi = {g, g, g[2:1]};
assign hbi = {4{b}};

// make vblank at least 8 lines
reg [3:0] vblank_cnt = 0;
always @(posedge clock56) begin
	reg hsync_old, vblank_old;

	hsync_old <= hsync;
	vblank_old <= vblank;
	if (hsync_old & !hsync) if (|vblank_cnt) vblank_cnt <= vblank_cnt - 1'd1;
	if (!vblank_old & vblank) vblank_cnt <= 9;
end

scandoubler #(.RGBW(24)) hdmi_scandoubler
(
	.clock   (clock56),
	.enable  (1'b1   ),
	.ice     (cep1x  ),
	.iblank  ({ vblank | |vblank_cnt, hblank }),
	.isync   ({ vsync,  hsync }),
	.irgb    ({ hri, hgi, hbi }),
	.oce     (cep2x  ),
	.oblank  (hoblank ),
	.osync   ({HDMI_VS, HDMI_HS}),
	.orgb    ({hro, hgo, hbo} )
);

osd #(.OUT_COLOR_DEPTH(8), .BIG_OSD(BIG_OSD), .USE_BLANKS(1'b1)) hdmi_osd
(
	.clk_sys(clock56),
	.SPI_SCK(spiCk  ),
	.SPI_SS3(spiSs3 ),
	.SPI_DI (spiMosi),
	.rotate (2'd0   ),
	.HSync  (HDMI_HS),
	.VSync  (HDMI_VS),
	.HBlank (hoblank[0]),
	.VBlank (hoblank[1]),
	.R_in   (hro    ),
	.G_in   (hgo    ),
	.B_in   (hbo    ),
	.R_out  (HDMI_R ),
	.G_out  (HDMI_G ),
	.B_out  (HDMI_B )
);

assign HDMI_DE = ~|hoblank;
assign HDMI_PCLK = clock56;
`endif
//-------------------------------------------------------------------------------------------------

wire clock32, locked32;
pll32 pll32(clock50, clock32, locked32);

wire clock56, locked56;
pll56 pll56(clock50, clock56, locked56);

wire power = locked32 & locked56;

//-------------------------------------------------------------------------------------------------

reg earIni, earGot;
always @(posedge clock32) if(!earGot) { earIni, earGot } <= { ear, 1'b1 };

//-------------------------------------------------------------------------------------------------

wire strb;
wire make;
wire[7:0] code;
ps2k keyb(clock32, ps2ko, strb, make, code);

reg[2:0] mbtns = 3'b111;
reg[7:0] xaxis;
reg[7:0] yaxis;
always @(posedge clock32) if(mouse_strobe) begin
	mbtns <= ~{ mouse_flags[2], mouse_flags[0], mouse_flags[1] };
	xaxis <= xaxis+mouse_x[8:1];
	yaxis <= yaxis+mouse_y[8:1];
end

reg F9 = 1'b1;
always @(posedge clock32) if(strb) case(code) 8'h01: F9 <= make; endcase

//-------------------------------------------------------------------------------------------------

reg reset = 1;
always @(posedge clock32, negedge power) begin
	if (!power)
		reset <= 1;
	else
		reset <= F9 && ready && !iniIo && !romIo && !status[0] && !buttons[1];
end

wire[1:0] speed = {1'b0, status[5]};

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

wire tape = ear^earIni;

wire[8:0] left;
wire[8:0] right;

wire[7:0] joy1 = joystick_0[7:0];
wire[7:0] joy2 = joystick_1[7:0];

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
	.cs     (sdvCs  ),
	.ck     (sdvCk  ),
	.mosi   (sdvMosi),
	.miso   (sdvMiso)
);

//-------------------------------------------------------------------------------------------------

i2s i2s_inst (
	.reset(1'b0),
	.clk(clock32),
	.clk_rate(32'd32_000_000),
	.sclk(i2s[0]),
	.lrclk(i2s[1]),
	.sdata(i2s[2]),
	.left_chan({ 1'b0,  left, 6'd0 }),
	.right_chan({ 1'b0,  right, 6'd0 })
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clock32) begin
	HDMI_BCK   <= i2s[0];
	HDMI_LRCK  <= i2s[1];
	HDMI_SDATA <= i2s[2];
end
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(clock32),
	.clk_rate_i(32'd32_000_000),
	.spdif_o(SPDIF),
	.sample_i({ 1'b0, right, 6'd0 , 1'b0,  left, 6'd0 })
);
`endif
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

reg[7:0] romP = 8'd7;
always @(posedge clock32) if(romIo) romP <= { 5'd0, romA[16:14] };

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
dpr #(64) dpr(clock56, memA1, memQ1, clock32, memA2[15:0], memD2, memW2 && vmm);

wire ready;
wire sdrRf = iniIo ? 1'b1 : rfsh;
wire sdrRd = iniIo ? 1'b0 : memR2 && (ram || rom);
wire sdrWr = iniIo ? iniW : romIo ? romW : memW2 && (ram || (memP2 == 8'h07 && memA2[13]));

wire[23:0] sdrA = { 2'd0, iniIo ? { 5'd0, iniA } : romIo ? romA[21:0] : memA2 };
wire[15:0] sdrD = { 8'd0, iniIo ? iniD : romIo ? romD : memD2 };
wire[15:0] sdrQ;

sdram sdram
(
	.clock  (clock32),
	.reset  (power  ),
	.ready  (ready  ),
	.rfsh   (sdrRf  ),
	.rd     (sdrRd  ),
	.wr     (sdrWr  ),
	.a      (sdrA   ),
	.d      (sdrD   ),
	.q      (sdrQ   ),
	.dramCs (dramCs ),
	.dramRas(dramRas),
	.dramCas(dramCas),
	.dramWe (dramWe ),
	.dramDQM(dramDQM),
	.dramDQ (dramDQ ),
	.dramBA (dramBA ),
	.dramA  (dramA  )
);

assign memQ2 = rom || ram ? sdrQ[7:0] : 8'hFF;

assign dramCk = clock32;
assign dramCe = 1'b1;

//-------------------------------------------------------------------------------------------------

assign led = sdvCs;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
