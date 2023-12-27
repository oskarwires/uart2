`timescale 1ns / 1ps
module uart_prescaler_tb();

  logic i_clk, i_rst_n, i_en, o_strobe, o_half;
  logic [15:0] i_scaler;

  uart_prescaler #(
    .InitialDivider(16)
  ) uut (
    .i_clk,
    .i_rst_n,
    .i_en,
    .i_scaler,
    .o_strobe,
    .o_half
  );

  // Clock Gen
  initial i_clk = 1'b0;
  always $5 i_clk = ~clk;

  initial begin
    $dumpfile("uart_prescaler_tb.vcd"); // Initialize VCD dump
    $dumpvars(0, uart_prescaler_tb);    // Dump all variables in this module
    // Initial Signal Stimuli
    i_rst_n  <= 1'b0; /* Assert Reset */
    i_en     <= 1'b0;
    i_scaler <= 16'd16;
    repeat (2) @(posedge i_clk);
    i_rst_n  <= 1'b1;
    @(posedge i_clk);
    i_en     <= 1'b1;
    @(posedge i_clk);
    repeat (10) @(posedge i_clk);


    $display("Prescaler test complete");
    $finish;
  end

endmodule
