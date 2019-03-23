module cpu(
  input wire clk,
  input wire resetn,
  output wire led,
  output wire [7:0] debug_port1,
  output wire [7:0] debug_port2,
  output wire [7:0] debug_port3,
  output wire [7:0] debug_port4,
  output wire [7:0] debug_port5,
  output wire [7:0] debug_port6,
  output wire [7:0] debug_port7
  );

// ~/.apio/packages/toolchain-icestorm/bin/arachne-pnr -d 8k -P cm81 -p pins.pcf -o hardware.asc hardware.blif
 
 /* .section - Register File (rf)*/
/*
Although there are 32 allocated registers in the register file

We define R0 - R15 as the normal registers
*/
localparam nreg = 16;
localparam reg_width = 32;
localparam reg_addr_width = $clog2(nreg);

  reg [reg_width - 1:0] rf_d1, rf_d2;   // register data output1, output2
  reg [reg_addr_width - 1:0] rf_rs1, rf_rs2;   // read address 1, 2
  reg [reg_addr_width - 1:0] rf_ws;    // write address
  reg [reg_width - 1:0] rf_wd;   // write data
  reg rf_we;          // write enable

always @(*) begin
  rf_rs1 = rf_Rn;
  rf_rs2 = rf_Rm;

  rf_ws = rf_wb[11:8];
  rf_wd = mf_wb[2] ? data_mem_rd : alu_wb;      // writeback select, mf_wb[2]
  rf_we = vf_wb & mf_wb[0]; // ALU result valid, write enabled
end

//   reg [reg_width-1+reg_addr_width+1:0] rf_write_reg;

// always @(posedge clk)
//   rf_write_reg <= {vf_wb, rf_ws, rf_wd}; // For WB -> EX [Valid, Tag (R_address), Data], 32 + 4 + 1 = 37 bits

reg_file regf(
  clk, resetn,

  // Inputs
  rf_rs1, rf_rs2,       // Read Addresses
  rf_wd, rf_ws, rf_we,  // Write Data, Address, Enable

  pc,  // Program counter

  // Outputs
  rf_d1, rf_d2
);
defparam regf.nreg = nreg;
defparam regf.reg_width = reg_width;
defparam regf.reg_addr_width = reg_addr_width;

/* .section - Data Storage */
localparam data_width = 32;
localparam data_width_l2b = $clog2(data_width / 8);
localparam data_words = 512;
localparam data_words_l2 = $clog2(data_words);
localparam data_addr_width = data_words_l2;

  reg [data_width - 1:0]  data_mem_rd;
  reg [data_width - 1:0]  data_mem_wd;
  reg [data_addr_width - 1:0] data_addr;
  reg data_mem_we;

always @(*) begin
  /*
    fwd_flags[5] = Rn conflict, fwd_flags[4] = Rm conflict
    LDR -> Rd, Rn = {Destination register, Address}
    STR -> Rn, Rm = {Address, register to store}
  */
  data_addr = fwd_flags[4] ? rf_wd[data_addr_width - 1:0] : alu_mem[data_addr_width - 1:0]; 
  data_mem_wd = fwd_flags[5] ? rf_wd : wd_mem;   
  data_mem_we = vf_mem & mf_mem[3]; // valid, memory write enable (MWE)
end

memory mem(
    clk,
    // Inputs - Write Enable, Read/Write Address, Write Data
    data_mem_we, data_addr, data_mem_wd,
    data_mem_rd
);
defparam mem.data_width = data_width;
defparam mem.data_words = data_words;
defparam mem.data_addr_width = data_addr_width;

/* .section - Instruction Fetch */
localparam code_width = 32;   // Instruction Width
localparam code_width_l2b = $clog2(data_width / 8);
localparam code_words = 512;  // Instruction Depth
localparam code_words_l2 = $clog2(data_words);
localparam code_addr_width = code_words_l2;// - code_width_l2b; // Kelvin note: why does code width get subtracted

  wire [code_width - 1:0]  code_mem_rd;

instruction_fetch ifetch(
  clk, resetn,
  pc,
  code_mem_rd
);
defparam ifetch.code_width = code_width;
defparam ifetch.code_words = code_words;
defparam ifetch.code_addr_width = code_addr_width;

/* .section - Instruction Decode */
  reg [3:0] cond_code;
  reg [7:0] opcode, muxflags;
  reg [3:0] rf_Rn, rf_Rm, rf_Rd;
  reg [2:0] rf_Rw;
  reg [31:0] imm32;

  reg [7:0] debug_id;
// mf_ex
// 7 CBS: Cond Branch
// 6 BS: Branch Select
// 4 DPF : Delay Pipeline flag
// 3 MWE: Memory write enable
// 2 WBS: Writeback Select
// 1 IS: Immediate Select
// 0 RFWE: Register file Write Enable
instruction_decode idecode(
  clk, resetn,
  // Input - Instruction
  inst_in,

  pc,
  cond_code, opcode, 
  muxflags,
  rf_Rn, rf_Rm, rf_Rd, 
  rf_Rw,  // Written Registers
  imm32,

  // Output - Program Counter, Debug 8-bit value
  debug_id
);

  reg [code_width - 1:0] prev_inst;
always @(posedge clk) begin
  prev_inst <= code_mem_rd;
end
  
  reg [code_width - 1: 0] inst_in;
always @(*) begin
  // If need to stall, feed previous instruction
  // MEM = LD, EX = NOT STR
  // inst_in = mf_mem[4] &  ~mf_ex[3] ? prev_inst : code_mem_rd;
  inst_in = mf_mem[4] ? prev_inst : code_mem_rd;
end

defparam idecode.code_width = code_width;   // Instruction Width
defparam idecode.code_words = code_words;  // Instruction Depth
defparam idecode.reg_width = reg_width;
defparam idecode.reg_addr_width = reg_addr_width;
defparam idecode.data_width = data_width;
defparam idecode.data_addr_width = data_addr_width;

/* .section - ALU (Execute) */
  // A2.4
  //cpsr registers (flags)
  //[3] negative (N), [2] zero (Z), [1] carry (C), [0] overflow(V)
  reg [31:0] cpsr_prev, cpsr_next;
  reg [31:0] A, B;
  reg [31:0] ALU_out;
  reg [7:0] op;
  reg [3:0] cc;
  reg VF; // Valid/Squash flag

always @(posedge clk)
  if(!resetn)
    cpsr_prev <= 32'd0;
  else
    cpsr_prev <= cpsr_next;
 // fwd_* = {wb_mem, wb_ex, mem_ex}
always @(*) begin
  op = opcode;
  cc = cond_code;

  // ALU Input A, mux PC in if address was R15
  A = (rf_ex[7:4] == 4'hF) ? pc_prev: rf_d1; 
  A = fwd_flags[3] ? rf_wd : A;  // WB -> EX
  A = fwd_flags[1] ? alu_mem: A;  // MEM -> EX
  // ALU Input 
  // Change B based on control flags mf_ex[1] = IS, immediate select
  // Otherwise, mux PC in if address was R15
  B = mf_ex[1] ? imm32 : (rf_ex[3:0] == 4'hF) ? pc_prev : rf_d2;
  B = fwd_flags[2] ? rf_wd : B;  // WB -> EX
  B = fwd_flags[0] ? alu_mem: B;  // MEM -> EX
end
  wire [7:0] debug_ex;
alu alu_m(
    clk, resetn,
    // Inputs
    cc, op,
    A, B,
    cpsr_prev,
    cpsr_next,

    // Outputs
    VF,
    ALU_out,

    debug_ex
);

/* .section FIFO */
/* 
One-cycle delay
  EX -> MEM
    ALU_out to data_mem_ws/wd

Two-cycle delay
  EX -> WB
    ALU_out to rf_wd
  ID -> MEM / Update PC
    mf_ex.BS/CBS/MWE to EX

  Three-cycle delay
  ID -> WB
    rf_Rd to rf_ws - Register Writeback address
    RFWE to rf_we - Register Writeback enable
    WBS to wb_sel - Writeback select (memory vs. ALU)
*/

// mf_ex
// 7 CBS: Cond Branch
// 6 BS: Branch Select
// 3 MWE: Memory write enable
// 2 WBS: Writeback Select
// 1 IS: Immediate Select
// 0 RFWE: Register file Write Enable
  reg [31:0] alu_mem, alu_wb;
  reg [(3*reg_addr_width+3)-1:0] rf_ex, rf_mem, rf_wb; // 12 + 3 -> 15 bits each
  reg [7:0] mf_ex, mf_mem, mf_wb;
  reg [reg_width-1:0] wd_mem;
  reg vf_mem, vf_wb;

always @(posedge clk) begin
  if(mf_ex[7]) // Branch and link
    alu_mem <= pc - 32'd4;
  else
    alu_mem <= ALU_out; // ALU out wire
  alu_wb <= alu_mem;

  rf_ex <= {rf_Rw, rf_Rd, rf_Rn, rf_Rm};
  rf_mem <= rf_ex;
  rf_wb <= rf_mem;

  mf_ex <= muxflags;
  mf_mem <= mf_ex; // mf_ex sync reg
  mf_wb <= mf_mem;

  wd_mem <= rf_d2;  // For stores - ALU computes address, rf_d2 is the register data

  // Valid wire & (not branch | branch link) & (not LD in mem stage or is STR) - STR condition removed
  //                                              NO-OP after Load
  vf_mem <= VF & (~mf_ex[6] | mf_ex[7]) & (~mf_mem[4] );//| mf_ex[3]);
  vf_wb <= vf_mem;
end
  // fwd_* = {wb_mem, wb_ex, mem_ex}
  reg [5:0] fwd_flags;
  reg [nreg-1:0] rf_use_ex, rf_use_mem;
  reg [nreg-1:0] rf_def_mem, rf_def_wb; 
hazard_detect res(
 // rf_use, rf_def,
  mf_ex, mf_mem, mf_wb,
  rf_ex, rf_mem, rf_wb,
  vf_mem, vf_wb,
  fwd_flags,
  rf_use_ex, rf_use_mem,
  rf_def_mem, rf_def_wb
);
defparam res.nreg = nreg;
defparam res.reg_addr_width = reg_addr_width;

/* .section Program counter*/
  reg [31:0] pc, pc_next, pc_prev;
  
  // Increment PC by 4 every cycle
  always @(*) begin
  // TODO: Insert logic to change pc_next based on control signals
    if (!resetn | pc >= (code_words << 2)) 
      pc_next = 0;
    else if(mf_ex[4]) // &  ~muxflags[3]) // (IF) > not LDR/STR (ID) > DPF true (EX)  
      pc_next = pc;   // Freeze PC for one cycle
    else if(~mf_mem[4] & mf_ex[6] & VF) // Not preceded by load & Branch Signal (mf_ex[6]) & Success Flag (ALU has result)
      pc_next = ALU_out; // pc_next = next address
    else
      pc_next = pc + 4;
  end

  always @(posedge clk) begin
    pc <= pc_next;
    pc_prev <= pc;
  end

  /* .section - Output */
assign led = pc[2]; // make the LED blink on the low order bit of the PC

//  {wb_mem, wb_ex, mem_ex}
// fwd_flags

// Assign DEBUG port values here (8-bits)
assign debug_port1 = pc[9:2];
assign debug_port2 = opcode; 
assign debug_port3 = ALU_out[7:0];         
assign debug_port4 = data_addr[7:0];    
assign debug_port5 = {vf_wb, vf_mem,  VF & (~mf_ex[6] | mf_ex[7]) & (~mf_mem[4])};      
assign debug_port6 = fwd_flags; // {wb_mem, wb_ex, mem_ex}
assign debug_port7 = rf_we ? rf_wd : 8'hfc;   // ALU debug value

endmodule
