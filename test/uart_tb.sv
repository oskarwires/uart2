`timescale 1ns / 1ps
module uart_tb();

  // Clock period for 50 MHz (20 ns period)
  localparam CLOCK_PERIOD = 20; // in nanoseconds
  localparam DATA_LENGTH = 8;
  localparam BAUD_RATE = 115200; // Baud rate
  localparam CLOCK_FREQUENCY = 50_000_000; // 50 MHz
  localparam UART_BIT_CYCLES = CLOCK_FREQUENCY / BAUD_RATE; // Clock cycles per UART bit

  localparam OVER_SAMPLE = 8;
  localparam FIFO_DEPTH  = 8;

  localparam NUMBER_TRANSMISSION = 10;
 
  logic i_clk, i_rst_n, o_baud_clk;
  logic i_rx;
  logic o_rx_rdy, i_rx_req;

  logic [DATA_LENGTH-1:0] o_rx_data;
  logic [DATA_LENGTH-1:0] data;

  uart #(
    .DataLength(DATA_LENGTH),
    .FifoDepth(FIFO_DEPTH),
    .OverSample(OVER_SAMPLE),
    .BaudRate(BAUD_RATE),
    .SystemClockFreq(CLOCK_FREQUENCY)
  ) uut (
    .i_clk,
    .o_baud_clk,
    .i_rst_n,
    .i_ctrl(),
    .o_status(),
    .i_tx_data(),
    .o_rx_data,
    .i_tx_req(),
    .i_rx_req,
    .o_rx_rdy,
    .i_rx,
    .o_tx(),
    .i_cts(),
    .o_rts()
  );

  // Clock Gen
  initial i_clk = 1'b0;
  always #(CLOCK_PERIOD / 2) i_clk = ~i_clk;

  int modified_cycles;

  initial begin
    //$dumpfile("uart_tb.vcd"); // Initialize VCD dump
    //$dumpvars(0, uart_tb);    // Dump all variables in this module
    // Initial Signal Stimuli
    i_rst_n  <= 1'b0; /* Assert Reset */
    i_rx_req <= 0;
    i_rx <= 1'b1;
    repeat (2) @(posedge i_clk);
    i_rst_n  <= 1'b1;

    repeat (2) @(posedge i_clk);

    for (int i = 0; i < NUMBER_TRANSMISSION; i++) begin
      // Generate a random byte
      data = $urandom;

      // Start bit (0)
      i_rx <= 0;
      repeat(UART_BIT_CYCLES) @(posedge i_clk);
  
      // Transmitting 8 data bits
      for (int i = 0; i < 8; i++) begin
        i_rx <= data[i];      
        repeat(UART_BIT_CYCLES) @(posedge i_clk);
      end
  
      // Stop bit (1)
      i_rx <= 1;
  
      wait(o_rx_rdy)
      i_rx_req <= 1;
      @(posedge i_clk);
      assert (o_rx_data == data) else $error("Mismatch: transmitted data %b does not match received data %b", data, o_rx_data);
      i_rx_req <= 0;
      repeat (30) @(posedge i_clk);
    end
   
    repeat (100) @(posedge i_clk);


    $display("UART TB test complete");
    $finish;
  end

endmodule

