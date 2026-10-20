// /src/regfile.v
`timescale 1ns/1ps
module regfile (
    input  wire         clk,
    input  wire         we,       // write enable (write on rising edge)
    input  wire [4:0]   ra1,
    input  wire [4:0]   ra2,
    input  wire [4:0]   wa,
    input  wire [31:0]  wd,
    output wire [31:0]  rd1,
    output wire [31:0]  rd2
);
    reg [31:0] regs [0:31];
    integer i;
    initial begin
        for (i=0;i<32;i=i+1) regs[i] = 32'b0;
    end

    // asynchronous read (common in simple behavioral regfiles)
    assign rd1 = (ra1 == 5'd0) ? 32'b0 : regs[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'b0 : regs[ra2];

    // synchronous write
    always @(posedge clk) begin
        if (we && (wa != 5'd0)) regs[wa] <= wd;
    end
endmodule

