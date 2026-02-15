//==============================================================================
// AXI4-Lite UVM Scoreboard
// Author: Brandon Dinh
// Description: Self-checking scoreboard with reference model
//==============================================================================

class axi_scoreboard extends uvm_scoreboard;
    
    `uvm_component_utils(axi_scoreboard)
    
    // Analysis port to receive transactions from monitor
    uvm_analysis_imp #(axi_transaction, axi_scoreboard) sb_imp;
    
    // Reference model - shadow registers
    bit [31:0] expected_temp_reg;
    bit [31:0] expected_press_reg;
    bit [31:0] expected_config_reg;
    bit [31:0] expected_status_reg;
    
    // Statistics
    int num_transactions;
    int num_passed;
    int num_failed;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "axi_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        sb_imp = new("sb_imp", this);
    endfunction
    
    //==========================================================================
    // Build Phase
    //==========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Initialize expected registers
        expected_temp_reg = 32'h0;
        expected_press_reg = 32'h0;
        expected_config_reg = 32'h0;
        expected_status_reg = 32'h0;
        
        num_transactions = 0;
        num_passed = 0;
        num_failed = 0;
    endfunction
    
    //==========================================================================
    // Write function - Called by monitor via analysis port
    //==========================================================================
    function void write(axi_transaction trans);
        num_transactions++;
        
        `uvm_info("SCOREBOARD", $sformatf("Received transaction #%0d: %s", 
                  num_transactions, trans.convert2string()), UVM_MEDIUM)
        
        if (trans.trans_type == axi_transaction::WRITE) begin
            check_write_transaction(trans);
        end else begin
            check_read_transaction(trans);
        end
    endfunction
    
    //==========================================================================
    // Check Write Transaction
    //==========================================================================
    function void check_write_transaction(axi_transaction trans);
        bit status_ok = 1;
        
        // Check response code
        case (trans.addr)
            32'h0: begin  // TEMP_DATA
                if (trans.resp == 2'b00) begin  // OKAY
                    expected_temp_reg = trans.data;
                    `uvm_info("SCOREBOARD", $sformatf("PASS: Write to TEMP_DATA: 0x%0h", trans.data), UVM_MEDIUM)
                    num_passed++;
                end else begin
                    `uvm_error("SCOREBOARD", $sformatf("FAIL: Unexpected RESP for TEMP_DATA write: %0d", trans.resp))
                    num_failed++;
                    status_ok = 0;
                end
            end
            
            32'h4: begin  // PRESS_DATA
                if (trans.resp == 2'b00) begin
                    expected_press_reg = trans.data;
                    `uvm_info("SCOREBOARD", $sformatf("PASS: Write to PRESS_DATA: 0x%0h", trans.data), UVM_MEDIUM)
                    num_passed++;
                end else begin
                    `uvm_error("SCOREBOARD", $sformatf("FAIL: Unexpected RESP for PRESS_DATA write: %0d", trans.resp))
                    num_failed++;
                    status_ok = 0;
                end
            end
            
            32'h8: begin  // CONFIG
                if (trans.resp == 2'b00) begin
                    expected_config_reg = trans.data;
                    `uvm_info("SCOREBOARD", $sformatf("PASS: Write to CONFIG: 0x%0h", trans.data), UVM_MEDIUM)
                    num_passed++;
                end else begin
                    `uvm_error("SCOREBOARD", $sformatf("FAIL: Unexpected RESP for CONFIG write: %0d", trans.resp))
                    num_failed++;
                    status_ok = 0;
                end
            end
            
            32'hC: begin  // STATUS (Read-only)
                if (trans.resp == 2'b10) begin  // SLVERR expected
                    `uvm_info("SCOREBOARD", "PASS: Write to read-only STATUS register correctly returned SLVERR", UVM_MEDIUM)
                    num_passed++;
                end else begin
                    `uvm_error("SCOREBOARD", $sformatf("FAIL: Write to STATUS should return SLVERR, got: %0d", trans.resp))
                    num_failed++;
                    status_ok = 0;
                end
            end
            
            default: begin
                if (trans.resp == 2'b10) begin  // SLVERR expected for invalid address
                    `uvm_info("SCOREBOARD", $sformatf("PASS: Invalid address 0x%0h correctly returned SLVERR", trans.addr), UVM_MEDIUM)
                    num_passed++;
                end else begin
                    `uvm_error("SCOREBOARD", $sformatf("FAIL: Invalid address should return SLVERR, got: %0d", trans.resp))
                    num_failed++;
                    status_ok = 0;
                end
            end
        endcase
    endfunction
    
    //==========================================================================
    // Check Read Transaction
    //==========================================================================
    function void check_read_transaction(axi_transaction trans);
        bit [31:0] expected_data;
        bit data_match;
        
        // Determine expected data based on address
        case (trans.addr)
            32'h0: expected_data = expected_temp_reg;
            32'h4: expected_data = expected_press_reg;
            32'h8: expected_data = expected_config_reg;
            32'hC: expected_data = expected_status_reg;  // Note: Status is dynamic
            default: expected_data = 32'h0;
        endcase
        
        // For STATUS register, we can't predict exact value, so just check RESP
        if (trans.addr == 32'hC) begin
            if (trans.resp == 2'b00) begin
                `uvm_info("SCOREBOARD", $sformatf("PASS: Read from STATUS: 0x%0h (dynamic, RESP OK)", trans.data), UVM_MEDIUM)
                num_passed++;
            end else begin
                `uvm_error("SCOREBOARD", $sformatf("FAIL: Read from STATUS returned bad RESP: %0d", trans.resp))
                num_failed++;
            end
        end else begin
            // For other registers, check data matches
            data_match = (trans.data == expected_data);
            
            if (data_match && (trans.resp == 2'b00)) begin
                `uvm_info("SCOREBOARD", $sformatf("PASS: Read from 0x%0h: Expected=0x%0h, Got=0x%0h", 
                          trans.addr, expected_data, trans.data), UVM_MEDIUM)
                num_passed++;
            end else begin
                `uvm_error("SCOREBOARD", $sformatf("FAIL: Read from 0x%0h: Expected=0x%0h, Got=0x%0h, Resp=%0d", 
                           trans.addr, expected_data, trans.data, trans.resp))
                num_failed++;
            end
        end
    endfunction
    
    //==========================================================================
    // Report Phase
    //==========================================================================
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("SCOREBOARD", "========================================", UVM_LOW)
        `uvm_info("SCOREBOARD", "     VERIFICATION RESULTS SUMMARY       ", UVM_LOW)
        `uvm_info("SCOREBOARD", "========================================", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Total Transactions: %0d", num_transactions), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Passed: %0d", num_passed), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Failed: %0d", num_failed), UVM_LOW)
        
        if (num_failed == 0) begin
            `uvm_info("SCOREBOARD", "*** TEST PASSED ***", UVM_LOW)
        end else begin
            `uvm_error("SCOREBOARD", "*** TEST FAILED ***")
        end
        `uvm_info("SCOREBOARD", "========================================", UVM_LOW)
    endfunction

endclass
