`timescale 1ns / 1ps
module uart_tb();
  // Clock period for 50 MHz (20 ns period)
  localparam CLOCK_PERIOD = 20; // in nanoseconds
  localparam DATA_LENGTH = 8;
  localparam BAUD_RATE = 115200; // Baud rate
  localparam CLOCK_FREQUENCY = 50_000_000; // 50 MHz
  localparam UART_BIT_CYCLES = CLOCK_FREQUENCY / BAUD_RATE; // Clock cycles per UART bit

  real UART_BIT_PERIOD_NS = 1_000_000_000.0 / BAUD_RATE; // Bit period in nanoseconds
  real HALF_BIT_PERIOD_NS = UART_BIT_PERIOD_NS / 2.0;

  localparam OVER_SAMPLE = 8;
  localparam FIFO_DEPTH  = 8;

  localparam NUMBER_TRANSMISSION = 8;
 
  logic i_clk, i_rst_n, o_baud_clk;
  logic i_rx, o_tx;
  logic o_rx_rdy, o_tx_rdy, i_tx_req, i_rx_req;

  logic [DATA_LENGTH-1:0] o_rx_data;
  logic [DATA_LENGTH-1:0] i_tx_data;

  bit [DATA_LENGTH-1:0] test_vectors[NUMBER_TRANSMISSION];

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
    .i_tx_data,
    .o_rx_data,
    .i_tx_req,
    .i_rx_req,
    .o_rx_rdy,
    .o_tx_rdy,
    .i_rx,
    .o_tx,
    .i_cts(),
    .o_rts()
  );

  // Clock Gen
  initial i_clk = 1'b0;
  always #(CLOCK_PERIOD / 2) i_clk = ~i_clk;

  int random_wait;

  logic [DATA_LENGTH-1:0] recieved_data;

  initial begin
    //$dumpfile("uart_tb.vcd"); // Initialize VCD dump
    //$dumpvars(0, uart_tb);    // Dump all variables in this module
    
    // Initial Signal Stimuli
    i_rst_n  <= 1'b0; // Assert reset
    i_tx_req <= 0;
    repeat (2) @(posedge i_clk);
    i_rst_n  <= 1'b1;
    repeat (2) @(posedge i_clk);
    
    assert (o_tx_rdy == 1'b1) else $error("Transmit not ready at startup"); // Should be ready at startup
    
    // Load data into TX FIFO
    for (int i = 0; i < NUMBER_TRANSMISSION; i++) begin
      wait (o_tx_rdy);
      test_vectors[i] = $urandom;
      i_tx_req <= 1;
      i_tx_data <= test_vectors[i];
      @(posedge i_clk);
      i_tx_req <= 0;
    end

    for (int i = 0; i < NUMBER_TRANSMISSION; i++) begin
      // Wait for the start bit
      @(negedge o_tx);
      
      // Wait half a bit period to align to the middle of bits
      #(HALF_BIT_PERIOD_NS);
      
      // Read each data bit
      for (int j = 0; j < DATA_LENGTH; j++) begin
          #(UART_BIT_PERIOD_NS); // Wait bit period
          recieved_data[j] = o_tx; // Sample the data bit
      end
      #(UART_BIT_PERIOD_NS); // Wait for stop bit
      // TODO: ADD PARITY BIT TESTING
      assert(o_tx == 1'b1) else $error("No Stop bit detected"); // Stop bit requirement
      assert (recieved_data == test_vectors[i]) else $error("Mismatch: input TX data %b does not match serial data outputted %b", test_vectors[i], recieved_data);
    end
   
    repeat (100) @(posedge i_clk);


    $display("UART TB test complete");
    $finish;
  end

endmodule

