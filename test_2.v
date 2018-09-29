`timescale 1 ns / 1 ps

module test(
    input in,
    output out
);
assign out = ~in;
endmodule

module simu(
);
// testbench 时钟信号
initial
begin
  $dumpfile("test.vcd");
  $dumpvars(0,simu);
end

reg clk = 0;
always #10 clk <= ~clk;
// 输出信号
wire out;
// 调用test模块
test mytest(clk, out);
endmodule
