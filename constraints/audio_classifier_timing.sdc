# ==============================================================================
# SDC Timing Constraints for FPGA Audio FFT Classifier
# Target: Intel Cyclone IV E EP4CE115F29C7 (DE2-115)
# Base Clock: 50 MHz On-Board Oscillator (20.000 ns Period)
# ==============================================================================

create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

set_clock_uncertainty -setup 0.300 [get_clocks {CLOCK_50}]
set_clock_uncertainty -hold 0.150 [get_clocks {CLOCK_50}]

# Pushbutton Reset and Switch Inputs
set_input_delay -clock CLOCK_50 -max 3.000 [get_ports {KEY* SW*}]
set_input_delay -clock CLOCK_50 -min 0.500 [get_ports {KEY* SW*}]

# Output Constraints for LED and 7-Segment Displays
set_output_delay -clock CLOCK_50 -max 3.000 [get_ports {LEDR* LEDG* HEX*}]
set_output_delay -clock CLOCK_50 -min 0.500 [get_ports {LEDR* LEDG* HEX*}]
