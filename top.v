module top (
  input  pin_clk,

  inout  pin_usb_p,
  inout  pin_usb_n,
  output pin_pu,

  output pin_led

  );

  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// generate 48 mhz clock
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  wire clk_48mhz;
  wire clk_locked;
  
// OUT = Input X (DIVF + 1) / (2^(DIVQ) X (DIVR + 1))
// Input = 16Mhz
// OUT = 16Mhz X 96 / (2^4 * 1) = 
  SB_PLL40_CORE #(
    .DIVR(4'b0000),
    .DIVF(7'b0101111),
    .DIVQ(3'b100),
    .FILTER_RANGE(3'b001),
    .FEEDBACK_PATH("SIMPLE"),
    .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
    .FDA_FEEDBACK(4'b0000),
    .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
    .FDA_RELATIVE(4'b0000),
    .SHIFTREG_DIV_MODE(2'b00),
    .PLLOUT_SELECT("GENCLK"),
    .ENABLE_ICEGATE(1'b0)
  ) usb_pll_inst (
    .REFERENCECLK(pin_clk),
    .PLLOUTCORE(clk_48mhz),
    .PLLOUTGLOBAL(),
    .EXTFEEDBACK(),
    .DYNAMICDELAY(),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .LATCHINPUTVALUE(),
    .LOCK(clk_locked),
    .SDI(),
    .SDO(),
    .SCLK()
  );

  // Generate reset signal (48Mhz clock domain)
  reg   [12:0] reset_cnt = 0;
  wire  resetn = &reset_cnt;
  always @(posedge clk_48mhz)
    if (clk_locked)
      reset_cnt <= reset_cnt + !resetn;

  // generate some slower clocks
  reg clk_24mhz;
  reg clk_12mhz;
  always @(posedge clk_48mhz) clk_24mhz = !clk_24mhz;
  always @(posedge clk_24mhz) clk_12mhz = !clk_12mhz;
  wire clk_logic = clk_12mhz; // Run most of the USB uart at 12mhz

  wire uart_tx_ready;
  reg uart_strobe;
  reg [7:0] uart_tx_data;
  reg uart_tx_strobe;

  wire uart_rx_strobe;
  wire [7:0] uart_rx_data;

  wire host_presence;

  wire usb_p_tx;
  wire usb_n_tx;
  wire usb_tx_en;
  wire usb_p_rx;
  wire usb_n_rx;
  wire reset;
  assign reset = !resetn;

  usb_serial serial(
    .clk_48mhz(clk_48mhz),
    .clk(clk_logic),
    .reset(reset),
    .host_presence(host_presence),
    .uart_tx_ready(uart_tx_ready),
    .uart_tx_strobe(uart_tx_strobe),
    .uart_tx_data(uart_tx_data),
    .uart_rx_strobe(uart_rx_strobe),
    .uart_rx_data(uart_rx_data),
    .usb_p_tx(usb_p_tx),
    .usb_n_tx(usb_n_tx),
    .usb_p_rx(usb_p_rx),
    .usb_n_rx(usb_n_rx),
    .usb_tx_en(usb_tx_en)
  );

  // Generate the slow speed clock
  localparam slow_clock_size = 23;
  reg [slow_clock_size:0]  slow_clock;
  wire clk_a1hz;
  always @(posedge clk_48mhz) slow_clock <= slow_clock + 1;
  assign clk_a1hz = slow_clock[slow_clock_size];

  // Generate the slow speed reset signal
  reg   [4:0] slow_reset_cnt = 0;
  wire  slow_resetn = &slow_reset_cnt;
  always @(posedge clk_a1hz)
    if (clk_locked)
      slow_reset_cnt <= slow_reset_cnt + !slow_resetn;

  localparam debug_bytes = 8; // must be power of two
  localparam debug_bytes_l2 = $clog2(debug_bytes);

  reg [7:0] data[0:debug_bytes - 1];
  wire [7:0] data_wd[0:debug_bytes - 1];
  reg [debug_bytes_l2:0] byte_output_count;

  // Data from the debugger
  reg [7:0] uart_out_data;
  wire uart_out_valid;
  reg uart_out_ready;

  // Data being sent to the debugger
  reg [7:0] uart_in_data;
  reg uart_in_valid;
  wire uart_in_ready;

// Send data to the USB port for debugging
  always @(posedge clk_a1hz) begin
    data[0] <= data[0] + 1; // Delete this if you don't want a slow speed cycle counter, but it's highly recommended.

    data[1] <= data_wd[1];
    data[2] <= data_wd[2];
    data[3] <= data_wd[3]; 
    data[4] <= data_wd[4];
    data[5] <= data_wd[5];
    data[6] <= data_wd[6];
    data[7] <= data_wd[7];
  end


  cpu the_cpu(clk_a1hz, slow_resetn, pin_led, 
              data_wd[1], data_wd[2], data_wd[3], data_wd[4], data_wd[5], data_wd[6], data_wd[7]);


// Out delay slows down output to the serial port.  The CPU runs at ~ 1Hz
// so no need to spam at 12Mbits/second :).  Spamming at full speed
// also causes bytes to fall on the floor because the python debugger
// can't read the usb port that fast.
localparam out_delay_max  = 13;
reg [out_delay_max:0]   out_delay;

always @(posedge clk_logic) begin
    if (!resetn) begin
        byte_output_count <= 0;
        out_delay <= 0;
    end
    else begin
        // Always see if there is a ready byte.  If there is, take it.
        if (uart_rx_strobe) begin
          uart_out_data <= uart_rx_data;          
        end

        out_delay <= out_delay + 1;
        if (uart_tx_ready && out_delay == 0) begin
            if (byte_output_count[debug_bytes_l2])
              uart_tx_data <= 8'b11111111;
            else
              uart_tx_data <= data[byte_output_count[debug_bytes_l2 - 1:0]];
            byte_output_count <= byte_output_count + 1;
            uart_tx_strobe <= 1;
        end else
          uart_tx_strobe <= 0;
    end
end

  // The commented out code would cause the USB port to drop
  // off the USB bus during reset.  Doesn't seem necessary.
  assign pin_pu = 1'b1;//(resetn) ? 1'b 1 : 1'bz;

  wire usb_p_rx_io;
  wire usb_n_rx_io;
  assign usb_p_rx = usb_tx_en ? 1'b1 : usb_p_rx_io;
  assign usb_n_rx = usb_tx_en ? 1'b0 : usb_n_rx_io;

tristate usbn_buffer(
  .pin(pin_usb_n),
  .enable(usb_tx_en),
  .data_in(usb_n_rx_io),
  .data_out(usb_n_tx)
  );

tristate usbp_buffer(
  .pin(pin_usb_p),
  .enable(usb_tx_en),
  .data_in(usb_p_rx_io),
  .data_out(usb_p_tx)
  );
endmodule

module tristate(
  inout pin,
  input enable,
  input data_out,
  output data_in
);
  SB_IO #(
    .PIN_TYPE(6'b1010_01) // tristatable output
  ) buffer(
    .PACKAGE_PIN(pin),
    .OUTPUT_ENABLE(enable),
    .D_IN_0(data_in),
    .D_OUT_0(data_out)
  );
endmodule
