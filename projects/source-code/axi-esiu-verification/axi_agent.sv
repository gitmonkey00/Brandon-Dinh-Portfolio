//==============================================================================
// AXI4-Lite UVM Agent
// Author: Brandon Dinh
// Description: Groups sequencer, driver, and monitor into reusable agent
//==============================================================================

class axi_agent extends uvm_agent;
    
    `uvm_component_utils(axi_agent)
    
    // Agent components
    uvm_sequencer #(axi_transaction) sequencer;
    axi_driver                       driver;
    axi_monitor                      monitor;
    
    // Analysis port from monitor (for scoreboard connection)
    uvm_analysis_port #(axi_transaction) agent_ap;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "axi_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // Build Phase
    //==========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create analysis port
        agent_ap = new("agent_ap", this);
        
        // Create monitor (always active)
        monitor = axi_monitor::type_id::create("monitor", this);
        
        // Create driver and sequencer only if agent is active
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = uvm_sequencer#(axi_transaction)::type_id::create("sequencer", this);
            driver = axi_driver::type_id::create("driver", this);
        end
    endfunction
    
    //==========================================================================
    // Connect Phase
    //==========================================================================
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect monitor's analysis port to agent's analysis port
        monitor.mon_ap.connect(agent_ap);
        
        // Connect driver to sequencer if active
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass
