derive_pll_clocks
derive_clock_uncertainty

create_clock -name clock50 -period 20.000 [get_ports {clock50}]
create_clock -name spiCk -period 100.000 [get_ports {spiCk}]
create_clock -name audioCk -period  0.250 [get_registers ep:ep|audio:audio|aCount[0]]

set_clock_groups -asynchronous \
	-group [get_clocks pll32|altpll_component|auto_generated|pll1|clk[0]] \
	-group [get_clocks pll56|altpll_component|auto_generated|pll1|clk[0]] \
	-group [get_clocks audioCk] \
	-group [get_clocks spiCk]

set_false_path -from {ear*}
set_false_path -from {spi*}
set_false_path -from {dram*}

set_false_path -to   {sync*}
set_false_path -to   {vga*}
set_false_path -to   {i2s*}
set_false_path -to   {dram*}
set_false_path -to   {spi*}
set_false_path -to   {led}
