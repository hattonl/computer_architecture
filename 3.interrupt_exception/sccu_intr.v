// CPU控制单元（带中断处理）
// module sccu_dataflow (op,func,z,wmem,wreg,regrt,m2reg,aluc,shift,aluimm,
//                     pcsrc,jal,sext);
// 新增加的信号有：
// output:
// aluc      alu计算方式
// pcsource  4种pc选项
// jal       子程序调用
// sext      立即数符号扩展
// inta      中断应答，中断发生，且中断允许标识位为1时inta值为1
// cause     cause寄存器记录引起中断的原因
// exc       中断或异常是否发生，外部中断或3种异常发生时为1
// wsta      发生中断或异常, 或 mtc0指令中rd为status寄存器号, 或中断/异常返回被执行
// wcau      发生中断或异常, 或 mtc0指令中rd为cause寄存器号
// wepc      发生中断或异常, 或 mtc0指令中rd为epc寄存器号
// mtc0      当前指令为mtc0指令时为1
// mfc0      mfc0信号以区分是通用寄存器还是专用寄存器，00为通用寄存器 01 - 11 为三个专用寄存器(01 status 10 cause 11 EPC)
// selpc     对于下一个PC的选择，00表示选择原来的npc(在第5章中表示过的那样)，01 EPC (中断返回？eret指令执行)，10 中断或异常的程序入口

module sccu_intr (op, op1, rd, func, z, wmem, wreg, regrt, m2reg, aluc,
        shift, aluimm, pcsource, jal, sext,
        intr, inta, ov, sta, cause, exc, wsta, wcau, wepc, mtc0, mfc0, selpc);

    input [5:0] op, func;
    input [4:0] op1, rd;  // 为本次中断处理的支持新添加
    input z;

    output [3:0] aluc;
    output [1:0] pcsource;
    output wreg;
    output regrt;
    output m2reg;
    output shift;
    output aluimm;
    output jal;
    output sext;
    output wmem;

    // 与异常或中断有关的额信号
    input intr, ov;
    input [31:0] sta;
    output inta, exc, wsta, wcau, wepc, mtc0;
    output [1:0] mfc0, selpc;
    output [31:0] cause;

    // 区别异常和中断的类型，4种，外部中断、系统调用、未实现的指令、溢出

    wire overflow = ov & (i_add | i_sub | i_addi); // ov 来自ALU的输出
    assign 	inta = int_int; // int_int 来自 ？？？
    wire int_int = sta[0] & intr;  // sta 寄存器 ？？ 
    wire exc_sys = sta[1] & i_syscall;
    wire exc_uni = sta[2] & unimplemented_inst;
    wire exc_ovr = sta[3] & overflow;
    assign exc = int_int | exc_sys | exc_uni | exc_ovr;

    // 产生ExcCode: 00 外部中断 01 系统调用 10 未实现的指令 11 溢出
    wire ExcCode0 = i_syscall | overflow;
    wire ExcCode1 = unimplemented_inst | overflow;
    assign cause = {28'h0, ExcCode1, ExcCode0, 2'b00};

    // 产生3个寄存器的写使能信号
    assign mtc0 = i_mtc0;
    assign wsta = exc | mtc0 & rd_is_status | i_eret;  // 发生中断或异常, 或 mtc0指令中rd为status寄存器号, 或中断/异常返回被执行
    assign wcau = exc | mtc0 & rd_is_cause; // 发生中断或异常, 或 mtc0指令中rd为cause寄存器号
    assign wepc = exc | mtc0 & rd_is_epc;  // 发生中断或异常, 或 mtc0指令中rd为epc寄存器号

    // 执行mfc0指令时选择寄存器：00 原来的、01 status 10 cause 11 EPC
    wire rd_is_status = (rd == 5'd12); // rd 是 12号寄存器 cause
    wire rd_is_cause  = (rd == 5'd13); // rd 是 13号寄存器 status
    wire rd_is_epc    = (rd == 5'd14); // rd 是 14号寄存器 EPC
    assign mfc0[0] = i_mfc0 & rd_is_status | i_mfc0 & rd_is_epc;
    assign mfc0[1] = i_mfc0 & rd_is_cause  | i_mfc0 & rd_is_epc;

    // PC的选择 00 原来的 01 EPC 10 异常或中断处理程序入口
    assign selpc[0] = i_eret;
    assign selpc[1] = exc;

    // 对新加4条指令译码以及确定是否为未实现的指令
    wire c0_type = ~op[5] & op[4] & ~op[3] & ~op[2] & ~op[1] & ~op[1] & ~op[0];
    wire i_mfc0  = c0_type & ~op1[4] & ~op1[3] & ~op1[2] & ~op1[1] & ~op1[0];
    wire i_mtc0  = c0_type & ~op1[4] & ~op1[3] &  op1[2] & ~op1[1] & ~op1[0];
    wire i_eret  = c0_type &  op1[4] & ~op1[3] & ~op1[2] & ~op1[1] & ~op1[0] & 
                ~func[5] & func[4] & func[3] & ~func[2] & ~func[1] & ~func[0];
    wire i_syscall = r_type & ~func[5] & ~func[4] & func[3] & func[2] & ~func[1] & ~func[0];
    wire unimplemented_inst = ~(i_mfc0 | i_mtc0 | i_eret | i_syscall |
            i_add | i_sub | i_and | i_or | i_xor | i_sll | i_srl | 
            i_sra | i_jr | i_addi | i_addi | i_ori | i_xori | i_lw |
            i_sw | i_beq | i_bne | i_lui | i_j | i_jal);
    
    
    // 以下与第5章的内容基本相同，只是顾及了mfc0指令
    wire r_type = ~|op;
    // ...
    wire i_add = r_type &  func[5] & ~func[4] & ~func[3] & ~func[2] & ~func[1] & ~func[0];
    wire i_sub = r_type &  func[5] & ~func[4] & ~func[3] & ~func[2] &  func[1] & ~func[0];
    wire i_and = r_type &  func[5] & ~func[4] & ~func[3] &  func[2] & ~func[1] & ~func[0];
    wire i_or  = r_type &  func[5] & ~func[4] & ~func[3] &  func[2] & ~func[1] &  func[0];
    wire i_xor = r_type &  func[5] & ~func[4] & ~func[3] &  func[2] &  func[1] & ~func[0];
    wire i_sll = r_type & ~func[5] & ~func[4] & ~func[3] & ~func[2] & ~func[1] & ~func[0];
    wire i_srl = r_type & ~func[5] & ~func[4] & ~func[3] & ~func[2] &  func[1] & ~func[0];
    wire i_sra = r_type & ~func[5] & ~func[4] & ~func[3] & ~func[2] &  func[1] &  func[0];
    wire i_jr  = r_type & ~func[5] & ~func[4] &  func[3] & ~func[2] & ~func[1] & ~func[0];

    wire i_addi = ~op[5] & ~op[4] &  op[3] & ~op[2] & ~op[1] & ~op[0];
    wire i_andi = ~op[5] & ~op[4] &  op[3] &  op[2] & ~op[1] & ~op[0];
    wire i_ori  = ~op[5] & ~op[4] &  op[3] &  op[2] & ~op[1] &  op[0];
    wire i_xori = ~op[5] & ~op[4] &  op[3] &  op[2] &  op[1] & ~op[0];
    wire i_lw   =  op[5] & ~op[4] & ~op[3] & ~op[2] &  op[1] &  op[0];
    wire i_sw   =  op[5] & ~op[4] &  op[3] & ~op[2] &  op[1] &  op[0];
    wire i_beq  = ~op[5] & ~op[4] & ~op[3] &  op[2] & ~op[1] & ~op[0];
    wire i_bne  = ~op[5] & ~op[4] & ~op[3] &  op[2] & ~op[1] &  op[0];
    wire i_lui  = ~op[5] & ~op[4] &  op[3] &  op[2] &  op[1] &  op[0];
    wire i_j    = ~op[5] & ~op[4] & ~op[3] & ~op[2] &  op[1] & ~op[0];
    wire i_jal  = ~op[5] & ~op[4] & ~op[3] & ~op[2] &  op[1] &  op[0];

    // 当指令为一下指令时，使能写寄存器
    assign wreg = i_add | i_sub | i_and | i_or | i_xor | i_sll |
                  i_srl | i_sra | i_addi | i_andi | i_ori | i_xori |
                  i_lui | i_lw | i_jal | i_mfc0; // add i_mfc0

    // 目的寄存器时rt
    assign regrt = i_addi | i_andi | i_ori | i_xori | i_lui | i_lw | i_mfc0; // add i_mfc0

    assign jal = i_jal; // 是子程序调用

    // 是否由存储器写入寄存器
    assign m2reg = i_lw;

    // ALU a 使用移位位数
    assign shift = i_sll | i_srl | i_sra;

    // ALU b 使用立即数
    assign aluimm = i_addi | i_andi | i_ori | i_xori | i_lui | i_lw | i_sw;

    // 立即数符号扩展
    assign sext = i_addi | i_lw | i_sw | i_beq | i_bne;

    // 写存储器
    assign wmem = i_sw;

    // aluc[3:0] 
    // x000  ADD
    // x100  SUB
    // x001  AND
    // x101  OR
    // x010  XOR
    // x110  LUI
    // 0011  SLL
    // 0111  SRL
    // 1111  SRA
    assign aluc[3] = i_sra;
    assign aluc[2] = i_sub | i_or | i_srl | i_sra | i_ori | i_lui;
    assign aluc[1] = i_xor | i_sll | i_srl | i_sra | i_xori | i_beq | i_bne | i_lui;
    assign aluc[0] = i_and | i_or | i_sll | i_srl | i_sra | i_andi | i_ori;

    // pcsource[1:0]
    // 00 PC + 4        下一条指令
    // 01 转移地址       bne beq 在 PC + 4 的基础上增加
    // 10 寄存器内的地址  jr
    // 11 跳转地址       j
    assign pcsource[1] = i_jr | i_j | jal;
    assign pcsource[0] = i_beq&z | i_bne&~z | i_j | i_jal;

endmodule
