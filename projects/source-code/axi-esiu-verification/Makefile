#==============================================================================
# Makefile for AXI4-Lite UVM Verification
# Author: Brandon Dinh
#==============================================================================

# Simulator (change to vcs if using Synopsys VCS)
SIM = questa

# Directories
RTL_DIR = .
TB_DIR = .
SIM_DIR = sim

# UVM Home (adjust path as needed)
UVM_HOME ?= /usr/share/uvm-1.2

# Compilation flags
VLOG_FLAGS = -sv +incdir+$(UVM_HOME)/src
VSIM_FLAGS = -voptargs=+acc -classdebug +UVM_TESTNAME=$(TEST) -do "run -all; quit"

# Source files
RTL_FILES = $(RTL_DIR)/esiu_dut.sv
TB_FILES = $(TB_DIR)/axi_if.sv \
           $(TB_DIR)/axi_uvm_pkg.sv \
           $(TB_DIR)/tb_top.sv

# Default test
TEST ?= axi_comprehensive_test

# Targets
.PHONY: all compile sim clean help

all: compile

help:
	@echo "========================================="
	@echo "  AXI4-Lite UVM Verification Makefile   "
	@echo "========================================="
	@echo "Usage:"
	@echo "  make compile              - Compile all files"
	@echo "  make sim TEST=<testname>  - Run simulation"
	@echo "  make clean                - Clean simulation files"
	@echo ""
	@echo "Available tests:"
	@echo "  - axi_write_read_test"
	@echo "  - axi_random_test"
	@echo "  - axi_back2back_test"
	@echo "  - axi_fault_test"
	@echo "  - axi_comprehensive_test (default)"
	@echo ""
	@echo "Examples:"
	@echo "  make sim"
	@echo "  make sim TEST=axi_fault_test"
	@echo "========================================="

compile:
	@echo "Compiling RTL and Testbench..."
	mkdir -p $(SIM_DIR)
	cd $(SIM_DIR) && vlib work
	cd $(SIM_DIR) && vlog $(VLOG_FLAGS) $(RTL_FILES) $(TB_FILES)
	@echo "Compilation complete!"

sim: compile
	@echo "Running test: $(TEST)"
	cd $(SIM_DIR) && vsim $(VSIM_FLAGS) tb_top
	@echo "Simulation complete!"

# Run with GUI
gui: compile
	@echo "Running test: $(TEST) with GUI"
	cd $(SIM_DIR) && vsim -gui +UVM_TESTNAME=$(TEST) tb_top

# Generate coverage report
cov: compile
	@echo "Running test with coverage: $(TEST)"
	cd $(SIM_DIR) && vsim $(VSIM_FLAGS) -coverage tb_top
	cd $(SIM_DIR) && vcover report -html fcover.ucdb
	@echo "Coverage report generated in sim/covhtmlreport/"

# Run all tests
regression:
	@echo "Running regression with all tests..."
	make sim TEST=axi_write_read_test
	make sim TEST=axi_random_test
	make sim TEST=axi_back2back_test
	make sim TEST=axi_fault_test
	make sim TEST=axi_comprehensive_test
	@echo "Regression complete!"

clean:
	@echo "Cleaning simulation files..."
	rm -rf $(SIM_DIR)
	rm -f transcript *.log *.vcd waves.vcd
	@echo "Clean complete!"

.DEFAULT_GOAL := help
