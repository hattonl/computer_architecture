`include "mux2x5.v"
`include "mux4x32.v"
`include "pipeidcu.v"
`include "regfile.v"

module pipeid (mwreg, mrn, ern, ewreg, em2reg, mm2reg, dpc4, inst, wrn,
              wdi, ealu, malu, mmo, wwreg, clk, clrn, bpc, jpc, pcsource,
              nostall, wreg, m2reg, wmem, aluc, aluimm, a, b, imm, rn,
              shift, jal);
    input [31:0] dpc4, inst, wdi, ealu, malu, mmo;
    input [4:0]  ern, mrn, wrn;
    input        mwreg, ewreg, em2reg, mm2reg, wwreg;
    input        clk, clrn;

    output [31:0] bpc, jpc, a, b, imm;
    output [4:0]  rn;
    output [3:0]  aluc;
    output [1:0]  pcsource;
    output        nostall, wreg, m2reg, wmem, aluimm, shift, jal;

    wire [5:0] op, func;
    wire [4:0] rs, rt, rd;
    wire [31:0] qa, qb, br_offset;
    wire [15:0] ext16;
    wire [1:0]  fwda, fwdb;
    wire        regrt, sext, rsrtequ, e;

    assign func = inst[5:0];
    assign op   = inst[31:26];
    assign rs   = inst[25:21];
    assign rt   = inst[20:16];
    assign rd   = inst[15:11];
    assign jpc  = {dpc4[31:28], inst[25:0], 2'b00}; // for j jal inst

    // mwreg, mrn, ern, ewreg, em2reg, mm2reg 为实现内部前推而增加的控制信号
    pipeidcu cu (mwreg, mrn, ern, ewreg, em2reg, mm2reg, rsrtequ, func,
                 op, rs, rt, wreg, m2reg, wmem, aluc, regrt, aluimm,
                 fwda, fwdb, nostall, sext, pcsource, shift, jal);
    
    // qa 根据rs 从寄存器组取出的数据
    // qb 根据rt 从寄存器组取出的数据
    // wdi: d: 要写入的数据
    // wrn:   要写入的寄存器号
    // wwreg: 写使能信号
    regfile rf (rs, rt, wdi, wrn, wwreg, ~clk, clrn, qa, qb);

    // regrt = 1 表示要写入的寄存器号为rt， 否则为rd
    mux2x5 des_reg_no (rd, rt, regrt, rn);


    // fwda与fwdb为两个内部前推实现的控制限号
    // 内部前推的实现，内部旁路
    mux4x32 alu_a (qa, ealu, malu, mmo, fwda, a);
    mux4x32 alu_b (qb, ealu, malu, mmo, fwdb, b);

    // rsrtequ = 1 表示，reg[rs] == reg[rd]
    assign rsrtequ = ~|(a^b);


    // imm 计算出带符号位扩展的立即数
    assign e = sext & inst[15];
    assign ext16 = {16{e}};
    assign imm = {ext16, inst[15:0]};

    // bpc 计算出跳转地址  beq\bne
    assign br_offset = {imm[29:0], 2'b00};
    // cla32 br_addr (dpc4, br_offset, 1'b0, bpc);
    assign bpc = dpc4 + br_offset;
    
endmodule

