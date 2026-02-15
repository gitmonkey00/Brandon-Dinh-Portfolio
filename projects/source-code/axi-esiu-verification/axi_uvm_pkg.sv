//==============================================================================
// AXI4-Lite UVM Package
// Author: Brandon Dinh
// Description: Package containing all UVM verification components
//==============================================================================

package axi_uvm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    //==========================================================================
    // Include all verification components in order
    //==========================================================================
    
    // Transaction
    `include "axi_transaction.sv"
    
    // Driver
    `include "axi_driver.sv"
    
    // Monitor
    `include "axi_monitor.sv"
    
    // Scoreboard
    `include "axi_scoreboard.sv"
    
    // Agent
    `include "axi_agent.sv"
    
    // Environment
    `include "axi_env.sv"
    
    // Sequences
    `include "axi_sequences.sv"
    
    // Tests
    `include "axi_test.sv"

endpackage
