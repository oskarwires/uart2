`timescale 1ns / 1ps

module fifo_tb;

  // Parameters
  localparam DataWidth = 8;
  localparam Depth     = 8;
  localparam PtrWidth  = $clog2(Depth);

  // Testbench Signals
  logic                 clk;
  logic [DataWidth-1:0] in_data;
  logic                 rst_n;
  logic                 write_en;
  logic                 read_en;
  logic [DataWidth-1:0] out_data;
  logic                 full;
  logic                 empty;

  // Instantiate the FIFO
  fifo #(
    .DataWidth(DataWidth),
    .Depth(Depth)
  ) uut (
    .i_clk(clk),
    .i_data(in_data),
    .i_rst_n(rst_n),
    .i_write_en(write_en),
    .i_read_en(read_en),
    .o_data(out_data),
    .o_full(full),
    .o_empty(empty)
  );

  // Clock Generation
  always #5 clk = ~clk;

  // Testbench Initial Block
  initial begin
    // Initialize signals
    clk      = 0;
    in_data     = 0;
    rst_n    = 0;
    write_en = 0;
    read_en  = 0;

    // Reset the FIFO
    #10;
    rst_n = 1;
    #10;
    rst_n = 0;
    #10;
    rst_n = 1;
    
    // Write to FIFO
    repeat (Depth) begin
      #10;
      in_data = $random;
      write_en = 1;
      #10;
      write_en = 0;
    end

    // Read from FIFO
    repeat (Depth) begin
      #10;
      read_en = 1;
      #10;
      read_en = 0;
    end

    // Additional test cases can be added here yay

    // End simulation
    #100;
    $finish;
  end

  // Monitor
  initial begin
    $monitor("Time = %t, Full = %b, Empty = %b, Data Out = %h", 
             $time, full, empty, out_data);
  end

endmodule
