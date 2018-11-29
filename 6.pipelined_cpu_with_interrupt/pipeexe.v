`include "mux2x32.v"
`include "alu.v"

// output
//  ern
//  ealu
module pipeexe (ealuc, ealuimm, ea, eb, eimm, eshift, ern0, epc4, ejal, ern,
                ealu);
    input [31:0] ea, eb, eimm, epc4;
    input [4:0]  ern0;
    input [3:0]  ealuc;
    input        ealuimm, eshift, ejal;

    output [31:0] ealu; // 如果是跳转指令则为pc+8的结果，否则是alu的计算结果。
    output [4:0]  ern; // 需要写入的寄存器号
    
    wire [31:0] alua, alub, sa, elau0, epc8;
    wire        z;

    assign      sa   = {eimm[5:0], eimm[31:6]};  // shift amount

    // cla32 ret_addr (epc4, 32'h4, 1'b0, epc8);
    assign      epc8 = epc4 + 32'h4; // 针对jal等延迟转移指令

    mux2x32 alu_ina (ea, sa, eshift, alua);
    mux2x32 alu_inb (eb, eimm, ealuimm, alub);
    mux2x32 save_pc8 (elau0, epc8, ejal, ealu);
    assign      ern = ern0 | {5{ejal}};  // ren0 要写入的寄存器编号 ？？？
    // 如果ejal为1则需要写入的寄存器为2'b11111, 即 31 号寄存器

    alu al_uint (alua, alub, ealuc, elau0, z);
endmodule