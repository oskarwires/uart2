module uart_baudgen #(
    parameter integer SystemClockFreq = 50_000_000,  // System clock frequency in Hz
    parameter integer BaudRate = 9600,               // Baud rate
    parameter integer OverSample = 16                // Oversample value
)(
    input  logic i_clk,     // System clock input
    input  logic i_rst_n,   // Active-low asynchronous reset
    output logic o_baud_clk // Output clock at baud rate * OverSample
);

    // Calculate the number of system clock cycles for one cycle of the output frequency
    localparam integer OutputFrequency = BaudRate * OverSample;
    localparam integer ClkCyclesPerOutputCycle = SystemClockFreq / (OutputFrequency * 2);

    integer counter = 0;
    logic baud_clk_tmp = 0;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            // Reset condition
            counter <= 0;
            baud_clk_tmp <= 0;
        end else begin
            // Normal operation
            if (counter == ClkCyclesPerOutputCycle - 1) begin
                counter <= 0;
                baud_clk_tmp <= ~baud_clk_tmp; // Toggle the baud clock
            end else begin
                counter <= counter + 1;
            end
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_baud_clk <= 0;
        end else begin
            o_baud_clk <= baud_clk_tmp;
        end
    end

endmodule
