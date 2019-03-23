module alu(
    input wire clk, resetn,

    input wire [3:0] cc,         // Conditional Code NZCV
    input wire [7:0] ALU_sel,    // ALU_sel (opcode)
    input wire [31:0] A, B,      // ALU inputs A B
    input wire [31:0] cpsr_in,      // Current Program Status Register

    output wire [31:0] cpsr_out,
    output wire VF, // Valid flag
    output wire [31:0] ALU_out,   // ALU result

    output wire [7:0] debug_alu
);

reg [1:0] branch_ps, branch_ns;

reg [31:0] ALU_result; // ALU result

wire N, Z, C, V;  // Arithmetic flags
wire cond_status;

reg ret_result; // Return ALU result
reg islogical;  // Logical operation (do not write V flag)
reg write_cpsr; // Update cpsr

assign cond_status = check_cond(cc, cpsr_in[31:28]);

always @(*) begin
    ALU_result = 0;
    ret_result = 1; //  Should return a value
    islogical = 0;
    write_cpsr = 0;

    branch_ns = 2'b00;
    
  
    // Check the condition register & instruction conditional field
    // if(check_cond(cc, cpsr_in)) begin
    if(cond_status) begin
        casez(ALU_sel)
        /* Arithmetic Instruction*/
            // AND - Bitwise AND
            8'b000_0000?: begin
                    ALU_result = A & B; 
                    islogical = 1;
                    write_cpsr = ALU_sel[0];
                end
            // EOR - Bitwise Exclusive-OR
            8'b000_0001?: begin
                    ALU_result = A ^ B; 
                    islogical = 1;
                    write_cpsr = ALU_sel[0];                   
                end
            // SUB - Subtraction
            8'b000_0010?: begin
                    ALU_result = A + (~B + 1); 
                    write_cpsr = ALU_sel[0];
                end
            // ADD - Addition
            8'b000_0100?: begin
                    ALU_result = A + B;
                    write_cpsr = ALU_sel[0]; 
                end
            // TST - Test
            8'b000_10001: begin
                    ALU_result = A & B; 
                    ret_result = 0;
                    write_cpsr = ALU_sel[0];
                end
            // TEQ - Test Equivalence
            8'b000_10011: begin
                    ALU_result = A ^ B; 
                    ret_result = 0;
                    write_cpsr = ALU_sel[0];
                end
            // CMP - Compare
            8'b000_10101: begin
                    ALU_result = A + (~B + 1); 
                    ret_result = 0;
                    write_cpsr = ALU_sel[0];
                end
            // CMN - Compare Negative
            8'b000_10001: begin
                    ALU_result = A + B; 
                    ret_result =  0;
                    write_cpsr = ALU_sel[0];
                end
            // ORR - Bitwise OR
            8'b000_1100?: begin
                    ALU_result = A | B;
                    islogical = 1;
                    write_cpsr = ALU_sel[0];
                end
            // MOV - MOV Immediate
            8'b0011101?: begin
                    ALU_result = B;
                    write_cpsr = ALU_sel[0];
                end

        /* Branch Instructions */ 
            8'b1010_????: begin // Branch
                    branch_ns = 2'b10;
                    ALU_result = A + B; // where B is target address (PC + 8 + imm24 (SE))
                end     
            8'b1011_????: begin // Branch with Link
                    branch_ns = 2'b10;
                    ALU_result = A + B; // where B is target address (PC + 8 + imm24 (SE))
                end     
            8'b0001_0010: begin // Branch and Exchange
                    branch_ns = 2'b10;
                    ALU_result = B;
                end
        /* Load/Store Instruction*/
            8'b010??0?1: begin // LDR
                    if(ALU_sel[3])
                        ALU_result = A + B; // rd1 = A, B = imm12
                    else
                        ALU_result = A - B;
                end
            8'b010??0?0: begin  // STR
                    if(ALU_sel[3])
                        ALU_result = A + B; // rd1 = A, B = imm12
                    else
                        ALU_result = A - B;
                end   
            default:
                ret_result = 0;            
        endcase
    end else begin
        ret_result = 0; // Failed conditional check
    end
    // Cycle 0: Branch
    // Cycle 1: ps = 10 -> squashed
    // Cycle 2: ps = 11 -> squashed
    // cycle 3: ps = 00 -> not squashed
end

assign N = ALU_result[31];  // (N)egative
assign Z = ALU_result == 0;    // (Z)ero
assign C = (A[31] & B[31]) ^ ALU_result[31]; // (C)arry
assign V = islogical ? cpsr_in[28] : (~A[31] & ~B[31] & ALU_result[31]) | (A[31] & B[31] & ~ALU_result[31]); // o(V)erflow

// always @(posedge clk) begin
//     SR <= !ret_result;
//     ALU_out <= ret_result ? ALU_result : 0;
//     cpsr_out <= (write_cpsr & ret_result) ? {N, Z, C, V, cpsr_in[27:0]} : cpsr_in;
// end
assign VF = ~(branch_ps[1] | ~ret_result);
assign cpsr_out = write_cpsr ? {N, Z, C, V, cpsr_in[27:0]} : cpsr_in;
assign ALU_out = ret_result ? ALU_result : 32'hFC_FC_FC_FC;

assign debug_alu = {3'b0, cond_status, branch_ns, branch_ps};

// Branch FSM
/*
ps:
    10: branch executed
    11: 1 cycle after branch
    00: 2 cycles after branch
*/
always @(posedge clk) begin
    if(!resetn)
        branch_ps <= 2'b00;
    else if (branch_ps[1])
        branch_ps <= branch_ps + 1;
    else if(branch_ns[1])
        branch_ps <= branch_ns;
end

/* 
Returns 1 if the condition specified in the instruction is met, otherwise returns 0 
A8-288
*/
function check_cond;
    input [3:0] cc;
    input [3:0] cpsr; // N, Z, C, V

    reg result;

    begin
        result = 0;
        case(cc[3:1])
            3'b000: result = (cpsr[2] == 1);
            3'b001: result = (cpsr[1] == 1);
            3'b010: result = (cpsr[3] == 1);
            3'b011: result = (cpsr[0] == 1);
            3'b100: result = (cpsr[1] == 1) & (cpsr[2] == 0);
            3'b101: result = (cpsr[3] == cpsr[0]);
            3'b110: result = (cpsr[3] == cpsr[0]) & (cpsr[2] == 0);
            3'b111: result = 1'b1;
        endcase
        if (cc[0]) //& cc != 4'hF) -> cc = 4'hF -> do not return
            result = !result;
        check_cond = result;
    end
endfunction

endmodule