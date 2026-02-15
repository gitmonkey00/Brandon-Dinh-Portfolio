//==============================================================================
// AXI4-Lite Interface Definition
// Author: Brandon Dinh
// Description: SystemVerilog interface for AXI4-Lite protocol signals
//==============================================================================

interface axi_if (
    input logic aclk,
    input logic aresetn
);

    //==========================================================================
    // AXI4-Lite Write Address Channel
    //==========================================================================
    logic [31:0] awaddr;
    logic        awvalid;
    logic        awready;
    
    //==========================================================================
    // AXI4-Lite Write Data Channel
    //==========================================================================
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wvalid;
    logic        wready;
    
    //==========================================================================
    // AXI4-Lite Write Response Channel
    //==========================================================================
    logic [1:0]  bresp;
    logic        bvalid;
    logic        bready;
    
    //==========================================================================
    // AXI4-Lite Read Address Channel
    //==========================================================================
    logic [31:0] araddr;
    logic        arvalid;
    logic        arready;
    
    //==========================================================================
    // AXI4-Lite Read Data Channel
    //==========================================================================
    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rvalid;
    logic        rready;
    
    //==========================================================================
    // Clocking blocks for synchronous operation
    //==========================================================================
    
    // Master clocking block (for driver)
    clocking master_cb @(posedge aclk);
        default input #1ns output #1ns;
        
        output awaddr;
        output awvalid;
        input  awready;
        
        output wdata;
        output wstrb;
        output wvalid;
        input  wready;
        
        input  bresp;
        input  bvalid;
        output bready;
        
        output araddr;
        output arvalid;
        input  arready;
        
        input  rdata;
        input  rresp;
        input  rvalid;
        output rready;
    endclocking
    
    // Monitor clocking block
    clocking monitor_cb @(posedge aclk);
        default input #1ns;
        
        input awaddr;
        input awvalid;
        input awready;
        
        input wdata;
        input wstrb;
        input wvalid;
        input wready;
        
        input bresp;
        input bvalid;
        input bready;
        
        input araddr;
        input arvalid;
        input arready;
        
        input rdata;
        input rresp;
        input rvalid;
        input rready;
    endclocking
    
    //==========================================================================
    // Modports for different components
    //==========================================================================
    
    modport MASTER (
        clocking master_cb,
        input aclk,
        input aresetn
    );
    
    modport SLAVE (
        input  awaddr,
        input  awvalid,
        output awready,
        
        input  wdata,
        input  wstrb,
        input  wvalid,
        output wready,
        
        output bresp,
        output bvalid,
        input  bready,
        
        input  araddr,
        input  arvalid,
        output arready,
        
        output rdata,
        output rresp,
        output rvalid,
        input  rready,
        
        input aclk,
        input aresetn
    );
    
    modport MONITOR (
        clocking monitor_cb,
        input aclk,
        input aresetn
    );
    
    //==========================================================================
    // Assertions for protocol checking
    //==========================================================================
    
    // Write address channel assertions
    property p_awvalid_stable;
        @(posedge aclk) disable iff (!aresetn)
        awvalid && !awready |=> $stable(awvalid) && $stable(awaddr);
    endproperty
    assert property (p_awvalid_stable) else 
        $error("AWVALID or AWADDR changed before AWREADY handshake");
    
    // Write data channel assertions
    property p_wvalid_stable;
        @(posedge aclk) disable iff (!aresetn)
        wvalid && !wready |=> $stable(wvalid) && $stable(wdata);
    endproperty
    assert property (p_wvalid_stable) else 
        $error("WVALID or WDATA changed before WREADY handshake");
    
    // Read address channel assertions
    property p_arvalid_stable;
        @(posedge aclk) disable iff (!aresetn)
        arvalid && !arready |=> $stable(arvalid) && $stable(araddr);
    endproperty
    assert property (p_arvalid_stable) else 
        $error("ARVALID or ARADDR changed before ARREADY handshake");
    
    // Write response assertions
    property p_bvalid_until_bready;
        @(posedge aclk) disable iff (!aresetn)
        bvalid && !bready |=> bvalid;
    endproperty
    assert property (p_bvalid_until_bready) else 
        $error("BVALID deasserted before BREADY");
    
    // Read data assertions
    property p_rvalid_until_rready;
        @(posedge aclk) disable iff (!aresetn)
        rvalid && !rready |=> rvalid;
    endproperty
    assert property (p_rvalid_until_rready) else 
        $error("RVALID deasserted before RREADY");
    
    // Address alignment check (word-aligned for 32-bit data)
    property p_awaddr_aligned;
        @(posedge aclk) disable iff (!aresetn)
        awvalid |-> (awaddr[1:0] == 2'b00);
    endproperty
    assert property (p_awaddr_aligned) else 
        $error("AWADDR not word-aligned: 0x%0h", awaddr);
    
    property p_araddr_aligned;
        @(posedge aclk) disable iff (!aresetn)
        arvalid |-> (araddr[1:0] == 2'b00);
    endproperty
    assert property (p_araddr_aligned) else 
        $error("ARADDR not word-aligned: 0x%0h", araddr);
    
    //==========================================================================
    // Coverage for handshake scenarios
    //==========================================================================
    
    covergroup cg_write_handshake @(posedge aclk);
        option.per_instance = 1;
        option.name = "write_handshake_cov";
        
        cp_aw_handshake: coverpoint (awvalid && awready) {
            bins handshake = {1};
        }
        
        cp_w_handshake: coverpoint (wvalid && wready) {
            bins handshake = {1};
        }
        
        cp_b_handshake: coverpoint (bvalid && bready) {
            bins handshake = {1};
        }
        
        // Cross coverage for timing
        cross cp_aw_handshake, cp_w_handshake;
    endgroup
    
    covergroup cg_read_handshake @(posedge aclk);
        option.per_instance = 1;
        option.name = "read_handshake_cov";
        
        cp_ar_handshake: coverpoint (arvalid && arready) {
            bins handshake = {1};
        }
        
        cp_r_handshake: coverpoint (rvalid && rready) {
            bins handshake = {1};
        }
    endgroup
    
    cg_write_handshake cg_wr = new();
    cg_read_handshake cg_rd = new();

endinterface
