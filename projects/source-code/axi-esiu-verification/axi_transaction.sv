//==============================================================================
// AXI4-Lite Transaction Class
// Author: Brandon Dinh
//==============================================================================

class axi_transaction extends uvm_sequence_item;
    
    // Transaction type
    typedef enum {READ, WRITE} trans_type_e;
    rand trans_type_e trans_type;
    
    // AXI4-Lite signals
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [3:0]  strb;
    bit [1:0]       resp;
    
    // Timing controls
    rand int awvalid_delay;
    rand int wvalid_delay;
    rand int arvalid_delay;
    rand int bready_delay;
    rand int rready_delay;
    
    // Factory registration
    `uvm_object_utils_begin(axi_transaction)
        `uvm_field_enum(trans_type_e, trans_type, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(strb, UVM_ALL_ON)
        `uvm_field_int(resp, UVM_ALL_ON)
    `uvm_object_utils_end
    
    //==========================================================================
    // Constraints
    //==========================================================================
    
    // Valid register addresses only
    constraint valid_addr_c {
        addr inside {32'h0, 32'h4, 32'h8, 32'hC};
    }
    
    // Reasonable delays for valid/ready handshakes
    constraint timing_c {
        awvalid_delay inside {[0:5]};
        wvalid_delay inside {[0:5]};
        arvalid_delay inside {[0:5]};
        bready_delay inside {[0:3]};
        rready_delay inside {[0:3]};
    }
    
    // Write strobe typically all 1's for full word write
    constraint strb_c {
        strb == 4'hF;
    }
    
    // Reasonable data values for sensor registers
    constraint data_c {
        if (addr == 32'h0) {  // Temperature register
            data inside {[0:1000], [1001:32'hFFFFFFFF]};  // In-range and out-of-range
        }
        if (addr == 32'h4) {  // Pressure register
            data inside {[0:2000], [2001:32'hFFFFFFFF]};
        }
    }
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "axi_transaction");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Convert to string for debugging
    //==========================================================================
    function string convert2string();
        string s;
        s = $sformatf("Type: %s, Addr: 0x%0h, Data: 0x%0h, Resp: %0d", 
                      trans_type.name(), addr, data, resp);
        return s;
    endfunction
    
    //==========================================================================
    // Do compare for scoreboard
    //==========================================================================
    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        axi_transaction rhs_;
        bit status;
        
        if (!$cast(rhs_, rhs)) begin
            `uvm_fatal("DO_COMPARE", "Cast failed")
            return 0;
        end
        
        status = super.do_compare(rhs, comparer);
        status &= (trans_type == rhs_.trans_type);
        status &= (addr == rhs_.addr);
        status &= (data == rhs_.data);
        
        return status;
    endfunction

endclass
