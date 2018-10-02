`timescale 1 ns / 1 ns
`include "mccomp.v"

module simu();
// testbench 时钟信号
    // reg [31:0] pc;
    // wire [31:0] inst;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, simu);
        // pc = 32'h00;
        // intr = 0;
        #4 clrn = 1;
        // intr = 0;
    end
    
    reg clrn = 0;
    reg clk = 1;

    always #2 clk <= ~clk;
    // always #10 clrn <= ~clrn;
    // 输出信号
    // wire out;
    // 调用test模块
    wire  [31: 0] a, b, alu, adr, tom, fromm, pc, ir;
    wire  [2:0] q;

    // module mccomp (clock, resetn, q, a, b, alu, adr, tom, fromm, pc, ir, mem_clk);
    // input clock, resetn, mem_clk
    // output others
    mccomp mytest (clk, clrn, q, a, b, alu, adr, tom, fromm, pc, ir);

/*
    always @ (posedge clk) begin
      pc = pc + 4;
    end

    scinstmem test(pc, inst);
*/
endmodule
