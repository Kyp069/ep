//-------------------------------------------------------------------------------------------------
//  PS/2 mouse
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
module ps2m
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      reset,
	inout  wire      ps2mDQ,
	inout  wire      ps2mCk,
	output wire[2:0] mbtns,
	output wire[7:0] xaxis,
	output wire[7:0] yaxis
);
//-------------------------------------------------------------------------------------------------

parameter clk_freq = 56_750_320;         // system clock frequency in Hz
parameter ps2_debounce_counter_size = 8; // set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)

reg       tx_ena = 0;			// transmit enable for ps2_transceiver
reg[ 8:0] tx_cmd;				// command to transmit
reg       tx_busy;				// ps2_transceiver busy signal
reg[ 7:0] ps2_code;				// PS/2 code received from ps2_transceiver
reg       ps2_code_new;			// new PS/2 code available flag from ps2_transceiver

ps2_transceiver #(clk_freq, ps2_debounce_counter_size) ps2_transceiver_0
(
	.clk         (clock       ),
	.reset_n     (reset       ),
	.tx_ena      (tx_ena      ),
	.tx_cmd      (tx_cmd      ),
	.tx_busy     (tx_busy     ),
	.ack_error   (            ),
	.ps2_code    (ps2_code    ),
	.ps2_code_new(ps2_code_new),
	.rx_error    (            ),
	.ps2_data    (ps2mDQ      ),
	.ps2_clk     (ps2mCk      )
);

localparam idle = 0;
localparam rx_ack1 = 1;
localparam rx_bat = 2;
localparam rx_id = 3;
localparam ena_reporting = 4;
localparam rx_ack2 = 5;
localparam stream = 6;

reg[1:0] packet;
reg[2:0] state = idle;
reg      ps2_code_new_prev = 0;

reg xsign, ysign, mbtn, lbtn, rbtn;
reg[8:0] xdata, ydata;

wire strobe = !ps2_code_new_prev && ps2_code_new;

always @(posedge clock, negedge reset)
	if(!reset) begin
		packet <= 1'd0;
		state <= idle;
	end
	else begin
		ps2_code_new_prev <= ps2_code_new;
		case(state)
			idle:
				if(!tx_busy) begin				// transmit to mouse not yet in process
					tx_ena <= 1'b1;				// enable transmit to PS/2 mouse
					tx_cmd <= 9'h1FF;			// send reset command (P=1,0xFF)
					state <= idle;				// remain in reset state
				end
				else if(tx_busy) begin			// transmit to mouse is in process
					tx_ena <= 1'b0;				// clear transmit enable
					state <= rx_ack1;			// wait to receive an acknowledge from mouse
				end

			rx_ack1:
				if(strobe) begin				//new PS/2 code received
					if(ps2_code == 8'hFA)		// new PS/2 code is acknowledge (0xFA)
						state <= rx_bat;		// wait to receive new BAT completion code
					else						// new PS/2 code was not an acknowledge
						state <= idle;			// reset mouse again
				end
				else							// new PS/2 code not yet received
					state <= rx_ack1;			// wait to receive a code from mouse

			rx_bat:
				if(strobe) begin				// new PS/2 code received
					if(ps2_code == 9'hAA)		// new PS/2 code is BAT completion (0xAA)
						state <= rx_id;			// wait to receive device ID code
					else						// new PS/2 code was not BAT completion
						state <= idle;			// reset mouse again
				end
				else							// new PS/2 code not yet received
					state <= rx_bat;			// wait to receive a code from mouse
	
			rx_id:
				if(strobe) begin				// new PS/2 code received
					if(ps2_code == 8'h00)		// new PS/2 code is a mouse device ID (0x00)
						state <= ena_reporting;	// send command to enable data reporting
					else						// new PS/2 code is not a mouse device ID
						state <= idle;			//reset mouse again
				end
				else							// new PS/2 code not yet received
					state <= rx_id;				// wait to receive a code from mouse

			ena_reporting:
				if(!tx_busy) begin				// transmit to mouse not yet in process
					tx_ena <= 1'b1;				// enable transmit to PS/2 mouse
					tx_cmd <= 9'h0F4;			// send enable reporting command (0xF4)
					state <= ena_reporting;		// remain in ena_reporting state
				end
				else if(tx_busy) begin			// transmit to mouse is in process
					tx_ena <= 1'b0;				// clear transmit enable
					state <= rx_ack2;			// wait to receive an acknowledge from mouse
				end

			rx_ack2:
				if(strobe) begin				// new PS/2 code received
					if(ps2_code == 8'hFA) 		// new PS/2 code is acknowledge (0xFA)
						state <= stream;		// proceed to collect and output data from mouse
					else						// new PS/2 code was not an acknowledge
						state <= idle;			// reset mouse again
				end
				else							// new PS/2 code not yet received
					state <= rx_ack2;			// wait to receive a code from mouse
		
			stream:
				if(strobe) begin				// new PS/2 code received
					if(packet == 2) packet <= 1'd0; else packet <= packet+1'd1;
					case(packet)
						0: { ysign, xsign, mbtn, rbtn, lbtn } <= { ps2_code[5:4], ps2_code[2:0] };
						1: xdata <= xdata+{ xsign, ps2_code };
						2: ydata <= ydata+{ ysign, ps2_code };
					endcase
				end
		endcase
	end

assign mbtns = ~{ mbtn, lbtn, rbtn };
assign xaxis = xdata[7:0];
assign yaxis = ydata[7:0];

endmodule
