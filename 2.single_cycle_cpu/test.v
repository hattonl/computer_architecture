`timescale 1 ns / 1 ns
`include "sccomp.v"

module simu();
// testbench 时钟信号
    // reg [31:0] pc;
    // wire [31:0] inst;

    initial
    begin
        $dumpfile("test.vcd");
        $dumpvars(0, simu);
        // pc = 32'h00;
        #20 clrn = 1;
    end
    reg clrn = 0;
    reg clk = 1;
    always #10 clk <= ~clk;
    // always #10 clrn <= ~clrn;
    // 输出信号
    // wire out;
    // 调用test模块

    wire [31:0] pc;
    wire [31:0] inst;
    wire [31:0] mem;
    wire wmem;
    wire [31:0] aluout;
    wire [31:0] data;
    sccomp mytest(clk, clrn, inst, pc, aluout, mem);

    
/*
    always @ (posedge clk) begin
      pc = pc + 4;
    end

    scinstmem test(pc, inst);
*/
endmodule
