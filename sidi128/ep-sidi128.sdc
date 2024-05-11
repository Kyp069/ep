derive_pll_clocks
derive_clock_uncertainty

create_clock -name clock50 -period 20.000 [get_ports {clock50}]
create_clock -name spiCk   -period 41.666 -waveform { 20.8 41.666 } [get_ports {spiCk}]
create_clock -name audioCk -period  0.250 [get_registers ep:ep|audio:audio|aCount[0]]

set sdram_clk "pll32|altpll_component|auto_generated|pll1|clk[0]"

set_clock_groups -asynchronous \
	-group [get_clocks pll32|altpll_component|auto_generated|pll1|clk[0]] \
	-group [get_clocks pll56|altpll_component|auto_generated|pll1|clk[0]] \
	-group [get_clocks audioCk] \
	-group [get_clocks spiCk]

set_input_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports {dramCk}] -max 6.4 [get_ports dramDQ[*]]
set_input_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports {dramCk}] -min 3.2 [get_ports dramDQ[*]]

set_output_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports {dramCk}] -max 1.5 [get_ports {dramDQ* dramA* dramBA* dramRas dramCas dramWe}]
set_output_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports {dramCk}] -min -0.8 [get_ports {dramDQ* dramA* dramBA* dramRas dramCas dramWe}]

set_false_path -from {ear*}
set_false_path -from {spi*}
set_false_path -from {dram*}

set_false_path -to   {sync*}
set_false_path -to   {vga*}
set_false_path -to   {i2s*}
set_false_path -to   {spi*}
set_false_path -to   {led}
