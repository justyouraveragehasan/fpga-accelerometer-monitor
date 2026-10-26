# FPGA Accelerometer Monitor

A digital system in VHDL that reads the on-board ADXL362 accelerometer over SPI and shows the live acceleration on the seven-segment display, with the board's orientation indicated by the RGB LED. Written for a Digilent Nexys A7-100T (Xilinx Artix-7, `xc7a100tcsg324-1`) and built in Vivado.

Originally written for the EE3070 Digital Systems Design module at Royal Holloway, University of London.

## What it does

- Reads X, Y and Z acceleration (and temperature) from the ADXL362 over a custom SPI master, averaging several samples per update.
- A switch selects the source: a 12-bit value set on the board switches, or a live axis from the accelerometer.
- Converts the signed 12-bit two's-complement reading to decimal and drives all eight seven-segment digits.
- Lights the RGB LED a different colour depending on which way the board is tilted.
- Can display the X acceleration in milli-g for the ±2 g range.

## Architecture

`display.vhd` is the top level and wires the blocks below together.

| Block | File | Role |
|-------|------|------|
| SPI master | `SPI_If.vhd` | Byte-level SPI transfers to the sensor |
| ADXL362 controller | `ADXL362Ctrl.vhd` | Register reads, sample averaging, data-ready |
| Accelerometer wrapper | `ACC_XYZ.vhd` | Exposes X/Y/Z/temperature as 12-bit buses |
| Source select | `input_sel.vhd`, `axis_sel.vhd` | Switches vs accelerometer; which axis |
| Binary to BCD | `bin2BCD.vhd` | Two's-complement 12-bit to BCD via shift-and-add-3 (double dabble) |
| BCD to 7-seg | `bin2seg.vhd` | BCD digit to cathode pattern |
| Display scan | `clock.vhd`, `counter.vhd`, `mux.vhd`, `DAnC.vhd` | Clock divider, digit counter, digit mux, anode (one-hot-low) control |
| mg conversion | `mg_convert.vhd` | Raw reading to milli-g (±2 g) |
| Orientation LED | `rgb_ctrl.vhd` | RGB colour from the averaged X/Y/Z |

The seven-segment display is driven by time-multiplexing: the counter steps through the eight digits fast enough that persistence of vision makes them all look lit.

## Build

1. Create a Vivado project targeting `xc7a100tcsg324-1` (Nexys A7-100T).
2. Add the sources in `src/`, set `display` as the top module.
3. Add `constraints/display.xdc`.
4. Run synthesis, implementation, and generate the bitstream, then program the board.

## Simulation

`sim/bin2BCD_tb.vhd` is a self-checking testbench for the binary-to-BCD converter: it drives known inputs and checks the BCD output against the expected digits.

## Layout

```
src/          VHDL design sources
sim/          testbench
constraints/  Nexys A7 pin/timing constraints (XDC)
```
