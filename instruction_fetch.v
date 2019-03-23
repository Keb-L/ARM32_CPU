/*
 * Kelvin Lin, Nate Park
 * Computer Architecture I
 * Winter 2019
 * 
 * Implements instruction fetch operation
 */
module instruction_fetch
(
  input wire clk, resetn,
  input wire [31:0] pc, // Program counter
  output reg [code_width - 1:0]  code_mem_rd
);

parameter code_width = 32;   // Instruction Width
parameter code_words = 512;  // Instruction Depth
parameter code_addr_width = 9;

  reg [code_width - 1:0]  code_mem[code_words - 1:0]; // Define instruction storage structure
  wire [code_addr_width - 1: 0] code_addr;
  // wire [7:0] instr_id;
  // wire isbranch;
  // wire [code_width - 1: 0] offset;
  // reg [29:0]  pc; // 30 bits for program counter

  initial begin
      // Use one of these two
      // $readmemb("./bin/load_store_conflict_bypass.mem", code_mem);
      $readmemb("./bin/lotsa_instructions.mem", code_mem);
  end
  /*
   *31|    28|27         20|19                    0|
   *  | cond |  operation  |                       |
   */
  // Assign address into code
  assign code_addr = pc[code_addr_width + 1:2];
  // assign isbranch =  (code_mem[code_addr][20:27] == 4'h_a) ? 1 : 0; 
  // // SignExtend(Adr24:'00', 32)
  // assign offset = (isbranch) ? {{8{code_mem[code_addr][23]}}, code_mem[code_addr][0:23]}: 1;

  // always @(negedge clk) begin
  //   code_mem_rd <= code_mem[code_addr];
  // end

  // always @(pc) begin
  //   code_mem_rd = code_mem[code_addr];
  // end

  always @(posedge clk) begin
    if (!resetn)
      code_mem_rd <= 32'hFF_FF_FF_FF;
    else
      code_mem_rd <= code_mem[code_addr];
  end

  // always @(posedge clk) begin
  //   if (!resetn) begin
  //     pc <= 0;
  //   end else if (pc >= code_words || pc < 0) begin // PC limit
  //     pc <= 0;
  //   end else begin 
  //     pc <= pc + offset;
  //   end 
  // end
endmodule