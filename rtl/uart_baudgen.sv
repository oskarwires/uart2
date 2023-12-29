module uart_baudgen #(
  parameter Divider = 1000,
  parameter OverSample = 8
)(
  input  logic i_rst_n,
  input  logic i_clk,
  output logic o_baud_clk
);

  localparam OverSampleDivider = Divider / OverSample;
  localparam CounterWidth = $clog2(OverSampleDivider + 1);

  logic [CounterWidth-1:0] counter;

  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if (!i_rst_n) begin
      o_baud_clk <= 1'b0;
      counter      <= OverSampleDivider;
    end else begin
      if (counter == '0) begin
        o_baud_clk <= ~o_baud_clk;
        counter      <= OverSampleDivider;
      end else begin
        counter <= counter - 1'b1;
      end 
    end
  end 

endmodule
