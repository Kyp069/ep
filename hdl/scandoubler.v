//-------------------------------------------------------------------------------------------------
//  Scandoubler
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
module scandoubler
//-------------------------------------------------------------------------------------------------
#
(
	parameter HCW = 10, // horizontal counter width
	parameter RGBW = 18 // rgb width
)
(
	input  wire           clock,
	input  wire           enable,

	input  wire           ice,
	input  wire[     1:0] iblank,
	input  wire[     1:0] isync,
	input  wire[RGBW-1:0] irgb,

	input  wire           oce,
	output wire[     1:0] osync,
	output wire[RGBW-1:0] orgb
);
//-------------------------------------------------------------------------------------------------

reg iHBlankDelayed, iHBlankPosedge, iHBlankNegedge;
always @(posedge clock) if(ice) begin
	iHBlankDelayed <= iblank[0];
	iHBlankPosedge <= !iHBlankDelayed && iblank[0];
	iHBlankNegedge <= iHBlankDelayed && !iblank[0];
end

reg iHSyncDelayed, iHSyncPosedge, iHSyncNegedge;
always @(posedge clock) if(ice) begin
	iHSyncDelayed <= isync[0];
	iHSyncPosedge <= !iHSyncDelayed && isync[0];
	iHSyncNegedge <= iHSyncDelayed && !isync[0];
end

reg iVSyncDelayed, iVSyncNegedge;
always @(posedge clock) if(ice) begin
	iVSyncDelayed <= isync[1];
	iVSyncNegedge <= iVSyncDelayed && !isync[1];
end

reg oHSyncDelayed, oHSyncPosedge;
always @(posedge clock) if(oce) begin
	oHSyncDelayed <= isync[0];
	oHSyncPosedge <= !oHSyncDelayed && isync[0];
end

//-------------------------------------------------------------------------------------------------

reg[HCW-1:0] iHCount;
always @(posedge clock) if(ice) if(iHSyncNegedge) iHCount <= 1'd0; else iHCount <= iHCount+1'd1;

reg[HCW-1:0] iHBlankBeg;
always @(posedge clock) if(ice) if(iHBlankPosedge) iHBlankBeg <= iHCount;

reg[HCW-1:0] iHBlankEnd;
always @(posedge clock) if(ice) if(iHBlankNegedge) iHBlankEnd <= iHCount;

reg[HCW-1:0] iHSyncBeg;
always @(posedge clock) if(ice) if(iHSyncPosedge) iHSyncBeg <= iHCount;

reg[HCW-1:0] iHSyncEnd;
always @(posedge clock) if(ice) if(iHSyncNegedge) iHSyncEnd <= iHCount;

reg line;
always @(posedge clock) if(ice) if(iVSyncNegedge) line <= 0; else if(iHSyncNegedge) line <= ~line;

//-------------------------------------------------------------------------------------------------

reg[HCW-1:0] oHCount;
always @(posedge clock) if(oce) if(oHSyncPosedge) oHCount <= iHSyncEnd-(iHSyncEnd-iHSyncBeg); else if(oHCount == iHSyncEnd) oHCount <= 0; else oHCount <= oHCount+1'd1;

//-------------------------------------------------------------------------------------------------

reg ohb;
always @(posedge clock) if(oce) if(oHCount == iHBlankBeg) ohb <= 1'b1; else if(oHCount == iHBlankEnd) ohb <= 1'b0;

reg ohs;
always @(posedge clock) if(oce) if(oHCount == iHSyncBeg) ohs <= 1'b1; else if(oHCount == iHSyncEnd) ohs <= 1'b0;

//-------------------------------------------------------------------------------------------------

// Xilinx: set parameter -infer_ramb8 No in XST to avoid PhysDesignRules:2410 warning

reg[RGBW-1:0] brgb;
reg[RGBW-1:0] buffer[0:(2*2**HCW)-1]; // 2 lines of 2**HCW pixels of RGBW words

always @(posedge clock) if(ice) buffer[{ line, iHCount }] <= irgb;
always @(posedge clock) if(oce) brgb <= buffer[{ ~line, oHCount }];

wire blank = enable ? iblank[1] || ohb  : |iblank;

assign osync = enable ? { isync[1], ohs } : { 1'b1, ~^isync };
assign orgb = blank ? 1'd0 : enable ? brgb : irgb;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
