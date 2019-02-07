/**
 * a,b 两个单精度浮点数
 * sub :1 a - b; sub :0 a + b
 * rm: 两个舍入控制码
 * s: 单精度浮点结果
 */
module fadder (a, b, sub, rm, s);
    input  [31:0] a,b; // fp inputs a and b
    input         sub; // 1: sub; 0: add
    input   [1:0] rm;  // round mode
    output [31:0] s; // fp  output 

    // 做减法需要使用绝对值大的减去绝对值小的
    // fp_large 表示绝对值大的
    // fp_small 表示绝对值小的
    wire        exchange = ({1'b0,b[30:0]} > {1'b0,a[30:0]});
    wire [31:0] fp_large = exchange? b : a;
    wire [31:0] fp_small = exchange? a : b;

    // 确定两个浮点数的隐藏位
    // 31 符号位
    // [30: 23] 指数部分
    // [22: 0] 尾数部分
    wire fp_large_hidden_bit = |fp_large[30:23];
    wire fp_small_hidden_bit = |fp_small[30:23];

    // large_frac24 和 small_frac24 是加入了隐藏位的两个尾数
    wire [23:0] large_frac24 = {fp_large_hidden_bit, fp_large[22:0]};
    wire [23:0] small_frac24 = {fp_small_hidden_bit, fp_small[22:0]};

    // 结果的阶码暂定为与绝对值大的相同
    wire [7:0] temp_exp = fp_large[30:23];

    // 确定最后的符号
    // 如果没有交换则说明a的绝对值大，无论加法还是减法，符号位与a相同 ... ok
    // 如果发生了交换则说明b的绝对值大，若是a+b则结果的符号位与b相同 ... 相同为加，不同为减
    // 若a-b，则计算结果的符号与b相反
    wire sign = exchange? sub^b[31] : a[31];

    // 确定真正的操作
    // 1：若  a, b 符号
    // 如果a,b 符号相反并且sub为0，则相减。
    // 如果a,b 符号相同并且sub为1，也相减 ... ok
    // 其他情况都是相加 ... 
    // ？？？？？？？？？？？？？？？？？？
    wire op_sub = sub ^ fp_large[31] ^ fp_small[31];

    // 确定两个浮点数是否为无穷大或者NaN
    wire fp_large_expo_is_ff = &fp_large[30:23]; // exp == 0xff
    wire fp_small_expo_is_ff = &fp_small[30:23];

    wire fp_large_frac_is_00 = ~|fp_large[22:0]; // frac == 0x0
    wire fp_small_frac_is_00 = ~|fp_small[22:0];

    wire fp_large_is_inf = fp_large_expo_is_ff & fp_large_frac_is_00;
    wire fp_small_is_inf = fp_small_expo_is_ff & fp_small_frac_is_00;
    wire fp_large_is_nan = fp_large_expo_is_ff &~fp_large_frac_is_00;
    wire fp_small_is_nan = fp_small_expo_is_ff &~fp_small_frac_is_00;


// 标志着需要进行特殊操作
    wire is_inf_nan = fp_large_is_inf | fp_small_is_inf |
                      fp_large_is_nan | fp_small_is_nan;
// diff

    // wire s_is_inf = fp_large_is_inf | fp_small_is_inf;

    // 表示结果为无穷大或者NaN
    // 如果有a, b 中有一个数是NaN则结果是NaN
    // 其他情况下也有可能是NaN，见课本257页
    wire s_is_nan = fp_large_is_nan | fp_small_is_nan | 
        ((sub ^ fp_small[31] ^ fp_large[31]) & fp_large_is_inf & fp_small_is_inf);

    // NaN的阶码为全1，只设置尾数部分，尾数部分设置为a和b中较大的那个尾数？？
    // 为什么要在只比较了24位并在尾数设置时设置了22+1位（开头的一位设置为了1）
    wire [22:0] nan_frac = ({1'b0,a[22:0]} > {1'b0,b[22:0]}) ?
                            {1'b1,a[21:0]} : {1'b1,b[21:0]};
    wire [22:0] inf_nan_frac = s_is_nan? nan_frac : 23'h0;

    // 对small_frac24右移并计算尾数的结果
    wire [7:0] exp_diff = fp_large[30:23] - fp_small[30:23];
    // small_den_only :1 表示绝对值小的数为非规格化数
    wire small_den_only = (fp_large[30:23] != 0) &
                             (fp_small[30:23] == 0);
    // 计算出要移位的位数
    wire [7:0] shift_amount = small_den_only? exp_diff - 8'h1 : exp_diff;、
    // 一个临时的50位容量
    wire [49:0] small_frac50 = (shift_amount >= 26)?
                               {26'h0,small_frac24} :
                               {small_frac24,26'h0} >> shift_amount;

    wire [26:0] small_frac27 = {small_frac50[49:24],|small_frac50[23:0]};
    wire [27:0] aligned_large_frac = {1'b0,large_frac24,3'b000};
    wire [27:0] aligned_small_frac = {1'b0,small_frac27};
    // 进行实际运算
    wire [27:0] cal_frac = op_sub? 
                    aligned_large_frac - aligned_small_frac :
                    aligned_large_frac + aligned_small_frac ;
    

    wire [26:0] f4,f3,f2,f1,f0;
    wire [4:0] zeros;
    // cal_frac共28位 前导0的个数最多可使用5位二进制进行表示
    // 一种二分法
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
    // 如果f1[26] == 0, zeroz[0] = 1, f0 = f1[25:0], 1b'0
    // 如果f1[26] == 1, zeros[0] = 0, f0 = f1; 
    // f0[26:0] 表示 cal_frac去掉前导零之后的值。

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
        ~rm[1] & rm[0] & (frac0[2] | frac0[1] | frac0[0]) & sign |
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
                5'b0_xx_x_1 : final_result = {8'hff,inf_nan_frac}; // nan
            default : final_result = {8'h00,23'h000000}; // 0
        endcase
    endfunction

endmodule