`include "sccu_intr.v"
`include "dff32.v"
`include "dffe32.v"
// `include "mux4x32.v"
`include "mux2x32.v"
`include "mux2x5.v"
`include "regfile.v"
`include "alu_ov.v"
// sccpu_intr cpu (clk, resetn, inst, memout, pc, wmem, aluout, data, intr, inta);
// inta 中断确认
// CPU中有PC寄存器，保存着上一次PC的值
// output
// pc       下一个PC，根据CPU控制单元中传出的selpc信号，选择npc, epc, EXC_BASE, 32'h0
// alu      alu输出的值
// data     从寄存器组中读取的值
// wmem     写memory使能信号
// inta     中断应答信号，
module sccpu_intr (clock, resetn, inst, mem, pc, wmem, alu, data, intr, inta);
    input [31:0] inst;
    input [31:0] mem;
    input clock, resetn, intr;
    output [31:0] pc;
    output [31:0] alu;
    output [31:0] data;
    output wmem, inta;

    parameter EXC_BASE = 32'h00000008; // base = BASE
    
    // 声明在原来位置会报错？？可能是编译器iverilog的原因
    wire exc, wsta, wcau, wepc, mtc0;
    wire [31:0] sta, cau, epc, sta_in, cau_in, epc_in,
                sta_l1_a0, epc_l1_a0, cause, alu_mem_c0, next_pc;
    
    wire [1:0] mfc0, selpc;
    // 
    wire [31:0] p4, bpc, npc, adr, ra, alua, alub, res, alu_mem;
    wire [3:0] aluc;
    wire [4:0] reg_dest, wn;
    wire [1:0] pcsource;
    wire zero, wmem, wreg, regrt, m2reg, shift, aluimm, jal, sext, overflow;
    wire [31:0] sa = {27'b0, inst[10:6]};
    wire [31:0] offset = {imm[13:0], inst[15:0], 1'b0, 1'b0};
    sccu_intr cu (inst[31:26], inst[25:21], inst[15:11], inst[5:0], zero, wmem,
        wreg, regrt, m2reg, aluc, shift, aluimm, pcsource, jal, sext,
        intr, inta, overflow, sta, cause, exc, wsta, wcau, wepc, mtc0, mfc0, selpc);
    wire e = sext & inst[15];
    wire [15:0] imm = {16{e}};
    wire [31:0] immediate = {imm, inst[15:0]};
    dff32 ip (next_pc, clock, resetn, pc);// next_pc   (not found)
    // cla32 pcplus4 (pc, 32h'4, 1'b0, p4); // 并行加法进位器，与现有的代码不符合，需要修改，缺少一位
    assign p4 = pc + 4;
    // cla32 br_adr  (pc, offset, 1'b0, adr);
    assign adr = pc + offset;

    wire [31:0] jpc = {p4[31:28], inst[25:0], 1'b0, 1'b0};
    mux2x32 alu_b  (data, immediate, aluimm, alub);
    mux2x32 alu_a  (ra, sa, shift, alua);
    mux2x32 result (alu, mem, m2reg, alu_mem);
    // jal 子程序调用
    mux2x32 link   (alu_mem_c0, p4, jal, res); // alu_mem_c0
    mux2x5  reg_wn (inst[15:11], inst[20:16], regrt, reg_dest);
    assign wn = reg_dest | {5{jal}};
    mux4x32 nextpc (p4, adr, ra, jpc, pcsource, npc);
    regfile rf (inst[25:21], inst[20:16], res, wn, wreg, clock, resetn, ra, data);
    alu_ov al_unit (alua, alub, aluc, alu, zero, overflow);

    // CPU模块新加的与异常或中断有关的电路：3个寄存器和7个多路器
    
    // 寄存器是否需要写入取决的wsta信号是否使能
    dffe32 c0_Status (sta_in, clock, resetn, wsta, sta);
    dffe32 c0_Cause  (cau_in, clock, resetn, wcau, cau);
    dffe32 c0_EPC    (epc_in, clock, resetn, wepc, epc);
    // unknow dffe32

    // 多路器的输出
    // sta_in
    // sta_l1_a0
    // cau_in
    // epc_in
    // epc_l1_a0
    // next_pc
    // alu_mem_c0

    // sta寄存器需要写入的值取决于是否执行了mtc0指令
    mux2x32 sta_l1 (sta_l1_a0, data, mtc0, sta_in);
    // sta寄存器左移or右移取决于中断或异常是否发生
    mux2x32 sta_l2 ({4'h0, sta[31:4]}, {sta[27:0], 4'h0}, exc, sta_l1_a0);

    // cau寄存器需要写入的值取决于是否执行了mtc0指令
    // 若执行了mtc0指令则写入cau寄存器的值取cause(引起中断或异常的原因)，否则写入data
    mux2x32 cau_l1 (cause, data, mtc0, cau_in);

    // 写入epc的值为“pc” or data, 取决于执行了何种指令
    mux2x32 epc_l1 (epc_l1_a0, data, mtc0, epc_in);
    // epc_l1_a0 取决于是否进行了中断应答
    mux2x32 epc_l2 (pc, npc, inta, epc_l1_a0);

    mux4x32 irq_pc (npc, epc, EXC_BASE, 32'h0, selpc, next_pc);
    mux4x32 fromc0 (alu_mem, sta, cau, epc, mfc0, alu_mem_c0);
endmodule
