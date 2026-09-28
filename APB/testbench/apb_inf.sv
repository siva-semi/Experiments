interface apb_inf;

//inputs from processor
logic pclk;
logic preset_n;

//inpts from tb
logic transfer;
logic pwrite;
logic [31:0] write_data ;
logic [31:0] paddr;
logic [31:0] read_data_out;

//signals of the master to slave
logic [31:0] cpu_addr;
logic [31:0] cpu_wdata;
logic cpu_wr;
logic cpu_en;

logic [31:0] cpu_rdata;  // output from slave


logic cpu_ready;         // Acknowledgement from slave
logic pslverr;
logic addr_valid;


clocking cb@(posedge pclk);
 default input #1step output #1;

 output transfer, pwrite, write_data, paddr;
 input  cpu_ready, pslverr, read_data_out;

 endclocking

/* modport dut (
    input  preset_n, pclk,
    input  cpu_addr, cpu_wdata, cpu_wr, cpu_en,
    output cpu_ready, pslverr, cpu_rdata
 );

 modport tb (
    input preset_n, pclk,
    clocking cb;
 );
 */

 endinterface
