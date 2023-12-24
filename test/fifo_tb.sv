`timescale 1ns / 1ps

module fifo_tb ();

  // Parameters
  localparam DataWidth = 8;
  localparam Depth     = 8;
  localparam PtrWidth  = $clog2(Depth);

  // Testbench Signals
  logic                 clk = 1'b0;
  logic [DataWidth-1:0] in_data;
  logic                 rst_n;
  logic                 write_en;
  logic                 read_en;
  logic [DataWidth-1:0] out_data;
  logic                 full;
  logic                 empty;
  
  logic [DataWidth-1:0] test_input [8];

  // Instantiate the FIFO
  fifo #(
    .DataWidth(DataWidth),
    .Depth(Depth)
  ) uut (
    .i_clk(clk),
    .i_wr_data(in_data),
    .i_rst_n(rst_n),
    .i_wr_en(write_en),
    .i_rd_en(read_en),
    .o_rd_data(out_data),
    .o_full(full),
    .o_empty(empty)
  );

  // Clock Generation
  always #5 clk = ~clk;

  // Testbench Initial Block
  initial begin
    // Initialize signals
    clk <= 0;
    in_data <= 0;
    rst_n <= 0;
    write_en <= 0;
    read_en <= 0;
      
    #10; // Wait for a couple of clock cycles
    rst_n <= 1;
    #20;
    rst_n <= 0;
    #10;
    rst_n <= 1;
    #10;
    
    // TEST 1:
    // Randomize the input vector
    for (int i = 0; i < 8; i++) begin
      test_input[i] <= $random; // Masking to get the lower 8 bits
    end
    @(posedge clk);
    
    // Write to FIFO
    for (int i = 0; i < Depth; i++) begin
      in_data <= test_input[i]; // Assign data
      write_en <= 1; // We want to write data!
      @(posedge clk); // Wait for next rising edge
    end
    in_data <= $random; // Assign random value to in_data, which should NOT be written
    write_en <= 0;
    @(posedge clk);
     
    // Read from FIFO
    for (int i = 0; i < Depth; i++) begin
      read_en <= 1;
      @(posedge clk); 
      assert(out_data == test_input[i]);
    end
    read_en <= 0;
    
    // TEST 2:
    // Randomize the input vector
    for (int i = 0; i < 8; i++) begin
      test_input[i] <= $random;
    end
    @(posedge clk);
    // Write to FIFO
    for (int i = 0; i < Depth; i++) begin
      @(posedge clk);
      in_data <= test_input[i];
      write_en <= 1;
      @(posedge clk);
      write_en <= 0;
    end
  
    // Read from FIFO
    for (int i = 0; i < Depth; i++) begin
      @(posedge clk);
      read_en <= 1;
      @(posedge clk);
      assert(out_data == test_input[i]);
      read_en <= 0;
    end
    
    // TEST 3:
    // Randomize the input vector
    for (int i = 0; i < 8; i++) begin
      test_input[i] <= $random;
    end
    @(posedge clk);
    
    // Write first value to FIFO
    @(posedge clk);
    in_data <= test_input[0];
    write_en <= 1;
    @(posedge clk);
    // Write rest of values to FIFO and start reading
    for (int i = 1; i < Depth; i++) begin
      read_en <= 1;
      in_data <= test_input[i];
      write_en <= 1;
      @(posedge clk)
      assert(out_data == test_input[i-1]);
    end
    in_data <= 0;
    write_en <= 0;
    read_en <= 1;
    @(posedge clk);
    read_en <= 0;
    
    // Additional test cases...
  
    #100;
    $finish;
  end
endmodule
