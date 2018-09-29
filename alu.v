module alu (a, b, aluc, r, z);
    input [31: 0] a,b;
    input [3: 0] aluc;
    output [31: 0] r;
    output z;

    wire [31: 0] d_and = a & b;
    wire [31: 0] d_or  = a | b;
    wire [31: 0] d_xor = a ^ b;
    wire [31: 0] d_lui = {b[15:0], 16'h0};
    wire [31: 0] d_and_or = aluc[2]? d_or : d_and;
    wire [31: 0] d_xor_lui = aluc[2]? d_lui: d_xor;
    wire [31: 0] d_as, d_sh;
    addsub32 as32 (a, b, aluc[2], d_as);
    shift shifter (b, a[4:0], aluc[2], aluc[3], d_sh);
    mux4x32 select (d_as, d_and_or, d_xor_lui, d_sh, aluc[1:0], r); // ok
    assign z = ~|r;
endmodule

module addsub32 (a, b, sub, s);
    input [31: 0] a, b;
    input sub;
    output [31: 0] s;
    cla32 as32 (a, b^{32{sub}}, sub, s); // 第三章中设计
endmodule


// 32位四选一多路器
// s == 00， y = a0
// s == 01， y = a1
// s == 10,  y = a2
// s == 11,  y = a3
// 使用always语句或者嵌套的“？：”assign语句来实现
module mux4x32 (a0, a1, a2, a3, s, y);
    input [31:0] a0, a1, a2, a3;
    input [1:0] s;
    output [31:0] y;

    function [31:0] select;
        input [31:0] a0, a1, a2, a3;
        input [1:0] s;
        case (s)
            2'b00: select = a0;
            2'b01: select = a1;
            2'b10: select = a2;
            2'b11: select = a3;
    endfunction

    assign y = select(a0, a1, a2, a3, s);
endmodule


//移位
module shift (d, sa, right, arith, sh);
    input [31:0] d;
    input [4:0]  sa;
    input right, arith;
    output [31:0] sh;
    reg [31:0] sh;

    always @ * begin
      if (!right) begin
        sh = d << sa;
      end else if (!arith) begin
        sh = d >> sa;
      end else begin
        sh = $signed(d) >>> sa; //算术右移
      end
    end
// $signed和$unsigned()，用以将括号内的表达式转换为signed和unsigned数据类型。
// >>> 
endmodule
