/*
 * Kelvin Lin, Nate Park
 * Computer Architecture I
 * Winter 2019
 *
 * Implements code_mem_rduction decode operation, maintains the program counter
 * and assigns register outputs
 */
module instruction_decode(
    input wire clk, resetn,
    input wire [code_width - 1:0] code_mem_rd,
    input wire [31:0] pc,

    output reg [3:0] cond_code,
    output reg [7:0] opcode, 
    output wire [7:0] muxflags,
    
    output reg [reg_addr_width - 1:0] Rn, Rm, Rd, 
    output reg [2:0] Rw,
    output reg [31:0] imm32, 

    // Program Counter
    output reg [7:0] debug_id
);

parameter code_width = 32;   // Instruction Width
parameter code_words = 512;  // Instruction Depth

parameter reg_width = 32;
parameter reg_addr_width = 5;

parameter data_width = 32;
parameter data_addr_width = 5;

`include "armv7_set.v"

/*
 * Clock outputs into registers
 *  
 * cond_code  - instruction conditional code
 * opcode     - 8-bit op code
 * Rn, Rm, Rd - Register addresses (rs1, rs2, ws)
 * imm32      - 32-bit immediate value
 * muxflags   - cpu mux flags 
 *  BLS : Conditional Branch
 *  BS : Branch Signals
 *  DPF : Delay Pipeline Flag
 *  MWE : Memory Write Enable
 *  WBS : Writeback Select
 *  IS : Immediate Select
 *  RFWE : Register File Write Enable
 */
always @(posedge clk) begin
  cond_code <= code_mem_rd[31:28];  // Execution Conditions
  opcode <= code_mem_rd[27:20];     // op code (1 byte)
  // muxflags <= {BLS, BS, 1'b0, DPF, MWE, WBS, IS, RFWE};

  imm32 <= immVal;
end
assign muxflags = {BLS, BS, 1'b0, DPF, MWE, WBS, IS, RFWE};

// High-level Instruction elements
reg [3:0] cond;
reg [2:0] op_type;

reg op;
reg [4:0] op1;
reg [3:0] op2;
reg [31:0] immVal;

// reg [3:0] Rd, Rm, Rn;
reg [2:0] Rw;

// BLS: Branch Link flag
// BS: Branch
// MWE: Memory write enable
// WBS: Writeback Sel
// IS: Immediate
// RFWE: Register file Write Enable
reg BLS, BS, DPF, MWE, WBS, IS, RFWE; 

// Combinational block
always @(*) begin
  // Register addresses
  Rd = 4'b0;
  Rm = 4'b0;
  Rn = 4'b0;
  Rw = 3'b0;

  // Mux flags
  BLS = 1'b0;
  BS = 1'b0;
  MWE = 1'b0;
  WBS = 1'b0;
  IS = 1'b0;
  RFWE = 1'b0;
  DPF = 1'b0;
  
  immVal = 0;

  debug_id = 1;

  // See A5.1
  // 31:28, 27:25, 4 are used as encoding
  if (code_mem_rd[31:28] != 4'h_f) begin
    debug_id = 2;
    casez(code_mem_rd[27:25]) // op_type
      3'b_00?: process_data(); // Data Processing
      3'b_010: load_store(); // Load/Store Word / Unsigned Byte
      3'b_011: load_store(); // Load/Store Word / Unsigned Byte
      3'b_10?: compute_branch(); // Branch (with Link) / Block Data Transfer
    //   3'b_11?: temp = 0; // Coprocessor code_mem_rduction
    endcase
  end
  // else cond = 0xF, can only be executed unconditionally
end



/*------------------------------------------------------------------------------------------------------------------*/

task process_data;
// Define Data processing here
  begin
    op = code_mem_rd[25];
    op1 = code_mem_rd[24:20];
    op2 = code_mem_rd[7:4];
    debug_id = 3;
    if(~op) begin // Register Data Processing

      // debug_id = 4;
      // bitmask op1 & 11001 (not 10xx0)
      if ( (op1 & 5'h19) != 5'h10) begin
        // ~5'b10??0: 
        // debug_id = 5;
        if( (op2 & 4'h1) === 4'h0) begin
          // Data-processing (register)
          // cond | 0 0 0 | op | ... | imm5 | op2 | 0 | ... |
          // op2 = code_mem_rd[6:5];
          // immVal = code_mem_rd[11:7];

          // debug_id = 6;
          casez(op1)
            5'b0000?: AND_reg(code_mem_rd, Rw, Rd, Rn, Rm, RFWE);              //op1 & op2
            5'b0001?: EOR_reg(code_mem_rd, Rw, Rd, Rn, Rm, RFWE);              //op1 eor op2
            5'b0010?: SUB_reg(code_mem_rd, Rw, Rd, Rn, Rm, RFWE);              //op1 - op2
            // 4'b0011: rev_sub;             //op2 - op1
            5'b0100?: ADD_reg(code_mem_rd, Rw, Rd, Rn, Rm, RFWE);              //op1 + op2
            // 4'b0101: add_with_carry;      //op1 + op2 + carry (cpsr[1])
            // 4'b0110: sub_with_carry;      //op1 - op2 + carry - 1
            // 4'b0111: rev_sub_with_carry;  //op2 - op1 + carry - 1
            5'b10001: TST_reg(code_mem_rd, Rw, Rn, Rm);              //set cspr to op1 & op2
            5'b10011: TEQ_reg(code_mem_rd, Rw, Rn, Rm);              //set cspr to op1 eor op2
            5'b10101: CMP_reg(code_mem_rd, Rw, Rn, Rm);              //set condition(cpsr) to op1 - op2
            5'b10111: CMN_reg(code_mem_rd, Rw, Rn, Rm);              //set cpsr to op1 + op2
            5'b1100?: ORR_reg(code_mem_rd, Rw, Rd, Rn, Rm, RFWE);          //op1 or op2
            // 4'b1101: mov;                 //destination = op2
            // 4'b1110: bic;                 //destination = op1 & not op2
            // 4'b1111: mvn;                 //destination = not op2
          endcase
        end
      end else begin
        casez(op1) 
          5'b10??0: begin
            if( (op2 & 4'h8) == 4'h0 ) begin
              // Miscellaneous 5.2.12
              casez({code_mem_rd[6:4], code_mem_rd[22:21]})
                5'b00101: BX_reg(code_mem_rd, Rw, Rm, BS, BLS);
              endcase
            end

          end
        endcase
      end
      // endcase
    end else begin
      // Immediate Data Processing
        debug_id = 4;
        // bitmask op1 & 11001 (not 10xx0)
         if ( (op1 & 5'h19) != 5'h10) begin
            // debug_id = 5;
            // not 5'b10??0: 
            debug_id = 6;
            casez(op1)
              5'b1101?: MOV_imm(code_mem_rd, Rw, Rd, immVal, RFWE, IS);
            endcase
         end
    end 
  end
endtask

task load_store;
// Define Load/store processing here
  begin
    debug_id = 6;
    op1 = code_mem_rd[24:20];
    casez(op1)
      5'b??0?0: STR_imm(code_mem_rd, Rw, Rn, Rm, immVal, MWE, IS);
      5'b??0?1: LDR_imm(code_mem_rd, Rw, Rd, Rn, immVal, DPF, RFWE, WBS, IS);
    endcase
  end
endtask

task compute_branch;
// Define branch computation here
  begin
    debug_id = 6;
    casez(code_mem_rd[25:20])
      6'b10????: B_imm(code_mem_rd, pc, Rw, Rn, immVal, IS, BS, BLS);
      6'b11????: BL_imm(code_mem_rd, pc, Rw, immVal, Rd, RFWE, IS, BS, BLS);
    endcase
  end
endtask

endmodule
