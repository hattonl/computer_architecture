module pipelined_fadder (a, b, sub, rm, s, clock, clrn, e);
    input [31:0] a, b;
    input        sub;
    input        e;  // enable
    input [1:0]  rm;
    input        clock, clrn;
    
    output [31:0] s;

    // alignment stage:
    wire [1:0]  a_rm;
    wire        a_is_inf_nan;
    wire [22:0] a_inf_nan_frac;
    wire        a_sign;
    wire [7:0]  a_exp;
    wire        a_op_sub;
    wire [23:0] a_large_frac;
    wire [26:0] a_small_frac;

    // a,b,sub input
    // others output
    fadd_align alignment(a, b, sub, a_is_inf_nan, a_inf_nan_frac, a_sign,
                a_exp, a_op_sub, a_large_frac, a_small_frac);

    // pipelined registers between alignment and calculation:
    wire [1:0] c_rm;
    wire       c_is_inf_nan;
    wire [22:0] c_inf_nan_frac;
    wire        c_sign;
    wire [7:0] c_exp;
    wire        c_op_sub;
    wire [23:0] c_large_frac;
    wire [26:0] c_small_frac;

    reg_align_cal reg_ac (rm, a_is_inf_nan, a_inf_nan_frac, a_sign, a_exp,
                         a_op_sub, a_large_frac, a_small_frac, clock, clrn,
                         e, c_rm, c_is_inf_nan, c_inf_nan_frac, c_sign,
                         c_exp, c_op_sub, c_large_frac, c_small_frac);
    
    // calculation stage:
    wire [27:0] c_frac;
    fadd_cal calculation (c_op_sub, c_large_frac, c_small_frac, c_frac);

    // pipelined registers between calulation and normalization:
    wire [1:0]  n_rm;
    wire        n_is_inf_nan;
    wire [22:0] n_inf_nan_frac;
    wire        n_sign;
    wire [7:0]  n_exp;
    wire [27:0] n_frac;

    reg_cal_norm reg_cn (c_rm, c_is_inf_nan, c_inf_nan_frac, c_sign, c_exp,
                         c_frac, clock, clrn, e, n_rm, n_is_inf_nan,
                         n_inf_nan_frac, n_sign, n_exp, n_frac);

    // normalization stage:
    fadd_norm normalization (n_rm, n_is_inf_nan, n_inf_nan_frac,
                             n_sign, n_exp, n_frac, s);

endmodule


module fadd_align (a, b, sub,
        is_inf_nan, inf_nan_frac, sign, temp_exp, op_sub, large_frac24, small_frac27);

    input [31:0] a, b;
    input        sub;

    output        is_inf_nan;
    output [22:0] inf_nan_frac;
    output        sign;
    output [7:0]  temp_exp;
    output [23:0] large_frac24;
    output [26:0] small_frac27;


    wire        exchange = ({1'b0, b[30:0]} > {1'b0, a[30:0]});
    wire [31:0] fp_large = exchange? b : a;
    wire [31:0] fp_small = exchange? a : b;

    wire fp_large_hidden_bit = |fp_large[30:23];
    wire fp_small_hidden_bit = |fp_small[30:23];

    // wire to assign (diff with book)
    wire [23:0] large_frac24 = {fp_large_hidden_bit, fp_large[22:0]};
    wire [23:0] small_frac24 = {fp_small_hidden_bit, fp_small[22:0]};

    // wire to assign
    assign temp_exp = fp_large[30:23];
    assign sign = exchange? sub^b[31] : a[31];
    wire op_sub = sub ^ fp_large[31] ^ fp_small[31];

    wire fp_large_expo_is_ff = &fp_large[30:23]; // exp == 0xff
    wire fp_small_expo_is_ff = &fp_small[30:23];

    wire fp_large_frac_is_00 = ~|fp_large[22:0]; // frac == 0x0
    wire fp_small_frac_is_00 = ~|fp_small[22:0];

    wire fp_large_is_inf = fp_large_expo_is_ff & fp_large_frac_is_00;
    wire fp_small_is_inf = fp_small_expo_is_ff & fp_small_frac_is_00;
    wire fp_large_is_nan = fp_large_expo_is_ff &~fp_large_frac_is_00;
    wire fp_small_is_nan = fp_small_expo_is_ff &~fp_small_frac_is_00;

    // wire to assign
    assign is_inf_nan = fp_large_is_inf | fp_small_is_inf |
                      fp_large_is_nan | fp_small_is_nan;

    wire s_is_nan =   fp_large_is_nan | fp_small_is_nan | 
        ((sub ^ fp_small[31] ^ fp_large[31]) & fp_large_is_inf & fp_small_is_inf);

    wire [22:0] nan_frac = ({1'b0, a[22:0]} > {1'b0, b[22:0]}) ?
                            {1'b1, a[21:0]} : {1'b1, b[21:0]};
    // wire to assign
    assign inf_nan_frac = s_is_nan? nan_frac : 23'h0;

    wire [7:0] exp_diff = fp_large[30:23] - fp_small[30:23];
    wire small_den_only = (fp_large[30:23] != 0) & (fp_small[30:23] == 0);
    wire [7:0] shift_amount = small_den_only? exp_diff - 8'h1 : exp_diff;

    wire [49:0] small_frac50 = (shift_amount >= 26)?
                               {26'h0,small_frac24} :
                               {small_frac24,26'h0} >> shift_amount;

    // wire to assign
    assign small_frac27 = {small_frac50[49:24],|small_frac50[23:0]};
    
endmodule

module reg_align_cal (a_rm, a_is_inf_nan, a_inf_nan_frac, a_sign, a_exp,
                      a_op_sub, a_large_frac, a_small_frac, clock, clrn,
                      e, c_rm, c_is_inf_nan, c_inf_nan_frac, c_sign,
                      c_exp, c_op_sub, c_large_frac, c_small_frac);
    input e;

    input [1:0]  a_rm;
    input        a_is_inf_nan;
    input [22:0] a_inf_nan_frac;
    input        a_sign;
    input [7:0]  a_exp;
    input        a_op_sub;
    input [23:0] a_large_frac;
    input [26:0] a_small_frac;
    
    input clock, clrn;

    output [1:0]  c_rm;
    output        c_is_inf_nan;
    output [22:0] c_inf_nan_frac;
    output        c_sign;
    output [7:0]  c_exp;
    output        c_op_sub;
    output [23:0] c_large_frac;
    output [26:0] c_small_frac;

    reg [1:0]  c_rm;
    reg        c_is_inf_nan;
    reg [22:0] c_inf_nan_frac;
    reg        c_sign;
    reg [7:0]  c_exp;
    reg        c_op_sub;
    reg [23:0] c_large_frac;
    reg [26:0] c_small_frac;

    always @ (posedge clock or negedge clrn) begin
        if (clrn == 0) begin
            c_rm           <= 0;
            c_is_inf_nan   <= 0;
            c_inf_nan_frac <= 0;
            c_sign         <= 0;
            c_exp          <= 0;
            c_op_sub       <= 0;
            c_large_frac   <= 0;
            c_small_frac   <= 0;
        end else if (e) begin
            c_rm           <= a_rm;
            c_is_inf_nan   <= a_is_inf_nan;
            c_inf_nan_frac <= a_inf_nan_frac;
            c_sign         <= a_sign;
            c_exp          <= a_exp;
            c_op_sub       <= a_op_sub;
            c_large_frac   <= a_large_frac;
            c_small_frac   <= a_small_frac;
        end
    end

endmodule

module fadd_cal (op_sub, large_frac24, small_frac27, cal_frac);
    input op_sub;
    input [23:0] large_frac24;
    input [26:0] small_frac27;

    output [27:0] cal_frac;
    wire   [27:0] aligned_large_frac = {1'b0, large_frac24, 3'b000};
    wire   [27:0] aligned_small_frac = {1'b0, small_frac27};

    assign cal_frac = op_sub? 
                      aligned_large_frac - aligned_small_frac;
                      aligned_large_frac + aligned_small_frac;

endmodule


module reg_cal_norm (c_rm, c_is_inf_nan, c_inf_nan_frac, c_sign, c_exp, c_frac, clock, clrn,
                     e, n_rm, n_is_inf_nan, n_inf_nan_frac, n_sign, n_exp, n_frac);
    input e;

    input [1:0]  c_rm;
    input        c_is_inf_nan;
    input [22:0] c_inf_nan_frac;
    input        c_sign;
    input [7:0]  c_exp;
    input [27:0] c_frac;

    input clock, clrn;

    output [1:0]  n_rm;
    output        n_is_inf_nan;
    output [22:0] n_inf_nan_frac;
    output        n_sign;
    output [7:0]  n_exp;
    output [27:0] n_frac;

    always @ (posedge clock or negedge clrn) begin
        if (clrn == 0) begin
            n_rm           <= 0;
            n_is_inf_nan   <= 0;
            n_inf_nan_frac <= 0;
            n_sign         <= 0;
            n_exp          <= 0;
            n_frac         <= 0;
        end else if (e) begin
            n_rm           <= c_rm;
            n_is_inf_nan   <= c_is_inf_nan;
            n_inf_nan_frac <= c_inf_nan_frac;
            n_sign         <= c_sign;
            n_exp          <= c_exp;
            n_frac         <= c_frac;
        end
    end
endmodule

module fadd_norm (rm, is_inf_nan, inf_nan_frac, sign, temp_exp, cal_frac, s);
    input [1:0]  rm;
    input        is_inf_nan;
    input [22:0] inf_nan_frac;
    input        sign;
    input [7:0]  temp_exp;
    input [27:0] cal_frac;
    output [31:0] s;

    wire [26:0] f4,f3,f2,f1,f0;
    wire [4:0]  zeros;
    assign zeros[4] = ~|cal_frac[26:11]; // 16-bit 0
    assign f4 = zeros[4]? {cal_frac[10:0],16'b0} : cal_frac[26:0];

    assign zeros[3] = ~|f4[26:19];      // 8-bit 0
    assign f3 = zeros[3]? {f4[18:0], 8'b0} : f4;

    assign zeros[2] = ~|f3[26:23];      // 4-bit 0
    assign f2 = zeros[2]? {f3[22:0], 4'b0} : f3;
    
    assign zeros[1] = ~|f2[26:25];      // 2-bit 0
    assign f1 = zeros[1]? {f2[24:0], 2'b0} : f2;

    assign zeros[0] = ~f1[26];          // 1-bit 0
    assign f0 = zeros[0]? {f1[25:0], 1'b0} : f1;
    reg [7:0] exp0;
    reg [26:0] frac0;

    always @ * begin
        if (cal_frac[27]) begin // 1x.xxxxxxxxxxxxxxxxxxxxxxx xxx
            // 直接向后移位，阶码加一
            frac0 = cal_frac[27:1]; // 1.xxxxxxxxxxxxxxxxxxxxxxx xxx
            exp0 = temp_exp + 8'h1;
        end else begin
            // f0[26] = 0 表示小数部分为0
            if ((temp_exp > zeros) && (f0[26])) begin // a normalized number
                exp0 = temp_exp - zeros;
                frac0 = f0; // 1.xxxxxxxxxxxxxxxxxxxxxxx xxx
            end else begin // is a denormalized number or 0
                exp0 = 0;  // 减完之后小数太小了就只能用0或者非规格化形式表示
                
                // 可以减一些，或者一些也不能减
                if (temp_exp != 0) // (e - 127) = ((e - 1) - 126)
                    frac0 = cal_frac[26:0] << (temp_exp - 8'h1);
                else frac0 = cal_frac[26:0];
            end
        end
    end
    // exp0 可能变成全1
    
    // 舍入的判断，进行进位或者不进位
    wire frac_plus_1 = // for rounding
        ~rm[1] & ~rm[0] & frac0[2] & (frac0[1] | frac0[0]) |
        ~rm[1] & ~rm[0] & frac0[2] & ~frac0[1] & ~frac0[0] & frac0[3] |
        ~rm[1] & rm[0]  & (frac0[2] | frac0[1] | frac0[0]) & sign |
         rm[1] & ~rm[0] & (frac0[2] | frac0[1] | frac0[0]) & ~sign;
    // frac0 27位 1 + 23 + 3
    wire [24:0] frac_round = {1'b0, frac0[26:3]} + frac_plus_1;

    // 如果进位之后尾数变成 10.00000...000 的形式，还需要重新进行调整阶码
    wire [7:0] exponent = frac_round[24]? exp0 + 8'h1 : exp0;
    wire overflow = &exp0 | &exponent;
    // 对上溢结果进行处理
    // 就近舍入：把上溢结果置成无穷大
    // 向0舍入：置成最大的规格化数
    // 向下舍入：把负数的上溢结果置成无穷大，把正数的上溢结果置成绝对值最大的正规格化数
    // 向上舍入：把正数的上溢结果置成无穷大，把负数的上溢结果置成绝对值最大的负规格化数

    wire [7:0]  final_exponent;
    wire [22:0] final_fraction;

    assign {final_exponent, final_fraction} = final_result(overflow, rm, 
        sign, is_inf_nan, exponent, frac_round[22:0], inf_nan_frac);
    
    assign s = {sign, final_exponent, final_fraction};

    function [30:0] final_result;
        input overflow;
        input [1:0] rm;
        input sign, is_inf_nan;
        input [7:0] exponent;
        input [22:0] fraction, inf_nan_frac;
        casex ({overflow, rm, sign, is_inf_nan})
                5'b1_00_x_x : final_result = {8'hff,23'h000000}; // inf
                5'b1_01_0_x : final_result = {8'hfe,23'h7fffff}; // max
                5'b1_01_1_x : final_result = {8'hff,23'h000000}; // inf
                5'b1_10_0_x : final_result = {8'hff,23'h000000}; // inf
                5'b1_10_1_x : final_result = {8'hfe,23'h7fffff}; // max
                5'b1_11_x_x : final_result = {8'hfe,23'h7fffff}; // max
                5'b0_xx_x_0 : final_result = {exponent,fraction}; // normal
                5'b0_xx_x_1 : final_result = {8'hff,inf_nan_frac}; // inf_nan
            default : final_result = {8'h00,23'h000000}; // 0
        endcase
    endfunction

endmodule
