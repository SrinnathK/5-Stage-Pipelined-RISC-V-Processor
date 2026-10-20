// /src/instr_mem.v
`timescale 1ns/1ps
module instr_mem (
    input  wire [31:0] addr,
    output reg  [31:0] instr
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i=0;i<256;i=i+1) mem[i]=32'b0;

        // Load instructions from imem.hex (one 32-bit hex word per line).
        $readmemh("imem.hex", mem);
    end

    always @(*) begin
        instr = mem[addr[9:2]]; 
    end
endmodule
