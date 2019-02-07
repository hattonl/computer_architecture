// 8-bits 带符号乘法器

// 运行结果慢于 wallace-tree 

module mul_signed (a, b, z);
    input  [7:0]  a, b;
    output [15:0] z;

    // 经过综合之后产生了多路选择器
    wire [7:0] ab0 = b[0]? a: 8'b0;
    wire [7:0] ab1 = b[1]? a: 8'b0;
    wire [7:0] ab2 = b[2]? a: 8'b0;
    wire [7:0] ab3 = b[3]? a: 8'b0;
    wire [7:0] ab4 = b[4]? a: 8'b0;
    wire [7:0] ab5 = b[5]? a: 8'b0;
    wire [7:0] ab6 = b[6]? a: 8'b0;
    wire [7:0] ab7 = b[7]? a: 8'b0;

    assign z = (({8'b1, ~ab0[7],  ab0[6:0]}         +
                 {7'b0, ~ab1[7],  ab1[6:0], 1'b0})  +
                ({6'b0, ~ab2[7],  ab2[6:0], 2'b0}   +
                 {5'b0, ~ab3[7],  ab3[6:0], 3'b0})) +
               (({4'b0, ~ab4[7],  ab4[6:0], 4'b0}   +
                 {3'b0, ~ab5[7],  ab5[6:0], 5'b0})  +
                ({2'b0, ~ab6[7],  ab6[6:0], 6'b0}   +
                 {1'b0,  ab7[7], ~ab7[6:0], 7'b0}));

endmodule

module mul_signed_v2 (a, b, z);
    input  [7:0]  a, b;
    output [15:0] z;
    reg [7:0] a_bi [7:0];

    always @ * begin
        integer i, j;
        for (i = 0; i < 7; i = i + 1)
            for (j = 0; j < 7; j = j + 1)
                a_bi[i][j] = a[i] & b[j];
        
        for (i = 0; i < 7; i = i + 1)
            a_bi[i][7] = ~(a[i] & b[7]);
        
        for (j = 0; j < 7; j = j + 1)
            a_bi[7][j] = ~(a[7] & b[j]);
        
        a_bi[7][7] = a[7] & b[7];
    end

    assign z = (({8'b1, a_bi[0][7], a_bi[0][6:0]}         +
                 {7'b0, a_bi[1][7], a_bi[1][6:0], 1'b0})  +
                ({6'b0, a_bi[2][7], a_bi[2][6:0], 2'b0}   +
                 {5'b0, a_bi[3][7], a_bi[3][6:0], 3'b0})) +
               (({4'b0, a_bi[4][7], a_bi[4][6:0], 4'b0}   +
                 {3'b0, a_bi[5][7], a_bi[5][6:0], 5'b0})  +
                ({2'b0, a_bi[6][7], a_bi[6][6:0], 6'b0}   +
                 {1'b1, a_bi[7][7], a_bi[7][6:0], 7'b0}));

endmodule

