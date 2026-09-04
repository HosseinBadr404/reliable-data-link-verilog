# Error-Resilient Data Link in Verilog

> **Course:** Digital Logic Design (طراحی مدارهای منطقی)

A transmitter/receiver RTL system that reads source memory, transmits framed data through an error-injection stage, and writes validated output to destination memory.

## Architecture

```text
source memory -> transmitter -> error injector -> receiver -> destination memory
```

The top-level module connects the complete path, while the behavioral testbench exercises end-to-end transmission. The included Xilinx ISE project file can be used with legacy FPGA tooling.

## Source files

- `transmitter.v` and `receiver.v` — link endpoints
- `error_injector.v` — controlled channel-error model
- `source_memory.v` and `destination_memory.v` — data storage models
- `transmitter_receiver_top.v` — system integration
- `transmitter_receiver_tb.v` — end-to-end testbench
- `RAM_Block_4096x16.vhd` — generated block-memory wrapper

## Simulate

Open `FinalProject.xise` in Xilinx ISE and run `transmitter_receiver_tb.v`. The top-level design instantiates the VHDL block-memory wrapper, so end-to-end simulation requires a mixed-language simulator such as ISim. The standalone transmitter, receiver, and error-injector modules are valid Verilog and can also be linted independently with modern tools.

Generated ISE/ISim binaries, logs, databases, and temporary files have intentionally been excluded.
