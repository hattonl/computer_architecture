// 顶层模块图，带中断与异常处理的计算机
// 输入信号只有两个时钟clk和clrn，或者说一个时钟
// 由这个时钟来驱动整个计算机的运行
`include "mccpu.v"
`include "mcmem.v"

// intr
// inta
// sccpu_intr
// module mccomp (clk, clrn, inst, pc, aluout, memout, intr, inta);
// module sc_interrupt (clk, clrn,i nst, pc, aluout, memout, memclk, intr, inta);
module mccomp (clock, resetn, q, a, b, alu, adr, tom, fromm, pc, ir);
    input   clock, resetn;
    output  [31: 0] a, b, alu, adr, tom, fromm, pc, ir;
    output  [2:0] q;

    wire wmem;

    mccpu mc_cpu (clock, resetn, fromm, pc, ir, a, b, alu, wmem, adr, tom, q);
    mcmem memory (clock, fromm, tom, adr, wmem);
endmodule
