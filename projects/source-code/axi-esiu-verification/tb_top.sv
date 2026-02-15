//==============================================================================
// Testbench Top Module
// Author: Brandon Dinh
// Description: Top-level module that instantiates DUT, interface, and runs UVM test
//==============================================================================

`timescale 1ns/1ps

module tb_top;

    // Import UVM package and our verification package
    import uvm_pkg::*;
    import axi_uvm_pkg::*;
    `include "uvm_macros.svh"
    
    //==========================================================================
    // Clock and Reset Generation
    //==========================================================================
    logic aclk;
    logic aresetn;
    
    // Clock generation: 100MHz (10ns period)
    initial begin
        aclk = 0;
        forever #5ns aclk = ~aclk;
    end
    
    // Reset generation
    initial begin
        aresetn = 0;
        repeat(5) @(posedge aclk);
        aresetn = 1;
        `uvm_info("TB_TOP", "Reset released", UVM_LOW)
    end
    
    //==========================================================================
    // Interface Instantiation
    //==========================================================================
    axi_if axi_vif (
        .aclk(aclk),
        .aresetn(aresetn)
    );
    
    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    
    // Simulated sensor inputs
    logic [31:0] sensor_temp_data;
    logic [31:0] sensor_press_data;
    logic        sensor_temp_valid;
    logic        sensor_press_valid;
    
    // Simple sensor data generator (simulates real sensors)
    initial begin
        sensor_temp_data  = 32'h0;
        sensor_press_data = 32'h0;
        sensor_temp_valid = 1'b0;
        sensor_press_valid = 1'b0;
        
        @(posedge aresetn);
        
        forever begin
            @(posedge aclk);
            // Generate random sensor data
            sensor_temp_data  = $urandom_range(0, 1200);  // Some in range, some out
            sensor_press_data = $urandom_range(0, 2500);
            sensor_temp_valid = $urandom_range(0, 1);
            sensor_press_valid = $urandom_range(0, 1);
        end
    end
    
    // DUT instantiation
    esiu_dut dut (
        // Clock and Reset
        .aclk(axi_vif.aclk),
        .aresetn(axi_vif.aresetn),
        
        // AXI4-Lite Write Address Channel
        .awaddr(axi_vif.awaddr),
        .awvalid(axi_vif.awvalid),
        .awready(axi_vif.awready),
        
        // AXI4-Lite Write Data Channel
        .wdata(axi_vif.wdata),
        .wstrb(axi_vif.wstrb),
        .wvalid(axi_vif.wvalid),
        .wready(axi_vif.wready),
        
        // AXI4-Lite Write Response Channel
        .bresp(axi_vif.bresp),
        .bvalid(axi_vif.bvalid),
        .bready(axi_vif.bready),
        
        // AXI4-Lite Read Address Channel
        .araddr(axi_vif.araddr),
        .arvalid(axi_vif.arvalid),
        .arready(axi_vif.arready),
        
        // AXI4-Lite Read Data Channel
        .rdata(axi_vif.rdata),
        .rresp(axi_vif.rresp),
        .rvalid(axi_vif.rvalid),
        .rready(axi_vif.rready),
        
        // Sensor Interface
        .sensor_temp_data(sensor_temp_data),
        .sensor_press_data(sensor_press_data),
        .sensor_temp_valid(sensor_temp_valid),
        .sensor_press_valid(sensor_press_valid)
    );
    
    //==========================================================================
    // UVM Configuration and Test Execution
    //==========================================================================
    initial begin
        // Set virtual interface in config DB
        uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_vif);
        
        // Enable waveform dumping
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_top);
        
        // Run the test
        run_test();
    end
    
    //==========================================================================
    // Timeout Watchdog
    //==========================================================================
    initial begin
        #10ms;  // 10 millisecond timeout
        `uvm_fatal("TIMEOUT", "Test timed out after 10ms!")
        $finish;
    end

endmodule
