module apb_slave

(
    input logic pclk, preset_n,
    
    output logic  [31:0] cpu_rdata,
    output logic         pslverr, cpu_ready,
    input  logic  [31:0] cpu_addr, cpu_wdata,
    input  logic         cpu_wr, cpu_en,
    output logic         addr_valid

);

logic [31:0] mem [logic [31:0]];

assign addr_valid = (cpu_addr >= 32'h8000_0000) && (cpu_addr <= 32'h8fff_ffff);

always@(posedge pclk) begin
    if(!preset_n) begin
        cpu_rdata <= 0;
        pslverr <= 0;
        cpu_ready <= 0;

        mem.delete();
        end 
        
        else begin

        cpu_ready <= 1;
        pslverr   <= 0;

          if(cpu_en && addr_valid) begin
            if(cpu_wr) begin
              mem[cpu_addr]  = cpu_wdata;
              $display("Addr-0x%0h|Data-0x%0h |WRITE", cpu_addr, cpu_wdata); 
            end else begin
              cpu_rdata     = mem[cpu_addr];
              $display("Addr-0x%0h|Data-0x%0h |READ", cpu_addr, cpu_rdata); 
          end 
          end
          
          else begin
            pslverr         <= 1;
            end

        end
        end
        endmodule
