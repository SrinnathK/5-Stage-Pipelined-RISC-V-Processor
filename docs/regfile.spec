Asynchronous Read, Synchronous Write

Because that’s exactly how real hardware register files behave in a CPU:

Reading happens during the same cycle (to feed ALU inputs).

Writing happens at the clock edge (so next instruction can see updated data).

This allows 1-cycle register access, which is essential for pipelined CPUs.