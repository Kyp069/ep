//-------------------------------------------------------------------------------------------------
//  Elan Enterprise audio
//-------------------------------------------------------------------------------------------------
//  This file is part of the Elan Enterprise FPGA implementation project.
//  Copyright (C) 2023 Kyp069 <kyp069@gmail.com>
//  Copyright (C) 2024 Rampa069
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
module audio
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      cecpu,
	input  wire      ceaud,

	input  wire      power,
	input  wire      reset,
	input  wire      iorq,
	input  wire      wr,
	input  wire[7:0] d,
	input  wire[7:0] a,

	output wire      irq0,
	output wire      irq1,

	output wire [8:0] r,
	output wire [8:0] l
);
//-------------------------------------------------------------------------------------------------

reg[9:0] cc = 0;
wire clock31K25 = cc[9];
always @(posedge clock) if(power) cc <= cc+1'd1;

wire nClk = nFreq == 2'b00 ? clock31K25 : nFreq == 2'b01 ? aZero : nFreq == 2'b10 ? bZero : cZero;

reg[16:0] lfsr_17 = 17'h1FFFF;
reg[ 6:0] lfsr_7  = 7'h7f;
reg[ 4:0] lfsr_5  = 5'h1f;
reg[ 3:0] lfsr_4  = 4'hf;

reg[16:0] lfsr_17_n = 17'h1FFFF;
reg[ 6:0] lfsr_7_n  = 7'h7f;

wire aRing = data[1][7];
wire bRing = data[3][7];
wire cRing = data[5][7];
wire nRing = data[6][7]; 

wire[1:0] aPc = data[1][5:4];
wire[1:0] bPc = data[3][5:4];
wire[1:0] cPc = data[5][5:4];

wire[1:0] nFreq = data[6][1:0];
wire[1:0] nLeng = data[6][3:2];

wire nSwap = data[6][4];
wire nLPF  = data[6][5]; 
wire nHPF  = data[6][6]; 
wire aHPF  = data[1][6];
wire bHPF  = data[3][6];
wire cHPF  = data[5][6];

reg aOut_prv, aOut = 0;
reg bOut_prv, bOut = 0;
reg cOut_prv, cOut = 0;
reg nOut_prv, nOut = 0;

always @(posedge clock) if(ceaud) begin
	lfsr_4 <= { lfsr_4[2:0], lfsr_4[3] ^ lfsr_4[2] };
	lfsr_5 <= { lfsr_5[3:0], lfsr_5[4] ^ lfsr_5[2] };
	lfsr_7 <= { lfsr_7[5:0], lfsr_7[6] ^ lfsr_7[5] };
	lfsr_17 <= (nLeng == 2'b00) ? { lfsr_17[15:0],(lfsr_17[16] ^ lfsr_17[13]) }
		:      (nLeng == 2'b01) ? { lfsr_17[15:0],(lfsr_17[14] ^ lfsr_17[13]) }
		:      (nLeng == 2'b10) ? { lfsr_17[15:0],(lfsr_17[10] ^ lfsr_17[ 8]) }
		:                         { lfsr_17[15:0],(lfsr_17[ 8] ^ lfsr_17[ 4]) };
end

always @(posedge nClk) begin
	lfsr_7_n  <= { lfsr_7_n[5:0], lfsr_7_n[6] ^ lfsr_7_n[5] };
	lfsr_17_n <= (nLeng == 2'b00) ? { lfsr_17_n[15:0],(lfsr_17_n[16] ^ lfsr_17_n[13]) }
		:        (nLeng == 2'b01) ? { lfsr_17_n[15:0],(lfsr_17_n[14] ^ lfsr_17_n[13]) }
		:        (nLeng == 2'b10) ? { lfsr_17_n[15:0],(lfsr_17_n[10] ^ lfsr_17_n[ 8]) }
		:                           { lfsr_17_n[15:0],(lfsr_17_n[ 8] ^ lfsr_17_n[ 4]) };
end

reg nOut_pn, nOut_lp,nOut_hp;
always @(posedge nClk) begin
	nOut_prv <= nOut;
	nOut_pn <= nSwap ? lfsr_7_n[0] : lfsr_17_n[0];
	nOut_lp <= (nLPF && ~cOut && cOut_prv) ? nOut_prv : nOut_pn;
	nOut_hp <= (nHPF && ~aOut && aOut_prv) ? 1'b0     : nOut_lp;
	nOut <= nRing ? ~(nOut_hp ^ bOut) : nOut_hp;
end

reg cOut_pn, cOut_hp;
always @(posedge clock) if(cZero) begin
	cOut_prv <= cOut;
	cOut_pn <= (cPc ==2'b01) ? lfsr_4[0]
		:      (cPc ==2'b10) ? lfsr_5[0]
		:      (cPc ==2'b11) ? nSwap ? lfsr_17[0] : lfsr_7_n[0]
		:      cTone;
	cOut_hp <= (cHPF && ~nOut && nOut_prv) ? 1'b0 : cOut_pn;
	cOut <= cRing ? ~(cOut_hp ^ aOut) : cOut_hp;
end

reg bOut_pn, bOut_hp;
always @(posedge clock) if(bZero) begin
	bOut_prv <= bOut;
	bOut_pn <= (bPc ==2'b01) ? lfsr_4[0]
		:      (bPc ==2'b10) ? lfsr_5[0]
		:      (bPc ==2'b11) ? nSwap ? lfsr_17[0] : lfsr_7_n[0]
		:      bTone;
	bOut_hp <= (bHPF && ~cOut && cOut_prv) ? 1'b0 : bOut_pn;
	bOut <= bRing?  ~(bOut_hp ^ nOut) : bOut_hp;
end

reg aOut_pn, aOut_hp;
always @(posedge clock) if(aZero) begin
	aOut_prv <= aOut;
	aOut_pn <= (aPc ==2'b01) ? lfsr_4[0]
		:      (aPc ==2'b10) ? lfsr_5[0]
		:      (aPc ==2'b11) ? nSwap ? lfsr_17[0] : lfsr_7_n[0]
		:      aTone;
	aOut_hp <= (aHPF && ~bOut && bOut_prv) ? 1'b0 : aOut_pn;
	aOut <= aRing ? ~(aOut ^ cOut) : aOut_hp;
end

//-------------------------------------------------------------------------------------------------

reg[7:0] data[0:15];
always @(posedge clock, negedge reset)
	if(!reset)
	begin
		data[0] <= 8'h00; data[4] <= 8'h00; data[ 8] <= 8'h00; data[12] <= 8'h00;
		data[1] <= 8'h00; data[5] <= 8'h00; data[ 9] <= 8'h00; data[13] <= 8'h00;
		data[2] <= 8'h00; data[6] <= 8'h00; data[10] <= 8'h00; data[14] <= 8'h00;
		data[3] <= 8'h00; data[7] <= 8'h07; data[11] <= 8'h00; data[15] <= 8'h00;
	end
	else if(cecpu)
		if(!iorq && !wr && a[7:4] == 4'hA) data[a[3:0]] <= d;

wire[11:0] aPeriod = { data[1][3:0], data[0] };
wire[11:0] bPeriod = { data[3][3:0], data[2] };
wire[11:0] cPeriod = { data[5][3:0], data[4] };

wire aSync = data[7][0];
wire bSync = data[7][1];
wire cSync = data[7][2];

wire lDac = data[7][3];
wire rDac = data[7][4];

wire[5:0] aLLevel = data[8][5:0];
wire[5:0] bLLevel = data[9][5:0];
wire[5:0] cLLevel = data[10][5:0];
wire[5:0] nLLevel = data[11][5:0];

wire[5:0] aRLevel = data[12][5:0];
wire[5:0] bRLevel = data[13][5:0];
wire[5:0] cRLevel = data[14][5:0];
wire[5:0] nRLevel = data[15][5:0];

//-------------------------------------------------------------------------------------------------

reg[11:0] aCount;
wire aZero = aCount == 0;
always @(posedge clock) if(ceaud) if(aSync || aZero) aCount <= aPeriod; else aCount <= aCount-1'd1;

reg[11:0] bCount;
wire bZero = bCount == 0;
always @(posedge clock) if(ceaud) if(bSync || bZero) bCount <= bPeriod; else bCount <= bCount-1'd1;

reg[11:0] cCount;
wire cZero = cCount == 0;
always @(posedge clock) if(ceaud) if(cSync || cZero) cCount <= cPeriod; else cCount <= cCount-1'd1;

//-------------------------------------------------------------------------------------------------

reg aTone;
always @(posedge clock) if(ceaud) if(aZero) aTone <= ~aTone;

reg bTone;
always @(posedge clock) if(ceaud) if(bZero) bTone <= ~bTone;

reg cTone;
always @(posedge clock) if(ceaud) if(cZero) cTone <= ~cTone;

//-------------------------------------------------------------------------------------------------

assign irq0 = aZero; 
assign irq1 = bZero;

assign r = rDac ? aRLevel : (aOut ? aRLevel : 6'd0)+(bOut ? bRLevel : 6'd0)+(cOut ? cRLevel : 6'd0)+(nOut ? nRLevel : 6'd0);
assign l = lDac ? aLLevel : (aOut ? aLLevel : 6'd0)+(bOut ? bLLevel : 6'd0)+(cOut ? cLLevel : 6'd0)+(nOut ? nLLevel : 6'd0);

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
