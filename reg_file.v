module reg_file(
    input wire clk, resetn,
    input wire [reg_addr_width - 1:0] rf_rs1, rf_rs2,   // registers address
    input wire [reg_width - 1: 0] rf_wd,
    input wire [reg_addr_width - 1:0] rf_ws,            // write address
    input wire rf_we,                                   // write enable    
    input wire [reg_width - 1: 0] pc,
    output reg [reg_width - 1:0] rf_d1, rf_d2          // output reg data
);
parameter nreg = 16;
parameter reg_width = 32;
parameter reg_addr_width = 4;

reg [reg_width - 1:0] rf[0:nreg - 1];  // Define 15, 32-bit registers, (R15 = PC)

  always @(posedge clk) begin
    // rf_d1 <= (rf_rs1 == 4'hF) ? pc : rf[rf_rs1];
    // rf_d2 <= (rf_rs2 == 4'hF) ? pc : rf[rf_rs2];
    rf_d1 <= rf[rf_rs1];
    rf_d2 <= rf[rf_rs2];

    if (resetn && rf_we && (rf_ws != 15))
      rf[rf_ws] <= rf_wd;
  end

endmodule