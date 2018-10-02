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



IF Stage

功能：IR <-- Memory[PC]; PC<--PC+4; 

电路图：ppt 6p

ID Stage 

功能：PC <-- {PC[31:28],address,00}; (jump)

功能：RegisterFile[31] <-- PC; PC <-- {PC[31:28],address,00}; (jump and link)

功能：PC <-- RegisterFile[rs];  (jump)

功能：A <-- RegisterFile[rs]; B <-- RegisterFile[rt]; C <-- PC + sign_extend(offset) << 2; （others）

电路图：ppt 7p 8p 9p 10p

EXE Stage

功能：beq: If (A == B) PC <-- C;  bne: If (A != B) PC <-- C;（branches）

功能：sll/srl/sra: C <-- A shift sa;（Shift ）

功能：add/sub/and/or/xor: C <-- A op B;（Register Calculation  ）

功能：addi/andi/ori/xori/lw/sw: C <-- A op extend(immediate); （Immediate Calculation ）

功能：lui: C <-- immediate << 16;  （Immediate Calculation ）

电路图：11p - 14p

MEM Stage

功能：lw: DR <-- Memory[C];    sw: Memory[C] <-- B;

电路图：15p

WB Stage

lw：RegisterFile[rt] <-- DR;

addi/andi/ori/xori/lui:   RegisterFile[rt] <-- c;

add/sub/and/or/xor/sll/srl/sra:   RegisterFile[rd] <-- C;



多周期CPU图

![屏幕快照 2018-09-29 上午11.55.20](/Users/hatton.liu/Desktop/屏幕快照 2018-09-29 上午11.55.20.png)



CPU控制单元中有限自动机的设计

![屏幕快照 2018-09-29 上午11.58.37](/Users/hatton.liu/Desktop/屏幕快照 2018-09-29 上午11.58.37.png)



![屏幕快照 2018-09-29 上午11.58.52](/Users/hatton.liu/Desktop/屏幕快照 2018-09-29 上午11.58.52.png)



![屏幕快照 2018-09-29 上午11.59.08](/Users/hatton.liu/Desktop/屏幕快照 2018-09-29 上午11.59.08.png)













