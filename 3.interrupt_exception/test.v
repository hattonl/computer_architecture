`timescale 1 ns / 1 ns
`include "sc_interrupt.v"

module simu();
// testbench 时钟信号
    // reg [31:0] pc;
    // wire [31:0] inst;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, simu);
        // pc = 32'h00;
        intr = 0;
        #20 clrn = 1;
        // intr = 0;
    end
    
    reg clrn = 0;
    reg clk = 1;
    reg [31:0] times = 0;
    always #10 clk <= ~clk;
    // always #10 clrn <= ~clrn;
    // 输出信号
    // wire out;
    // 调用test模块
    
    // 触发时间950ns - 970ns
    always begin
        #10 times = times + 10;
        if (times >= 950 && times <= 970)
            intr = 1;
        else
            intr = 0;
    end

    wire [31:0] pc;
    wire [31:0] inst;
    wire [31:0] mem;
    wire wmem;
    wire [31:0] aluout;
    wire [31:0] data;
    reg intr;
    wire inta;
    // module sc_interrupt (clk, clrn, inst, pc, aluout, memout, intr, inta);
    sc_interrupt mytest(clk, clrn, inst, pc, aluout, mem, intr, inta);

    
/*
    always @ (posedge clk) begin
      pc = pc + 4;
    end

    scinstmem test(pc, inst);
*/
endmodule
