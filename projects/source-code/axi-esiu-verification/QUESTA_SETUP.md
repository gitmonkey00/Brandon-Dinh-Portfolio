# Questa/ModelSim Setup Guide

## Prerequisites

1. **Questa Sim or ModelSim installed**
   - Questa Sim 2020.1 or later (recommended)
   - ModelSim PE/SE 2020.1 or later

2. **UVM Library**
   - Questa 10.1+ has UVM built-in
   - If not, UVM 1.2 should be available at `$UVM_HOME`

3. **Environment Setup**
   ```bash
   # Check if Questa is in PATH
   which vsim
   
   # Check UVM availability
   vsim -version
   # Should show UVM version
   ```

---

## Quick Start - Method 1: Using Questa Script (Easiest)

```bash
# Make script executable
chmod +x run_questa.sh

# Run default comprehensive test
./run_questa.sh

# Run specific test
./run_questa.sh axi_fault_test
```

---

## Quick Start - Method 2: Using Makefile

```bash
# Use the Questa-optimized Makefile
cp Makefile.questa Makefile

# Show help
make help

# Compile
make compile

# Run simulation
make sim

# Run with GUI
make gui

# Run specific test
make sim TEST=axi_random_test
```

---

## Manual Compilation (Step-by-Step)

### Step 1: Create Work Library
```bash
vlib work
vmap work work
```

### Step 2: Compile Files in Order

**IMPORTANT: Files must be compiled in this exact order!**

```bash
# 1. Interface (no dependencies)
vlog -sv -timescale=1ns/1ps axi_if.sv

# 2. DUT (depends on interface)
vlog -sv -timescale=1ns/1ps esiu_dut.sv

# 3. UVM Package (contains all verification components)
vlog -sv -timescale=1ns/1ps +incdir+$UVM_HOME/src axi_uvm_pkg.sv

# 4. Testbench Top (depends on everything)
vlog -sv -timescale=1ns/1ps +incdir+$UVM_HOME/src tb_top.sv
```

### Step 3: Run Simulation

**Batch Mode:**
```bash
vsim -c +UVM_TESTNAME=axi_comprehensive_test tb_top -do "run -all; quit -f"
```

**GUI Mode:**
```bash
vsim +UVM_TESTNAME=axi_comprehensive_test tb_top
# Then in GUI: run -all
```

---

## Common Questa Issues and Fixes

### Issue 1: "UVM_HOME not found"
**Solution:**
```bash
# Questa has built-in UVM, find it:
export UVM_HOME=$QUESTA_HOME/verilog_src/uvm-1.2

# Or for ModelSim:
export UVM_HOME=/path/to/uvm-1.2
```

### Issue 2: "Package axi_uvm_pkg not found"
**Solution:**
Compile files in the correct order (see Step 2 above). The package MUST be compiled before tb_top.

### Issue 3: "Virtual interface not found"
**Solution:**
Make sure axi_if.sv compiles without errors before compiling other files.

### Issue 4: Compilation warnings about timescale
**Solution:**
All files use `-timescale=1ns/1ps` flag. This is already included in the scripts.

### Issue 5: "Fatal: (vsim-3807) Types do not match"
**Solution:**
Clean and recompile everything:
```bash
rm -rf work
make compile
```

---

## Viewing Results

### Check Simulation Output
```bash
# View transcript
cat transcript

# Look for:
# - "TEST PASSED" or "TEST FAILED"
# - Transaction counts
# - UVM report summary
```

### View Waveforms
```bash
# If waves.vcd was generated:
vsim -view waves.vcd

# Or use GTKWave:
gtkwave waves.vcd
```

### Generate Coverage Report (if ran with coverage)
```bash
# After running: make coverage
vcover report -html coverage.ucdb

# Open report
firefox covhtmlreport/index.html
```

---

## File Compilation Order Diagram

```
┌─────────────┐
│  axi_if.sv  │  ← Compile FIRST (no dependencies)
└──────┬──────┘
       │
       ↓
┌─────────────┐
│esiu_dut.sv  │  ← Compile SECOND (uses interface)
└──────┬──────┘
       │
       ↓
┌──────────────┐
│axi_uvm_pkg.sv│  ← Compile THIRD (package with all UVM components)
└──────┬───────┘
       │
       ↓
┌─────────────┐
│ tb_top.sv   │  ← Compile LAST (imports package, instantiates everything)
└─────────────┘
```

---

## Available Tests

Run any of these tests by setting `TEST` parameter:

| Test Name | Command | Description |
|-----------|---------|-------------|
| `axi_write_read_test` | `make sim TEST=axi_write_read_test` | Basic write-read verification |
| `axi_random_test` | `make sim TEST=axi_random_test` | Constrained random testing |
| `axi_back2back_test` | `make sim TEST=axi_back2back_test` | Back-to-back transactions |
| `axi_fault_test` | `make sim TEST=axi_fault_test` | Fault injection |
| `axi_comprehensive_test` | `make sim` | All tests (DEFAULT) |

---

## Expected Output

When simulation runs successfully, you should see:

```
# UVM_INFO @ 0: reporter [RNTST] Running test axi_comprehensive_test...
# UVM_INFO @ 0: uvm_test_top [TEST] =========================================
# UVM_INFO @ 0: uvm_test_top [TEST]    COMPREHENSIVE VERIFICATION SUITE    
# UVM_INFO @ 0: uvm_test_top [TEST] =========================================
# ... (transactions executing) ...
# UVM_INFO @ XXXns: uvm_test_top.env.scoreboard [SCOREBOARD] ==================
# UVM_INFO @ XXXns: uvm_test_top.env.scoreboard [SCOREBOARD] Total Transactions: 237
# UVM_INFO @ XXXns: uvm_test_top.env.scoreboard [SCOREBOARD] Passed: 237
# UVM_INFO @ XXXns: uvm_test_top.env.scoreboard [SCOREBOARD] Failed: 0
# UVM_INFO @ XXXns: uvm_test_top.env.scoreboard [SCOREBOARD] *** TEST PASSED ***
# =========================================
#           TEST PASSED                   
# =========================================
```

---

## Troubleshooting Checklist

- [ ] Questa/ModelSim in PATH? (`which vsim`)
- [ ] UVM available? (`vsim -version` shows UVM)
- [ ] Compiled in correct order?
- [ ] Work library created? (`ls -la work/`)
- [ ] No compilation errors? (check for `**Error:` in output)
- [ ] Using correct test name? (see Available Tests table)

---

## Next Steps

After successful simulation:

1. **View waveforms** to understand protocol timing
2. **Check scoreboard output** for pass/fail statistics
3. **Run different tests** to verify corner cases
4. **Generate coverage report** to identify gaps
5. **Modify sequences** to add your own test scenarios

---

## Getting Help

If you encounter issues:

1. Check `transcript` file for error messages
2. Ensure compilation order is correct
3. Clean and rebuild: `make clean && make compile`
4. Check Questa version: `vsim -version`
5. Verify UVM path: `echo $UVM_HOME`
