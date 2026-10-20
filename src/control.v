`timescale 1ns/1ps
module control (
    input  wire [6:0] opcode,
    output reg        regwrite,
    output reg [1:0]  imm_src,
    output reg        alu_src,
    output reg        mem_write,
    output reg [1:0]  result_src,
    output reg        branch,
    output reg [1:0]  alu_op,
    output reg        jump
);
    localparam OPC_LW  = 7'b0000011;
    localparam OPC_SW  = 7'b0100011;
    localparam OPC_R   = 7'b0110011;
    localparam OPC_BEQ = 7'b1100011;
    localparam OPC_IT  = 7'b0010011; // addi (I-type ALU)
    localparam OPC_JAL = 7'b1101111;

    always @(*) begin
        regwrite   = 0;
        imm_src    = 2'b00;
        alu_src    = 0;
        mem_write  = 0;
        result_src = 2'b00;
        branch     = 0;
        alu_op     = 2'b00;
        jump       = 0;

        case (opcode)
            OPC_LW: begin
                regwrite   = 1;
                imm_src    = 2'b00; // I
                alu_src    = 1;
                mem_write  = 0;
                result_src = 2'b01; // from mem
                branch     = 0;
                alu_op     = 2'b00; // add for address
                jump       = 0;
            end
            OPC_SW: begin
                regwrite   = 0;
                imm_src    = 2'b01; // S
                alu_src    = 1;
                mem_write  = 1;
                result_src = 2'b00;
                branch     = 0;
                alu_op     = 2'b00;
                jump       = 0;
            end
            OPC_R: begin
                regwrite   = 1;
                imm_src    = 2'b00;
                alu_src    = 0;
                mem_write  = 0;
                result_src = 2'b00; // ALU
                branch     = 0;
                alu_op     = 2'b10; // R-type
                jump       = 0;
            end
            OPC_BEQ: begin
                regwrite   = 0;
                imm_src    = 2'b10; // B
                alu_src    = 0;
                mem_write  = 0;
                result_src = 2'b00;
                branch     = 1;
                alu_op     = 2'b01; // use SUB for compare
                jump       = 0;
            end
            OPC_IT: begin
                regwrite   = 1;
                imm_src    = 2'b00; // I
                alu_src    = 1;
                mem_write  = 0;
                result_src = 2'b00; // ALU
                branch     = 0;
                alu_op     = 2'b10;
                jump       = 0;
            end
            OPC_JAL: begin
                regwrite   = 1;
                imm_src    = 2'b11; // J
                alu_src    = 0;
                mem_write  = 0;
                result_src = 2'b10; // PC+4
                branch     = 0;
                alu_op     = 2'b00;
                jump       = 1;
            end
            default: begin
                // NOP
            end
        endcase
    end
endmodule
