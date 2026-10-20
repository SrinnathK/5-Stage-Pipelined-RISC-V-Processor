`timescale 1ns/1ps
module alu_control (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire       funct7_5, // bit[30] (funct7[5]) used to distinguish sub
    output reg  [3:0] alu_ctrl
);
    always @(*) begin
        alu_ctrl = 4'b0000;
        case (alu_op)
            2'b00: alu_ctrl = 4'b0000; // ADD (for lw/sw)
            2'b01: alu_ctrl = 4'b0001; // SUB (for branch compare)
            2'b10: begin // R-type or I-type ALU (use funct3/funct7)
                case (funct3)
                    3'b000: begin
                        if (funct7_5) alu_ctrl = 4'b0001; else alu_ctrl = 4'b0000; // SUB if funct7[5]=1
                    end
                    3'b111: alu_ctrl = 4'b0010; // AND
                    3'b110: alu_ctrl = 4'b0011; // OR
                    default: alu_ctrl = 4'b0000;
                endcase
            end
            default: alu_ctrl = 4'b0000;
        endcase
    end
endmodule
