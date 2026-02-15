//==============================================================================
// AXI4-Lite UVM Monitor
// Author: Brandon Dinh
// Description: Observes AXI4-Lite bus and sends transactions to scoreboard
//==============================================================================

class axi_monitor extends uvm_monitor;
    
    `uvm_component_utils(axi_monitor)
    
    // Virtual interface
    virtual axi_if vif;
    
    // Analysis port to send observed transactions
    uvm_analysis_port #(axi_transaction) mon_ap;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "axi_monitor", uvm_component parent = null);
        super.new(name, parent);
        mon_ap = new("mon_ap", this);
    endfunction
    
    //==========================================================================
    // Build Phase
    //==========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not set for monitor")
        end
    endfunction
    
    //==========================================================================
    // Run Phase
    //==========================================================================
    task run_phase(uvm_phase phase);
        axi_transaction trans;
        
        forever begin
            // Wait for either a write or read transaction
            fork
                begin
                    monitor_write(trans);
                end
                begin
                    monitor_read(trans);
                end
            join_any
            disable fork;
            
            // Send transaction to scoreboard via analysis port
            if (trans != null) begin
                `uvm_info("MONITOR", $sformatf("Observed transaction: %s", trans.convert2string()), UVM_MEDIUM)
                mon_ap.write(trans);
            end
        end
    endtask
    
    //==========================================================================
    // Monitor Write Transaction
    //==========================================================================
    task monitor_write(output axi_transaction trans);
        bit [31:0] addr_captured;
        bit [31:0] data_captured;
        
        // Wait for write address valid
        @(posedge vif.aclk);
        while (!(vif.awvalid && vif.awready)) @(posedge vif.aclk);
        addr_captured = vif.awaddr;
        
        // Wait for write data valid
        @(posedge vif.aclk);
        while (!(vif.wvalid && vif.wready)) @(posedge vif.aclk);
        data_captured = vif.wdata;
        
        // Wait for write response
        @(posedge vif.aclk);
        while (!(vif.bvalid && vif.bready)) @(posedge vif.aclk);
        
        // Create transaction object
        trans = axi_transaction::type_id::create("trans");
        trans.trans_type = axi_transaction::WRITE;
        trans.addr = addr_captured;
        trans.data = data_captured;
        trans.resp = vif.bresp;
        
        `uvm_info("MONITOR", $sformatf("Write observed: Addr=0x%0h, Data=0x%0h, Resp=%0d", 
                  trans.addr, trans.data, trans.resp), UVM_HIGH)
    endtask
    
    //==========================================================================
    // Monitor Read Transaction
    //==========================================================================
    task monitor_read(output axi_transaction trans);
        bit [31:0] addr_captured;
        
        // Wait for read address valid
        @(posedge vif.aclk);
        while (!(vif.arvalid && vif.arready)) @(posedge vif.aclk);
        addr_captured = vif.araddr;
        
        // Wait for read data valid
        @(posedge vif.aclk);
        while (!(vif.rvalid && vif.rready)) @(posedge vif.aclk);
        
        // Create transaction object
        trans = axi_transaction::type_id::create("trans");
        trans.trans_type = axi_transaction::READ;
        trans.addr = addr_captured;
        trans.data = vif.rdata;
        trans.resp = vif.rresp;
        
        `uvm_info("MONITOR", $sformatf("Read observed: Addr=0x%0h, Data=0x%0h, Resp=%0d", 
                  trans.addr, trans.data, trans.resp), UVM_HIGH)
    endtask

endclass
