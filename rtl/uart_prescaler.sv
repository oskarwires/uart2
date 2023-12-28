`timescale 1ns / 1ps
// Scales the clock signal according to scale factor
module uart_prescaler #(
  parameter InitialDivider = 16,
  parameter OverSample = 8
)(
  input  logic        i_clk,
  input  logic        i_rst_n,
  input  logic        i_en,
  input  logic [15:0] i_scaler, /* Scale factor */
  output logic        o_strobe, /* Strobe signal */
  output logic        o_half    /* Halfway signal */
);

  logic [15:0] counter;

  /* Counter Logic */
  always_ff @(posedge i_clk) begin
    if (!i_rst_n) begin
      counter <= '0;
    end else begin
      if (i_en) begin
        if (counter == (i_scaler - 16'd1)) counter <= '0;
        else counter <= counter + 16'b1;
      end
    end
  end

  /* Halfway Signal Gen */
  always_comb begin
    if (!i_rst_n) begin
      o_half <= 1'b0;
    end else begin
      o_half <= (counter == (i_scaler[15:1] - 16'd2));
    end
  end

  /* Strobe Signal Gen */
  always_comb begin
    if (!i_rst_n) begin
      o_strobe <= 1'b0;
    end else begin
      o_strobe <= (counter == (i_scaler - 16'd2));
    end
  end

endmodule
