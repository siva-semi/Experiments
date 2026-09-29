module tb_top;


apb_inf inf();

int clk_high, clk_low, clk_period;

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


apb_master apb_op1 (
    .pclk         (inf.pclk),
    .preset_n     (inf.preset_n),
    .transfer     (inf.transfer),
    .pwrite       (inf.pwrite),
    .write_data   (inf.write_data),
    .paddr        (inf.paddr),
    .cpu_addr     (inf.cpu_addr),
    .cpu_wdata    (inf.cpu_wdata),
    .cpu_wr       (inf.cpu_wr),
    .cpu_en       (inf.cpu_en),
    .cpu_ready    (inf.cpu_ready),
    .pslverr      (inf.pslverr),
    .cpu_rdata    (inf.cpu_rdata),
    .read_data_out(inf.read_data_out)
);

apb_slave apb_op2 (
    .pclk      (inf.pclk),
    .preset_n  (inf.preset_n),
    .cpu_addr  (inf.cpu_addr),
    .cpu_wdata (inf.cpu_wdata),
    .cpu_wr    (inf.cpu_wr),
    .cpu_en    (inf.cpu_en),
    .cpu_ready (inf.cpu_ready),
    .pslverr   (inf.pslverr),
    .cpu_rdata (inf.cpu_rdata),
    .addr_valid(inf.addr_valid)
);

always @(posedge inf.pclk) begin
    $display("[%4t ns] en=%b wr=%b rdy=%b | addr=0x%0h | cpu_rdata=0x%0h | read_data_out=0x%0h",
        $time,
        inf.cpu_en, inf.cpu_wr, inf.cpu_ready,
        inf.cpu_addr, inf.cpu_rdata, inf.read_data_out);
end

// -------------------------------------------------------
// WRITE task
// -------------------------------------------------------
task apb_write(input logic [31:0] addr, input logic [31:0] data);
    inf.pwrite     = 1;
    inf.transfer   = 1;
    inf.paddr      = addr;
    inf.write_data = data;

    @(posedge inf.pclk); // T1: IDLE?SETUP
    @(posedge inf.pclk); // T2: SETUP?ACCESS; drop transfer here

    inf.transfer   = 0;
    inf.pwrite     = 0;
    inf.paddr      = 0;
    inf.write_data = 0;

    @(posedge inf.pclk); // T3: ACCESS, cpu_en=1, slave writes
    @(posedge inf.pclk); // T4: back to IDLE

    $display("[TB] *** WRITE COMPLETE | addr=0x%0h | data=0x%0h ***\n", addr, data);
endtask

// -------------------------------------------------------
// READ task
// -------------------------------------------------------
task apb_read(input logic [31:0] addr);
    inf.pwrite   = 0;
    inf.transfer = 1;
    inf.paddr    = addr;

    @(posedge inf.pclk); // T1: IDLE?SETUP
    @(posedge inf.pclk); // T2: SETUP?ACCESS; drop transfer so FSM?IDLE after first ACCESS

    inf.transfer = 0;
    inf.paddr    = 0;

    @(posedge inf.pclk); // T3: ACCESS, cpu_en=1, read_data_out captures cpu_rdata (NBA)
    //@(posedge inf.pclk); // T4: read_data_out is stable on output flop now

   // #1;
   $display("[TB] *** READ  COMPLETE | addr=0x%0h | read_data_out=0x%0h ***\n",
              addr, inf.read_data_out);

    @(posedge inf.pclk); // back to IDLE
endtask

//------------------------------------------------------
// Test case 1 -- Simple Write and Read
//------------------------------------------------------

task t1_simple_rw();
    $display("simple read and write");
    apb_write(32'h8000_0004, 32'hBEEF_DEAD);
    apb_read(32'h8000_0004);
    $display("Done TEST-1");
    endtask

//------------------------------------------------------
// Test Case 2 -- Repeated write and Read
//------------------------------------------------------

task t2_repeat_rw();
    $display("repeated write and read");
    logic [31:0] addr, data;
    int i;

    for(i=0; i<10; i++) begin
      addr = 32'h8000_0000 + (4*i);
      data = 32'hA000_0000 + i;
      apb_write(addr, data);
      end

    for(i=0; i<10; i++) begin
      addr = 32'h8000_0000 + (4*i);
      apb_read(addr);
      end
      
      $display("Done TEST-2");
      endtask

//------------------------------------------------------
// Test Case 3 -- Mis-aligned Address
//------------------------------------------------------

task t3_addr_slip();
    $display("Accessing wrong address alignment - last 4 bits except [0,4,8,C]");
    apb_write(32'h8000_0001, 32'h1234_CAFE);
    apb_read(32'h8000_0001);
    apb_read(32'h8000_0000);
    $display("Done TEST-3");
    endtask

//------------------------------------------------------
// Test Case 4 -- Out of bounds
//------------------------------------------------------

task t4_cross_addr_limit();
    $display("Accessing out of bounds address");
    apb_write(32'h9000_0000, 32'hCAFE_BEEF);
    apb_write(32'h7fff_ffff, 32'hCAFE_BEEF);

    apb_read(32'h9000_0000);
    apb_read(32'h7fff_ffff);
    $display("Done TEST-4");
    endtask


//------------------------------------------------------
// Random reset
//------------------------------------------------------
initial begin
    inf.preset_n = $urandom;           
    inf.preset_n = 0;                  
    repeat($urandom_range(6,1)) @(posedge inf.pclk); 
    inf.preset_n = 1;                  
end

//-------------------------------------------------------
// Calling Test Case Tasks
//-------------------------------------------------------
initial begin
    inf.paddr      = 0;
    inf.write_data = 0;
    inf.pwrite     = 0;
    inf.transfer   = 0;

    wait @(posedge inf.preset_n);
    wait @(posedge clk);

    if($test$plusargs(TEST="test1") t1_simple_rw();
    else if($test$plusargs(TEST="test2") t2_repeat_rw();
    else if($test$plusargs(TEST="test3") t3_addr_slip();
    else if($test$plusargs(TEST="test4") t4_cross_addr_limit();
    else begin
      $display("No Test given, running TEST-1 by default");
      t1_simple_rw();
      end

    #40;
    $display("Simulation Done");
    $finish;
    end


 

// -------------------------------------------------------
// Stimulus
// -------------------------------------------------------
/*initial begin
    inf.paddr      = 0;
    inf.write_data = 0;
    inf.pwrite     = 0;
    inf.transfer   = 0;
    inf.preset_n   = 0;

    @(posedge inf.preset_n);
    @(posedge inf.pclk);

    $display("[TB] --- Starting WRITE ---");
    apb_write(32'h8123_000A, 32'hcafe_beef);

   // repeat(2) @(posedge inf.pclk);

    $display("[TB] --- Starting READ ---");
    apb_read(32'h8123_000A);

    #40;
    $display("[TB] SIMULATION DONE");
    $finish;
end
*/

initial begin
    $dumpfile("apb_top.vcd");
    $dumpvars(0);
end

endmodule
