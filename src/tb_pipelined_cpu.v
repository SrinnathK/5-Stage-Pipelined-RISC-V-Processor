// tb_pipelined_cpu.v – minimal, pure Verilog testbench (fixed: no in-block declarations)
`timescale 1ns/1ps
module tb_pipelined_cpu;
    reg clk, rst;
    integer cycle;
    reg pass;
    integer i;
    reg [31:0] wbval;

    // instantiate CPU under test
    pipelined_cpu cpu (.clk(clk), .rst(rst));

    // clock generator
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns period
    end

    // initial reset and startup
    initial begin
        $display("\n--- Running pipelined_cpu minimal TB ---");
        rst = 1;
        #12;
        rst = 0;
        cycle = 0;
    end

    // per-cycle compact monitor and final checks
    always @(posedge clk) begin
        cycle = cycle + 1;
        $display("[CYCLE %0d] PC=0x%08h", cycle, cpu.pc);

        if (cpu.EXMEM_mem_write) begin
            $display("    [MEM] Write 0x%08h -> dmem[%0d]", cpu.EXMEM_rd2, cpu.EXMEM_alu_result >> 2);
        end

        if (cpu.MEMWB_regwrite) begin
            wbval = (cpu.MEMWB_result_src == 2'b01) ? cpu.MEMWB_read_data :
                    (cpu.MEMWB_result_src == 2'b10) ? (cpu.MEMWB_pc + 4) :
                                                      cpu.MEMWB_alu_result;
            $display("    [WB]  x%0d <= 0x%08h (%0d)", cpu.MEMWB_rd, wbval, wbval);
        end

        // change this cycle count if you need longer run
        if (cycle == 60) begin
            $display("\n--- Final checks ---");
            pass = 1;

            if (cpu.regs.regs[1] !== 32'd5) begin $display("FAIL: x1=%0d expect=5", cpu.regs.regs[1]); pass = 0; end
            else $display("OK:   x1=5");

            if (cpu.regs.regs[2] !== 32'd3) begin $display("FAIL: x2=%0d expect=3", cpu.regs.regs[2]); pass = 0; end
            else $display("OK:   x2=3");

            if (cpu.regs.regs[3] !== 32'd8) begin $display("FAIL: x3=%0d expect=8", cpu.regs.regs[3]); pass = 0; end
            else $display("OK:   x3=8");

            if (cpu.dmem.mem[0] !== 32'd8) begin $display("FAIL: dmem[0]=%0d expect=8", cpu.dmem.mem[0]); pass = 0; end
            else $display("OK:   dmem[0]=8");

            if (cpu.regs.regs[4] !== 32'd8) begin $display("FAIL: x4=%0d expect=8", cpu.regs.regs[4]); pass = 0; end
            else $display("OK:   x4=8");

            if (cpu.regs.regs[5] !== 32'd0) begin $display("FAIL: x5=%0d expect=0 (branch skip)", cpu.regs.regs[5]); pass = 0; end
            else $display("OK:   x5=0 (branch skipped)");

            if (cpu.regs.regs[6] !== 32'd9) begin $display("FAIL: x6=%0d expect=9", cpu.regs.regs[6]); pass = 0; end
            else $display("OK:   x6=9");

            if (pass) $display("\n=== TEST PASSED ✅ ===");
            else begin
                $display("\n=== TEST FAILED ❌ ===");
                // small dump for debugging
                for (i=0; i<8; i=i+1) $display("x%0d = 0x%08h (%0d)", i, cpu.regs.regs[i], cpu.regs.regs[i]);
                $display("dmem[0]=0x%08h (%0d)", cpu.dmem.mem[0], cpu.dmem.mem[0]);
            end

            $finish;
        end
    end

endmodule
