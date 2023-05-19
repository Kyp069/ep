//-------------------------------------------------------------------------------------------------
//  Elan Enterprise interrupts
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
module interrupts
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      cecpu,
	input  wire      ceirq,

	input  wire      reset,
	input  wire      iorq,
	input  wire      wr,
	input  wire[7:0] a,
	input  wire[7:0] d,
	output wire[7:0] q,

	input  wire      irq0,
	input  wire      irq1,
	input  wire      irqv,

	output wire      int0
);
//-------------------------------------------------------------------------------------------------

wire ioA7 = !(!iorq && a == 8'hA7);
wire ioB4 = !(!iorq && a == 8'hB4);

reg[6:5] regA7;
always @(posedge clock, negedge reset)
	if(!reset) regA7 <= 1'd0; else
	if(cecpu) if(!ioA7 && !wr) regA7 <= d[6:5];

reg[7:0] cc1K;
wire z1K = cc1K == 1'd0;
always @(posedge clock) if(ceirq) if(z1K) cc1K <= 8'd250; else cc1K <= cc1K-1'd1;

reg[12:0] cc50;
wire z50 = cc50 == 1'd0;
always @(posedge clock) if(ceirq) if(z50) cc50 <= 13'd5000; else cc50 <= cc50-1'd1;

reg[17:0] cc1;
wire z1 = cc1 == 1'd0;
always @(posedge clock) if(ceirq) if(z1) cc1 <= 18'd250000; else cc1 <= cc1-1'd1;

reg ff0 = 0;
wire z0 = regA7 == 2'b00 ? z1K : regA7 == 2'b01 ? z50 : regA7 == 2'b10 ? irq0 : irq1;
always @(posedge clock) if(ceirq) if(z0) ff0 <= ~ff0;

reg ff1 = 0;
always @(posedge clock) if(ceirq) if(z1) ff1 <= ~ff1;

reg zd, zv;
always @(posedge clock) if(ceirq) begin zd <= irqv; zv <= irqv && !zd; end

//-------------------------------------------------------------------------------------------------

reg[5:0] regB4;

always @(posedge clock, negedge reset)
	if(!reset) regB4 <= 1'd0; else
	if(ceirq) begin
		if(z0) regB4[1] <= regB4[0];
		if(z1) regB4[3] <= regB4[2];
		if(zv) regB4[5] <= regB4[4];
	end
	else if(cecpu)
		if(!ioB4 && !wr) begin
			regB4[0] <= d[0];
			regB4[2] <= d[2];
			regB4[4] <= d[4];
			if(!d[0] || d[1]) regB4[1] <= 1'b0;
			if(!d[2] || d[3]) regB4[3] <= 1'b0;
			if(!d[4] || d[5]) regB4[5] <= 1'b0;
		end

//-------------------------------------------------------------------------------------------------

assign q = { 2'b00, regB4[5],irqv, regB4[3],ff1, regB4[1],ff0 };
assign int0 = !(regB4[1] || regB4[3] || regB4[5]);

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------

/*
about interrupts:

Interrupts are controlled by 0b4h register, that sets up which interrupts are enabled.
write:
bit0 - enable Dave defined interrupts (50Hz/1Khz/frequency of tone generator 0 or 1)
bit1 - resets Dave interrupt request flag (if interrupt occurs, interrupt flag is becomes active, it has to reset "manually")
bit2 - enable 1Hz interrupt
bit3 - resets 1Hz interrupt request flag (if interrupt occurs, interrupt flag is becomes active, it has to reset "manually")
bit4 - enable Nick interrupt (video interrupt)
bit5 - resets Nick interrupt request flag (if interrupt occurs, interrupt flag is becomes active, it has to reset "manually")
bit6 - enable INT2 - it is not used, i think it was for future implementation
bit7 - resets INT2 - it is not used, i think it was for future implementation

read:
bit0 - Dave defined interrupts flip/flop(50Hz/1Khz/frequency of tone generator 0 or 1)
bit1 - gives back Dave interrupt status flag (if interrupt occured 1, if not 0 it remains active until it is not reseted by writing bit1 to port 0b4h, and iterrepupt generating until reset)
bit2 - interrupt flip/flop
bit3 - gives back 1Hz interrupt status flag (if interrupt occured 1, if not 0 it remains active until it is not reseted by writing bit3 to port 0b4h, and iterrepupt generating until reset)
bit4 - it contains the value of VINT flag of avtual LPB
bit5 - gives back Nick interrupt status flag (if interrupt occured 1, if not 0, it remains active until it is not reseted by writing bit5 to port 0b4h, and iterrepupt generating until reset)
bit6 - INT2 - it is not used, i think it was for future implementation
bit7 - gives back INT2 - it is not used, i think it was for future implementation

bit0 flip/flop changed when "interrupt time is reached"
bit1 changes to 1 (interrupt occurs), if bit0 is changed, and remains in 1 until it is not cleared by setting bit1 of 0b4h port
bit2 flip/flop changed in each sec from 0 to 1 and from 1 to 0
bit3 changes to 1 (interrupt occurs), if bit2 is changed, and remains in 1 until it is not cleared by setting bit1 of 0b4h port
bit4 contains the VINT (video interrupt) flag of actually read LPB
bit5 changes to one if LPT pointer starts to read next LPB after LPB which contained VINT flag
This means that if we want to place more working interrupts into LPT, after each LPB contains VINT need to insert an LPB without VINT to activate that place for interrupt.

bit0,2,4 are updated even if the corresponding interrupts are disabled.
*/