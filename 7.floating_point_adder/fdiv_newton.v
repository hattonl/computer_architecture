module fdiv_newton (a, b, rm, fdiv, enable, clock, resetn,
                    s, busy, stall, count, reg_x);

    input [31:0]  a, b;   // fp a/b
    input [1:0]   rm;     // round mode
    input         fdiv;   // ID stage: i_fdiv
    input         emable, clock, resetn; // enable
    output [31:0] s;      // fp output
    output        busy;   // for generating stall
    output        stall;  // for pipeline stall
    output [4:0]  count;  // for iteration control
    output [25:0] reg_x;  // x_i

    parameter ZERO = 31'h00000000;
    parameter INF  = 31'h7f800000;
    parameter NaN  = 31'h7fc00000;
    parameter MAX  = 31'h7f7fffff;

    wire a_expo_is_00 = ~|a[30:23]; // a_expo = 00
    wire b_expo_is_00 = ~|b[30:23]; // b_expo = 00
    wire a_expo_is_ff =  &a[30:23]; // a_expo = ff
    wire b_expo_is_ff =  &b[30:23]; // b_expo = ff
    wire a_frac_is_00 = ~|a[22:0];  // a_frac = 00
    wire b_frac_is_00 = ~|b[22:0];  // b_frac = 00

    wire sign = a[31] ^ b[31];
    wire [9:0] exp_10 = {2'h0, a[30:23]} - {2'h0, b[30:23]} + 10'h7f;
    wire [23:0] a_temp24 = a_expo_is_00? {a[22:0], 1'b0}: {1'b1, a[22:0]};
    wire [23:0] b_temp24 = b_expo_is_00? {b[22:0], 1'b0}: {1'b1, b[22:0]};

    wire [23:0] a_frac24, b_frac24; // to 1xx...xxx for den
    wire [4:0]  shamt_a, shamt_b;   // how many bits shifted
    
    shift_to_msb_equ_1 shift_a (a_temp24, a_frac24, shamt_a);
    shift_to_msb_equ_1 shift_b (b_temp24, b_frac24, shamt_b);
    wire [9:0] exp10 = exp_10 - shamt_a + shamt_b;

    
    reg e1_sign, e1_ae00, e1_aeff, e1_af00, e1_be00, e1_beff, e1_bf00;
    reg e2_sign, e2_ae00, e2_aeff, e2_af00, e2_be00, e2_beff, e2_bf00;
    reg e3_sign, e3_ae00, e3_aeff, e3_af00, e3_be00, e3_beff, e3_bf00;

    reg [1:0] e1_rm, e2_rm, e3_rm;
    reg [9:0] e1_exp10, e2_exp10, e3_exp10;

    always @ (negedge resetn or posedge clock)
        if (resetn == 0) begin // pipeline registers
            // reg_e1       //reg_e2        // reg_e3
            e1_sign  <= 0;  e2_sign  <= 0;  e3_sign  <= 0;
            e1_rm    <= 0;  e2_rm    <= 0;  e3_rm    <= 0;
            e1_exp10 <= 0;  e2_exp10 <= 0;  e3_exp10 <= 0;
            e1_ae00  <= 0;  e2_ae00  <= 0;  e3_ae00  <= 0;
            e1_aeff  <= 0;  e2_aeff  <= 0;  e3_aeff  <= 0;
            e1_af00  <= 0;  e2_af00  <= 0;  e3_af00  <= 0;
            e1_be00  <= 0;  e2_be00  <= 0;  e3_be00  <= 0;
            e1_beff  <= 0;  e2_beff  <= 0;  e3_beff  <= 0;
            e1_bf00  <= 0;  e2_bf00  <= 0;  e3_bf00  <= 0;
        end else if (enable) begin
            e1_sign  <= sign;          e2_sign  <= e1_sign;  e3_sign  <= e2_sign;
            e1_rm    <=rm;             e2_rm    <= e1_rm;    e3_rm    <= e2_rm;
            e1_exp10 <= exp10;         e2_exp10 <= e1_exp10; e3_exp10 <= e2_exp10;
            e1_ae00  <= a_expo_is_00;  e2_ae00  <= e1_ae00;  e3_ae00  <= e2_ae00;
            e1_aeff  <= a_expo_is_ff;  e2_aeff  <= e1_aeff;  e3_aeff  <= e2_aeff;
            e1_af00  <= a_frac_is_00;  e2_af00  <= e1_af00;  e3_af00  <= e2_af00;
            e1_be00  <= b_expo_is_00;  e2_be00  <= e1_be00;  e3_be00  <= e2_be00;
            e1_beff  <= b_expo_is_ff;  e2_beff  <= e1_beff;  e3_beff  <= e2_beff;
            e1_bf00  <= b_frac_is_00;  e2_bf00  <= e1_bf00;  e3_bf00  <= e2_bf00;
        end

    newton24 frac_newton (a_frac24, b_frac24, fdiv, enable, clock, resetn,
                          q, busy, count, reg_x, stall);

    wire [31:0] q; // af24/bf24 = 1.xxxxx...x or 0.1xxx...x
    wire [31:0] z0 = q[31] ? q : {q[30:0], 1'b0}; // 1.xxxxx...x
    wire [9:0]  exp_adj = q[31] ? e3_exp10: e3_exp10 - 10'b1; // reg_e3

    reg [9:0]  exp0;
    reg [31:0] frac0;

    always @ * begin
        if (exp_adj[9]) begin // exp is negative
            exp0 = 0;
            if (z0[31]) // 1.xx...x exp_adj = minus
                frac0 = z0 >> (10'b1 - exp_adj); // den (-126)
            else
                frac0 = 0;
        end else if (exp_adj == 0) begin // exp is 0
            exp0 = 0;
            frac0 = {1'b0, z0[31:2], |z0[1:0]}; // den (-126)
        end else begin // exp > 0
            if (exp_adj > 254) begin // inf
                exp0 = 10'hff;
                frac0 = 0;
            end else begin // normal
                exp0 = exp_adj;
                frac0 = z0;
            end
        end
    end

    wire [26:0] frac = {frac0[31:6], |frac0[5:0]} // sticky
    wire frac_plus_1 = // reg_e3
        ~e3_rm[1] & ~e3_rm[0] & frac[3] &  frac[2] & ~frac[1] & ~frac[0] |
        ~e3_rm[1] & ~e3_rm[0] & frac[2] & (frac[1] | frac[0])  |
        ~e3_rm[1] &  e3_rm[0] & (frac[2] | frac[1] | frac[0]) & e3_sign |
         e3_rm[1] & ~e3_rm[0] & (frac[2] | frac[1] | frac[0]) & ~e3_sign;
    wire [24:0] frac_round = {1'b0, frac[26:3]} + frac_plus_1;
    wire [9:0]  exp1 = frac_round[24]? exp0+10'h1: exp0;
    wire        overflow = (exp1 >= 10'h0ff); // overflow

    wire [7:0]  exponent;
    wire [22:0] fraction;

    assign {exponent, fraction} = final_result(overflow, e3_rm, e3_sign, e3_ae00,
        e3_aeff, e3_af00, e3_be00, e3_beff, e3_bf00, {exp1[7:0], frac_round[22:0]});
    assign s = {e3_sign, exponent, fraction};

    function [30:0] final_result;
        input overflow;
        input [1:0] e3_rm;
        input e3_sign;
        input a_e00, a_eff, a_f00, b_e00, b_eff, b_f00;
        input [30:0] calc;

        casex ({overflow, e3_rm, e3_sign, a_e00, a_eff, a_f00, b_e00, b_eff, b_f00})
            10'b100x_xxx_xxx : final_result = INF;  // overflow
            10'b1010_xxx_xxx : final_result = MAX;  // overflow
            10'b1011_xxx_xxx : final_result = INF;  // overflow
            10'b1100_xxx_xxx : final_result = INF;  // overflow
            10'b1101_xxx_xxx : final_result = MAX;  // overflow

            10'b111x_xxx_xxx : final_result = MAX;  // overflow
            10'b0xxx_010_xxx : final_result = NaN;  // NaN / any
            10'b0xxx_011_010 : final_result = NaN;  // inf / NaN
            10'b0xxx_100_010 : final_result = NaN;  // den / NaN
            10'b0xxx_101_010 : final_result = NaN;  // 0 / NaN

            10'b0xxx_00x_010 : final_result = NaN;  // normal / NaN
            10'b0xxx_011_011 : final_result = NaN;  // inf / inf
            10'b0xxx_100_011 : final_result = ZERO; // den / inf
            10'b0xxx_101_011 : final_result = ZERO; // 0 / inf
            10'b0xxx_00x_011 : final_result = ZERO; // normal / inf

            10'b0xxx_011_101 : final_result = INF;  // inf / 0
            10'b0xxx_100_101 : final_result = INF;  // den / 0
            10'b0xxx_101_101 : final_result = NaN;  // 0 / 0
            10'b0xxx_00x_101 : final_result = INF;  // normal / 0
            10'b0xxx_011_100 : final_result = INF;  // inf / den

            10'b0xxx_100_100 : final_result = calc; // den / den
            10'b0xxx_101_100 : final_result = ZERO; // 0 / den
            10'b0xxx_00x_100 : final_result = calc; // normal / den
            10'b0xxx_011_00x : final_result = INF;  // inf / normal
            10'b0xxx_100_00x : final_result = calc; // den / normal

            10'b0xxx_101_00x : final_result = ZERO; // 0 / normal
            10'b0xxx_00x_00x : final_result = calc  // normal / normal
            default          : final_result = NaN;
        endcase   
    endfunction
endmodule


module shift_to_msb_equ_1 (a, b, shamt);
    input  [23:0] a;     // shift a = xx...x to b = 1x...x
    output [23:0] b;     // 1x...x
    output [4:0]  shamt; // how many bits shifted
    wire [23:0] a5, a4, a3, a2, a1, a0;
    assign a5 = a;
    assign shamt[4] = ~|a5[23:8];           // 16-bit 0
    assign a4 = shamt[4]? {a5[7:0], 16'b0}: a5;
    assign shamt[3] = ~|a4[23:16];          // 8-bit  0
    assign a3 = shamt[3]? {a4[15:0], 8'b0}: a4;
    assign shamt[2] = ~|a3[23:20];          // 4-bit  0
    assign a2 = shamt[2]? {a3[19:0], 4'b0}: a3;
    assign shamt[1] = ~|a2[23:22];          // 2-bit 0
    assign a1 = shamt[1]? {a2[21:0], 2'b0}: a2;
    assign shamt[0] = ~a1[23];              // 1-bit 0
    assign a0 = shamt[0]? {a1[22:0], 1'b0}: a1;
    assign b = a0;

endmodule


module newton24 (a, b, fdiv, enable, clock, resetn, q, busy, count, reg_x,
                stall);
    input [23:0] a; // dividend: fraction: .1xxx...x
    input [23:0] b; // divisor:  fraction: .1xxx.xxx
    input        fdiv;
    input        enable, clock, resetn;

    output [31:0] q;
    output        busy;
    output [4:0]  count;
    output [25:0] reg_x;
    output        stall;

    reg [31:0] q;
    reg [25:0] reg_x;
    reg [23:0] reg_a;
    reg [23:0] reg_b;
    reg [4:0]  count;
    reg        busy;

    wire [7:0] x0 = rom(b[22:19]);

    always @ (posedge clock or negedge resetn) begin
        if (resetn == 0) begin
            count <= 5'b0; // reset count
            busy  <= 1'b0; // reset to not busy
        end else begin      // not reset
            if (fdiv & (count == 0)) begin  // do once only
                count <= 5'b1;              // set count
                busy  <= 1'b1;              // set to busy
            end else begin  // execution: 3 iterations
                if (count == 5'h01) begin
                    reg_x <= {2'b1, x0, 16'b0}; // 01.xxx0...0
                    reg_a <= a;                 // .1xxxx...x
                    reg_b <= b;                 // .1xxxx...x
                end
                if (count != 0) count <= count + 5'b1; // count++
                if (count == 5'h0f) busy <= 0; // ready for next
                if (count == 5'h10) count <= 5'b0; // reset count
                if ((count == 5'h06) ||
                    (count == 5'h0b) ||
                    (count == 5'h10))
                        reg_x <= x52[50:25];        // xx.xxxxx...x
            end
        end
    end

    assign stall = fdiv & (count == 0) | busy;

    wire [49:0] bxi;
    wire [51:0] x52;
    wallace_tree26x24 bxxi(reg_x, reg_b, bxi);
    wire [25:0] b26 = ~bxi[48:23] + 1'b1;
    wallace_tree26x26 xipl (reg_x, b26, x52);

    wire [48:0] m_s;
    wire [41:0] m_c;

    wallace_tree24x26_mul wt (reg_a, reg_x, m_s[48:8], m_c, m_s[7:0]);

    reg [48:0] a_s;
    reg [41:0] a_c;

    always @ (negedge resetn or posedge clock)
        if (resetn == 0) begin
            a_s <= 0;
            a_c <= 0;
            q   <= 0;
        end else if (enable) begin
            a_s <= m_s;
            a_c <= m_c;
            q   <= e2p;
        end

    wire [49:0] d_x = {1'b0, a_s} + {a_c, 8'b0};
    wire [31:0] e2p = {d_x[48:18], |d_x[17:0]};

    function [7:0] rom;
        input [3:0] b;
        case (b)
            4'h0: rom = 8'hf0;  4'h1: rom = 8'hd4;
            4'h2: rom = 8'hba;  4'h3: rom = 8'ha4;
            4'h4: rom = 8'h8f;  4'h5: rom = 8'h7d;
            4'h6: rom = 8'h6c;  4'h7: rom = 8'h5c;
            4'h8: rom = 8'h4e;  4'h9: rom = 8'h41;
            4'ha: rom = 8'h35;  4'hb: rom = 8'h29;
            4'hc: rom = 8'h1f;  4'hd: rom = 8'h15;
            4'he: rom = 8'h0c;  4'hf: rom = 8'h04;
        endcase
    endfunction
endmodule

module wallace_tree26x24 (a, b, c);

endmodule

module wallace_tree26x26 (a, b, c);

endmodule

module wallace_tree24x26 (a, b, c);

endmodule
