// 加减单元
// sub == 1 表示进行减法运算
// sub == 0 表示进行加法运算
module addsub32(a, b, sub, s);
    input [31:0] a, b;
    input sub;
    output [31:0] s;

    assign s = sub ? a - b : a + b;
endmodule
