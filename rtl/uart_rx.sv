module uart_rx #(
  //params
)(
  //i/o
  /* Main Signals */
  input  logic       i_clk, // Assuming this is at baudrate * oversampling (16)
  input  logic 	     i_rst_n,
  /* UART Signals */
  input  logic       i_rx,
  output logic [7:0] o_rx_data,
  /* Sample Timing */
  input  logic       i_strobe,
  input  logic       i_half,
  output logic       o_prescaler_en 
);
 
  typedef enum logic [2:0] {
    RESET = 3'b000,
    WAIT  = 2'b001,
    LOAD  = 3'b010,
    STOP  = 3'b011,
    READY = 3'b100
  } states_t;

  states_t curr_state, next_state;
  logic [2:0] counter;

  // State controller
  always_ff @(posedge i_clk) begin
    if (!i_rst_n) curr_state <= RESET;
    else          curr_state <= next_state;
  end

  // Next State Logic Controller
  always_comb begin
    unique case (state)
      RESET:
        next_state   = WAIT;
      WAIT:
        if (serial_in == '0)
          next_state = LOAD;
        else 
          next_state = WAIT;
      LOAD:
        if (counter == '0)
          next_state = STOP;
        else 
          next_state = LOAD;
      STOP:
        // wait for stop bit
      READY: 
        next_state   = WAIT;
    endcase
  end

  always_comb begin
    unique case (state)
      RESET: 
      WAIT:  
      LOAD:  
      STOP:  
      READY: 
    endcase
  end

  always_ff @(posedge i_clk)
    if (!i_rst_n)
      o_rx_data <= 0;
    else if (i_half)
      o_rx_data <= {rx, o_rx_data[7:1]};
  
  always_ff @(posedge i_clk)
    if (!i_rst_n)
      counter <= '0;
    else if (i_half)
      counter <= counter - 3'b1;  

endmodule

