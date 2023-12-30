`timescale 1ns / 1ps
// Scales the clock signal according to scale factor
module uart_prescaler #(
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
  localparam ClockOffset = 0;
  localparam OffsetOverSample = OverSample - ClockOffset;

  logic first_count;

  /* Counter Logic */
  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if (!i_rst_n) begin
      counter <= '0;
      first_count <= '1;
    end else begin
      if (i_en) begin
        if (first_count)
          if (counter == (OffsetOverSample - 1)) begin
            counter <= '0;
            first_count <= '0;
          end else counter <= counter + 1'b1;
        else
          if (counter == (OffsetOverSample - 1)) counter <= '0;
          else counter <= counter + 1'b1;
      end
    end
  end

  /* Halfway Signal Gen */
  always_comb begin
    if (!i_rst_n) begin
      o_half <= 1'b0;
    end else begin
      o_half <= (counter == (OffsetOverSample/2)-2);
    end
  end

  /* Strobe Signal Gen */
  always_comb begin
    if (!i_rst_n) begin
      o_strobe <= 1'b0;
    end else begin
      o_strobe <= (counter == (OffsetOverSample)-2);
    end
  end

endmodule
