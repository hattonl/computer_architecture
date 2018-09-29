// 计算单元
`include "mux4x32.v"

module alu (a,b,aluc,r,z);
    input [31:0] a, b;                                      // aluc[3:0]
    input [3:0]  aluc;                                      // 
    output [31:0] r;                                        // x000  ADD
    output z;                                               // x100  SUB
    wire [31:0] d_and = a & b;                              // x001  AND
    wire [31:0] d_or  = a | b;                              // x101  OR
    wire [31:0] d_xor = a ^ b;                              // x010  XOR
    wire [31:0] d_lui = {b[15:0],16'h0};                    // x110  LUI
    wire [31:0] d_and_or  = aluc[2]? d_or  : d_and;         // 0011  SLL
    wire [31:0] d_xor_lui = aluc[2]? d_lui : d_xor;         // 0111  SRL
    wire [31:0] d_as,d_sh;                                  // 1111  SRA

    // 加减法器，由aluc[2]来指示加减法。
    // d_as表示结果
    addsub32 as32 (a,b,aluc[2],d_as);

    // 移位器，进行移位运算
    shift shifter (b,a[4:0],aluc[2],aluc[3],d_sh);

    // 4路选择器，将几路结果进行选择输出
    mux4x32 select (d_as,d_and_or,d_xor_lui,d_sh,aluc[1:0],r);

    assign z = ~|r;
endmodule


module addsub32 (a,b,sub,s);
    input  [31:0] a,b;
    input         sub;
    output [31:0] s;
    assign s = sub ? a - b : a + b;
endmodule


module shift (d, sa, right, arith, sh);
    input [31:0] d; // data to be shifted
    input [4:0] sa; // shift amount
    input right;    // right or left
    input arith;    // arithmetic or logic
    output [31:0] sh;
    reg [31:0] sh;

    always @ * begin    
      if (!right) sh = d << sa;
      else if (!arith) sh = d >> sa;
      else sh = $signed(d) >>> sa;
    end
endmodule
