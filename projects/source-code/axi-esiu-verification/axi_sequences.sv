//==============================================================================
// AXI4-Lite UVM Sequences
// Author: Brandon Dinh
// Description: Test sequences for ESIU verification
//==============================================================================

//==============================================================================
// Base Sequence
//==============================================================================
class axi_base_sequence extends uvm_sequence #(axi_transaction);
    
    `uvm_object_utils(axi_base_sequence)
    
    function new(string name = "axi_base_sequence");
        super.new(name);
    endfunction
    
endclass

//==============================================================================
// Simple Write Sequence
//==============================================================================
class axi_write_sequence extends axi_base_sequence;
    
    `uvm_object_utils(axi_write_sequence)
    
    rand bit [31:0] addr;
    rand bit [31:0] data;
    
    function new(string name = "axi_write_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi_transaction trans;
        
        `uvm_info("WRITE_SEQ", $sformatf("Starting write: Addr=0x%0h, Data=0x%0h", addr, data), UVM_MEDIUM)
        
        `uvm_do_with(trans, {
            trans.trans_type == axi_transaction::WRITE;
            trans.addr == local::addr;
            trans.data == local::data;
        })
        
        `uvm_info("WRITE_SEQ", $sformatf("Write complete with response: %0d", trans.resp), UVM_MEDIUM)
    endtask
    
endclass

//==============================================================================
// Simple Read Sequence
//==============================================================================
class axi_read_sequence extends axi_base_sequence;
    
    `uvm_object_utils(axi_read_sequence)
    
    rand bit [31:0] addr;
    bit [31:0] read_data;
    
    function new(string name = "axi_read_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi_transaction trans;
        
        `uvm_info("READ_SEQ", $sformatf("Starting read from Addr=0x%0h", addr), UVM_MEDIUM)
        
        `uvm_do_with(trans, {
            trans.trans_type == axi_transaction::READ;
            trans.addr == local::addr;
        })
        
        read_data = trans.data;
        `uvm_info("READ_SEQ", $sformatf("Read complete: Data=0x%0h, Resp=%0d", read_data, trans.resp), UVM_MEDIUM)
    endtask
    
endclass

//==============================================================================
// Write-Read Sequence (Verify read-back)
//==============================================================================
class axi_write_read_sequence extends axi_base_sequence;
    
    `uvm_object_utils(axi_write_read_sequence)
    
    rand bit [31:0] addr;
    rand bit [31:0] write_data;
    
    constraint valid_addr_c {
        addr inside {32'h0, 32'h4, 32'h8};  // Exclude read-only STATUS register
    }
    
    function new(string name = "axi_write_read_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi_write_sequence wr_seq;
        axi_read_sequence rd_seq;
        
        `uvm_info("WR_RD_SEQ", $sformatf("Write-Read test: Addr=0x%0h, Data=0x%0h", addr, write_data), UVM_MEDIUM)
        
        // Write
        wr_seq = axi_write_sequence::type_id::create("wr_seq");
        wr_seq.addr = addr;
        wr_seq.data = write_data;
        wr_seq.start(m_sequencer);
        
        // Read back
        rd_seq = axi_read_sequence::type_id::create("rd_seq");
        rd_seq.addr = addr;
        rd_seq.start(m_sequencer);
        
        // Check (scoreboard will verify, but can add assertion here)
        if (rd_seq.read_data == write_data) begin
            `uvm_info("WR_RD_SEQ", "PASS: Read data matches written data", UVM_MEDIUM)
        end else begin
            `uvm_error("WR_RD_SEQ", $sformatf("FAIL: Read=0x%0h, Expected=0x%0h", 
                       rd_seq.read_data, write_data))
        end
    endtask
    
endclass

//==============================================================================
// Random Register Access Sequence
//==============================================================================
class axi_random_sequence extends axi_base_sequence;
    
    `uvm_object_utils(axi_random_sequence)
    
    rand int num_transactions;
    
    constraint num_trans_c {
        num_transactions inside {[10:50]};
    }
    
    function new(string name = "axi_random_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi_transaction trans;
        
        `uvm_info("RANDOM_SEQ", $sformatf("Starting %0d random transactions", num_transactions), UVM_MEDIUM)
        
        repeat(num_transactions) begin
            `uvm_do(trans)
            `uvm_info("RANDOM_SEQ", $sformatf("Transaction: %s", trans.convert2string()), UVM_HIGH)
        end
        
        `uvm_info("RANDOM_SEQ", "Random sequence complete", UVM_MEDIUM)
    endtask
    
endclass

//==============================================================================
// Back-to-Back Write Sequence
//==============================================================================
class axi_back2back_write_sequence extends axi_base_sequence;
    
    `uvm_object_utils(axi_back2back_write_sequence)
    
    rand int num_writes;
    
    constraint num_writes_c {
        num_writes inside {[5:20]};
    }
    
    function new(string name = "axi_back2back_write_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi_transaction trans;
        
        `uvm_info("B2B_WR_SEQ", $sformatf("Starting %0d back-to-back writes", num_writes), UVM_MEDIUM)
        
        repeat(num_writes) begin
            `uvm_do_with(trans, {
                trans.trans_type == axi_transaction::WRITE;
                trans.awvalid_delay == 0;  // No delay
                trans.wvalid_delay == 0;
                trans.bready_delay == 0;
            })
        end
        
        `uvm_info("B2B_WR_SEQ", "Back-to-back write sequence complete", UVM_MEDIUM)
    endtask
    
endclass

//==============================================================================
// Fault Injection Sequence - Out of Range Values
//==============================================================================
class axi_fault_injection_sequence extends axi_base_sequence;
    
    `uvm_object_utils(axi_fault_injection_sequence)
    
    function new(string name = "axi_fault_injection_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi_write_sequence wr_seq;
        axi_read_sequence rd_seq;
        
        `uvm_info("FAULT_SEQ", "Starting fault injection tests", UVM_MEDIUM)
        
        // Test 1: Out of range temperature
        `uvm_info("FAULT_SEQ", "Test 1: Out-of-range temperature value", UVM_MEDIUM)
        wr_seq = axi_write_sequence::type_id::create("wr_seq");
        wr_seq.addr = 32'h0;  // TEMP_DATA
        wr_seq.data = 32'hFFFFFFFF;  // Way out of range
        wr_seq.start(m_sequencer);
        
        // Read STATUS register to check error flag
        rd_seq = axi_read_sequence::type_id::create("rd_seq");
        rd_seq.addr = 32'hC;  // STATUS
        rd_seq.start(m_sequencer);
        
        if (rd_seq.read_data[2]) begin  // Bit 2 = temp out of range
            `uvm_info("FAULT_SEQ", "PASS: Out-of-range temperature detected in STATUS", UVM_MEDIUM)
        end else begin
            `uvm_error("FAULT_SEQ", "FAIL: STATUS register did not flag out-of-range temperature")
        end
        
        // Test 2: Out of range pressure
        `uvm_info("FAULT_SEQ", "Test 2: Out-of-range pressure value", UVM_MEDIUM)
        wr_seq = axi_write_sequence::type_id::create("wr_seq");
        wr_seq.addr = 32'h4;  // PRESS_DATA
        wr_seq.data = 32'hFFFFFFFF;
        wr_seq.start(m_sequencer);
        
        rd_seq.addr = 32'hC;
        rd_seq.start(m_sequencer);
        
        if (rd_seq.read_data[3]) begin  // Bit 3 = pressure out of range
            `uvm_info("FAULT_SEQ", "PASS: Out-of-range pressure detected in STATUS", UVM_MEDIUM)
        end
        
        // Test 3: Write to read-only STATUS register (should get SLVERR)
        `uvm_info("FAULT_SEQ", "Test 3: Write to read-only STATUS register", UVM_MEDIUM)
        wr_seq = axi_write_sequence::type_id::create("wr_seq");
        wr_seq.addr = 32'hC;  // STATUS (read-only)
        wr_seq.data = 32'hDEADBEEF;
        wr_seq.start(m_sequencer);
        // Scoreboard will check for SLVERR response
        
        // Test 4: Invalid address
        `uvm_info("FAULT_SEQ", "Test 4: Invalid address access", UVM_MEDIUM)
        wr_seq = axi_write_sequence::type_id::create("wr_seq");
        wr_seq.addr = 32'h100;  // Invalid address
        wr_seq.data = 32'h12345678;
        wr_seq.start(m_sequencer);
        // Scoreboard will check for SLVERR response
        
        `uvm_info("FAULT_SEQ", "Fault injection sequence complete", UVM_MEDIUM)
    endtask
    
endclass

//==============================================================================
// Reset Sequence - Test behavior during/after reset
//==============================================================================
class axi_reset_sequence extends axi_base_sequence;
    
    `uvm_object_utils(axi_reset_sequence)
    
    function new(string name = "axi_reset_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi_write_sequence wr_seq;
        axi_read_sequence rd_seq;
        
        `uvm_info("RESET_SEQ", "Testing reset behavior", UVM_MEDIUM)
        
        // Write some data
        wr_seq = axi_write_sequence::type_id::create("wr_seq");
        wr_seq.addr = 32'h0;
        wr_seq.data = 32'hABCD1234;
        wr_seq.start(m_sequencer);
        
        // TODO: Trigger reset (would need access to reset signal)
        // For now, just document that reset testing should be done
        
        // After reset, registers should be cleared
        rd_seq = axi_read_sequence::type_id::create("rd_seq");
        rd_seq.addr = 32'h0;
        rd_seq.start(m_sequencer);
        
        if (rd_seq.read_data == 32'h0) begin
            `uvm_info("RESET_SEQ", "PASS: Register cleared after reset", UVM_MEDIUM)
        end else begin
            `uvm_error("RESET_SEQ", $sformatf("FAIL: Register not cleared, value=0x%0h", rd_seq.read_data))
        end
    endtask
    
endclass

//==============================================================================
// Comprehensive Test Sequence - Runs all test scenarios
//==============================================================================
class axi_comprehensive_sequence extends axi_base_sequence;
    
    `uvm_object_utils(axi_comprehensive_sequence)
    
    function new(string name = "axi_comprehensive_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi_write_read_sequence wr_rd_seq;
        axi_random_sequence rand_seq;
        axi_back2back_write_sequence b2b_seq;
        axi_fault_injection_sequence fault_seq;
        
        `uvm_info("COMP_SEQ", "========================================", UVM_LOW)
        `uvm_info("COMP_SEQ", "   COMPREHENSIVE VERIFICATION SUITE    ", UVM_LOW)
        `uvm_info("COMP_SEQ", "========================================", UVM_LOW)
        
        // Phase 1: Basic write-read tests
        `uvm_info("COMP_SEQ", "Phase 1: Basic Write-Read Tests", UVM_LOW)
        repeat(10) begin
            wr_rd_seq = axi_write_read_sequence::type_id::create("wr_rd_seq");
            wr_rd_seq.randomize();
            wr_rd_seq.start(m_sequencer);
        end
        
        // Phase 2: Random access patterns
        `uvm_info("COMP_SEQ", "Phase 2: Random Access Patterns", UVM_LOW)
        rand_seq = axi_random_sequence::type_id::create("rand_seq");
        rand_seq.randomize();
        rand_seq.start(m_sequencer);
        
        // Phase 3: Back-to-back transactions
        `uvm_info("COMP_SEQ", "Phase 3: Back-to-Back Transactions", UVM_LOW)
        b2b_seq = axi_back2back_write_sequence::type_id::create("b2b_seq");
        b2b_seq.randomize();
        b2b_seq.start(m_sequencer);
        
        // Phase 4: Fault injection
        `uvm_info("COMP_SEQ", "Phase 4: Fault Injection Testing", UVM_LOW)
        fault_seq = axi_fault_injection_sequence::type_id::create("fault_seq");
        fault_seq.start(m_sequencer);
        
        `uvm_info("COMP_SEQ", "========================================", UVM_LOW)
        `uvm_info("COMP_SEQ", "   COMPREHENSIVE SUITE COMPLETE        ", UVM_LOW)
        `uvm_info("COMP_SEQ", "========================================", UVM_LOW)
    endtask
    
endclass
