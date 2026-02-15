//==============================================================================
// AXI4-Lite UVM Tests
// Author: Brandon Dinh
// Description: Test classes that configure environment and run sequences
//==============================================================================

//==============================================================================
// Base Test
//==============================================================================
class axi_base_test extends uvm_test;
    
    `uvm_component_utils(axi_base_test)
    
    // Environment
    axi_env env;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "axi_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // Build Phase
    //==========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create environment
        env = axi_env::type_id::create("env", this);
    endfunction
    
    //==========================================================================
    // End of Elaboration Phase
    //==========================================================================
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        
        // Print topology
        uvm_top.print_topology();
    endfunction
    
    //==========================================================================
    // Report Phase
    //==========================================================================
    function void report_phase(uvm_phase phase);
        uvm_report_server server;
        int err_num;
        
        super.report_phase(phase);
        
        server = uvm_report_server::get_server();
        err_num = server.get_severity_count(UVM_ERROR);
        
        if (err_num != 0) begin
            $display("========================================");
            $display("          TEST FAILED                   ");
            $display("========================================");
        end else begin
            $display("========================================");
            $display("          TEST PASSED                   ");
            $display("========================================");
        end
    endfunction

endclass

//==============================================================================
// Simple Write-Read Test
//==============================================================================
class axi_write_read_test extends axi_base_test;
    
    `uvm_component_utils(axi_write_read_test)
    
    function new(string name = "axi_write_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        axi_write_read_sequence seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Write-Read Test", UVM_LOW)
        
        // Run 20 write-read sequences
        repeat(20) begin
            seq = axi_write_read_sequence::type_id::create("seq");
            seq.randomize();
            seq.start(env.agent.sequencer);
        end
        
        // Let transactions complete
        #100ns;
        
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// Random Test
//==============================================================================
class axi_random_test extends axi_base_test;
    
    `uvm_component_utils(axi_random_test)
    
    function new(string name = "axi_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        axi_random_sequence seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Random Test", UVM_LOW)
        
        seq = axi_random_sequence::type_id::create("seq");
        seq.randomize() with {num_transactions == 50;};
        seq.start(env.agent.sequencer);
        
        #100ns;
        
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// Back-to-Back Test
//==============================================================================
class axi_back2back_test extends axi_base_test;
    
    `uvm_component_utils(axi_back2back_test)
    
    function new(string name = "axi_back2back_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        axi_back2back_write_sequence seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Back-to-Back Test", UVM_LOW)
        
        repeat(5) begin
            seq = axi_back2back_write_sequence::type_id::create("seq");
            seq.randomize();
            seq.start(env.agent.sequencer);
        end
        
        #100ns;
        
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// Fault Injection Test
//==============================================================================
class axi_fault_test extends axi_base_test;
    
    `uvm_component_utils(axi_fault_test)
    
    function new(string name = "axi_fault_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        axi_fault_injection_sequence seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Fault Injection Test", UVM_LOW)
        
        seq = axi_fault_injection_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        #100ns;
        
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// Comprehensive Test - Runs all scenarios
//==============================================================================
class axi_comprehensive_test extends axi_base_test;
    
    `uvm_component_utils(axi_comprehensive_test)
    
    function new(string name = "axi_comprehensive_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        axi_comprehensive_sequence seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", "========================================", UVM_LOW)
        `uvm_info("TEST", "   COMPREHENSIVE VERIFICATION SUITE    ", UVM_LOW)
        `uvm_info("TEST", "========================================", UVM_LOW)
        
        seq = axi_comprehensive_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        // Extra time for all transactions to complete
        #500ns;
        
        phase.drop_objection(this);
    endtask

endclass
