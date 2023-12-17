// Dual-Port RAM for FIFO, sync read and write, with no reset
module fifo_mem #(
  parameter  DataWidth = 8,
  parameter  Depth     = 16,
  localparam AddrWidth  = $clog2(Depth)
)(
  input  logic                 i_clk,
  input  logic                 i_wr_en,
  input  logic [AddrWidth-1:0] i_wr_addr,
  input  logic [DataWidth-1:0] i_wr_data,
  input  logic [AddrWidth-1:0] i_rd_addr,
  output logic [DataWidth-1:0] o_rd_data,
);

  logic [DataWidth-1:0] memory [Depth];
  
  always_ff @(posedge i_clk) begin
    o_rd_data <= memory[i_rd_addr];
    if (i_wr_en) memory[i_wr_addr] <= i_wr_data;
  end
  
endmodule
