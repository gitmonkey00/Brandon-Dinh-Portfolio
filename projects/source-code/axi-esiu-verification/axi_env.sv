//==============================================================================
// AXI4-Lite UVM Environment
// Author: Brandon Dinh
// Description: Top-level verification environment containing agent and scoreboard
//==============================================================================

class axi_env extends uvm_env;
    
    `uvm_component_utils(axi_env)
    
    // Environment components
    axi_agent      agent;
    axi_scoreboard scoreboard;
    
    // Coverage collector (optional - can be added)
    // axi_coverage_collector coverage;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "axi_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // Build Phase
    //==========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create agent
        agent = axi_agent::type_id::create("agent", this);
        
        // Create scoreboard
        scoreboard = axi_scoreboard::type_id::create("scoreboard", this);
        
        // Optionally create coverage collector
        // coverage = axi_coverage_collector::type_id::create("coverage", this);
    endfunction
    
    //==========================================================================
    // Connect Phase
    //==========================================================================
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect agent's analysis port to scoreboard
        agent.agent_ap.connect(scoreboard.sb_imp);
        
        // Optionally connect to coverage collector
        // agent.agent_ap.connect(coverage.cov_imp);
    endfunction

endclass
