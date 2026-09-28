module tb_top;

int clk_high, clk_low, clk_period;

apb_inf inf();

initial begin
  inf.pclk        =     0;

  clk_period  =     $urandom_range(10,40);
  clk_high    =     (clk_period * $urandom_range(40,60)) / 100;
  if(clk_high == 0) clk_high = 1;
  clk_low     =     clk_period - clk_high;

  forever begin

    #(clk_high) inf.pclk = 1;
    #(clk_low)  inf.pclk = 0;
  end
end

apb_master apb_op1  
(
    .pclk(inf.pclk),
    .preset_n(inf.preset_n),
    .transfer(inf.transfer),
    .pwrite(inf.pwrite),
    .write_data(inf.write_data),
    .cpu_addr(inf.cpu_addr),
    .paddr(inf.paddr),
    .cpu_wdata(inf.cpu_wdata),
    .cpu_wr(inf.cpu_wr),
    .cpu_en(inf.cpu_en),
    .cpu_ready(inf.cpu_ready),
    .pslverr(inf.pslverr),
    .cpu_rdata(inf.cpu_rdata),
    .read_data_out(inf.read_data_out)
);
apb_slave  apb_op2  
(
    .pclk(inf.pclk), 
    .preset_n(inf.preset_n), 
    .cpu_addr(inf.cpu_addr),
    .cpu_wdata(inf.cpu_wdata),
    .cpu_wr(inf.cpu_wr),
    .cpu_en(inf.cpu_en),
    .cpu_ready(inf.cpu_ready),
    .pslverr(inf.pslverr),
    .cpu_rdata(inf.cpu_rdata),
    .addr_valid(inf.addr_valid)
);
  
task apb_write(input logic [31:0] cpu_addr_t, input logic [31:0] cpu_wdata_t);


  inf.pwrite = 1;
  inf.transfer = 1;

  inf.paddr = cpu_addr_t;
  inf.write_data = cpu_wdata_t;

  @(posedge inf.pclk);
  @(posedge inf.pclk);
  @(posedge inf.pclk);

  inf.transfer = 0;

  $display("[%0t] -- apb_write | addr = 0x%0h | data = 0x%0h", $time, inf.cpu_addr, inf.cpu_wdata);

  endtask

  task apb_read(input logic [31:0] cpu_addr_t2);

 
  inf.pwrite = 0;
  inf.transfer = 1;

  inf.paddr = cpu_addr_t2;

  @(posedge inf.pclk);
  @(posedge inf.pclk);
  @(posedge inf.pclk);

   $display("[%0t] -- apb_read | addr = 0x%0h | data = 0x%0h", $time, inf.cpu_addr, inf.read_data_out);


  inf.transfer = 0;

  endtask
  
initial begin
inf.paddr         = 0;
inf.write_data    = 0;
inf.pwrite        = 0;
inf.transfer      = 0;

inf.preset_n = 0;
#10; inf.preset_n = 1;

#10; apb_write(32'h8123_000A, 32'hcafe_beef);

#20; apb_read (32'h8123_000A);

#40; $finish;
end

initial begin
$dumpfile ("apb_top.vcd");
$dumpvars (0);
end
endmodule
