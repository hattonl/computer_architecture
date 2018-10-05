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

// input and output

// input:
//  op
//  func
//  z
//  clock
//  resetn

// output:
//  wpc:  ip寄存器写使能信号
//  wir:  ir寄存器写是能信号
//  wmem: memory写使能信号
//  wreg: 寄存器组写使能信号
//  iord:   memory访问地址，区分访问数据还是取指令
//  regrt:  表示写入的寄存器号为reg[rt], 默认情况下为reg[rd]
//  m2reg:  表示写入寄存器的值来自memory
//  aluc:   ALU 运算的控制信号，进行加、减、与、异或
//  shift:  表示选择寄存器的指还是选择移位sa来作为opa的值
//  alusrca: ALU a端输入数据的选择
//  alusrcb: ALU b端输入的数据选择
//  pcsource: PC的信号选择
//  jal:  
//  sext: 是否进行符号位扩展，为1表示进行符号为扩展，为0表示不进行符号位的扩展
//  state: 表示当前所在的周期

module mccu (op, func, z, clock, resetn,
             wpc, wir, wmem, wreg, iord, regrt, m2reg, aluc,
            shift, alusrca, alusrcb, pcsource, jal, sext, state);

    input [5:0] op, func;
    input z, clock, resetn;
    output reg wpc, wir, wmem, wreg, iord, regrt, m2reg;
    output reg [3:0] aluc;
    output reg [1:0] alusrcb, pcsource;
    output reg       shift, alusrca, jal, sext;
    output reg [2:0] state;

    reg [2:0] next_state;

    parameter [2:0] sif  = 3'b000, // IF  state
                    sid  = 3'b001, // ID  state
                    sexe = 3'b010, // EXE state
                    smem = 3'b011, // MEM state
                    swb  = 3'b100; // WB  state

    wire r_type, i_add, i_sub, i_and, i_or, i_xor, i_sll, i_srl, i_sra, i_jr;
    wire i_addi, i_andi, i_ori, i_xori, i_lw, i_sw, i_beq, i_bne, i_lui, i_j, i_jal;

    and (r_type, ~op[5], ~op[4], ~op[3], ~op[2], ~op[1], ~op[0]);
    and (i_add, r_type,  func[5], ~func[4], ~func[3], ~func[2], ~func[1], ~func[0]);
    and (i_sub, r_type,  func[5], ~func[4], ~func[3], ~func[2],  func[1], ~func[0]);
    and (i_and, r_type,  func[5], ~func[4], ~func[3],  func[2], ~func[1], ~func[0]);
    and (i_or,  r_type,  func[5], ~func[4], ~func[3],  func[2], ~func[1],  func[0]);
    and (i_xor, r_type,  func[5], ~func[4], ~func[3],  func[2],  func[1], ~func[0]);
    and (i_sll, r_type, ~func[5], ~func[4], ~func[3], ~func[2], ~func[1], ~func[0]);
    and (i_srl, r_type, ~func[5], ~func[4], ~func[3], ~func[2],  func[1], ~func[0]);
    and (i_sra, r_type, ~func[5], ~func[4], ~func[3], ~func[2],  func[1],  func[0]);
    and (i_jr,  r_type, ~func[5], ~func[4],  func[3], ~func[2], ~func[1], ~func[0]);
    
    and (i_addi, ~op[5], ~op[4],  op[3], ~op[2], ~op[1], ~op[0]);
    and (i_andi, ~op[5], ~op[4],  op[3],  op[2], ~op[1], ~op[0]);
    and (i_ori,  ~op[5], ~op[4],  op[3],  op[2], ~op[1],  op[0]);
    and (i_xori, ~op[5], ~op[4],  op[3],  op[2],  op[1], ~op[0]);
    and (i_lw,    op[5], ~op[4], ~op[3], ~op[2],  op[1],  op[0]);
    and (i_sw,    op[5], ~op[4],  op[3], ~op[2],  op[1],  op[0]);
    and (i_beq,  ~op[5], ~op[4], ~op[3],  op[2], ~op[1], ~op[0]);
    and (i_bne,  ~op[5], ~op[4], ~op[3],  op[2], ~op[1],  op[0]);
    and (i_lui,  ~op[5], ~op[4],  op[3],  op[2],  op[1],  op[0]);
    and (i_j,    ~op[5], ~op[4], ~op[3], ~op[2],  op[1], ~op[0]);
    and (i_jal,  ~op[5], ~op[4], ~op[3], ~op[2],  op[1],  op[0]);

    wire i_shift; // 是否进行移位
    or (i_shift, i_sll, i_srl, i_sra);

    always @ * begin        // control signals' default outputs:
        wpc      = 0;       // do not wirte pc
        wir      = 0;       // do not wirte ir
        wmem     = 0;       // do not witre memory
        wreg     = 0;       // do not witre register file
        iord     = 0;       // select pc as memory address
        aluc     = 4'bx000; // ALU operation: add
        alusrca  = 0;       // ALU input a: reg a or sa
        alusrcb  = 2'h0;    // ALU input b: reg b
        regrt    = 0;       // reg dest no: rd
        m2reg    = 0;       // select reg c
        shift    = 0;       // select reg a
        pcsource = 2'h0;    // select alu output
        jal      = 0;       // not a jal
        sext     = 1;        // sign extend

        case (state)
            // ---- IF:
            sif: begin  // IF state
                wpc = 1; // write pc
                wir = 1; // write IR
                alusrca = 1; // PC
                alusrcb = 2'h1; // 4
                next_state = sid; // next state: ID
            end

            // ---- ID:
            sid: begin // ID state
                if (i_j) begin // j instruction
                    pcsource = 2'h3; // jump address
                    wpc = 1; // write PC
                    next_state = sif; // next state: IF
                end else if (i_jal) begin // jal instruction
                    pcsource = 2'h3; // jump address
                    wpc = 1;    // wirte PC
                    jal = 1; // reg no = 31
                    wreg = 1; // save PC + 4
                    next_state = sif; // next state: IF
                end else if (i_jr) begin // jr instruction
                    pcsource = 2'h2; // jump register
                    wpc = 1; // write PC
                    next_state = sif; // next state: IF
                end else begin // other instruction
                    aluc = 4'bx000; // add
                    alusrca = 1; // PC
                    alusrcb = 2'h3; //branch offset
                    next_state = sexe; // next state: EXE
                end
            end

            // ---- EXE:
            sexe: begin // EXE state
                aluc[3] = i_sra;
                aluc[2] = i_sub | i_or  | i_srl | i_sra | i_ori  | i_lui;
                aluc[1] = i_xor | i_sll | i_srl | i_sra | i_xori | i_beq |
                          i_bne | i_lui;
                aluc[0] = i_and | i_or  | i_sll | i_srl | i_sra  | i_andi |
                          i_ori;
                if (i_beq || i_bne) begin // beq or bne instruction
                    pcsource = 2'h1; // branch address
                    wpc = i_beq & z | i_bne & ~z; // write PC
                    next_state = sif; // next state: IF
                end else begin  // other instruction
                    if (i_lw || i_sw) begin // lw or sw instruction
                        alusrcb = 2'h2; // select offset
                        next_state = smem; // next state: MEM
                    end else begin
                        if (i_shift) shift = 1; // shift instruction
                        if (i_addi || i_andi || i_ori || i_xori || i_lui)
                            alusrcb = 2'h2; // select immediate
                        if (i_andi || i_ori || i_xori)
                            sext = 0; // 0-extend
                        
                        next_state = swb;
                    end
                end
            end

            // ---- MEM:
            smem: begin // MEM state
                iord = 1; // memory address = C
                if (i_lw) begin
                    next_state = swb; // next state: WB
                end else begin // store
                    wmem = 1; // write memory
                    next_state = sif; // next state: IF
                end
            end

            // ---- WB:
            swb: begin // WB state
                if (i_lw) m2reg = 1; // select memory data
                if (i_lw || i_addi || i_andi || i_ori || i_xori || i_lui)
                    regrt = 1; // reg dest no: rt

                wreg = 1; // write register file
                next_state = sif; // next state: IF
            end

            // ---- END

            default: begin
                next_state = sif; // default state
            end
        endcase
    end // end always

    always @ (posedge clock or negedge resetn) begin // state registers
        if (resetn == 0) begin
            state <= sif;
        end else begin
            state <= next_state;
        end
    end // end always

endmodule
