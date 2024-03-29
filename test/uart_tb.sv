`timescale 1ns / 1ps
module uart_tb();
  /* UUT Params */
  localparam      BaudRate    = 115200; // Baud rate
  localparam      FifoDepth   = 8;
  localparam      FlowControl = 1;
  localparam      ClockFreq   = 133_000_000;
  localparam      DataLength  = 8;

  /* TB Params */
  localparam      NumberTest  = 8;

  /* Calculated Params */
  localparam      UartBitCycles   = ClockFreq / BaudRate; // Clock cycles per UART bit
  localparam real ClockPeriod     = 1_000_000_000.0 / ClockFreq;
  localparam real UartBitPeriodNs = 1_000_000_000.0 / BaudRate; // Bit period in nanoseconds
  localparam real HalfBitPeriodNs = UartBitPeriodNs / 2.0;
 
  logic i_clk, i_rst_n;
  logic i_rx, o_tx, i_cts, o_rts;
  logic o_rx_rdy, o_tx_rdy, i_tx_req, i_rx_req;

  logic [DataLength-1:0] o_rx_data;
  logic [DataLength-1:0] i_tx_data;

  logic [DataLength-1:0] test_tx_vectors[NumberTest];
  logic [DataLength-1:0] test_rx_vectors[NumberTest];

  logic [DataLength-1:0] recieved_uart_tx_data;
  logic [DataLength-1:0] recieved_uart_rx_data;

  logic o_rx_error;

  uart #(
    .DataLength(DataLength),
    .FifoDepth(FifoDepth),
    .BaudRate(BaudRate),
    .SystemClockFreq(ClockFreq),
    .FlowControl(FlowControl)
  ) uut (
    .i_clk,
    .i_rst_n,
    .i_tx_data,
    .o_rx_data,
    .i_tx_req,
    .i_rx_req,
    .o_rx_rdy,
    .o_tx_rdy,
    .o_rx_error,
    .i_rx,
    .o_tx,
    .i_cts,
    .o_rts
  );
 
  // Task to write to fifo_tx
  task automatic fifo_tx_write (
    input [DataLength-1:0] wr_data
  );
    wait (o_tx_rdy);
    i_tx_req <= 1;
    i_tx_data <= wr_data;
    @(posedge i_clk);
    i_tx_req <= 0;
  endtask

  // Task to read fifo_rx
  task automatic fifo_rx_read (
    output [DataLength-1:0] rd_data
  );
    wait(o_rx_rdy);
    i_rx_req <= 1;
    @(posedge i_clk);
    rd_data = o_rx_data;
    i_rx_req <= 0;
    @(posedge i_clk);
  endtask

  // Task to read incoming transmit stream from the UUT to test TX
  task automatic recieve_uart_stream (
    output [DataLength-1:0] uart_packet
  );
    @(negedge o_tx); // Wait for start bit (falling edge from 1 to 0)
      
    // Wait half a bit period to align to the middle of bits
    #(HalfBitPeriodNs);
    
    // Read each data bit
    for (int j = 0; j < DataLength; j++) begin
        #(UartBitPeriodNs);    // Wait bit period
        uart_packet[j] = o_tx; // Sample the data bit
    end
    #(UartBitPeriodNs); // Wait for stop bit

    assert(o_tx == 1'b1) else $error("No Stop bit detected"); // Stop bit requirement
  endtask

  // Task to transmit a UART packet to the UUT to test RX
  task automatic transmit_uart_stream (
    input [DataLength-1:0] uart_packet
  );
    // Start Bit (0)
    i_rx = 0; // Async assignment of value to model real world async conditions
    #(UartBitPeriodNs); // Wait bit period

    // Transmitting DataLength data bits
    for (int i = 0; i < DataLength; i++) begin
      i_rx = uart_packet[i];      
      #(UartBitPeriodNs); // Wait bit period
    end

    // Stop bit (1)
    i_rx = 1;
    #(UartBitPeriodNs); // Wait bit period
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
        // Generate random TX packets
        for (int i = 0; i < NumberTest; i++) begin
          test_tx_vectors[i] = $urandom;
        end
        
        fork
          // Load data into TX FIFO and simultaneously read the serial stream output
          begin
            // Load data into TX FIFO
            for (int i = 0; i < NumberTest; i++) begin
              fifo_tx_write(test_tx_vectors[i]);
            end
          end
       
          begin
            // Read transmitted uart data
            for (int i = 0; i < NumberTest; i++) begin
              // Wait for the start bit
              recieve_uart_stream(recieved_uart_tx_data);
              assert (recieved_uart_tx_data == test_tx_vectors[i]) else $error("TX Error: input TX data %h does not match serial data outputted %h", test_tx_vectors[i], recieved_uart_tx_data);
            end
          end
        join
      end
     
      /* ----- TESTING RX ----- */
      begin
        // Generate random RX packets
        for (int i = 0; i < NumberTest; i++) begin
          test_rx_vectors[i] = $urandom;
        end

        // Send serial stream and simultaneously read the RX FIFO
        fork
          begin
            // Transmit uart data stream
            for (int i = 0; i < NumberTest; i++) begin
              transmit_uart_stream(test_rx_vectors[i]);
            end
          end
          
          begin
            // Read recieved uart data
            for (int i = 0; i < NumberTest; i++) begin
              fifo_rx_read(recieved_uart_rx_data);
              assert (recieved_uart_rx_data == test_rx_vectors[i]) else $error("RX Error: Serial data sent %h does not match output RX data %h", test_rx_vectors[i], recieved_uart_rx_data);
            end
          end
        join
      end
    join

    /* ----- TEST 2 ----- */
    // Time to test RX error assertion
    // We will do this by just not giving a stop bit
    test_rx_vectors[0] = $urandom;

    i_rx = 0; // Start Bit (0)
    #(UartBitPeriodNs); // Wait bit period

    // Transmitting DataLength data bits
    for (int i = 0; i < DataLength; i++) begin
      i_rx = test_rx_vectors[0][i];      
      #(UartBitPeriodNs); // Wait bit period
    end
    i_rx = 0; // Invalid stop bit, low (0)
    #(UartBitPeriodNs); // Wait bit period
    i_rx = 1; // Now we give a stop bit
    
    repeat (10) @(posedge i_clk);

    assert (o_rx_error == 1'b1) else $error("RX Error: o_rx_error not asserted after invalid stop bit");
    // Assert reset, should clear error

    i_rst_n  <= '0; // Assert reset
    repeat (2) @(posedge i_clk);
    i_rst_n  <= '1;
    repeat (1) @(posedge i_clk);
    assert (o_rx_error == 1'b0) else $error("RX Error: o_rx_error not de-asserted after reset");
    repeat (100) @(posedge i_clk);

    // Does RX still work after?
    test_rx_vectors[0] = $urandom;
    transmit_uart_stream(test_rx_vectors[0]);
    fifo_rx_read(recieved_uart_rx_data);
    assert (recieved_uart_rx_data == test_rx_vectors[0]) else $error("RX Error: Serial data sent %h does not match output RX data %h (after reset)", test_rx_vectors[0], recieved_uart_rx_data);

    /* ----- TEST 3 ----- */
    // What about an invalid start bit (let's put i_rx low for a few clock cycles, then hold it high again, simulating noise)
    i_rx = 0;
    repeat (20) @(posedge i_clk);
    i_rx = 1;
    repeat (10) #(UartBitPeriodNs);
    assert (o_rx_rdy == 1'b0) else $error("RX Error: incorrectly started sampling on short start bit");

    // Great, now make sure RX still works properly!
    test_rx_vectors[0] = $urandom;
    transmit_uart_stream(test_rx_vectors[0]);
    fifo_rx_read(recieved_uart_rx_data);
    assert (recieved_uart_rx_data == test_rx_vectors[0]) else $error("RX Error: Serial data sent %h does not match output RX data %h (after bad start bit)", test_rx_vectors[0], recieved_uart_rx_data);

    repeat (100) @(posedge i_clk);

    $display("UART TB test complete");
    $finish;
  end

endmodule

