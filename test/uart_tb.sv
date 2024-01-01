`timescale 1ns / 1ps
module uart_tb();
  // Clock period for 50 MHz (20 ns period)
  localparam ClockPeriod = 20; // in nanoseconds
  localparam DataLength = 8;
  localparam BaudRate = 115200; // Baud rate
  localparam ClockFrequency = 50_000_000; // 50 MHz
  localparam UartBitCycles = ClockFrequency / BaudRate; // Clock cycles per UART bit

  real UartBitPeriodNs = 1_000_000_000.0 / BaudRate; // Bit period in nanoseconds
  real HalfBitPeriodNs = UartBitPeriodNs / 2.0;

  /* UUT Params */
  localparam OverSample    = 8;
  localparam FifoDepth     = 8;
  localparam FlowControl   = 1;
  localparam ErrorChecking = 1;
  localparam ParityEven    = 1;

  localparam NumberTest = 8;
 
  logic i_clk, i_rst_n, o_baud_clk;
  logic i_rx, o_tx, i_cts, o_rts;
  logic o_rx_rdy, o_tx_rdy, i_tx_req, i_rx_req;

  logic [DataLength-1:0] o_rx_data;
  logic [DataLength-1:0] i_tx_data;

  logic [DataLength-1:0] test_tx_vectors[NumberTest];
  logic [DataLength-1:0] test_rx_vectors[NumberTest];

  logic [DataLength-1:0] recieved_uart_tx_data;
  logic [DataLength-1:0] recieved_uart_rx_data;
  logic recieved_uart_tx_parity_bit, calculated_uart_tx_parity_bit;
  logic recieved_uart_rx_parity_bit, calculated_uart_rx_parity_bit;

  logic [1:0] o_status; // {frame error, parity error}

  uart #(
    .DataLength(DataLength),
    .FifoDepth(FifoDepth),
    .OverSample(OverSample),
    .BaudRate(BaudRate),
    .SystemClockFreq(ClockFrequency),
    .FlowControl(FlowControl),
    .ErrorChecking(ErrorChecking),
    .ParityEven(ParityEven)
  ) uut (
    .i_clk,
    .o_baud_clk,
    .i_rst_n,
    .i_ctrl(),
    .o_status,
    .i_tx_data,
    .o_rx_data,
    .i_tx_req,
    .i_rx_req,
    .o_rx_rdy,
    .o_tx_rdy,
    .i_rx,
    .o_tx,
    .i_cts,
    .o_rts
  );
 
  // Task to write to fifo_tx
  task automatic fifo_tx_write (
    input logic [DataLength-1:0] wr_data
  );
    wait (o_tx_rdy);
    i_tx_req <= 1;
    i_tx_data <= wr_data;
    @(posedge i_clk);
    i_tx_req <= 0;
  endtask

  // Task to read fifo_rx
  task automatic fifo_rx_read (
    output logic [DataLength-1:0] rd_data
  );
    wait(o_rx_rdy);
    i_rx_req <= 1;
    @(posedge i_clk);
    rd_data = o_rx_data;
    i_rx_req <= 0;
  endtask

  // Task to read incoming transmit stream from the UUT to test TX
  task automatic recieve_uart_stream (
    output logic [DataLength-1:0] uart_packet,
    output logic                  parity_bit
  );
    @(negedge o_tx); // Wait for start bit (falling edge from 1 to 0)
      
    // Wait half a bit period to align to the middle of bits
    #(HalfBitPeriodNs);
    
    // Read each data bit
    for (int j = 0; j < DataLength; j++) begin
        #(UartBitPeriodNs);    // Wait bit period
        uart_packet[j] = o_tx; // Sample the data bit
    end
    #(UartBitPeriodNs); // Wait for stop or parity bit

    if (ErrorChecking) begin
      parity_bit = o_tx;
      #(UartBitPeriodNs); // Wait for stop bit
    end

    assert(o_tx == 1'b1) else $error("Error: No Stop bit detected"); // Stop bit requirement
  endtask

  // Task to transmit a UART packet to the UUT to test RX
  task automatic transmit_uart_stream (
    input logic [DataLength-1:0] uart_packet,
    input logic                  parity_bit,
    input logic                  no_stop_bit = 1 // Used for testing frame error
  );
    // Async assignment of value to model real world async conditions
    i_rx = 0; // Start Bit (0)
    #(UartBitPeriodNs); // Wait bit period

    // Transmitting DataLength data bits
    for (int i = 0; i < DataLength; i++) begin
      i_rx = uart_packet[i];      
      #(UartBitPeriodNs); // Wait bit period
    end

    if (ErrorChecking) begin
      i_rx = parity_bit;
      #(UartBitPeriodNs); // Wait bit period
    end
    
    if (no_stop_bit) begin
      i_rx = 0; // Insert random 0 instead of stop bit
      #(UartBitPeriodNs); // Wait bit period
    end else begin
      i_rx = 1; // Stop bit (1)
      #(UartBitPeriodNs); // Wait bit period
    end
  endtask

  task automatic calculate_parity (
    input  logic [DataLength-1:0] uart_packet,
    output logic                  parity_value
  );
    logic parity_value_even = ^uart_packet;
    parity_value = ParityEven ? parity_value_even : ~parity_value_even;
  endtask

  // Clock Gen
  initial i_clk = 1'b0;
  always #(ClockPeriod / 2) i_clk = ~i_clk;

  int random_wait;

  initial begin
    //$dumpfile("uart_tb.vcd"); // Initialize VCD dump
    //$dumpvars(0, uart_tb);    // Dump all variables in this module
    
    // Initial Signal Stimuli
    i_rst_n  <= '0; // Assert reset
    i_tx_req <= '0;
    i_rx_req <= '0;
    i_rx     <= '1; // Hold the RX line high
    i_cts    <= '1; // Permit the UUT to send
    repeat (2) @(posedge i_clk);
    i_rst_n  <= '1;
    repeat (2) @(posedge i_clk);
    
    assert (o_tx_rdy == 1'b1) else $error("Error: o_tx_rdy != 1 at startup"); // Should be ready at startup
    
    fork // Test RX and TX simultaneously
      /* ----- TESTING TX ----- */
      begin
        // Load data into TX FIFO
        for (int i = 0; i < NumberTest; i++) begin
          test_tx_vectors[i] = $urandom;
          fifo_tx_write(test_tx_vectors[i]);
        end
     
        // Read transmitted uart data
        for (int i = 0; i < NumberTest; i++) begin
          // Wait for the start bit
          recieve_uart_stream(recieved_uart_tx_data, recieved_uart_tx_parity_bit);

          if (ErrorChecking) begin
            calculate_parity(test_tx_vectors[i], calculated_uart_tx_parity_bit);
            assert (recieved_uart_tx_parity_bit == calculated_uart_tx_parity_bit) else $error("TX Test: calculated parity bit %b does not match outputted parity bit %b", calculated_uart_tx_parity_bit, recieved_uart_tx_parity_bit);
          end

          assert (recieved_uart_tx_data == test_tx_vectors[i]) else $error("TX Test: input TX data %b does not match serial data outputted %b", test_tx_vectors[i], recieved_uart_tx_data);
        end
      end
  
      /* ----- TESTING RX ----- */
      begin
        // Transmit uart data stream
        for (int i = 0; i < NumberTest; i++) begin
          test_rx_vectors[i] = $urandom;
          calculate_parity(test_rx_vectors[i], calculated_uart_rx_parity_bit);
          
          transmit_uart_stream(test_rx_vectors[i], calculated_uart_rx_parity_bit, 0);
        end
    
        // Read recieved uart data
        for (int i = 0; i < NumberTest; i++) begin
          fifo_rx_read(recieved_uart_rx_data);
          if (ErrorChecking) assert (o_status == 2'b00) else $error("RX Test: Error in UART output status, expected b00 (no error), got %b", o_status);
          assert (recieved_uart_rx_data == test_rx_vectors[i]) else $error("RX Test: input TX data %b does not match serial data outputted %b", test_rx_vectors[i], recieved_uart_rx_data);
        end
      end
    join
    
  
    /* ----- Test error checking ----- */
    if (ErrorChecking) begin
      // Simulate wrong parity bit
      for (int i = 0; i < NumberTest; i++) begin
        // Send random packet with wrong parity bit
        test_rx_vectors[i] = $urandom;
        calculate_parity(test_rx_vectors[i], calculated_uart_rx_parity_bit);
        transmit_uart_stream(test_rx_vectors[i], ~calculated_uart_rx_parity_bit, 0); // Inverted calculated parity bit
      
        // Read recieved uart data
        fifo_rx_read(recieved_uart_rx_data);
        assert (o_status == 2'b01) else $error("Parity Error Test: Error in UART output status, expected b01 (parity error only), got %b", o_status);
        assert (recieved_uart_rx_data == test_rx_vectors[i]) else $error("Mismatch: input TX data %b does not match serial data outputted %b", test_rx_vectors[i], recieved_uart_rx_data);
      end
      
      // Simulate frame overrun (invalid stop bit, which we just simulate as a extra 0 bit before a real stop bit)
      // Send random packet with wrong parity bit
      test_rx_vectors[0] = $urandom;
      calculate_parity(test_rx_vectors[0], calculated_uart_rx_parity_bit);
      transmit_uart_stream(test_rx_vectors[0], ~calculated_uart_rx_parity_bit, 1); // Inverted parity bit & no stop bit

      // Read recieved uart data
      fifo_rx_read(recieved_uart_rx_data);
      assert (o_status == 2'b11) else $error("Frame Error Test: Error in UART output status, expected b11 (parity & frame error), got %b", o_status);
    end

    repeat (100) @(posedge i_clk);

    $display("UART TB test complete");
    $finish;
  end

endmodule

