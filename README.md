# 5-Stage Pipelined RISC-V Processor

A 32-bit, 5-stage pipelined RISC-V processor implemented in Verilog.

## Features

- 5-stage pipeline: IF, ID, EX, MEM, WB
- ALU, register file, instruction/data memory
- Control and immediate-generation units
- Supports core instructions including `ADD`, `SUB`, `AND`, `OR`, `ADDI`, `LW`, `SW`, `BEQ`, and `JAL`
- Hazard-aware pipeline control
- Verilog testbench with cycle-by-cycle monitoring and final checks

## Simulation

Tested with **QuestaSim/ModelSim**.

From the `src` directory:

```bash
vlog *.v
vsim -c work.tb_pipelined_cpu -do "run 600ns; quit"
```

The testbench checks register and memory results and reports `TEST PASSED` or `TEST FAILED`.

## Structure

```text
src/    RTL and testbench
docs/   Architecture and design documentation
tb/     Testbench-related files
sim/    Simulation files
```

## Author

Srinnath Krishnan

