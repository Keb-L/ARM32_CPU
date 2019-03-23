module memory
(
    input wire clk,
    input wire data_mem_we,
    input wire [data_addr_width - 1:0] data_addr,
    input wire [data_width - 1:0]  data_mem_wd,
    output reg [data_width - 1:0]  data_mem_rd
);
parameter data_width = 32;   
parameter data_words = 512; 
parameter data_addr_width = $clog2(data_words);

  reg [data_width - 1:0]  data_mem[data_words - 1:0];
//   reg [data_width - 1:0]  data_mem_rd;
//   reg [data_width - 1:0]  data_mem_wd;
//   reg [data_addr_width - 1:0] data_addr;
//   reg data_mem_we;
  initial begin
    $readmemh("./bin/data_mem.mem", data_mem);
  end

  always @(posedge clk) begin
    data_mem_rd <= data_mem[data_addr];
    if (data_mem_we)
        data_mem[data_addr] <= data_mem_wd;

  end

endmodule