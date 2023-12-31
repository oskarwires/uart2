module uart_tx #(
  parameter Parity = 1'b0,
  parameter StopBit = 1'b1,
  parameter DataLength = 8,
  parameter OverSample = 8
)(
  //i/o
  /* Main Signals */
  input  logic                  i_clk, // Assuming this is at baudrate * oversampling
  input  logic 	                i_rst_n,
  /* UART Signals */
  output logic                  o_tx,
  input  logic [DataLength-1:0] i_tx_fifo_data,
  /* Sample Timing */
  input  logic                  i_tx_fifo_empty,
  output logic                  o_tx_fifo_read_en
);

  localparam ClkCounterWidth = $clog2(OverSample);
  localparam BitCounterWidth = $clog2(DataLength);

  typedef enum logic [2:0] {
    RESET  = 3'b000,
    WAIT   = 3'b001,
    START  = 3'b010,
    DATA   = 3'b011,
    PARITY = 3'b100, 
    STOP   = 3'b101,
    DONE   = 3'b110
  } states_t;

  states_t curr_state, next_state;

  logic [ClkCounterWidth-1:0] clk_counter;
  logic [BitCounterWidth-1:0] bit_counter;

  logic shift_reg_en, clk_counter_en, bit_counter_en;

  // State controller
  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if (!i_rst_n) curr_state <= RESET;
    else          curr_state <= next_state;
  end

  always_comb begin
    unique case (curr_state)
      RESET:
        next_state = WAIT;
      WAIT:
        if (!i_tx_fifo_empty)
          next_state = START;
        else 
          next_state = WAIT;
      START:
        if (clk_counter == '0)
          next_state = DATA;
        else 
          next_state = START;
      DATA:
        if (bit_counter == DataLength - 1 && clk_counter == '0)
          case (Parity)
            0: next_state = STOP;
            1: next_state = PARITY;
          endcase
        else
          next_state = DATA;
      STOP:
        if (clk_counter == '0)
          next_state = WAIT;
        else
          next_state = STOP;
      DONE:
        next_state = WAIT;
    endcase
  end 

  logic o_tx_d;

  always_comb begin
    unique case (curr_state)
      RESET:  {clk_counter_en, bit_counter_en, o_tx_fifo_read_en, o_tx_d} = {3'b000, 1'b1};
      WAIT:   {clk_counter_en, bit_counter_en, o_tx_fifo_read_en, o_tx_d} = {3'b000, 1'b1};
      START:  {clk_counter_en, bit_counter_en, o_tx_fifo_read_en, o_tx_d} = {3'b100, 1'b0};
      DATA:   {clk_counter_en, bit_counter_en, o_tx_fifo_read_en, o_tx_d} = {3'b110, i_tx_fifo_data[bit_counter]};
      PARITY: {clk_counter_en, bit_counter_en, o_tx_fifo_read_en, o_tx_d} = {3'b100, 1'b1};
      STOP:   {clk_counter_en, bit_counter_en, o_tx_fifo_read_en, o_tx_d} = {3'b100, 1'b1};
      DONE:   {clk_counter_en, bit_counter_en, o_tx_fifo_read_en, o_tx_d} = {3'b001, 1'b1};
    endcase
  end 

  /* TX Flip Flop */
  always_ff @(posedge i_clk, negedge i_rst_n)
    if (!i_rst_n)
      o_tx <= '1;
    else
      o_tx <= o_tx_d;
   
  /* Decrementing Clk Counter */
  always_ff @(posedge i_clk, negedge i_rst_n)
    if (!i_rst_n || !clk_counter_en)
      clk_counter <= OverSample - 1;
    else
      clk_counter <= clk_counter - 1'b1;  

  /* Incrementing Bit Counter */
  always_ff @(posedge i_clk, negedge i_rst_n)
    if (!i_rst_n || !bit_counter_en)
      bit_counter <= '0;
    else if (clk_counter == '0)
      bit_counter <= bit_counter + 1'b1;  

endmodule
