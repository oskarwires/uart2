# UART Transceiver

SystemVerilog UART transceiver with FIFO buffer, majority three voting, and error detection.

Using this transceiver is extremely easy. Below are the strictly neccesary steps, with optional ones omitted
1. Copy `fifo.sv`, `fifo_ctrl.sv`, `fifo_mem.sv`, `uart.sv`, `uart_rx.sv`, and `uart_tx.sv` into your source
2. Instantiate `uart.sv` in your code
3. Feed your system clock and reset (active low) into `i_clk` and `i_rst_n`, respectively
4. Define your clock frequency in the `SystemClockFreq` param
5. Define the baud rate in the `BaudRate` param
6. That's it!

To transmit data:
1. Check that `o_tx_rdy = 1` (meaning the TX FIFO isn't full)
2. Write your data to `i_tx_data` and assert `i_tx_req = 1` (in the same clock cycle). Ensure that `i_tx_req` is high for *only* one (1) clock cycle
3. If flow control is enabled, the transceiver will wait until the clear to send (CTS) line is high before transmitting

To receive data:
1. Check that `o_rx_rdy = 1` (meaning there is data in the RX FIFO)
2. Read the value in `o_rx_data` and assert `i_rx_req` (in the same clock cycle). Ensure that `i_rx_req` is high for *only* one (1) clock cycle
3. If `o_rx_error = 1`, then the stop bit received was invalid. The UART transceiver goes into a error state and a reset must be asserted to leave this state

## More details
This UART transceiver has 3 main features that make it great: RX & TX FIFO, enhanced noise immunity through majority three voting, and stop bit error detection.

### FIFO
The FIFOs on this transceiver are implemented as simple synchronous uni-directional FIFOs. For the RX FIFO, the transceiver inserts data, and the user agent extracts it.
For the TX FIFO, the transceiver extracts data, and the user agent inserts it.

### Majority three voting
To help with noise immunity, each bit's value is sampled three times during each bit period. Once the start bit is received, to align the bit sampling, the RX module starts a counter.
This counter signals every half-bit period, full-bit period, 4/10th bit period, and 6/10th bit period. 
We sample the bit's value on the 4/10th, 5/10th, and 6/10th of the period. The majority of these three values is the value received. 
Because we are running the RX module at the input clock frequency, which is (normally) _many_ times higher than the baud rate, the alignment of the half-bit strobe is extremely accurate. 

### Stop bit error detection
To detect a valid stop bit, we check that the incoming bit's majority three value = `1` when we expect a stop bit. If this is true, then great, we send the received packet to the RX FIFO. If this stop bit's majority three value is `0`, however, then we go into an error state and `o_rx_error = 1`. To get out of this state, a reset must be asserted.

## Parameters
- `DataLength`: how many bits to send and receive. Default = `8`
- `BaudRate`: the baud rate of the transceiver. Default = `115200`
- `FifoDepth`: how words stored in the FIFO. Default = `8`
- `SystemClockFreq`: the clock frequency given to `i_clk`. Default = `50 MHz`
- `Parity`: enable parity bit if `1`, disable if `0`. Default = `0`
- `ParityEven`: even parity bit if `1`, odd parity bit if `0`. Default = `0`
- `FlowControl`: enables RTS and CTS hardware flow control. Default = `0`

## TODO
- Add parity bit
- Add parameter to allow for soft-error handling, meaning that the receiver will wait a set amount of clock cycles after an invalid stop bit before it starts listening for a start bit again. This means no need for reset assertion to get out of error state

## License
See the `LICENSE` file
