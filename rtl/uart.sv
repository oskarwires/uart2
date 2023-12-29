`timescale 1ns / 1ps
// Configurable UART module
module uart #(
  parameter DataLength = 8,
  parameter FifoDepth = 8,
  parameter OverSample = 8,
  parameter ClkDivider = 216
)(
  /* Main Signals */
  input  logic        i_rst_n,    /* Sync. active low reset */
  input  logic        i_clk,
  /* Module Signals */
  input  logic [31:0] i_ctrl,     /* Control Register */
  output logic [31:0] o_status,   /* Status Register */
  input  logic [7:0]  i_tx_data,  /* Byte to send */
  output logic [7:0]  o_rx_data,  /* Recieved byte */
  input  logic        i_tx_req,   /* Request to send */
  input  logic        i_rx_req,   /* Request to read */
  output logic        o_rx_rdy,   /* Data in RX FIFO */
  output logic        o_baud_clk, /* Baud Clk For Testing */
  /* UART Signals */
  input  logic        i_rx,
  output logic        o_tx,
  input  logic        i_cts,
  output logic        o_rts    
);

  logic prescaler_half, prescaler_strobe, prescaler_en;  

  logic [DataLength-1:0] uart_rx_data;
  logic uart_rx_fifo_write_en;

  logic fifo_empty; 

  fifo #(
    .DataWidth(DataLength),
    .Depth(FifoDepth)
  ) fifo_rx (
    .i_clk,
    .i_rst_n,
    .i_wr_data(uart_rx_data),
    .i_wr_en(uart_rx_fifo_write_en),
    .i_rd_en(i_rx_req),
    .o_rd_data(o_rx_data),
    .o_full(),
    .o_empty(fifo_empty)
  );

  uart_baudgen #(
    .Divider(ClkDivider),
    .OverSample(OverSample)
  ) uart_baudgen (
    .i_clk,
    .i_rst_n,
    .o_baud_clk(o_baud_clk)
  );

  uart_rx #(
    .DataLength(DataLength)
  ) uart_rx (
    .i_clk(o_baud_clk),
    .i_rst_n,
    .i_rx,
    .o_rx_data(uart_rx_data),
    .o_fifo_write_en(uart_rx_fifo_write_en),
    .i_strobe(prescaler_strobe),
    .i_half(prescaler_half),
    .o_prescaler_en(prescaler_en)
  );

  uart_prescaler #(
    .OverSample(8)
  ) uart_prescaler (
    .i_clk(o_baud_clk),
    .i_rst_n,
    .i_en(prescaler_en),
    .i_scaler(16'd8),
    .o_strobe(prescaler_strobe),
    .o_half(prescaler_half)
  );

  assign o_rx_rdy = ~fifo_empty;
 
endmodule

