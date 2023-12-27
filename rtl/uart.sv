`timescale 1ns / 1ps
// Configurable UART module
module uart_axi #(
  parameter FifoDepth = 8
)(
  /* Main Signals */
  input  logic        i_rst_n,   /* Sync. active low reset */
  input  logic        i_clk,
  /* Module Signals */
  input  logic [31:0] i_ctrl,    /* Control Register */
  output logic [31:0] o_status,  /* Status Register */
  input  logic [7:0]  i_tx_data, /* Byte to send */
  output logic [7:0]  o_rx_data, /* Recieved byte */
  input  logic        i_tx_req,  /* Request to send */
  input  logic        i_rx_req,  /* Request to read */
  output logic        o_rx_rdy,  /* Data in RX FIFO */
  /* UART Signals */
  input  logic        i_rx,
  output logic        o_tx,
  input  logic        i_cts,
  output logic        o_rts    
);
  logic fifo_empty;  
  
  fifo #(
    .DataWidth(8),
    .Depth(FifoDepth)
  ) fifo (
    .i_clk,
    .i_rst_n,
    .i_wr_data(i_tx_data),
    .i_wr_en(i_tx_req),
    .i_rd_en(i_rx_req),
    .o_rd_data(o_rx_data),
    .o_full(),
    .o_empty(fifo_empty)
  );

  assign o_rx_rdy = ~fifo_empty;
 
endmodule

