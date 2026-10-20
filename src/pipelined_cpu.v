// pipelined_cpu.v 
`timescale 1ns/1ps
module pipelined_cpu (
    input wire clk,
    input wire rst
);
    // ----------------
    // Program counter
    // ----------------
    reg [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4 = pc + 4;

    // ----------------
    // MEM/WB pipeline registers
    // ----------------
    reg [31:0] MEMWB_read_data;
    reg [31:0] MEMWB_alu_result;
    reg [4:0]  MEMWB_rd;
    reg        MEMWB_regwrite;
    reg [1:0]  MEMWB_result_src;
    reg [31:0] MEMWB_pc;

    // ----------------
    // WB stage: result selection
    // ----------------
    wire [31:0] wb_result;
    assign wb_result = (MEMWB_result_src == 2'b01) ? MEMWB_read_data :
                       (MEMWB_result_src == 2'b10) ? (MEMWB_pc + 4) : MEMWB_alu_result;

    // ----------------
    // IF stage: instr mem
    // ----------------
    wire [31:0] instr_if;
    instr_mem imem(.addr(pc), .instr(instr_if));

    // IF/ID pipeline regs
    reg [31:0] IFID_instr;
    reg [31:0] IFID_pc;

    // ID decode fields
    wire [6:0] ID_opcode = IFID_instr[6:0];
    wire [4:0] ID_rs1    = IFID_instr[19:15];
    wire [4:0] ID_rs2    = IFID_instr[24:20];
    wire [4:0] ID_rd     = IFID_instr[11:7];
    wire [2:0] ID_funct3 = IFID_instr[14:12];
    wire       ID_funct7_5 = IFID_instr[30];

    // ----------------
    // Control unit (ID stage)
    // ----------------
    wire        ctrl_regwrite;
    wire [1:0]  ctrl_imm_src;
    wire        ctrl_alu_src;
    wire        ctrl_mem_write;
    wire [1:0]  ctrl_result_src;
    wire        ctrl_branch;
    wire [1:0]  ctrl_alu_op;
    wire        ctrl_jump;

    control control_unit (
        .opcode(ID_opcode),
        .regwrite(ctrl_regwrite),
        .imm_src(ctrl_imm_src),
        .alu_src(ctrl_alu_src),
        .mem_write(ctrl_mem_write),
        .result_src(ctrl_result_src),
        .branch(ctrl_branch),
        .alu_op(ctrl_alu_op),
        .jump(ctrl_jump)
    );

    // ----------------
    // Register file: single instance (reads use ID rs1/rs2, writes from MEM/WB)
    // ----------------
    wire [31:0] rf_rd1, rf_rd2;
    wire        rf_we = MEMWB_regwrite;
    wire [4:0]  rf_wa = MEMWB_rd;
    wire [31:0] rf_wd = wb_result;

    regfile regs (
        .clk(clk),
        .we(rf_we),
        .ra1(ID_rs1),
        .ra2(ID_rs2),
        .wa(rf_wa),
        .wd(rf_wd),
        .rd1(rf_rd1),
        .rd2(rf_rd2)
    );

    // ----------------
    // Immediate generator (ID)
    // ----------------
    wire [31:0] imm_id;
    imm_gen immgen (.instr(IFID_instr), .imm_src(ctrl_imm_src), .imm_out(imm_id));

    // ----------------
    // ID/EX pipeline registers
    // ----------------
    reg [31:0] IDEX_pc;
    reg [31:0] IDEX_rd1;
    reg [31:0] IDEX_rd2;
    reg [31:0] IDEX_imm;
    reg [4:0]  IDEX_rs1;
    reg [4:0]  IDEX_rs2;
    reg [4:0]  IDEX_rd;
    reg        IDEX_regwrite;
    reg        IDEX_alu_src;
    reg [1:0]  IDEX_alu_op;
    reg        IDEX_mem_write;
    reg [1:0]  IDEX_result_src;
    reg        IDEX_branch;
    reg        IDEX_jump;
    reg [2:0]  IDEX_funct3;
    reg        IDEX_funct7_5;

    // ----------------
    // EX stage: ALU
    // ----------------
    wire [31:0] alu_a = IDEX_rd1;
    wire [31:0] alu_b = (IDEX_alu_src) ? IDEX_imm : IDEX_rd2;

    wire [3:0] alu_ctrl;
    alu_control aluctrl (
        .alu_op(IDEX_alu_op),
        .funct3(IDEX_funct3),
        .funct7_5(IDEX_funct7_5),
        .alu_ctrl(alu_ctrl)
    );

    wire [31:0] alu_result;
    wire        alu_zero;
    alu alu0 (.a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl), .result(alu_result), .zero(alu_zero));

    wire [31:0] ex_branch_target = IDEX_pc + IDEX_imm;

    // ----------------
    // EX/MEM pipeline registers
    // ----------------
    reg [31:0] EXMEM_alu_result;
    reg        EXMEM_zero;
    reg [31:0] EXMEM_rd2;
    reg [4:0]  EXMEM_rd;
    reg        EXMEM_regwrite;
    reg        EXMEM_mem_write;
    reg [1:0]  EXMEM_result_src;
    reg [31:0] EXMEM_pc;
    reg        EXMEM_branch;
    reg [31:0] EXMEM_branch_target;
    reg        EXMEM_jump;

    // ----------------
    // MEM stage: data memory
    // ----------------
    wire [31:0] mem_read_data;
    data_mem dmem (
        .clk(clk),
        .mem_write(EXMEM_mem_write),
        .addr(EXMEM_alu_result),
        .write_data(EXMEM_rd2),
        .read_data(mem_read_data)
    );


    wire take_branch = EXMEM_branch & EXMEM_zero;
    wire take_jump   = EXMEM_jump;
    assign pc_next = (take_jump) ? EXMEM_branch_target :
                     (take_branch) ? EXMEM_branch_target :
                     (pc + 4);


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'b0;
            IFID_instr <= 32'b0;
            IFID_pc <= 32'b0;

            IDEX_pc <= 32'b0;
            IDEX_rd1 <= 32'b0;
            IDEX_rd2 <= 32'b0;
            IDEX_imm <= 32'b0;
            IDEX_rs1 <= 5'b0;
            IDEX_rs2 <= 5'b0;
            IDEX_rd <= 5'b0;
            IDEX_regwrite <= 1'b0;
            IDEX_alu_src <= 1'b0;
            IDEX_alu_op <= 2'b00;
            IDEX_mem_write <= 1'b0;
            IDEX_result_src <= 2'b00;
            IDEX_branch <= 1'b0;
            IDEX_jump <= 1'b0;
            IDEX_funct3 <= 3'b0;
            IDEX_funct7_5 <= 1'b0;

            EXMEM_alu_result <= 32'b0;
            EXMEM_zero <= 1'b0;
            EXMEM_rd2 <= 32'b0;
            EXMEM_rd <= 5'b0;
            EXMEM_regwrite <= 1'b0;
            EXMEM_mem_write <= 1'b0;
            EXMEM_result_src <= 2'b00;
            EXMEM_pc <= 32'b0;
            EXMEM_branch <= 1'b0;
            EXMEM_branch_target <= 32'b0;
            EXMEM_jump <= 1'b0;

            MEMWB_read_data <= 32'b0;
            MEMWB_alu_result <= 32'b0;
            MEMWB_rd <= 5'b0;
            MEMWB_regwrite <= 1'b0;
            MEMWB_result_src <= 2'b00;
            MEMWB_pc <= 32'b0;
        end else begin
            // PC
            pc <= pc_next;

            // IF/ID <= IF
            IFID_instr <= instr_if;
            IFID_pc <= pc;

            // ID/EX <= ID
            IDEX_pc <= IFID_pc;
            IDEX_rd1 <= rf_rd1;
            IDEX_rd2 <= rf_rd2;
            IDEX_imm <= imm_id;
            IDEX_rs1 <= ID_rs1;
            IDEX_rs2 <= ID_rs2;
            IDEX_rd <= ID_rd;
            IDEX_regwrite <= ctrl_regwrite;
            IDEX_alu_src <= ctrl_alu_src;
            IDEX_alu_op <= ctrl_alu_op;
            IDEX_mem_write <= ctrl_mem_write;
            IDEX_result_src <= ctrl_result_src;
            IDEX_branch <= ctrl_branch;
            IDEX_jump <= ctrl_jump;
            IDEX_funct3 <= ID_funct3;
            IDEX_funct7_5 <= ID_funct7_5;

            // EX/MEM <= EX
            EXMEM_alu_result <= alu_result;
            EXMEM_zero <= alu_zero;
            EXMEM_rd2 <= IDEX_rd2;
            EXMEM_rd <= IDEX_rd;
            EXMEM_regwrite <= IDEX_regwrite;
            EXMEM_mem_write <= IDEX_mem_write;
            EXMEM_result_src <= IDEX_result_src;
            EXMEM_pc <= IDEX_pc;
            EXMEM_branch <= IDEX_branch;
            EXMEM_branch_target <= ex_branch_target;
            EXMEM_jump <= IDEX_jump;

            // MEM/WB <= MEM
            MEMWB_read_data <= mem_read_data;
            MEMWB_alu_result <= EXMEM_alu_result;
            MEMWB_rd <= EXMEM_rd;
            MEMWB_regwrite <= EXMEM_regwrite;
            MEMWB_result_src <= EXMEM_result_src;
            MEMWB_pc <= EXMEM_pc;
        end
    end

    // debug print
    always @(posedge clk) begin
        $display("T=%0t PC=0x%08h IF_instr=0x%08h", $time, pc, instr_if);
    end

endmodule
