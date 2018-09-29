`include "sccu_dataflow.v"
`include "dff32.v"
// `include "mux4x32.v"
`include "regfile.v"
`include "alu.v"

module sccpu (clk,clrn,inst,mem,pc,wmem,alu,data);
    input [31:0] inst;
    input [31:0] mem;
    input clk, clrn;
    output [31:0] pc;
    output [31:0] alu;
    output [31:0] data;
    output wmem;

    wire [5:0] op = inst[31:26];
    wire [4:0] rs = inst[25:21];
    wire [4:0] rt = inst[20:16];
    wire [4:0] rd = inst[15:11];
    wire [5:0] func = inst[05:00];
    wire [15:0] imm = inst[15:00];
    wire [25:0] addr = inst[25:00];

    wire [3:0] aluc;
    wire [1:0] pcsrc;
    wire wreg, regrt, m2reg, shift;
    wire aluimm, jal, sext, z;

    // cpu 控制单元
    // 输入只有 op 与 func 以及 z，来判断
    // 各种信号是否进行使能等
    // 各种信号的含义 如wiz笔记中               understand half
    sccu_dataflow cu (op,func,z,wmem,wreg,regrt,m2reg,
        aluc,shift,aluimm,pcsrc,jal,sext);

    wire [31:0] qa, qb, npc;
    wire [31:0] p4 = pc + 32'h4;                    // PC + 4 下一条指令地址
    wire [31:0] sa = {27'b0,inst[10:6]};            // 中间变量 移位数
    wire [15:0] s16 = {16{sext & inst[15]}};        // 中间变量
    wire [31:0] i32 = {s16,imm};                    // 中间变量，符号扩展后的立即数
    wire [31:0] dis = {s16[13:0],imm,2'b00};        // beq、bne 求下一条指令地址的中间变量
    wire [31:0] jpc = {p4[31:28],addr,2'b00};       // j、jal 求下一条指令地址的中间变量
    wire [31:0] bpc = p4 + dis;                     // beq、bne 求下一条指令地址
    wire [31:0] alua =shift ?sa :qa;                // alua端的值选择 如果需要移位则选择 sa，否则选择reg[rs]
    wire [31:0] alub = aluimm ? i32 : qb;           // alub端的值选择 如果使用立即数则选择扩展后的立即数，否则选择reg[rt]
    wire [31:0] r = m2reg ? mem : alu;              // 中间结果：如果是从存储器写往寄存器则选择mem否则选择alu的值
    wire [31:0] wd = jal ? p4 : r;                  // 是否为子程序调用？如果是，则将写入寄存器的值为PC+4，否则为r
    wire [4:0]  wn = (regrt ? rt : rd) | {5{jal}};  // 写往寄存器的地址，如果回写的目的寄存器号位rt，则位rt否则位rd
                                                    // 但是如果指令是jal时，将覆盖这些值，回写的目的寄存器号为31

    // 32位d触发器随着时钟沿的到来，pc更新为npc的值。  understand
    dff32 i_point(npc,clk,clrn,pc);

    // 32位四选一器
    // npc 根据pcsrc的值，从p4, bpc, qa, jpc 中选择一个   understand
    mux4x32 nextpc (p4,bpc,qa,jpc,pcsrc,npc);

    // regfile 表示32个寄存器  unstand
    regfile rf (rs,rt,wd,wn,wreg,clk,clrn,qa,qb);

    // 计算单元，输入两个计算数，以及计算的具体操作。
    // 输出计算结果与是否为0等
    alu alunit (alua,alub,aluc,alu,z);

    assign data = qb;

endmodule
