// 32位2选一选择器
module mux2x32 (a0, a1, s, y);
    input [31:0] a0, a1;
    output s;
    output [31:0] y;

    assign y = s ? a1 : a0;

endmodule
