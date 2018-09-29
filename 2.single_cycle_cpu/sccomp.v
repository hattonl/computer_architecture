// 顶层模块图，单周期CPU
// 输入信号只有两个时钟clk和clrn，或者说一个时钟
// 由这个时钟来驱动整个计算机的运行
`include "sccpu.v"
`include "scinstmem.v"
`include "scdatamem.v"

module sccomp (clk,clrn,inst,pc,aluout,memout);
    input         clk, clrn;
    output [31:0] pc;
    output [31:0] inst;
    output [31:0] aluout;
    output [31:0] memout;
    wire   [31:0] data;
    wire          wmem;

    // 单周期CPU模块
    // 输入：inst, memout, clk, clrn
    // 输入取出的指令 以及 取出的数据
    // 输出：pc, aluout, data, wmem
    // 下一条PC的地址，计算结果（如果需要操作mem则为地址否则没用），要写入mem的data
    sccpu cpu (clk,clrn,inst,memout,pc,wmem,aluout,data);
    // instruction memory 指令存储器模块
    // 输入：pc  pc为地址
    // 输出：inst  取出的指令
    scinstmem imem (pc,inst);
    // data memory 数据存储器模块
    // 输入：clk, wmem, data, aluout
    // 如果需要写入 wmem时，aluout 作为写入的地址
    // wmem 写存储器使能
    // data 要写入的值
    // 输出：memout
    // 写入和读取都使用一个地址
    scdatamem dmem (clk,memout,data,aluout,wmem);
endmodule
