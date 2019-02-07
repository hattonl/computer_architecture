module fmul (a, b, rm, s);
    input  [31:0] a, b;
    input  [1:0]  rm;
    output [31:0] s;

    wire a_expo_is_00 = ~|a[30:23]; // exp = 00
    wire b_expo_is_00 = ~|b[30:23];
    wire a_expo_is_ff =  &a[30:23]; // xep = ff
    wire b_expo_is_ff =  &b[30:23];
    wire a_frac_is_00 = ~|a[22:0];  // frac = 0
    wire b_frac_is_00 = ~|b[22:0];

    wire a_is_inf = a_expo_is_ff &  a_frac_is_00;
    wire b_is_inf = b_expo_is_ff &  b_frac_is_00;
    wire a_is_nan = a_expo_is_ff & ~a_frac_is_00;
    wire b_is_nan = b_expo_is_ff & ~b_frac_is_00;

    wire a_is_0   = a_expo_is_00 &  a_frac_is_00;
    wire b_is_0   = b_expo_is_00 &  b_frac_is_00;

    wire is_inf_nan = a_is_inf | b_is_inf | a_is_nan | b_is_nan;
    wire s_is_nan = a_is_nan | (a_is_inf & b_is_0) |
                    b_is_nan | (b_is_inf & a_is_0);
    
    wire [22:0] nan_frac = ({1'b0, a[22:0]} > {1'b0, b[22:0]})?
                            {1'b1, a[21:0]} : {1'b1, b[21:0]};
    
    wire [22:0] inf_nan_frac = s_is_nan? nan_frac: 23'h0;

    wire       sign = a[31]^b[31];
    wire [9:0] exp10 = {2'h0, a[30:23]} + {2'h0, b[30:23]} - 10'h7f +
                        a_expo_is_00 + b_expo_is_00; // -126

    wire [23:0] a_frac24 = {~a_expo_is_00, a[22:0]};
    wire [23:0] b_frac24 = {~b_expo_is_00, b[22:0]};
    wire [47:0] z;
    wire [38:0] z_sum;
    wire [39:0] z_carry;

    wallace_tree24 wt24 (a_frac24, b_frac24, z_sum, z_carry, z[7:0]);
    assign z[47:8] = {1'b0, z_sum} + z_carry;

    wire [46:0] z5, z5, z3, z2, z1, z0;
    wire [5:0] zeros;
    
    assign zeros[5] = ~|z[46:15]; // 32-bit 0
    assign z5 = zeros[5]? {z[14:0], 32'b0}: z[46:0];

    assign zeros[4] = ~|z[46:31]; // 16-bit 0
    assign z4 = zeros[4]? {z[30:0], 16'b0}: z5;

    assign zeros[3] = ~|z[46:39]; // 8-bit 0
    assign z3 = zeros[3]? {z[38:0], 8'b0}: z4;

    assign zeros[2] = ~|z[46:43]; // 4-bit 0
    assign z2 = zeros[2]? {z[42:0], 4'b0}: z3;

    assign zeros[1] = ~|z[46:45]; // 2-bit 0
    assign z1 = zeros[1]? {z[44:0], 2'b0}: z2;

    assign zeros[0] = ~z1[46]; // 1-bit 0

    assign z0 = zeros[0]? {z1[45:0], 1'b0}: z1;

    reg [9:0]  exp0;
    reg [46:0] frac0;

    always @ * begin
        if (z[47]) begin
            exp0 = exp10 + 10'h1; // 1x.xxxx...xxxx xxx
            frac0 = z[47:1];
        end else begin
            if (!exp10[9] && (exp10[8:0] > zeros) && z0[46]) begin
                exp0 = exp10 - zeros; // 01.xxx....xxx xxx
                frac0 = z0; 
            end else begin
                exp0 = 0; // is a denormalized number or 0
                if (!exp10[9] && (exp10 != 0))
                     frac0 = z[46:0] << (exp10 - 10'h1);  // e-127 --> -126
                else frac0  = z[46:0] >> (10'h1 - exp10); // e = 0 or neg
            end
        end
    end

    wire [26:0] frac = {frac0[46:21], |frac0[20:0]};
    wire frac_plus_1 = 
        ~rm[1] & ~rm[0] & frac0[2] & (frac0[1] | frac0[0]) |
        ~rm[1] & ~rm[0] & frac0[2] & ~frac0[1] & ~frac0[0] & frac0[3] |
        ~rm[1] &  rm[0] & (frac0[2] | frac0[1] | frac0[0]) & sign |
         rm[1] & ~rm[0] & (frac0[2] | frac0[1] | frac0[0]) & ~sign;
    
    wire [24:0] frac_round = {1'b0, frac[26:3]} + frac_plus_1;
    wire [9:0]  exp1 = frac_round[24]? exp0 + 10'h1: exp0;
    wire        overflow = (exp0 >= 10'h0ff) | (exp1 >= 10'h0ff);

    wire [7:0]  final_exponent;
    wire [22:0] final_fraction;

    assign {final_exponent, final_fraction} = final_result(overflow, rm,
            sign, is_inf_nan, exp1[7:0], frac_round[22:0], inf_nan_frac);
    
    function [30:0] final_result;
        input overflow;
        input [1:0] rm;
        input sign, is_inf_nan;
        input [7:0] exponent;
        input [22:0] fraction, inf_nan_frac;

        casex ({overflow, rm, sign, is_inf_nan})
            5'b1_00_x_x : final_result = {8'hff, 23'h000000}; // inf
            5'b1_01_0_x : final_result = {8'hfe, 23'h7fffff}; // max
            5'b1_01_1_x : final_result = {8'hff, 23'h000000}; // inf
            5'b1_10_0_x : final_result = {8'hff, 23'h000000}; // inf
            5'b1_10_1_x : final_result = {8'hfe, 23'h7fffff}; // max
            5'b1_11_x_x : final_result = {8'hfe, 23'h7fffff}; // max
            5'b0_xx_x_0 : final_result = {exponent, fraction}; // normal
            5'b0_xx_x_1 : final_result = {8'hff, inf_nan_frac}; // inf_nan
            default     : final_result = {8'h00, 23'h000000}; // 0
        endcase
    endfunction

endmodule


// unimplements
/* 
    a_frac24 [23:0]
    b_frac24 [23:0]
    wire [38:0] z_sum;
    wire [39:0] z_carry;
    wire [27:0] z;
*/
module wallace_tree24(a_frac24, b_frac24, z_sum, z_carry, z[7:0])
    
endmodule

// assign z[47:8] = {1'b0, z_sum} + z_carry;
