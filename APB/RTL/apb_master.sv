module apb_master
(
    input logic pclk, preset_n,

    input  logic  transfer, pwrite, 
    input  logic [31:0] write_data, paddr,
    input  logic [31:0] cpu_rdata,
    input  logic  pslverr, cpu_ready,
    output logic [31:0] cpu_addr, cpu_wdata, read_data_out,
    output logic  cpu_wr, cpu_en
);


localparam [1:0]
    IDLE   = 2'b00,
    SETUP  = 2'b01,
    ACCESS = 2'b11;

    reg [2:0] curr_state, next_state;

//declaring states

    always@(posedge pclk) begin
        if(!preset_n) begin
            curr_state <= IDLE;
        end 
        else begin
          curr_state <= next_state;
          
              read_data_out <= cpu_rdata;
        end
    end

   

//next state logic
    always@(*) begin
     next_state = curr_state;
        
        case(curr_state)
             IDLE : begin
                    if(transfer)
                      next_state = SETUP;
                    end

             SETUP: begin
                    next_state = ACCESS;
                    end

            ACCESS: begin
                    if(cpu_ready)begin
                        if(transfer)
                            next_state = SETUP;
                        else
                            next_state = IDLE;
                    end 
                    else begin
                            next_state = ACCESS;
                    end
                    end

            default: begin 
            next_state = IDLE;
            end

            endcase
            end

    always @(posedge pclk) begin
        if(!preset_n) begin
            cpu_addr      <= 0;
            cpu_wdata     <= 0;
            read_data_out <= 0;
            cpu_wr        <= 0;
            cpu_en        <= 0;
        end else begin

            case(next_state)
                IDLE: begin
            cpu_addr      <= 0;
            cpu_wdata     <= 0;
            read_data_out <= 0;
            cpu_wr        <= 0;
            cpu_en        <= 0;
                end

                SETUP: begin
            cpu_addr      <= paddr;
            cpu_wr        <= pwrite;
            cpu_wdata     <= write_data;
            cpu_en        <= 0;
                end

                ACCESS: begin
                cpu_en    <= 1;
                end

                default: begin
            cpu_addr      <= 0;
            cpu_wdata     <= 0;
            read_data_out <= 0;
            cpu_wr        <= 0;
            cpu_en        <= 0;
                end
                endcase
        end
    end
endmodule

