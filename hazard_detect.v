module hazard_detect(
    input wire [7:0] mf_ex, mf_mem, mf_wb,
    input wire [(3*reg_addr_width+3)-1:0] rf_ex, rf_mem, rf_wb,
    input wire vf_mem, vf_wb,

    output wire [5:0] fwd_flags,
    output reg [nreg-1:0] rf_use_ex, rf_use_mem,
    output reg [nreg-1:0] rf_def_mem, rf_def_wb 
);
parameter nreg = 16;
parameter reg_addr_width = 4;
/*
hazard_detect.v
    rf_use, rf_def: 16-bit registers that denote which registers are currently being used and defined
    mf_ex, mf_mem, mf_wb: 8-bit status registers from instruction decode
    rf_ex, rf_mem, rf_wb: 12-bit wires (4 bits per register) that records the Rd, Rn, Rm in each pipeline stage.
*/

/*
Hazard detect implements the combinational logic to create route bypasses in the system. 
In order to detect hazards, we implement the idea of use-define.
    A user is a register whose value is used in another computation. Users are referenced
    as Rn and Rm which are the two register read addresses entered into the register file

    A definer is a register whose value is the result of a computation. Defines are assigned during
    the writeback state and are referenced as Rd. They are are the registers entered as rf_ws, the 
    write address on the register file.

A hazard occurs when there is a use-define conflict. We define a use-define conflict as when something
that is being defined (in the pipeline) is used by subsequent instructions. Since the writeback for the
defined register has not occurred yet, we need to forward the result or create a bypass so that the value
can be used correctly for the next instruction.

However, not all values are used and some values get squashed mid-way through the pipeline. We must consider 
those conditions. A simple example might be the no-output comparison instructions such as TST. TST computes
the AND operation between two register values, however it has no output. The instruction decode must always 
assign the register addresses and so Rd defaults to 0. However, since Rd is never actually used, it should 
not be marked as a define register.

Conditions for use-define to be assigned/de-assigned:
  1. Use
    Each bit in the use register represents one register index. The register index (0-15) is assigned 
    only when the register is properly assigned. 
      Rn - Always assigned
      Rm - Assigned if not immediate and not load.

There are three types of bypass that are needed:
    1. Sequential Data Processing Relationship
        ALU     -     MEM     -     WB
        ADD(R5)      ADD(R4)     ADD(R1)
        ADD R1, R2, R3
        ADD R4, R1, R2
        ADD R5, R1, R2
      In the above two instructions, R1 is defined in the first instruction as R1 = R2 + R3.
      However, R1 is not assigned as R2 + R3 until 5 cycles later when the writeback occurs.
      Therefore, we need to identify this hazard and forward the ALU result of R2 + R3 back into 
      the appropriate ALU input so that R4 = R1 + R2 can use the correct value.

      What about
        ADD R1, R2, R3
        ADD R1, R1, R2   

    2. Load + Data Processing Relationship
        LDR R1, [R4]    // R1 = mem[R4]
        ADD R2, R3, R1  // R2 = R3 + R1
        EX  -  MEM  -  WB
        ADD   >NOP<   LDR
      For a load + data processing hazard, there are needs to be two cycles between the load and add instructions.
      Since we cannot add combinational logic in the memory module as that will cause the design to wrap and
      use significantly more logical units, we have to place the bypass during the WB stage to the EX stage. 
      Therefore, we must delay the earlier stages of the pipeline by 1 clock cycle and perform a bypass.
      
    3. Load/Store Processing Relationship or Store + Data Processing
        LDR R1, [R4]  // R1 = mem[R4]
        STR R1, [R2]  or  STR R3, [R1]
        MEM - WB
        STR   LDR
      For a load + store processing relationship, we need to add a bypass from the WB stage to the MEM stage.
      In first example, we are loading a value from memory address R4 to R1. Then, we are storing then value
      from R1 to memory address R2. This requires a bypass from the WB stage to the MEM stage as the new data in R1 
      is needed as the write data input to the memory module. In the second example, we are using the value in R1 as
      the address for the memory store. Similarly, we need to add a bypass from the WB stage to the MEM stage for this 
      case as well.

        ADD R1, R2, R3
        STR R1, [R4] or STR R4, [R1]
      In this case too, we need to take the writeback result (for the add) and bypass the result from the
      WB to the MEM stage.

      Load Conditions

      > Load-Store
      - - IF - ID - EX - MEM - WB
      0	  LD
      1	  ST	 LD
      2   ??	 ST   LD 
      Increment PC (2) if LD_EX and ST_ID

      > Load-Other
      - - IF - ID - EX - MEM - WB
      0	  LD
      1	  I1	 LD
      2   I2	 I1   LD 
      3	  I2 	 I1   I1X  LD
      Freeze PC (2) if LD_EX and not ST_ID
      Feed I1 back through
*/
  // reg [nreg-1:0] rf_use_ex, rf_use_mem;
  // reg [nreg-1:0] rf_def_mem, rf_def_wb; 
always @(*) begin
  // Defaults
  rf_use_ex = 16'b0;
  rf_use_mem = 16'b0;

  rf_def_mem = 16'b0;
  rf_def_wb = 16'b0;
  // Assign 1 is register is written (bits 14-12)
  //           14     13   12   8   4   0
  // rf_* = {Rw_d, Rw_n, Rw_m, Rd, Rn, Rm}
  rf_use_ex[rf_ex[3:0]] = rf_ex[12] ? 1'b1 : 1'b0;   // Rm_EX
  rf_use_ex[rf_ex[7:4]] = rf_ex[13] ? 1'b1 : 1'b0;   // Rn_EX
  rf_use_mem[rf_mem[3:0]] = rf_mem[12] ? 1'b1 : 1'b0;  // Rm_MEM
  rf_use_mem[rf_mem[7:4]] = rf_mem[13] ? 1'b1: 1'b0;  // Rn_MEM
  // rf_use[rf_wb[3:0]] <= 1'b1;   // Rm_WB
  // rf_use[rf_wb[7:4]] <= 1'b1;   // Rn_WB

  // rf_def[rf_ex[11:8]] <= 1'b1;  // Rd_EX
  rf_def_mem[rf_mem[11:8]] = rf_mem[14] ? 1'b1 : 1'b0; // Rd_MEM
  rf_def_wb[rf_wb[11:8]] = rf_wb[14] ? 1'b1 : 1'b0;  // Rd_WB

  /* Forwarding Cases
    MEM -> EX
    WB -> EX
    WB -> MEM
  */
end

  reg [1:0] fwd_mem_ex, fwd_wb_ex, fwd_wb_mem;
always @(*) begin
  fwd_mem_ex = 2'b0;
  fwd_wb_ex = 2'b0;
  fwd_wb_mem = 2'b0;
  // If def-use AND is non-zero -> conflict

  // mf_* = {BLS, BS, 0, DPF, MWE, WBS, IS, RFWE}
  // vf_* = Valid result at *

  // MEM -> EX
  if (rf_def_mem & rf_use_ex) begin
    fwd_mem_ex = vf_mem & mf_mem[0] ? // Valid Mem result and writing to reg file
              {rf_mem[11:8] == rf_ex[7:4], rf_mem[11:8] == rf_ex[3:0]} : 
              2'b0;
  end
  
  // WB -> EX
  if (rf_def_wb & rf_use_ex) begin
    fwd_wb_ex = vf_wb & mf_wb[0] ?  // Valid wb result and writing to reg file
              {rf_wb[11:8] == rf_ex[7:4], rf_wb[11:8] == rf_ex[3:0]} : 
              2'b0;
  end

  // WB -> MEM
  if (rf_def_wb & rf_use_mem) begin
    fwd_wb_mem = vf_wb & mf_wb[0] ? // Valid wb result and writing to reg file
              {rf_wb[11:8] == rf_mem[7:4], rf_wb[11:8] == rf_mem[3:0]} : 
              2'b0;
  end

end

assign fwd_flags = {fwd_wb_mem, fwd_wb_ex, fwd_mem_ex};
endmodule