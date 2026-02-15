//==============================================================================
// AXI4-Lite UVM Driver
// Author: Brandon Dinh
// Description: Drives AXI4-Lite transactions onto the DUT interface
//==============================================================================

class axi_driver extends uvm_driver #(axi_transaction);
    
    `uvm_component_utils(axi_driver)
    
    // Virtual interface
    virtual axi_if vif;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "axi_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // Build Phase
    //==========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not set for driver")
        end
    endfunction
    
    //==========================================================================
    // Run Phase
    //==========================================================================
    task run_phase(uvm_phase phase);
        // Initialize signals
        reset_signals();
        
        forever begin
            // Get transaction from sequencer
            seq_item_port.get_next_item(req);
            
            `uvm_info("DRIVER", $sformatf("Driving transaction: %s", req.convert2string()), UVM_MEDIUM)
            
            // Drive transaction based on type
            if (req.trans_type == axi_transaction::WRITE) begin
                drive_write(req);
            end else begin
                drive_read(req);
            end
            
            seq_item_port.item_done();
        end
    endtask
    
    //==========================================================================
    // Reset all AXI signals
    //==========================================================================
    task reset_signals();
        vif.awvalid <= 1'b0;
        vif.awaddr  <= 32'h0;
        vif.wvalid  <= 1'b0;
        vif.wdata   <= 32'h0;
        vif.wstrb   <= 4'h0;
        vif.bready  <= 1'b0;
        vif.arvalid <= 1'b0;
        vif.araddr  <= 32'h0;
        vif.rready  <= 1'b0;
    endtask
    
    //==========================================================================
    // Drive AXI4-Lite Write Transaction
    //==========================================================================
    task drive_write(axi_transaction trans);
        fork
            // Write address channel
            begin
                repeat(trans.awvalid_delay) @(posedge vif.aclk);
                vif.awvalid <= 1'b1;
                vif.awaddr  <= trans.addr;
                
                @(posedge vif.aclk);
                while (!vif.awready) @(posedge vif.aclk);
                
                vif.awvalid <= 1'b0;
                vif.awaddr  <= 32'h0;
            end
            
            // Write data channel
            begin
                repeat(trans.wvalid_delay) @(posedge vif.aclk);
                vif.wvalid <= 1'b1;
                vif.wdata  <= trans.data;
                vif.wstrb  <= trans.strb;
                
                @(posedge vif.aclk);
                while (!vif.wready) @(posedge vif.aclk);
                
                vif.wvalid <= 1'b0;
                vif.wdata  <= 32'h0;
                vif.wstrb  <= 4'h0;
            end
        join
        
        // Write response channel
        repeat(trans.bready_delay) @(posedge vif.aclk);
        vif.bready <= 1'b1;
        
        @(posedge vif.aclk);
        while (!vif.bvalid) @(posedge vif.aclk);
        
        trans.resp = vif.bresp;
        
        vif.bready <= 1'b0;
        
        `uvm_info("DRIVER", $sformatf("Write complete: Addr=0x%0h, Data=0x%0h, Resp=%0d", 
                  trans.addr, trans.data, trans.resp), UVM_HIGH)
    endtask
    
    //==========================================================================
    // Drive AXI4-Lite Read Transaction
    //==========================================================================
    task drive_read(axi_transaction trans);
        // Read address channel
        repeat(trans.arvalid_delay) @(posedge vif.aclk);
        vif.arvalid <= 1'b1;
        vif.araddr  <= trans.addr;
        
        @(posedge vif.aclk);
        while (!vif.arready) @(posedge vif.aclk);
        
        vif.arvalid <= 1'b0;
        vif.araddr  <= 32'h0;
        
        // Read data channel
        repeat(trans.rready_delay) @(posedge vif.aclk);
        vif.rready <= 1'b1;
        
        @(posedge vif.aclk);
        while (!vif.rvalid) @(posedge vif.aclk);
        
        trans.data = vif.rdata;
        trans.resp = vif.rresp;
        
        vif.rready <= 1'b0;
        
        `uvm_info("DRIVER", $sformatf("Read complete: Addr=0x%0h, Data=0x%0h, Resp=%0d", 
                  trans.addr, trans.data, trans.resp), UVM_HIGH)
    endtask

endclass
