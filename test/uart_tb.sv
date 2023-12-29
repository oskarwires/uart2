module uart_tb();

  logic i_clk, i_rst_n;
  logic i_rx;

  uart uut (
    .i_clk,
    .i_rst_n,
    .i_ctrl(),
    .o_status(),
    .i_tx_data(),
    .o_rx_data(),
    .i_tx_req(),
    .i_rx_req(),
    .o_rx_rdy(),
    .i_rx,
    .o_tx(),
    .i_cts(),
    .o_rts()
  );

  // Clock Gen
  initial i_clk = 1'b0;
  always #5 i_clk = ~i_clk;

  initial begin
    $dumpfile("uart_tb.vcd"); // Initialize VCD dump
    $dumpvars(0, uart_tb);    // Dump all variables in this module
    // Initial Signal Stimuli
    i_rst_n  <= 1'b0; /* Assert Reset */
    i_rx <= 1'b1;
    repeat (2) @(posedge i_clk);
    i_rst_n  <= 1'b1;

    repeat (3) @(posedge i_clk);
    i_rx     <= 1'b0;
    repeat (8) @(posedge i_clk);
    i_rx     <= 1'b1;
    repeat (8) @(posedge i_clk);
    i_rx     <= 1'b0;
    repeat (8) @(posedge i_clk);
    i_rx     <= 1'b1;
    repeat (40) @(posedge i_clk);
    i_rx     <= 1'b0;
    repeat (8) @(posedge i_clk);
    i_rx     <= 1'b1;

    repeat (100) @(posedge i_clk);


    $display("UART TB test complete");
    $finish;
  end

endmodule

