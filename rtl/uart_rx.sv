module uart_rx #(
  parameter Parity = 1'b0,
  parameter StopBit = 1'b1,
  parameter DataLength = 8
  //params
)(
  //i/o
  /* Main Signals */
  input  logic                  i_clk, // Assuming this is at baudrate * oversampling
  input  logic 	                i_rst_n,
  /* UART Signals */
  input  logic                  i_rx,
  output logic [DataLength-1:0] o_rx_data,
  /* Sample Timing */
  input  logic                  i_strobe,
  input  logic                  i_half,
  output logic                  o_prescaler_en,
  output logic                  o_parity_error,
  output logic                  o_stop_bit_error,
  output logic                  o_fifo_write_en	
);
 
  localparam counter_width = $clog2(DataLength);
 
  typedef enum logic [2:0] {
    RESET  = 3'b000,
    WAIT   = 3'b001,
    START  = 3'b010,
    LOAD   = 3'b011,
    PARITY = 3'b100, 
    STOP   = 3'b101,
    READY  = 3'b110
  } states_t;

  states_t curr_state, next_state;

  logic [counter_width-1:0] bit_counter;
  logic counter_rst_n, shift_reg_en;

  logic parity_bit;

  // State controller
  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if (!i_rst_n) curr_state <= RESET;
    else          curr_state <= next_state;
  end

  // Next State Logic Controller
  always_comb begin
    unique case (curr_state)
      RESET:
        next_state   = WAIT;
      WAIT:
        if (i_rx == '0)
          next_state = START;
        else 
          next_state = WAIT;
      START:
        if (i_strobe == '1)
	  next_state = LOAD;
	else
	  next_state = START;
      LOAD:
        if (bit_counter == '0 && i_half)
          case (Parity)
            0: next_state = STOP;
            1: next_state = PARITY;
          endcase
        else 
          next_state = LOAD;
      PARITY:
        if (i_half) 
          next_state = STOP;
        else
          next_state = PARITY; 
      STOP:
        if (i_half && i_rx) // halfway strobe AND rx == 1 (stop bit)
          next_state = READY;
        else 
          next_state = STOP;
      READY: 
        next_state   = WAIT;
    endcase
  end

  always_comb begin
    unique case (curr_state)
      RESET:  {o_prescaler_en, counter_rst_n, o_fifo_write_en, shift_reg_en} = 4'b0000;
      WAIT:   {o_prescaler_en, counter_rst_n, o_fifo_write_en, shift_reg_en} = 4'b0000;
      START:  {o_prescaler_en, counter_rst_n, o_fifo_write_en, shift_reg_en} = 4'b1000;
      LOAD:   {o_prescaler_en, counter_rst_n, o_fifo_write_en, shift_reg_en} = 4'b1101;
      PARITY: {o_prescaler_en, counter_rst_n, o_fifo_write_en, shift_reg_en} = 4'b1000;
      STOP:   {o_prescaler_en, counter_rst_n, o_fifo_write_en, shift_reg_en} = 4'b1000;
      READY:  {o_prescaler_en, counter_rst_n, o_fifo_write_en, shift_reg_en} = 4'b0010;
    endcase
  end

  /* Shift Register */
  always_ff @(posedge i_clk, negedge i_rst_n)
    if (!i_rst_n)
      o_rx_data <= 0;
    else if (i_half && shift_reg_en)
      o_rx_data <= {i_rx, o_rx_data[DataLength-1:1]};
  
  /* Decrementing Counter */
  always_ff @(posedge i_clk, negedge i_rst_n)
    if (!i_rst_n || !counter_rst_n)
      bit_counter <= '1;
    else if (i_half)
      bit_counter <= bit_counter - 3'b1;  

endmodule

