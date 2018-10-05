module pipedereg (dwreg, dm2reg, dwmem, daluc, daluimm, da, db, dimm, drn,
                 dshift, djal, dpc4, clk, clrn, ewreg, em2reg, ewmem,
                 ealuc, ealuimm, ea, eb, eimm, ern, eshift, ejal, epc4);
    input [31:0] da, db, dimm, dpc4;
    input [4:0]  drn;
    input        dwreg, dm2reg, dwmem, daluimm, dshift, djal;
    input        clk, clrn;
    
    output [31:0] ea, eb, eimm, epc4;
    output [4:0]  ern;
    output [3:0]  ealuc;
    output        ewreg, em2reg, ewmem, ealuimm, eshift, ejal;

    reg [31:0] ea, eb, eimm, epc4;
    reg [4:0]  ern;
    reg [3:0]  ealuc;
    reg        ewreg, em2reg, ewmem, ealuimm, eshift, ejal;

    always @ (negedge clrn or posedge clk)
        if (clrn == 0) begin
            ewreg   <= 0;   em2reg <= 0;
            ewmem   <= 0;   ealuc  <= 0;
            ealuimm <= 0;   ea     <= 0;
            eb      <= 0;   eimm   <= 0;
            ern     <= 0;   eshift <= 0;
            ejal    <= 0;   epc4   <= 0;
        end else begin
            ewreg   <= dwreg;       em2reg <= dm2reg;
            ewmem   <= dwmem;       ealuc  <= daluc;
            ealuimm <= daluimm;     ea     <= da;
            eb      <= db;          eimm   <= dimm;
            ern     <= drn;         eshift <= dshift;
            ejal    <= djal;        epc4   <= dpc4;
        end

endmodule
