//-------------------------------------------------------------------------------------------------
//  SD interface
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
module usd
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      cecpu,
	input  wire      cespi,
	input  wire      reset,

	output reg [7:5] page,
	input  wire      ioSD,
	input  wire      rd,
	input  wire      wr,
	input  wire[7:0] a,
	input  wire[7:0] d,
	output reg [7:0] q,

	output reg       cs,
	output wire      ck,
	output wire      mosi,
	input  wire      miso
);
//-------------------------------------------------------------------------------------------------

wire ioRd = ioSD && !rd;
wire ioWr = ioSD && !wr;

reg usdHs;
reg spiRW;
reg[7:0] usdD;

always @(posedge clock, negedge reset)
	if(!reset) begin
		q <= 8'hFF;
		cs <= 1'b1;
		usdHs <= 1'b0;
		usdD <= 8'hFF;
	end
	else if(cecpu) begin
		spiRW <= 1'b0;
		if(ioWr) case(a[1:0])
			2'b00: begin spiRW <= 1'b1; if(!usdHs) usdD <= d; end
			2'b01: cs <= ~d[7];
			2'b10: page <= d[7:5];
			2'b11: begin usdHs <= d[7]; if(d[7]) usdD <= 8'hFF; end
		endcase
		if(ioRd)
			if(usdHs) begin spiRW <= 1'b1; q <= spiQ; end
			else case(a[1:0])
			2'b00: q <= spiQ;
			2'b01: q <= { 1'b0, 1'b0, 6'h3F };
			default: q <= 8'hFF;
		endcase
	end

reg spiIo, spiRWd;
always @(posedge clock) begin
	spiIo <= 1'b0;
	spiRWd <= spiRW;
	if(spiRW && !spiRWd) spiIo <= 1'b1;
end

wire[7:0] spiD = usdD;
wire[7:0] spiQ;

spi SD
(
	.clock  (clock  ),
	.ce     (cespi  ),
	.io     (spiIo && !cs),
	.d      (spiD   ),
	.q      (spiQ   ),
	.ck     (ck     ),
	.mosi   (mosi   ),
	.miso   (miso   )
);

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
