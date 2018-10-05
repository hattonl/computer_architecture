# 多周期CPU

The single-cycle CPU executes each instruction in one clock cycle regardless of the complexity of the instructions. The key design point of the multiple-cycle CPU is to divide the execution of an instruction into several small steps.Each step takes a short clock cycle. Then we can use more cycles to execute complex instructions and use fewer cycles to execute simple instructions. 



分为5个时钟周期：（我觉得这里又可以复习一下时钟周期，机器周期那部分的概念了）

最复杂的：lw 命令有5个周期

1. Instruction fetch (IF). 
2. Instruction decode and operand fetch (ID). 
3. Execution (EXE).  
4. Memory access (MEM). 
5. Write back (WB). 

The computational instructions take four cycles. 

The conditional instructions take three cycles. 

The jump instructions take two clock cycles. 



![屏幕快照 2018-09-29 上午11.43.06](/Users/hatton.liu/Desktop/屏幕快照 2018-09-29 上午11.43.06.png)



![屏幕快照 2018-10-03 上午11.18.51](/Users/hatton.liu/Desktop/屏幕快照 2018-10-03 上午11.18.51.png)





多周期CPU的设计原则：在每个周期结束时把本周期的结果保存在某个地方以便下一个周期使用。

### IF Stage

取指令周期IF。

做两件事：1. 取指令。2. PC + 4

功能：IR <-- Memory[PC]; PC<--PC+4; 

电路图：ppt 6p

### ID Stage 

指令译码周期ID。

做三件事：

1.根据寄存器号rs从寄存器堆中读出32位数据

2.根据寄存器号rt从寄存器堆中读出32位数据

3.ALU计算转移地址（将加过4个PC与指令中偏移量左移两位相加（符号扩展））（只为了beq和bne指令）



暂存：ABC



功能：PC <-- {PC[31:28],address,00}; (jump)

功能：RegisterFile[31] <-- PC; PC <-- {PC[31:28],address,00}; (jump and link)

功能：PC <-- RegisterFile[rs];  (jump)

功能：A <-- RegisterFile[rs]; B <-- RegisterFile[rt]; C <-- PC + sign_extend(offset) << 2; （others）

电路图：ppt 7p 8p 9p 10p

### EXE Stage

指令执行周期EXE。



功能1：beq: If (A == B) PC <-- C;  bne: If (A != B) PC <-- C;（branches）

对于beq和bne命令的执行。A和B是ID周期中，从寄存器组取出的32位数据。C是ID周期计算出的转移地址。

判断是否相等由ALU完成。

功能2：sll/srl/sra: C <-- A shift sa;（Shift ）（PPt上应该有误，书本上和图片上的显示都是B）

C <-- B shift sa;（Shift ）



功能3：add/sub/and/or/xor: C <-- A op B;（Register Calculation  ）



功能4：addi/andi/ori/xori/lw/sw: C <-- A op extend(immediate); （Immediate Calculation ）



功能5：lui: C <-- immediate << 16;  （Immediate Calculation ）

电路图：11p - 14p

### MEM Stage

存储器访问周期。

前提：在EXE周期，已经计算出了存储器地址，并放在了存储器C中。

功能：lw: DR <-- Memory[C];    sw: Memory[C] <-- B;

电路图：15p

### WB Stage

结果回写周期。

把ALU的计算结果或者从存储器取来的数据写入寄存器堆。

lw：RegisterFile[rt] <-- DR;

addi/andi/ori/xori/lui:   RegisterFile[rt] <-- c;

add/sub/and/or/xor/sll/srl/sra:   RegisterFile[rd] <-- C;



多周期CPU图

![屏幕快照 2018-09-29 上午11.55.20](/Users/hatton.liu/Desktop/屏幕快照 2018-09-29 上午11.55.20.png)



CPU控制单元中有限自动机的设计

![屏幕快照 2018-09-29 上午11.58.37](/Users/hatton.liu/Desktop/屏幕快照 2018-09-29 上午11.58.37.png)



![屏幕快照 2018-09-29 上午11.58.52](/Users/hatton.liu/Desktop/屏幕快照 2018-09-29 上午11.58.52.png)



![屏幕快照 2018-09-29 上午11.59.08](/Users/hatton.liu/Desktop/屏幕快照 2018-09-29 上午11.59.08.png)







CU代码解析

CPU复位时：State 默认周期为IF取指令周期

1.在取指令周期中

```verilog
wpc = 1; // write pc  写IP寄存器   将npc写入到pc中
wir = 1; // write IR  写IR寄存器   将frommem的值写入到inst寄存器中
alusrca = 1; // PC	  ALU a端的输入源置1   选择PC作为ALU a端的输入值
alusrcb = 2'h1; // 4  ALU b端的输入源也置1 选择立即数4作为ALU b端的输入值
next_state = sid; // next state: ID  选择下一个周期为ID取操作数周期
```

ALU默认做加法，next_pc的值默认选择alu输出的值，则此时ir寄存器中存放的是当前的指令inst，ip寄存器中存放的是pc+4。（IP寄存器复位后的默认值是0）



2.在ID周期中

取操作数周期

```verilog
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
```

如果是跳转指令j、jal、jr三者中的其中一个，则它们的运行周期在本周期结束后就已经已经全部进行完了，所以next_state = sif，重新进入取值周期。同时它们也会重新选择IP寄存器的值。

j 和 jal: 选择jpc，即 {pc[31:28], inst[25:0], 1'b0, 1'b0};

jr 选择，qa，即根据指令 inst[25:21] 从寄存器组中读出的值。

另外，jal指令还要把reg[31]的值设置为PC+4的值。所以，使能jal信号以及以及写寄存器信号wreg。

如果是其他指令，则 pc + offset？ 存入到regc中。（主要是针对beq和bne指令）

A和B也都要读入，但后面用到不用到就另说了。



3.在EXE周期中

```verilog
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
```

在EXE周期中，主要通过ALU进行运算。z=1表示结果为0，两个操作数相等。

首先根据指令，对alu计算的控制信号进行赋值。

（真的有这么强的并发性？）

对于beq或者bne跳转指令的话，如果满足条件则写pc，修改pc的值为regc，即在上一个周期中通过偏移量计算得的，如果不满足条件的话，就不写PC的值，这样的话下一条PC的值应该是PC+4（在IF周期中已经计算过了）。

对于lw和sw指令来说，ALU的b端选择为immediate，即{imm, inst[15:0]}，相加后结果存为C。并标志下一个周期为MEM存储器周期。

如果是其他指令则根据具体指令来选择时候进行移位操作，ALU b端的操作数，以及是否进行符号扩展等。

4.在MEM周期中

存储器周期：只有lw和sw指令进入了存储器周期。

```verilog
iord = 1; // memory address = C
if (i_lw) begin
    next_state = swb; // next state: WB
end else begin // store
    wmem = 1; // write memory
    next_state = sif; // next state: IF
end
```

进入存储器周期，首先置位iord信号，表示访问存储器的地址选择regc。

如果是lw指令，则经过iord信号使能后，自动将memory中的信号读取到DR寄存器中。并进入到WB周期。

如果是sw指令，则还需要开启wmem写memory信号，由于tomem的值等于regb的值。而存储器的地址也被选择了regc的值，则memroy将被写入。sw指令周期全部结束，进入到取指令周期中。

5.寄存器回写周期

```verilog
if (i_lw) m2reg = 1; // select memory data
if (i_lw || i_addi || i_andi || i_ori || i_xori || i_lui)
    regrt = 1; // reg dest no: rt

wreg = 1; // write register file
next_state = sif; // next state: IF
```

根据指令，选择m2reg表示，写入reg的数据来自memory。

regrt = 1表示，写入的寄存器为reg[rt]。

指令周期全部执行完毕，进入到IF取指令周期。

