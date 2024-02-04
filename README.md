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

**By Default** the module assumes no parity bit, hardware flow control off, data length of 8 bits, fifo depth of 8 words, system clock frequency of 50 MHz, and 115200 baud rate.

## Parameters:
- `DataLength`: how many bits to send and receive. Default = `8`
- `BaudRate`: the baud rate of the transceiver. Default `115200`
- `FifoDepth`: how words stored in the FIFO. Default `8`
- `SystemClockFreq`: the clock frequency given to `i_clk`. Default `50 MHz`
- `Parity`: enable parity bit if `1`, disable if `0`. Default `0`
- `ParityEven`: even parity bit if `1`, odd parity bit if `0`. Default `0`
- `FlowControl`: enables RTS and CTS hardware flow control. Default `0`

## TODO:
Add parity bit
