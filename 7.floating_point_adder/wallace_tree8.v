// unsigned 8*8

module wallace_tree8 (a, b, z);
    input [7:0]   a, b;
    output [15:0] z;

    reg [7:0] p[7:0];

    always @ * begin
        integer i, j;
        for (i = 0; i < 8; i = i + i)
            for (j = 0; j < 8; j = j + 1)
                p[i][j] = a[i] & b[j];
    end

    assign z[0] = p[0][0];

    parameter zero = 1'b0;

    wire [2:0] s1[12:01];
    wire [2:0] c1[13:02];

    // index 14: p[7][7]
    // index 13: p[7][6], p[6][7]
    
    add1 fa1_12_0 (p[7][5], p[6][6], p[5][7], s1[12][0], c1[13][0]);
    add1 fa1_11_0 (p[7][4], p[6][5], p[5][6], s1[11][0], c1[12][0]);

    // index 11: p[4][7]
    add1 fa1_10_1 (p[7][3], p[6][4], p[5][5], s1[10][1], c1[11][1]);
    add1 fa1_10_0 (p[4][6], p[3][7], zero,    s1[10][0], c1[11][0]);
    add1 fa1_09_1 (p[7][2], p[6][3], p[5][4], s1[9][1],  c1[10][1]);
    add1 fa1_09_0 (p[4][5], p[3][6], p[2][7], s1[9][0],  c1[10][0]);
    add1 fa1_08_1 (p[7][1], p[6][2], p[5][3], s1[8][1],  c1[9][1]);

    // index 08: p[1][7]
    add1 fa1_08_0 (p[4][4], p[3][5], p[2][6], s1[8][0],  c1[9][0]);
    add1 fa1_07_2 (p[7][0], p[6][1], p[5][2], s1[7][2],  c1[8][2]);
    add1 fa1_07_1 (p[4][3], p[3][4], p[2][5], s1[7][1],  c1[8][1]);
    add1 fa1_07_0 (p[1][6], p[0][7], zero,    s1[7][0],  c1[8][0]);
    add1 fa1_06_1 (p[6][0], p[5][1], p[4][2], s1[6][1],  c1[7][1]);

    // index 06: p[0][6]
    add1 fa1_06_0 (p[3][3], p[2][4], p[1][5], s1[6][0], c1[7][0]);
    add1 fa1_05_1 (p[5][0], p[4][1], p[3][2], s1[5][1], c1[6][1]);
    add1 fa1_05_0 (p[2][3], p[1][4], p[0][5], s1[5][0], c1[6][0]);
    add1 fa1_04_1 (p[4][0], p[3][1], p[2][2], s1[4][1], c1[5][1]);
    add1 fa1_04_0 (p[1][3], p[0][4], zero,    s1[4][0], c1[5][0]);
    add1 fa1_03_0 (p[3][0], p[2][1], p[1][2], s1[3][0], c1[4][0]);

    // index 03: p[0][3]
    add1 fa1_02_0 (p[2][0], p[1][1], p[0][2], s1[2][0], c1[3][0]);
    add1 fa1_01_0 (p[1][0], p[0][1], zero,    s1[1][0], c1[2][0]);

    assign z[1] = s1[1][0];


    wire [1:0] s2 [13: 2];
    wire [1:0] c2 [14: 3];

    // index 14:   p[7][7]
    add1 fa2_13_0 (p[7][6],   p[6][7],   c1[13][0], s2[13][0], c2[14][0]);
    add1 fa2_12_0 (s1[12][0], c1[12][0], zero,      s2[12][0], c2[13][0]);
    add1 fa2_11_0 (s1[11][0], p[4][7],   c1[11][0], s2[11][0], c2[12][0]);
    // index 11:   c1[11][0]
    add1 fa2_10_0 (s1[10][0], s1[10][0], c1[10][0], s2[10][0], c2[11][0]);
    // index 10:   c1[10][0]
    add1 fa2_09_0 (s1[9][1],  s1[9][0],  c1[9][1],  s2[9][0],  c2[10][0]);
    // index 09:   c1[09][0]
    add1 fa2_08_1 (s1[8][1],  s1[8][0],  p[1][7],   s2[8][1],  c2[9][1]);
    add1 fa2_08_0 (c1[8][2],  c1[8][1],  c1[8][0],  s2[8][0],  c2[9][0]);
    add1 fa2_07_1 (s1[7][2],  s1[7][1],  s1[7][0],  s2[7][1],  c2[8][1]);
    add1 fa2_07_0 (c1[7][1],  c1[7][0],  zero,      s2[7][0],  c2[8][0]);
    add1 fa2_06_1 (s1[6][1],  s1[6][0],  p[0][6],   s2[6][1],  c2[7][1]);
    add1 fa2_06_0 (c1[6][1],  c1[6][0],  zero,      s2[6][0],  c2[7][0]);
    add1 fa2_05_0 (s1[5][1],  s1[5][0],  c1[5][1],  s2[5][0],  c2[6][0]);
    // index 05:   c1[05][0]
    add1 fa2_04_0 (s1[4][1],  s1[4][0],  c1[4][0],  s2[4][0],  c2[5][0]);
    add1 fa2_03_0 (s1[3][0],  p[0][3],   c1[3][0],  s2[3][0],  c2[4][0]);
    add1 fa2_02_0 (s1[2][0],  c1[2][0],  zero,      s2[2][0],  c2[3][0]);
    
    assign z[2] = s2[2][0];


    wire [11: 3] s3;
    wire [12: 4] c3;
    // index 14: p[7][7],   c2[14][0]
    // index 13: s2[13][0], c2[13][0]
    // index 12: s2[12][0], c2[12][0]
    add1 fa3_11_0 (s2[11][0], c1[11][0], c2[11][0], s3[11], c3[12]);
    add1 fa3_10_0 (s2[10][0], c1[10][0], c2[10][0], s3[10], c3[11]);
    add1 fa3_09_0 (s2[9][0],  c1[9][0],  c2[9][1],  s3[9],  c3[10]);
    // index 09: c2[9][0]
    add1 fa3_08_0 (s2[8][1],  s2[8][0],  c2[8][0],  s3[8],  c3[9]);
    add1 fa3_07_0 (s2[7][1],  s2[7][0],  c2[7][1],  s3[7],  c3[8]);
    // index 07: c2[7][0]
    add1 fa3_06_0 (s2[6][1],  s2[6][0],  c2[6][0],  s3[6],  c3[7]);
    add1 fa3_05_0 (s2[5][0],  c1[5][0],  c2[5][0],  s3[5],  c3[6]);
    add1 fa3_04_0 (s2[4][0],  c2[4][0],  zero,      s3[4],  c3[5]);
    add1 fa3_03_0 (s2[3][0],  c2[3][0],  zero,      s3[3],  c3[4]);

    assign z[3] = s3[3];

    wire [14:4] s4;
    wire [15:5] c4;

    add1 fa4_14_0 (p[7][7],   c2[14][0], zero,   s4[14], c4[15]);
    add1 fa4_13_0 (s2[13][0], c2[13][0], zero,   s4[13], c4[14]);
    add1 fa4_12_0 (s2[12][0], c2[12][0], c3[12], s4[12], c4[13]);
    add1 fa4_11_0 (s3[11],    c3[11],    zero,   s4[11], c4[12]);
    add1 fa4_10_0 (s3[10],    c3[10],    zero,   s4[10], c4[11]);
    add1 fa4_09_0 (s3[9],     c2[9][0],  c3[9],  s4[9],  c4[10]);
    add1 fa4_08_0 (s3[8],     c2[8][0],  c3[8],  s4[8],  c4[9]);
    add1 fa4_07_0 (s3[7],     c2[7][0],  c3[7],  s4[7],  c4[8]);
    add1 fa4_06_0 (s3[6],     c3[6],     zero,   s4[6],  c4[7]);
    add1 fa4_05_0 (s3[5],     c3[5],     zero,   s4[5],  c4[6]);
    add1 fa4_04_0 (s3[4],     c3[4],     zero,   s4[4],  c4[5]);

    assign z[4] = s4[4];
    assign z[15:5] = {1b'0, s4[14:5]} + c4[15:5]; // 进位传播加法器

endmodule


module add1 (a, b, ci, s, co);
    input a,b,ci;
    output s,co;
    assign {co,s} = a + b + ci;
endmodule
