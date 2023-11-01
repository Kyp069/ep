module wd17xx (
	clk_sys,
	ce,
	reset,
	io_en,
	rd,
	wr,
	addr,
	din,
	dout,
	drq,
	intrq,
	busy,
	wp,
	size_code,
	layout,
	side,
	ready,
	ready_n,
	disk_change_n,
	disk_change_reset_n,
	img_mounted,
	img_size,
	prepare,
	sd_lba,
	sd_rd,
	sd_wr,
	sd_ack,
	sd_buff_addr,
	sd_buff_dout,
	sd_buff_din,
	sd_buff_wr
);
	input clk_sys;
	input ce;
	input reset;
	input io_en;
	input rd;
	input wr;
	input [1:0] addr;
	input [7:0] din;
	output wire [7:0] dout;
	output wire drq;
	output wire intrq;
	output wire busy;
	input wp;
	input [2:0] size_code;
	input layout;
	input side;
	input ready;
	output wire ready_n;
	output reg disk_change_n;
	input disk_change_reset_n;
	input img_mounted;
	input [20:0] img_size;
	output wire prepare;
	output wire [31:0] sd_lba;
	output reg sd_rd;
	output reg sd_wr;
	input sd_ack;
	input [8:0] sd_buff_addr;
	input [7:0] sd_buff_dout;
	output wire [7:0] sd_buff_din;
	input sd_buff_wr;
	parameter MODEL = 0;
	parameter EDSK = 0;
	parameter CLK_EN = 16'd32000;
	parameter F_NUM = 4'b0001;
	reg [7:0] cmd;
	wire [31:0] step_rate_clk = (cmd[1:0] == 2'b00 ? (16'd6 * CLK_EN) - 1'd1 : (cmd[1:0] == 2'b01 ? (16'd12 * CLK_EN) - 1'd1 : ((MODEL == 2) && (cmd[1:0] == 2'b10) ? (16'd2 * CLK_EN) - 1'd1 : (cmd[1:0] == 2'b10 ? (16'd20 * CLK_EN) - 1'd1 : (MODEL == 2 ? (16'd3 * CLK_EN) - 1'd1 : (16'd30 * CLK_EN) - 1'd1)))));
	reg s_motor;
	wire s_ready = ~ready;
	assign ready_n = ~(~s_ready && s_motor);
	reg [7:0] q;
	assign dout = q;
	reg [1:0] s_drq_busy;
	wire s_drq = s_drq_busy[1];
	assign drq = s_drq;
	wire s_busy = s_drq_busy[0];
	assign busy = s_busy;
	reg s_intrq;
	assign intrq = s_intrq;
	reg [20:0] buff_a;
	reg scan_active = 0;
	reg [20:0] scan_addr;
	reg [1:0] sd_block = 0;
	assign sd_lba = (scan_active ? scan_addr[20:9] : buff_a[20:9] + sd_block);
	assign prepare = (EDSK ? scan_active : img_mounted);
	reg [7:0] sectors_per_track;
	reg [7:0] edsk_spt = 0;
	reg [1:0] wd_size_code;
	wire [10:0] sector_size = 11'd128 << wd_size_code;
	reg [11:0] byte_addr;
	wire [7:0] buff_dout;
	reg format;
	localparam A_DATA = 3;
	reg buff_wr;
	wire wre = wr & io_en;
	wd177x_dpram sbuf(
		.clock(clk_sys),
		.address_a({sd_block, sd_buff_addr}),
		.data_a(sd_buff_dout),
		.wren_a(sd_buff_wr & sd_ack),
		.q_a(sd_buff_din),
		.address_b((scan_active ? (img_size[19] ? scan_addr[9:0] : scan_addr[8:0]) : byte_addr)),
		.data_b((format ? 8'd0 : din)),
		.wren_b(((wre & buff_wr) & (addr == A_DATA)) & ~scan_active),
		.q_b(buff_dout)
	);
	function [15:0] crc;
		input [15:0] curcrc;
		input [7:0] val;
		reg [3:0] i;
		begin
			crc = {curcrc[15:8] ^ val, 8'h00};
			for (i = 0; i < 8; i = i + 1'd1)
				if (crc[15]) begin
					crc = crc << 1;
					crc = crc ^ 16'h1021;
				end
				else
					crc = crc << 1;
			crc = {curcrc[7:0] ^ crc[15:8], crc[7:0]};
		end
	endfunction
	reg var_size = 0;
	reg [20:0] disk_size;
	reg layout_r;
	wire [20:0] hs = (layout_r & side ? disk_size >> 1 : 20'd0);
	reg [7:0] disk_track;
	wire [7:0] dts = {disk_track[6:0], side} >> layout_r;
	reg [20:0] edsk_offset = 0;
	reg [1:0] edsk_sizecode = 0;
	reg [7:0] wdreg_sector;
	always @(posedge clk_sys) begin
		case ({var_size, size_code})
			0: buff_a <= hs + {((({1'b0, dts, 4'b0000} + {dts, 3'b000}) + {dts, 1'b0}) + wdreg_sector) - 1'd1, 7'd0};
			1: buff_a <= hs + {({dts, 4'b0000} + wdreg_sector) - 1'd1, 8'd0};
			2: buff_a <= hs + {(({dts, 3'b000} + dts) + wdreg_sector) - 1'd1, 9'd0};
			3: buff_a <= hs + {(({dts, 2'b00} + dts) + wdreg_sector) - 1'd1, 10'd0};
			4: buff_a <= hs + {(({dts, 3'b000} + {dts, 1'b0}) + wdreg_sector) - 1'd1, 9'd0};
			5: buff_a <= hs + {(({dts, 4'b0000} + dts) + wdreg_sector) - 1'd1, 8'd0};
			default: buff_a <= edsk_offset;
		endcase
		case ({var_size, size_code})
			0: sectors_per_track <= 26;
			1: sectors_per_track <= 16;
			2: sectors_per_track <= 9;
			3: sectors_per_track <= 5;
			4: sectors_per_track <= 10;
			5: sectors_per_track <= 17;
			default: sectors_per_track <= edsk_spt;
		endcase
		case ({var_size, size_code})
			0: wd_size_code <= 0;
			1: wd_size_code <= 1;
			2: wd_size_code <= 2;
			3: wd_size_code <= 3;
			4: wd_size_code <= 2;
			5: wd_size_code <= 1;
			default: wd_size_code <= edsk_sizecode;
		endcase
	end
	reg [1:0] blk_size;
	always @(*)
		case (wd_size_code)
			0: blk_size = 0;
			1: blk_size = 0;
			2: blk_size = (buff_a[8:0] ? 2'd1 : 2'd0);
			3: blk_size = (buff_a[8:0] ? 2'd2 : 2'd1);
		endcase
	localparam A_COMMAND = 0;
	localparam A_STATUS = 0;
	localparam A_TRACK = 1;
	localparam A_SECTOR = 2;
	wire s_readonly = wp;
	reg s_crcerr;
	reg s_headloaded;
	reg RNF;
	reg s_index;
	reg s_lostdata;
	reg s_wrfault;
	integer s_motor_timer;
	reg s_motor_tick;
	reg cmd_type_1;
	reg cmd_type_2;
	reg cmd_type_3;
	reg cmd_type_4;
	reg cmd_type_wr;
	reg s_wpe;
	reg [7:0] wdreg_track;
	reg [7:0] wdreg_data;
	wire [7:0] wdreg_stat_tmp = {((MODEL == 1) || (MODEL == 3) ? s_ready : s_motor), (cmd_type_wr || cmd_type_1) && (s_readonly & s_wpe), (cmd_type_1 ? s_headloaded : s_wrfault), RNF, s_crcerr, (cmd_type_1 | cmd_type_4 ? !disk_track : s_lostdata), (cmd_type_1 | cmd_type_4 ? s_index & s_motor : drq), s_busy};
	wire [7:0] wdreg_status = wdreg_stat_tmp;
	reg [7:0] read_addr [0:5];
	reg buff_rd;
	reg step_direction;
	reg [10:0] data_length;
	reg [31:0] state = 32'd0;
	wire [7:0] next_track = ((din[6] ? din[5] : step_direction) ? (disk_track ? disk_track - 1'd1 : 8'b00000000) : disk_track + 1'd1);
	wire [10:0] next_length = data_length - 1'b1;
	reg watchdog_set;
	reg [15:0] wd_timer;
	wire watchdog_bark = wd_timer == 0;
	always @(posedge clk_sys) begin
		if (s_motor_tick)
			s_motor_timer <= 12800000;
		else if (s_motor_timer)
			s_motor_timer <= s_motor_timer - 1;
		s_motor <= s_motor_timer != 0;
	end
	always @(*)
		case (addr)
			A_STATUS: q = wdreg_status;
			A_TRACK: q = wdreg_track;
			A_SECTOR: q = wdreg_sector;
			A_DATA: q = (state == 32'd0 ? wdreg_data : (buff_rd ? buff_dout : read_addr[byte_addr[2:0]]));
		endcase
	always @(posedge clk_sys)
		if (ce)
			if (watchdog_set)
				wd_timer <= 4096;
			else if (wd_timer != 0)
				wd_timer <= wd_timer - 1'b1;
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		integer cnt;
		if (ce) begin
			if (cnt)
				cnt <= cnt - 1;
			else
				cnt <= 1600000;
			s_index <= cnt < 37030;
		end
	end
	wire rde = rd & io_en;
	always @(posedge clk_sys) begin
		if (img_mounted)
			disk_change_n <= 0;
		if (~disk_change_reset_n)
			disk_change_n <= 1;
	end
	reg [10:0] edsk_addr;
	reg [10:0] edsk_size = 0;
	wire [10:0] edsk_next = ((edsk_addr + 1'd1) >= edsk_size ? 11'd0 : edsk_addr + 1'd1);
	reg [7:0] edsk_sector = 0;
	reg edsk_side = 0;
	reg [7:0] edsk_sidef = 0;
	reg [10:0] edsk_start;
	reg [6:0] edsk_track = 0;
	reg [7:0] edsk_trackf = 0;
	reg scan_wr;
	reg [7:0] spt_size = 0;
	reg [7:0] spt_addr;
	always @(posedge clk_sys) begin : sv2v_autoblock_2
		reg old_wr;
		reg old_rd;
		reg [2:0] cur_addr;
		reg read_data;
		reg write_data;
		reg rw_type;
		integer wait_time;
		reg [3:0] read_timer;
		reg [9:0] seektimer;
		reg [7:0] ra_sector;
		reg multisector;
		reg write;
		reg [5:0] ack;
		reg sd_busy;
		reg old_mounted;
		reg [3:0] scan_state;
		reg [1:0] scan_cnt;
		reg [1:0] blk_max;
		old_mounted <= img_mounted;
		if (old_mounted && ~img_mounted) begin
			if (EDSK) begin
				scan_active <= 1;
				scan_addr <= 0;
				scan_state <= 0;
				scan_wr <= 0;
				sd_block <= 0;
				disk_track <= 0;
				wdreg_track <= 0;
			end
			disk_size <= img_size[20:0];
			layout_r <= layout;
		end
		if (reset & ~scan_active) begin
			read_data <= 0;
			write_data <= 0;
			multisector <= 0;
			step_direction <= 0;
			disk_track <= 0;
			wdreg_track <= 0;
			wdreg_sector <= 0;
			wdreg_data <= 0;
			data_length <= 0;
			byte_addr <= 0;
			buff_rd <= 0;
			buff_wr <= 0;
			state <= 32'd0;
			s_wpe <= 1;
			{s_headloaded, RNF, s_crcerr, s_intrq} <= 0;
			{s_wrfault, s_lostdata} <= 0;
			s_drq_busy <= 0;
			watchdog_set <= 0;
			seektimer <= 'h3ff;
			{ack, sd_wr, sd_rd, sd_busy} <= 0;
			ra_sector <= 1;
		end
		else if (ce) begin
			ack <= {ack[4:0], sd_ack};
			if (ack[5:4] == 'b1)
				{sd_rd, sd_wr} <= 0;
			if (ack[5:4] == 'b10)
				sd_busy <= 0;
			if (scan_active)
				if (scan_addr >= img_size)
					scan_active <= 0;
				else
					case (scan_state)
						0: begin
							sd_rd <= 1;
							sd_busy <= 1;
							scan_wr <= 0;
							scan_state <= 1;
						end
						1:
							if (!sd_busy) begin
								scan_wr <= 1;
								scan_cnt <= 1;
								scan_state <= 2;
							end
						2: begin
							scan_cnt <= scan_cnt + 1'd1;
							if (!scan_cnt) begin
								scan_wr <= ~scan_wr;
								if (scan_wr) begin
									scan_addr <= scan_addr + 1'b1;
									if (&scan_addr[8:0]) begin
										scan_active <= var_size;
										scan_state <= 0;
									end
								end
							end
						end
					endcase
			old_wr <= wre;
			old_rd <= rde;
			if ((!old_rd && rde) || (!old_wr && wre))
				cur_addr <= addr;
			if ((old_rd && !rde) && (cur_addr == A_STATUS)) begin
				s_intrq <= 0;
				{s_wrfault, RNF, s_crcerr, s_lostdata} <= 0;
			end
			if ((old_rd && !rde) && (cur_addr == A_DATA))
				read_data <= 1;
			if ((old_wr && !wre) && (cur_addr == A_DATA))
				write_data <= 1;
			case (state)
				32'd0: s_motor_tick <= 1'b0;
				32'd1:
					if (s_ready) begin
						RNF <= 1;
						state <= 32'd19;
					end
					else begin
						seektimer <= seektimer - 1'b1;
						if (!seektimer) begin
							byte_addr <= 0;
							if (var_size) begin
								if (~format)
									edsk_addr <= edsk_start;
								if (EDSK)
									spt_addr <= (side ? spt_size >> 1 : 8'd0) + disk_track;
								state <= 32'd2;
							end
							else if (!wdreg_sector)
								wdreg_sector <= 1;
							else if ((wdreg_sector > sectors_per_track) || (wdreg_track > 84)) begin
								RNF <= (format ? 1'b0 : 1'b1);
								state <= 32'd19;
							end
							else
								state <= (rw_type ? 32'd3 : 32'd6);
						end
					end
				32'd2:
					if (((rw_type & (edsk_track == disk_track)) & (edsk_side == side)) & (format | (edsk_sector == wdreg_sector)))
						state <= 32'd3;
					else if ((~rw_type & (edsk_track == disk_track)) & (edsk_side == side)) begin
						read_addr[0] <= edsk_trackf;
						read_addr[1] <= edsk_sidef;
						read_addr[2] <= edsk_sector;
						read_addr[3] <= edsk_sizecode;
						state <= 32'd6;
					end
					else if (edsk_next == edsk_start) begin
						if (~format)
							RNF <= 1;
						state <= 32'd19;
					end
					else
						edsk_addr <= edsk_next;
				32'd3: begin
					data_length <= sector_size;
					byte_addr <= buff_a[8:0];
					blk_max <= blk_size;
					sd_block <= 0;
					state <= 32'd4;
				end
				32'd4: begin
					sd_busy <= 1;
					sd_rd <= 1;
					state <= 32'd5;
				end
				32'd5:
					if (!sd_busy) begin
						sd_block <= sd_block + 1'd1;
						state <= (write ? 32'd13 : 32'd6);
						if (sd_block < blk_max)
							state <= 32'd4;
					end
				32'd6: begin
					watchdog_set <= 1;
					read_timer <= 15;
					state <= 32'd7;
				end
				32'd7: begin
					read_timer <= read_timer - 1'b1;
					if (!read_timer) begin
						read_data <= 0;
						watchdog_set <= 0;
						s_lostdata <= 0;
						s_drq_busy <= 2'b11;
						state <= 32'd8;
					end
				end
				32'd8:
					if (watchdog_bark | (read_data & s_drq)) begin
						s_drq_busy <= 2'b01;
						s_lostdata <= watchdog_bark;
						if (next_length == 0) begin
							if (multisector) begin
								wdreg_sector <= wdreg_sector + 1'b1;
								state <= 32'd1;
							end
							else
								state <= 32'd19;
						end
						else begin
							byte_addr <= byte_addr + 1'd1;
							data_length <= next_length;
							state <= 32'd6;
						end
					end
				32'd10:
					if (s_ready) begin
						s_wrfault <= 1;
						state <= 32'd19;
					end
					else begin
						sd_block <= 0;
						state <= 32'd11;
					end
				32'd11: begin
					sd_busy <= 1;
					sd_wr <= 1;
					state <= 32'd12;
				end
				32'd12:
					if (!sd_busy) begin
						sd_block <= sd_block + 1'd1;
						if (sd_block < blk_max)
							state <= 32'd11;
						else if ((format && var_size) && !edsk_next)
							state <= 32'd19;
						else if (multisector) begin
							edsk_addr <= edsk_next;
							wdreg_sector <= wdreg_sector + 1'b1;
							state <= 32'd1;
						end
						else
							state <= 32'd19;
					end
				32'd13: begin
					watchdog_set <= 1;
					read_timer <= 15;
					state <= 32'd14;
				end
				32'd14: begin
					read_timer <= read_timer - 1'b1;
					if (!read_timer) begin
						write_data <= 0;
						watchdog_set <= 0;
						s_lostdata <= 0;
						s_drq_busy <= 2'b11;
						state <= 32'd15;
					end
				end
				32'd15:
					if (watchdog_bark | (write_data & s_drq)) begin
						s_drq_busy <= 2'b01;
						s_lostdata <= watchdog_bark;
						if (!next_length)
							state <= 32'd10;
						else begin
							byte_addr <= byte_addr + 1'd1;
							data_length <= next_length;
							state <= 32'd13;
						end
					end
				32'd16: begin
					data_length <= 0;
					{s_wrfault, RNF, s_crcerr, s_lostdata} <= 0;
					state <= 32'd19;
				end
				32'd17: begin
					wait_time <= step_rate_clk;
					state <= 32'd18;
				end
				32'd18:
					if (wait_time)
						wait_time <= wait_time - 1;
					else
						state <= 32'd19;
				32'd19: begin
					format <= 0;
					buff_rd <= 0;
					buff_wr <= 0;
					state <= 32'd0;
					s_drq_busy <= 2'b00;
					seektimer <= 'h3ff;
					s_intrq <= 1;
				end
			endcase
			if (!old_wr & wre)
				case (addr)
					A_COMMAND: begin
						s_intrq <= 0;
						cmd <= din;
						if ((state == 32'd0) | (din[7:4] == 'hd)) begin
							cmd_type_1 <= din[7] == 1'b0;
							cmd_type_2 <= din[7:6] == 2'b10;
							cmd_type_3 <= (din[7:5] == 3'b111) || (din[7:4] == 4'b1100);
							cmd_type_4 <= din[7:4] == 4'b1101;
							cmd_type_wr <= (din[7:5] == 3'b101) || (din[7:4] == 4'b1111);
							s_wpe <= ~din[7];
							s_motor_tick <= ((cmd_type_1 || cmd_type_2) || cmd_type_3 ? 1'b1 : 1'b0);
							case (din[7:4])
								'h0: begin
									s_headloaded <= din[3];
									wdreg_track <= 0;
									wdreg_sector <= 1;
									ra_sector <= 1;
									disk_track <= 0;
									RNF <= 0;
									s_drq_busy <= 2'b01;
									state <= 32'd17;
								end
								'h1: begin
									disk_track <= wdreg_data;
									s_headloaded <= din[3];
									wdreg_track <= wdreg_data;
									s_drq_busy <= 2'b01;
									state <= 32'd17;
								end
								'h2, 'h3, 'h4, 'h5, 'h6, 'h7: begin
									if (din[6] == 1)
										step_direction <= din[5];
									disk_track <= next_track;
									if (din[4])
										wdreg_track <= next_track;
									s_headloaded <= din[3];
									s_drq_busy <= 2'b01;
									state <= 32'd17;
								end
								'h8, 'h9, 'ha, 'hb, 'hf: begin
									s_drq_busy <= 2'b01;
									{s_wrfault, RNF, s_crcerr, s_lostdata} <= 0;
									{write, buff_rd} <= (din[5] ? 2'b10 : 2'b01);
									buff_wr <= din[5];
									if (din[6])
										wdreg_sector <= 1;
									format <= din[6];
									multisector <= din[4];
									rw_type <= 1;
									write_data <= 0;
									read_data <= 0;
									edsk_start <= 0;
									edsk_addr <= 0;
									state <= 32'd1;
									s_wpe <= din[5];
									if (s_readonly & din[5]) begin
										s_wrfault <= 1;
										state <= 32'd17;
									end
								end
								'hc: begin
									s_drq_busy <= 2'b01;
									{s_wrfault, RNF, s_crcerr, s_lostdata} <= 0;
									{write, buff_rd} <= 0;
									buff_wr <= 0;
									format <= 0;
									multisector <= 0;
									rw_type <= 0;
									read_data <= 0;
									edsk_start <= edsk_next;
									data_length <= 6;
									read_addr[0] <= disk_track;
									read_addr[1] <= {7'b0000000, side};
									read_addr[2] <= 1;
									read_addr[3] <= wd_size_code;
									read_addr[4] <= 8'h00;
									read_addr[5] <= 8'h00;
									if (ra_sector >= sectors_per_track)
										ra_sector <= 1;
									else
										ra_sector <= ra_sector + 1'd1;
									state <= 32'd1;
								end
								'hd:
									if (state != 32'd0)
										state <= 32'd16;
									else
										{s_wrfault, RNF, s_crcerr, s_lostdata, s_drq_busy} <= 0;
								'he: begin
									{s_wrfault, s_crcerr} <= 0;
									RNF <= 1;
									s_lostdata <= 1;
									s_drq_busy <= 2'b01;
									state <= 32'd17;
								end
							endcase
						end
					end
					A_TRACK:
						if (!s_busy)
							wdreg_track <= din;
					A_SECTOR:
						if (!s_busy)
							{ra_sector, wdreg_sector} <= {din, din};
					A_DATA: wdreg_data <= din;
				endcase
		end
	end
	generate
		if (EDSK) begin : genblk1
			wire [7:0] scan_data = buff_dout;
			reg [54:0] edsk [0:1991];
			reg [7:0] spt [0:165];
			always @(posedge clk_sys) begin
				{edsk_track, edsk_side, edsk_trackf, edsk_sidef, edsk_sector, edsk_sizecode, edsk_offset} <= edsk[edsk_addr];
				edsk_spt <= spt[spt_addr];
			end
			reg [7:0] tpos;
			reg [7:0] tsize;
			reg [7:0] tsizes [0:165];
			always @(posedge clk_sys) tsize <= tsizes[tpos];
			wire [127:0] edsk_sig = "EXTENDED CPC DSK";
			wire [127:0] sig_pos = edsk_sig >> (8'd120 - (scan_addr[7:0] << 3));
			always @(posedge clk_sys) begin : sv2v_autoblock_3
				reg old_active;
				reg old_wr;
				reg [13:0] hdr_pos;
				reg [13:0] bcnt;
				reg [7:0] idStatus;
				reg [6:0] track;
				reg side;
				reg [7:0] sector;
				reg [1:0] sizecode;
				reg [7:0] crc1;
				reg [7:0] crc2;
				reg [7:0] sectors;
				reg [15:0] track_size;
				reg [15:0] track_pos;
				reg [20:0] offset;
				reg [20:0] offset1;
				reg [7:0] size_lo;
				reg [10:0] secpos;
				reg [7:0] trackf;
				reg [7:0] sidef;
				old_active <= scan_active;
				if (scan_active & ~old_active) begin
					edsk_size <= 0;
					spt_size <= 0;
					track_pos <= 0;
					var_size <= 1;
				end
				old_wr <= scan_wr;
				if ((scan_wr & ~old_wr) & scan_active) begin
					if ((scan_addr[20:0] < 16) & (sig_pos[7:0] != scan_data))
						var_size <= 0;
					if (var_size)
						if (scan_addr == 48)
							spt_size <= scan_data;
						else if ((scan_addr == 49) & (scan_data == 2))
							spt_size <= spt_size << 1;
						else if (scan_addr == 52) begin
							track_size <= {scan_data, 8'd0};
							track_pos <= 0;
							tpos <= 1;
						end
						else if ((scan_addr > 52) & (scan_addr < 218)) begin
							tsizes[scan_addr - 52] <= scan_data;
							spt[scan_addr - 52] <= 0;
						end
						else if ((scan_addr >= 256) && track_size) begin
							track_pos <= track_pos + 1'd1;
							case (track_pos)
								0: offset <= scan_addr + 9'd256;
								16: track <= scan_data[6:0];
								17: side <= scan_data[0];
								21: sectors <= scan_data;
								22: spt[(side ? spt_size >> 1 : 8'd0) + track] <= sectors;
								default:
									if ((track_pos >= 24) && sectors)
										case (track_pos[2:0])
											0: begin
												trackf <= scan_data;
												secpos <= edsk_size;
												offset1 <= offset;
											end
											1: sidef <= scan_data;
											2: sector <= scan_data;
											3: sizecode <= scan_data[1:0];
											6: size_lo <= scan_data;
											7: begin
												if ({scan_data, size_lo}) begin
													edsk[secpos] <= {track, side, trackf, sidef, sector, sizecode, offset1};
													edsk_size <= edsk_size + 1'd1;
													offset <= offset + {scan_data, size_lo};
												end
												sectors <= sectors - 1'd1;
											end
											default:
												;
										endcase
							endcase
							if (track_pos >= (track_size - 1'd1)) begin
								track_size <= {tsize, 8'd0};
								track_pos <= 0;
								tpos <= tpos + 1'd1;
							end
						end
				end
			end
		end
	endgenerate
endmodule
module wd177x_dpram (
	clock,
	address_a,
	data_a,
	wren_a,
	q_a,
	address_b,
	data_b,
	wren_b,
	q_b
);
	parameter DATAWIDTH = 8;
	parameter ADDRWIDTH = 12;
	input clock;
	input [ADDRWIDTH - 1:0] address_a;
	input [DATAWIDTH - 1:0] data_a;
	input wren_a;
	output reg [DATAWIDTH - 1:0] q_a;
	input [ADDRWIDTH - 1:0] address_b;
	input [DATAWIDTH - 1:0] data_b;
	input wren_b;
	output reg [DATAWIDTH - 1:0] q_b;
	reg [DATAWIDTH - 1:0] ram [0:(1 << ADDRWIDTH) - 1];
	always @(posedge clock)
		if (wren_a) begin
			ram[address_a] <= data_a;
			q_a <= data_a;
		end
		else
			q_a <= ram[address_a];
	always @(posedge clock)
		if (wren_b) begin
			ram[address_b] <= data_b;
			q_b <= data_b;
		end
		else
			q_b <= ram[address_b];
endmodule
