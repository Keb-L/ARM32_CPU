/*
  Instruction Decode for ARMv7 (32-bit) Instruction Set
  A5-193
*/

/*
  SECTION A -
    DATA PROCESSING / ARITHMETIC INSTRUCTIONS
*/
  /* REGISTER-BASED INSTRUCTIONS */

  /* (1)
    AND operation on register
    A8-326

    This instruction performs a bitwise AND of a register value and an optionally-shifted register value, and writes the
    result to the destination register. It can optionally update the condition flags based on the result.

      Assembler Syntax
      AND{S}{<c>}{<q>} {<Rd>,} <Rn>, <Rm> {, <shift>}
        S: Instruction update CPSR flags
        <Rd>: Destination Register
        <Rn>: 1st operand Register
        <Rm>: 2nd operand register (Optionally shifted)
        <shift> shift value to apply to value read from <Rm>
  */
  task AND_reg;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rd, Rn, Rm;
    output rf_we;
    begin
      Rn = code_mem_rd[19:16];
      Rd = code_mem_rd[15:12];
      // imm5 = code_mem_rd[11:7];
      // type = code_mem_rd[6:5];
      Rm = code_mem_rd[3:0];

      Rw = 3'b111; // Assigned Rd, Rn, Rm
      rf_we = 1;
    end
  endtask

  /* (2)
    Exclusive OR (register)
    A8-384

    Bitwise Exclusive OR (register) performs a bitwise Exclusive OR of a register value and an optionally-shifted
    register value, and writes the result to the destination register. It can optionally update the condition flags based on
    the result.

      Assembler Syntax
      EOR{S}{<c>}{<q>} {<Rd>,} <Rn>, <Rm> {, <shift>}
        S: Instruction update CPSR flags
        <Rd>: Destination Register
        <Rn>: 1st operand Register
        <Rm>: 2nd operand register (Optionally shifted)
        <shift> shift value to apply to value read from <Rm>
  */
  task EOR_reg;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rd, Rn, Rm;
    output rf_we;
    begin
      Rn = code_mem_rd[19:16];
      Rd = code_mem_rd[15:12];
      // imm5 = code_mem_rd[11:7];
      // type = code_mem_rd[6:5];
      Rm = code_mem_rd[3:0];

      Rw = 3'b111; // Assigned Rd, Rn, Rm
      rf_we = 1;
    end
  endtask

  /* (3)
    OR (register)
    A8-518

    Bitwise OR (register) performs a bitwise (inclusive) OR of a register value and an optionally-shifted register value,
    and writes the result to the destination register. It can optionally update the condition flags based on the result.

      Assembler Syntax
      ORR{S}{<c>}{<q>} {<Rd>,} <Rn>, <Rm> {, <shift>}
        S: Instruction update CPSR flags
        <Rd>: Destination Register
        <Rn>: 1st operand Register
        <Rm>: 2nd operand register (Optionally shifted)
        <shift> shift value to apply to value read from <Rm>
  */
  task ORR_reg;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rd, Rn, Rm;
    output rf_we;
    begin
      Rn = code_mem_rd[19:16];
      Rd = code_mem_rd[15:12];
      // imm5 = code_mem_rd[11:7];
      // type = code_mem_rd[6:5];
      Rm = code_mem_rd[3:0];      
      
      Rw = 3'b111; // Assigned Rd, Rn, Rm
      rf_we = 1;
    end
  endtask

  /* (4)
    Subtraction operation on Register
    A8-712

    This instruction subtracts an optionally-shifted register value from a register value, and writes the result to the
    destination register. It can optionally update the condition flags based on the result.

      Assembler Syntax
      SUB{S}{<c>}{<q>} {<Rd>,} <Rn>, <Rm> {, <shift>}
        S: Instruction update CPSR flags
        <Rd>: Destination Register
        <Rn>: 1st operand Register
        <Rm>: 2nd operand register (Optionally shifted)
        <shift> shift value to apply to value read from <Rm>
  */
  task SUB_reg;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rd, Rn, Rm;
    output rf_we;

    begin
      Rn = code_mem_rd[19:16];
      Rd = code_mem_rd[15:12];
      // imm5 = code_mem_rd[11:7];
      // type = code_mem_rd[6:5];
      Rm = code_mem_rd[3:0];
      
      Rw = 3'b111; // Assigned Rd, Rn, Rm
      rf_we = 1;
    end
  endtask

  /* (5)
    Addition operation on Register
    A8-312

    This instruction adds a register value and an optionally-shifted register value, and writes the result to the destination
    register. It can optionally update the condition flags based on the result.

      Assembler Syntax
      ADD{S}{<c>}{<q>} {<Rd>,} <Rn>, <Rm> {, <shift>}
        S: Instruction update CPSR flags
        <Rd>: Destination Register
        <Rn>: 1st operand Register
        <Rm>: 2nd operand register (Optionally shifted)
        <shift> shift value to apply to value read from <Rm>
  */
  task ADD_reg;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rd, Rn, Rm;
    output rf_we;
    begin
      Rn = code_mem_rd[19:16];
      Rd = code_mem_rd[15:12];
      // imm5 = code_mem_rd[11:7];
      // type = code_mem_rd[6:5];
      Rm = code_mem_rd[3:0];

      Rw = 3'b111; // Assigned Rd, Rn, Rm
      rf_we = 1;
    end
  endtask

  /* (6)
    Test operation on register
    A8-746

    Test (register) performs a bitwise AND operation on a register value and an optionally-shifted register value. It
    updates the condition flags based on the result, and discards the result.

      Assembler Syntax
      TST{<c>}{<q>} <Rn>, <Rm> {, <shift>}
        <Rn>: 1st operand Register
        <Rm>: 2nd operand register (Optionally shifted)
        <shift> shift value to apply to value read from <Rm>
  */
  task TST_reg;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rn, Rm;
    begin
      Rn = code_mem_rd[19:16];
      // imm5 = code_mem_rd[11:7];
      // type = code_mem_rd[6:5];
      Rm = code_mem_rd[3:0];

      Rw = 3'b011; // Assigned Rn, Rm
    end
  endtask

  /* (7)
    Test Equivalence operation on register
    A8-741

    Test Equivalence (register) performs a bitwise exclusive OR operation on a register value and an optionally-shifted
    register value. It updates the condition flags based on the result, and discards the result.

      Assembler Syntax
      TEQ{<c>}{<q>} <Rn>, <Rm> {, <shift>}
        <Rn>: 1st operand Register
        <Rm>: 2nd operand register (Optionally shifted)
        <shift> shift value to apply to value read from <Rm>
  */
  task TEQ_reg;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rn, Rm;
    begin
      Rn = code_mem_rd[19:16];
      // imm5 = code_mem_rd[11:7];
      // type = code_mem_rd[6:5];
      Rm = code_mem_rd[3:0];

      Rw = 3'b011; // Assigned Rn, Rm
    end
  endtask

  /* (8)
    Compare operation on registers
    A8-372

    Compare (register) subtracts an optionally-shifted register value from a register value. It updates the condition flags
    based on the result, and discards the result.

      Assembler Syntax
      CMP{<c>}{<q>} <Rn>, <Rm> {, <shift>}
        <Rn>: 1st operand Register
        <Rm>: 2nd operand register (Optionally shifted)
        <shift> shift value to apply to value read from <Rm>
  */
  task CMP_reg;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rn, Rm;
    begin
      Rn = code_mem_rd[19:16];
      // imm5 = code_mem_rd[11:7];
      // type = code_mem_rd[6:5];
      Rm = code_mem_rd[3:0];

      Rw = 3'b011; // Assigned Rn, Rm
    end
  endtask

  /* (9)
    Compare operation on registers
    A8-366

    Compare Negative (register) adds a register value and an optionally-shifted register value. It updates the condition
    flags based on the result, and discards the result.

      Assembler Syntax
      CMN{<c>}{<q>} <Rn>, <Rm> {, <shift>}
        <Rn>: 1st operand Register
        <Rm>: 2nd operand register (Optionally shifted)
        <shift> shift value to apply to value read from <Rm>
  */
  task CMN_reg;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rn, Rm;
    begin
      Rn = code_mem_rd[19:16];
      // imm5 = code_mem_rd[11:7];
      // type = code_mem_rd[6:5];
      Rm = code_mem_rd[3:0];

      Rw = 3'b011; // Assigned Rn, Rm
    end
  endtask

  /* (10)
    MOV(immediate)
    A8-484

    Move (immediate) writes an immediate value to the destination register. It can optionally update the condition flags
    based on the value.

    cond_00_1_1101_S_0000_Rd_imm12

      Assembler Syntax
      MOV{S}{<c>}{<q>} <Rd>, #<const>
        <Rd> The destination register
        <const> The immediate value to be placed in <Rd> (0-65535)
  */
  task MOV_imm;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rd;
    output [31:0] imm32;
    output RFWE, IS;
    begin
      Rd = code_mem_rd[15:12];
      imm32 = {20'd0, code_mem_rd[11:0]};
      RFWE = 1;
      IS = 1;

      Rw = 3'b100; // Assigned Rd
    end
  endtask

/*
  SECTION B -
    CONTROL FLOW / BRANCH INSTRUCTIONS
*/
  /* (1)
    Branch
    A8-334

    Branch causes a branch to a target address

      Assembler Syntax
      B{<c>}{<q>} <label>
        <label> The label of the instruction that is to be branched to. The assembler calculates the required value of
                the offset from the PC value of the B instruction to this label, then selects an encoding that sets imm32
                to that offset.
  */
  task B_imm;
    input [31:0] code_mem_rd;
    input [31:0] pc;
    output [2:0] Rw;
    output [3:0] Rn;
    output [31:0] imm32;
    output IS, BS, BLS;
    begin
      imm32 = 4 + {{6{code_mem_rd[23]}}, code_mem_rd[23:0], 2'b00};
      Rn = 4'hF;

      // mux control signals
      IS = 1;
      BS = 1;
      BLS = 0; 

      Rw = 3'b010; // Assigned Rn
    end
  endtask

  /* (2)
    Branch with Link
    A8-348

    Branch with Link calls a subroutine at a PC-relative address

      Assembler Syntax
      BL{X}{<c>}{<q>} <label>
      <label> The label of the instruction that is to be branched to.
              BL uses encoding T1 or A1. The assembler calculates the required value of the offset from the PC
              value of the BL instruction to this label, then selects an encoding with imm32 set to that offset.

  */
  task BL_imm;
    input [31:0] code_mem_rd;
    input [31:0] pc;
    output [2:0] Rw;
    output [31:0] imm32;
    output [3:0] Rd;
    output RFWE, IS, BS, BLS;
    begin
      imm32 = (pc + 4) + {{6{code_mem_rd[23]}}, code_mem_rd[23:0], 2'b00};
      Rd = 4'hE; // Register 14 (LR)
      
      Rw = 3'b100; // Assigned Rd
      // Mux control signals
      IS = 1;
      BS = 1;
      RFWE = 1;
      BLS = 1; 
    end
  endtask

  /*(3)
    Branch and Exchange
    A8-352
    
    Branch and Exchange causes a branch to an address and instruction set specified by a register.
    
    | cond 4 | 0001 0010 | (1111) (1111) (1111) | 0001 | Rm 4 |

      Assembler Syntax
      BX{<c>}{<q>} <Rm>
      
      <Rm> The register that contains the branch target address
  */
  task BX_reg;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rm;
    output BS, BLS;

    begin
      Rm = code_mem_rd[3:0];
      Rw = 3'b001;
      BS = 1;
      BLS = 0;
    end

  endtask
/*
  SECTION C -
    LOAD / STORE
*/
  /* (1)
    LOAD (immediate, ARM)
    A8-408

    Load Register (immediate) calculates an address from a base register value and an immediate offset, loads a word
    from memory, and writes it to a register. It can use offset, post-indexed, or pre-indexed addressing

    Assembler Syntax
    LDR<c> <Rt>, [<Rn>{, #+/-<imm12>}]
      <Rt>: Destination Register
      <Rm>: Data Register
      <imm12>: Offset constant to apply to Rn
  */
  task LDR_imm;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rd, Rn;
    output [31:0] immVal;
    output DPF, RFWE, WBS, IS;
    begin
      Rd = code_mem_rd[15:12];
      Rn = code_mem_rd[19:16];
      Rw = 3'b110;

      immVal =  {20'd0, code_mem_rd[11:0]}; // load Address into Memory
      DPF = 1;
      RFWE = 1; // Register File Write Enable
      WBS = 1;   // Writeback Select (memory)
      IS = 1; // Immediate select
    end
  endtask

  /* (3)
    STORE (immediate, ARM)
    A8-674

    Store Register (immediate) calculates an address from a base register value and an immediate offset, and stores a
    word from a register to memory. It can use offset, post-indexed, or pre-indexed addressing.

    Assembler Syntax
      STR<c> <Rt>, [<Rn>{, #+/-<imm12>}]
      <Rt>: Destination Register
      <Rn>: Data Register
      <imm12>: Offset constant to apply to Rn
  */
  task STR_imm;
    input [31:0] code_mem_rd;
    output [2:0] Rw;
    output [3:0] Rn, Rm; 
    output [31:0] immVal;
    output MWE, IS;
    begin
      Rn = code_mem_rd[19:16];
      Rm = code_mem_rd[15:12]; // Rt
      Rw = 3'b011;
      immVal = {20'd0, code_mem_rd[11:0]}; // Store address into memory
      MWE = 1;
      IS = 1;
    end
  endtask
