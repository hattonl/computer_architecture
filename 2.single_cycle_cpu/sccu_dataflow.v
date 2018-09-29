module sccu_dataflow (op,func,z,wmem,wreg,regrt,m2reg,aluc,shift,aluimm,
                    pcsrc,jal,sext);
    input [5:0] op, func;
    input z;

    output [3:0] aluc;
    output [1:0] pcsrc;
    output wreg;
    output regrt;
    output m2reg;
    output shift;
    output aluimm;
    output jal;
    output sext;
    output wmem;

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
    assign wreg = i_add | i_sub | i_add | i_or | i_xor | i_sll |
                  i_srl | i_sra | i_addi | i_andi | i_ori | i_xori |
                  i_lui | i_lw | i_jal;

    // 目的寄存器时rt
    assign regrt = i_addi | i_andi | i_ori | i_xori | i_lui | i_lw;

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
    assign pcsrc[1] = i_jr | i_j | jal;
    assign pcsrc[0] = i_beq&z | i_bne&~z | i_j | i_jal;

endmodule
