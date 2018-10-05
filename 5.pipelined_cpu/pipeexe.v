module pipeexe (ealuc, ealuimm, ea, eb, eimm, eshift, ern0, epc4, ejal, ern,
                ealu);
    input [31:0] ea, eb, eimm, epc4;
    input [4:0]  ern0;
    input [3:0]  ealuc;
    input        ealuimm, eshift, ejal;

    output [31:0] ealu;
    output [4:0]  ern;
    
    wire [31:0] alua, alub, sa, elau0, epc8;
    wire        z;

    assign      sa   = {eimm[5:0], eimm[31:6]};  // shift amount

    // cla32 ret_addr (epc4, 32'h4, 1'b0, epc8);
    assign      epc8 = epc4 + 32'h4;

    mux2x32 alu_ina (ea, sa, eshift, alua);
    mux2x32 alu_inb (eb, eimm, ealuimm, alub);
    mux2x32 save_pc8 (elau0, epc8, ejal, ealu);
    assign      ern = ern0 | {5{ejal}};
    alu al_uint (alua, alub, ealuc, elau0, z);
endmodule