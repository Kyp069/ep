(* CORE_GENERATION_INFO = "clock,clk_wiz_v3_6,{component_name=clock,use_phase_alignment=false,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,feedback_source=FDBK_AUTO,primtype_sel=MMCM_ADV,num_out_clk=1,clkin1_period=20.000,clkin2_period=10.0,use_power_down=false,use_reset=false,use_locked=true,use_inclk_stopped=false,use_status=false,use_freeze=false,use_clk_valid=false,feedback_type=SINGLE,clock_mgr_type=MANUAL,manual_override=false}" *)
//-------------------------------------------------------------------------------------------------
module mmcm
//-------------------------------------------------------------------------------------------------
(
	input  wire clock50,
	output wire clock56,
	output wire clock32,
	output wire clock64,
	output wire locked
 );
//-------------------------------------------------------------------------------------------------

wire ci50;
IBUF ibuf(.I(clock50), .O(ci50));

wire co56, fb56, lc56;
MMCME2_ADV #
(
	.BANDWIDTH            ("OPTIMIZED"),
	.CLKOUT4_CASCADE      ("FALSE"    ),
	.COMPENSATION         ("ZHOLD"    ),
	.STARTUP_WAIT         ("FALSE"    ),
	.DIVCLK_DIVIDE        (2          ),
	.CLKFBOUT_MULT_F      (37.875     ),
	.CLKFBOUT_PHASE       ( 0.000     ),
	.CLKFBOUT_USE_FINE_PS ("FALSE"    ),
	.CLKOUT0_DIVIDE_F     (16.625     ),
	.CLKOUT0_PHASE        ( 0.000     ),
	.CLKOUT0_DUTY_CYCLE   ( 0.500     ),
	.CLKOUT0_USE_FINE_PS  ("FALSE"    ),
	.CLKIN1_PERIOD        (20.000     ),
	.REF_JITTER1          ( 0.010     )
)
mmcm56
(
	.CLKIN1              (ci50),
	.CLKIN2              (1'b0),

	.CLKFBIN             (fb56),
	.CLKFBOUT            (fb56),

	.CLKFBOUTB           (),
	.CLKOUT0             (co56),
	.CLKOUT0B            (),
	.CLKOUT1             (),
	.CLKOUT1B            (),
	.CLKOUT2             (),
	.CLKOUT2B            (),
	.CLKOUT3             (),
	.CLKOUT3B            (),
	.CLKOUT4             (),
	.CLKOUT5             (),
	.CLKOUT6             (),

	.CLKINSEL            ( 1'b1),
	.DADDR               ( 7'h0),
	.DCLK                ( 1'b0),
	.DEN                 ( 1'b0),
	.DWE                 ( 1'b0),
	.DI                  (16'h0),
	.DO                  (),
	.DRDY                (),

	.PSCLK               (1'b0),
	.PSEN                (1'b0),
	.PSINCDEC            (1'b0),
	.PSDONE              (),

	.RST                 (1'b0),
	.LOCKED              (lc56),
	.PWRDWN              (1'b0),
	.CLKINSTOPPED        (),
	.CLKFBSTOPPED        ()
);

BUFG bufg56(.I(co56), .O(clock56));

wire co32, co64, fb32, lc32;

MMCME2_ADV #
(
	.CLKIN1_PERIOD        (20.000     ),
	.DIVCLK_DIVIDE        ( 5         ),
	.CLKFBOUT_MULT_F      (64.000     ),
	.CLKOUT0_DIVIDE_F     (20.000     ),
	.CLKOUT1_DIVIDE       (10         )
)
mmcm32
(
	.CLKIN1              (ci50),
	.CLKIN2              (1'b0),

	.CLKFBIN             (fb32),
	.CLKFBOUT            (fb32),

	.CLKFBOUTB           (),
	.CLKOUT0             (co32),
	.CLKOUT0B            (),
	.CLKOUT1             (co64),
	.CLKOUT1B            (),
	.CLKOUT2             (),
	.CLKOUT2B            (),
	.CLKOUT3             (),
	.CLKOUT3B            (),
	.CLKOUT4             (),
	.CLKOUT5             (),
	.CLKOUT6             (),

	.CLKINSEL            ( 1'b1),
	.DADDR               ( 7'h0),
	.DCLK                ( 1'b0),
	.DEN                 ( 1'b0),
	.DWE                 ( 1'b0),
	.DI                  (16'h0),
	.DO                  (),
	.DRDY                (),

	.PSCLK               (1'b0),
	.PSEN                (1'b0),
	.PSINCDEC            (1'b0),
	.PSDONE              (),

	.RST                 (1'b0),
	.LOCKED              (lc32),
	.PWRDWN              (1'b0),
	.CLKINSTOPPED        (),
	.CLKFBSTOPPED        ()
);

BUFG bufg32(.I(co32), .O(clock32));
BUFG bufg64(.I(co64), .O(clock64));

assign locked = lc56 & lc32;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
