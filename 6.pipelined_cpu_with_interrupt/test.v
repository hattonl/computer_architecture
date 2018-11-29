`timescale 1 ns / 1 ns
`include "pipelinedcpu.v"

module simu();
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, simu);
        #4 clrn = 1;
    end
    
    reg clrn = 0;
    reg clk = 1;

    always #2 clk <= ~clk;
    wire  [31: 0] pc, inst, ealu, malu, walu;
    
    pipelinedcpu mytest (clk, clrn, pc, inst, ealu, malu, walu);

endmodule
