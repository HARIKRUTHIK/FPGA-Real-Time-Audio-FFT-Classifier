# ==============================================================================
# ModelSim Batch Simulation Script for FPGA Audio FFT Classifier
# Compatible: ModelSim SE / Intel FPGA Edition 10.5+ / QuestaSim
# ==============================================================================

vlib work
vmap work work

echo ">>> Compiling Audio Classifier RTL Suite..."
vlog rtl/*.v

echo ">>> Testing Sample Generator Block..."
vlog tb/tb_sample_gen.v
vsim -c -do "run -all; quit" tb_sample_gen

echo ">>> Testing Magnitude Approximator Block..."
vlog tb/tb_magnitude_block.v
vsim -c -do "run -all; quit" tb_magnitude_block

echo ">>> Testing Acoustic Energy Classifier Block..."
vlog tb/tb_detection_block.v
vsim -c -do "run -all; quit" tb_detection_block

echo "=========================================================================="
echo ">>> All Audio Classifier verification testbenches executed successfully."
echo "=========================================================================="
quit -f
