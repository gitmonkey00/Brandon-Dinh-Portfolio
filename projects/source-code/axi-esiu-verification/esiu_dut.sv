//==============================================================================
// Environmental Sensor Interface Unit (ESIU) - AXI4-Lite Slave
// Author: Brandon Dinh
// Description: Memory-mapped register interface for temperature and pressure
//              sensor data with AXI4-Lite protocol compliance
//==============================================================================

module esiu_dut #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Clock and Reset
    input  wire                     aclk,
    input  wire                     aresetn,
    
    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]    awaddr,
    input  wire                     awvalid,
    output reg                      awready,
    
    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]    wdata,
    input  wire [3:0]               wstrb,
    input  wire                     wvalid,
    output reg                      wready,
    
    // AXI4-Lite Write Response Channel
    output reg  [1:0]               bresp,
    output reg                      bvalid,
    input  wire                     bready,
    
    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]    araddr,
    input  wire                     arvalid,
    output reg                      arready,
    
    // AXI4-Lite Read Data Channel
    output reg  [DATA_WIDTH-1:0]    rdata,
    output reg  [1:0]               rresp,
    output reg                      rvalid,
    input  wire                     rready,
    
    // Sensor Interface (Simulated inputs)
    input  wire [31:0]              sensor_temp_data,
    input  wire [31:0]              sensor_press_data,
    input  wire                     sensor_temp_valid,
    input  wire                     sensor_press_valid
);

    //==========================================================================
    // Register Map
    //==========================================================================
    // 0x00: TEMP_DATA   - Temperature sensor data register (R/W)
    // 0x04: PRESS_DATA  - Pressure sensor data register (R/W)
    // 0x08: CONFIG      - Configuration register (R/W)
    // 0x0C: STATUS      - Status register (RO)
    
    localparam ADDR_TEMP_DATA  = 4'h0;
    localparam ADDR_PRESS_DATA = 4'h4;
    localparam ADDR_CONFIG     = 4'h8;
    localparam ADDR_STATUS     = 4'hC;
    
    // AXI Response codes
    localparam RESP_OKAY   = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    //==========================================================================
    // Internal Registers
    //==========================================================================
    reg [31:0] temp_data_reg;
    reg [31:0] press_data_reg;
    reg [31:0] config_reg;
    reg [31:0] status_reg;
    
    // Write state machine
    reg [1:0] write_state;
    localparam W_IDLE  = 2'b00;
    localparam W_WRITE = 2'b01;
    localparam W_RESP  = 2'b10;
    
    // Read state machine
    reg [1:0] read_state;
    localparam R_IDLE = 2'b00;
    localparam R_READ = 2'b01;
    
    // Latched addresses for write and read
    reg [ADDR_WIDTH-1:0] write_addr;
    reg [ADDR_WIDTH-1:0] read_addr;
    
    //==========================================================================
    // Status Register Bit Definitions
    //==========================================================================
    // [0]   : Temperature sensor valid
    // [1]   : Pressure sensor valid
    // [2]   : Temperature out of range
    // [3]   : Pressure out of range
    // [7:4] : Reserved
    
    wire temp_out_of_range  = (sensor_temp_data > 32'd1000) || (sensor_temp_data < 32'd0);
    wire press_out_of_range = (sensor_press_data > 32'd2000) || (sensor_press_data < 32'd0);
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            status_reg <= 32'h0;
        end else begin
            status_reg[0] <= sensor_temp_valid;
            status_reg[1] <= sensor_press_valid;
            status_reg[2] <= temp_out_of_range;
            status_reg[3] <= press_out_of_range;
            status_reg[31:4] <= 28'h0;
        end
    end
    
    //==========================================================================
    // AXI4-Lite Write Logic
    //==========================================================================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            awready      <= 1'b0;
            wready       <= 1'b0;
            bvalid       <= 1'b0;
            bresp        <= RESP_OKAY;
            write_state  <= W_IDLE;
            write_addr   <= {ADDR_WIDTH{1'b0}};
            
            temp_data_reg  <= 32'h0;
            press_data_reg <= 32'h0;
            config_reg     <= 32'h0;
        end else begin
            case (write_state)
                W_IDLE: begin
                    awready <= 1'b1;
                    wready  <= 1'b0;
                    bvalid  <= 1'b0;
                    
                    if (awvalid && awready) begin
                        write_addr  <= awaddr;
                        awready     <= 1'b0;
                        wready      <= 1'b1;
                        write_state <= W_WRITE;
                    end
                end
                
                W_WRITE: begin
                    if (wvalid && wready) begin
                        wready <= 1'b0;
                        
                        // Decode address and write to register
                        case (write_addr[3:0])
                            ADDR_TEMP_DATA: begin
                                temp_data_reg <= wdata;
                                bresp <= RESP_OKAY;
                            end
                            ADDR_PRESS_DATA: begin
                                press_data_reg <= wdata;
                                bresp <= RESP_OKAY;
                            end
                            ADDR_CONFIG: begin
                                config_reg <= wdata;
                                bresp <= RESP_OKAY;
                            end
                            ADDR_STATUS: begin
                                // Status register is read-only
                                bresp <= RESP_SLVERR;
                            end
                            default: begin
                                bresp <= RESP_SLVERR; // Invalid address
                            end
                        endcase
                        
                        bvalid      <= 1'b1;
                        write_state <= W_RESP;
                    end
                end
                
                W_RESP: begin
                    if (bvalid && bready) begin
                        bvalid      <= 1'b0;
                        write_state <= W_IDLE;
                    end
                end
                
                default: write_state <= W_IDLE;
            endcase
        end
    end
    
    //==========================================================================
    // AXI4-Lite Read Logic
    //==========================================================================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            arready    <= 1'b0;
            rvalid     <= 1'b0;
            rdata      <= {DATA_WIDTH{1'b0}};
            rresp      <= RESP_OKAY;
            read_state <= R_IDLE;
            read_addr  <= {ADDR_WIDTH{1'b0}};
        end else begin
            case (read_state)
                R_IDLE: begin
                    arready <= 1'b1;
                    rvalid  <= 1'b0;
                    
                    if (arvalid && arready) begin
                        read_addr  <= araddr;
                        arready    <= 1'b0;
                        read_state <= R_READ;
                        
                        // Decode address and read from register
                        case (araddr[3:0])
                            ADDR_TEMP_DATA: begin
                                rdata <= temp_data_reg;
                                rresp <= RESP_OKAY;
                            end
                            ADDR_PRESS_DATA: begin
                                rdata <= press_data_reg;
                                rresp <= RESP_OKAY;
                            end
                            ADDR_CONFIG: begin
                                rdata <= config_reg;
                                rresp <= RESP_OKAY;
                            end
                            ADDR_STATUS: begin
                                rdata <= status_reg;
                                rresp <= RESP_OKAY;
                            end
                            default: begin
                                rdata <= 32'h0;
                                rresp <= RESP_SLVERR;
                            end
                        endcase
                        
                        rvalid <= 1'b1;
                    end
                end
                
                R_READ: begin
                    if (rvalid && rready) begin
                        rvalid     <= 1'b0;
                        read_state <= R_IDLE;
                    end
                end
                
                default: read_state <= R_IDLE;
            endcase
        end
    end
    
    //==========================================================================
    // Update sensor data registers when sensor valid
    //==========================================================================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Registers already reset above
        end else begin
            if (sensor_temp_valid && config_reg[0]) begin  // Auto-update enabled
                temp_data_reg <= sensor_temp_data;
            end
            
            if (sensor_press_valid && config_reg[1]) begin  // Auto-update enabled
                press_data_reg <= sensor_press_data;
            end
        end
    end

endmodule
