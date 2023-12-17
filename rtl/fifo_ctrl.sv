module fifo #(
  parameter  DataWidth   = 8,
  parameter  Depth       = 64,
  localparam PtrWidth    = $clog2(Depth),
)(
  input  logic                 i_clk,
  input  logic [DataWidth-1:0] i_data,
  input  logic                 i_rst_n,
  input  logic                 i_wr_en,
  input  logic                 i_rd_en,
  output logic [DataWidth-1:0] o_data,
  output logic                 o_full,
  output logic                 o_empty
);
  initial begin
    $display("Hello world from fifo ctrl");
  end

  logic [DataWidth-1:0] buffer[Depth];
  logic [PtrWidth:0]    wr_ptr, wr_ptr_next;
  logic [PtrWidth:0]    rd_ptr, rd_ptr_next;                 

  always_ff @(posedge i_clk) begin
    if (!i_rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
    end else begin
      wr_ptr <= wr_ptr_next;
      rd_ptr <= rd_ptr_next;
    end
  end

  always_comb begin
    if (i_wr_en) wd_ptr_next = wd_ptr_next + 1'b1;
    else         wd_ptr_next = wd_ptr;

    if (i_rd_en) rd_ptr_next = rd_ptr_next + 1'b1;
    else         rd_ptr_next = rd_ptr;
  end

  assign o_full  = ((wr_ptr[PtrWidth] != rd_ptr[PtrWidth]) && (writePtr[PtrWidth-1:0] == readPtr[PtrWidth-1:0]));
  assign o_empty = ((wr_ptr[PtrWidth] == rd_ptr[PtrWidth]) && (writePtr[PtrWidth-1:0] == readPtr[PtrWidth-1:0]));
  
endmodule

