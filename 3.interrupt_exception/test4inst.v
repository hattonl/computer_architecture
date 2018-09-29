`timescale 1 ns / 1 ns
`include "sc_interrupt.v"

module simu();
// testbench 时钟信号
    // reg [31:0] pc;
    // wire [31:0] inst;

    initial
    begin
        $dumpfile("test.vcd");
        $dumpvars(0, simu);
        // pc = 32'h00;
        // #20 clrn = 1;
        pc = 0;
    end
    // reg clrn = 0;
    // reg clk = 1;
    always #10 pc = pc + 4;
    // always #10 clrn <= ~clrn;
    // 输出信号
    // wire out;
    // 调用test模块

    reg [31:0] pc;
    wire [31:0] inst;
    
    // module sc_interrupt (clk, clrn, inst, pc, aluout, memout, intr, inta);
    sci_intr mytest(pc, inst);
    // module sci_intr (a,inst);
    
/*
    always @ (posedge clk) begin
      pc = pc + 4;
    end

    scinstmem test(pc, inst);
*/
endmodule
