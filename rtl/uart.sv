`timescale 1ns / 1ps
// Configurable UART module
module uart #(
  parameter DataLength      = 8,
  parameter FifoDepth       = 8,
  parameter OverSample      = 8,
  parameter BaudRate        = 115200,
  parameter SystemClockFreq = 50_000_000

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
  output logic        o_tx_rdy,   /* TX FIFO Not Full */
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

  logic uart_rx_fifo_write_en_sync_1, uart_rx_fifo_write_en_sync_2, uart_rx_fifo_write_en_rising;
  always_ff @(posedge i_clk) begin
    uart_rx_fifo_write_en_sync_1 <= uart_rx_fifo_write_en;
    uart_rx_fifo_write_en_sync_2 <= uart_rx_fifo_write_en_sync_1;
    uart_rx_fifo_write_en_rising <= uart_rx_fifo_write_en_sync_1 & ~uart_rx_fifo_write_en_sync_2;
  end

  logic uart_tx_fifo_read_en, uart_tx_fifo_read_en_sync_1, uart_tx_fifo_read_en_sync_2, uart_tx_fifo_read_en_rising;
  always_ff @(posedge i_clk) begin
    uart_tx_fifo_read_en_sync_1 <= uart_tx_fifo_read_en;
    uart_tx_fifo_read_en_sync_2 <= uart_tx_fifo_read_en_sync_1;
    uart_tx_fifo_read_en_rising <= uart_tx_fifo_read_en_sync_1 & ~uart_tx_fifo_read_en_sync_2;
  end


  logic i_rx_sync_1, i_rx_sync_2;
  always_ff @(posedge o_baud_clk) begin
    i_rx_sync_1 <= i_rx;
    i_rx_sync_2 <= i_rx_sync_1;
  end

  fifo #(
    .DataWidth(DataLength),
    .Depth(FifoDepth)
  ) fifo_rx (
    .i_clk,
    .i_rst_n,
    .i_wr_data(uart_rx_data),
    .i_wr_en(uart_rx_fifo_write_en_rising),
    .i_rd_en(i_rx_req),
    .o_rd_data(o_rx_data),
    .o_full(),
    .o_empty(rx_fifo_empty)
  );

  logic tx_fifo_full, tx_fifo_empty;
  logic [DataLength-1:0] uart_tx_fifo_data;


  fifo #(
    .DataWidth(DataLength),
    .Depth(FifoDepth)
  ) fifo_tx (
    .i_clk,
    .i_rst_n,
    .i_wr_data(i_tx_data),
    .i_wr_en(i_tx_req),
    .i_rd_en(uart_tx_fifo_read_en_rising),
    .o_rd_data(uart_tx_fifo_data),
    .o_full(tx_fifo_full),
    .o_empty(tx_fifo_empty)
  );

  uart_tx #(
    .DataLength(DataLength)
  ) uart_tx (
    .i_clk(o_baud_clk),
    .i_rst_n,
    .o_tx,
    .i_tx_fifo_data(uart_tx_fifo_data),
    .i_tx_fifo_empty(tx_fifo_empty),
    .o_tx_fifo_read_en(uart_tx_fifo_read_en)
  );

  uart_baudgen #(
    .SystemClockFreq(SystemClockFreq),
    .BaudRate(BaudRate),
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
    .i_rx(i_rx_sync_2),
    .o_rx_data(uart_rx_data),
    .o_rx_fifo_write_en(uart_rx_fifo_write_en),
    .i_strobe(prescaler_strobe),
    .i_half(prescaler_half),
    .o_prescaler_en(prescaler_en)
  );

  uart_prescaler #(
    .OverSample(OverSample)
  ) uart_prescaler (
    .i_clk(o_baud_clk),
    .i_rst_n,
    .i_en(prescaler_en),
    .o_strobe(prescaler_strobe),
    .o_half(prescaler_half)
  );

  assign o_rx_rdy = ~rx_fifo_empty;
  assign o_tx_rdy = ~tx_fifo_full;
 
endmodule

