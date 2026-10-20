// /src/imm_gen.v
`timescale 1ns/1ps
module imm_gen (
    input  wire [31:0] instr,
    input  wire [1:0]  imm_src, // 00 I, 01 S, 10 B, 11 J
    output reg  [31:0] imm_out
);
    always @(*) begin
        case (imm_src)
            2'b00: begin // I-type
                imm_out = {{20{instr[31]}}, instr[31:20]};
            end
            2'b01: begin // S-type
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
            2'b10: begin // B-type (branch) - already shifted (LSB = 0)
                imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            2'b11: begin // J-type (jal) - LSB = 0
                imm_out = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            default: imm_out = 32'b0;
        endcase
    end
endmodule
