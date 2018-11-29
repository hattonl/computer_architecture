`include "pipepc.v"
`include "pipeif.v"
`include "pipeir.v"
`include "pipeid.v"
`include "pipedereg.v"
`include "pipeexe.v"
`include "pipeemreg.v"
`include "pipemem.v"
`include "pipemwreg.v"
// `include "mux2x32.v"

// 和ppt上有两处不同
// ppt
// module pipelinedcpu (clk, clrn, pc, inst, ealu, malu, wdi);
module pipelined_cpu_exc_int (clock, resetn, pc, inst, ealu, malu, walu,
                                intr, inta);
// module pipelinedcpu (clock, memclock, resetn, pc, inst, ealu, malu, walu);
    // input clock, memclock, resetn;
    input clock, resetn, intr;
    output [31:0] pc, inst, ealu, malu, walu;
    output  inta;

    parameter EXC_BASE = 32'h00000008; // = base = BASE
    
    wire [31:0] bpc, jpc, npc, pc4, ins, dpc4, inst, da, db, dimm, ea, eb, eimm;
    wire [31:0] epc4, mb, mmo, wmo, wdi;
    wire [4:0]  drn, ern0, ern, mrn, wrn;
    wire [3:0]  daluc, ealuc; // daluc = aluc
    wire [1:0]  pcsource;
    wire        wpcir;
    wire        dwreg, dm2reg, dwmem, daluimm, dshift, djal;
    wire        ewreg, em2reg, ewmem, ealuimm, eshift, ejal;
    wire        mwreg, mm2reg, mwmem;
    wire        wwreg, wm2reg;

    // 提供第一条pc = 0
    // wpcir 被使能时，更新pc的值为npc
    pipepc prog_cnt (npc, wpcir, clock, resetn, pc);

    // 取指令到ins，计算pc4，选择npc
    // pc, bpc, da, jpc 从何而来？
    pipeif if_stage (pcsource, pc, bpc, da, jpc, npc, pc4, ins);

    // 寄存pc4 与 ins 指令
    // wpcir 被使能时，更新dpc4为pc4， 
    // wpcir 为0时，流水线暂停
    pipeir inst_reg (pc4, ins, wpcir, clock, resetn, dpc4, inst);

    // 
    pipeid id_stage (mwreg, mrn, ern, ewreg, em2reg, mm2reg, dpc4, inst,
                     wrn, wdi, ealu, malu, mmo, wwreg, clock, resetn, // 以上为输入信号，以下为输出信号
                     bpc, jpc, pcsource, wpcir, dwreg, dm2reg, dwmem,
                     daluc, daluimm, da, db, dimm, drn, dshift, djal);

    // ID阶段到EXE阶段的寄存器 一一对应
    pipedereg de_reg (dwreg, dm2reg, dwmem, daluc, daluimm, da, db, dimm,
                      drn,  dshift, djal, dpc4, clock, resetn,
                      ewreg, em2reg, ewmem, ealuc, ealuimm, ea, eb, eimm,
                      ern0, eshift, ejal, epc4);
    
    
    pipeexe exe_stage (ealuc, ealuimm, ea, eb, eimm, eshift, ern0, epc4,
                       ejal, ern, ealu);

    // 对除了clock, resetn 之外的信号全部寄存，一一对应
    pipeemreg em_reg (ewreg, em2reg, ewmem, ealu, eb, ern, clock, resetn,
                      mwreg, mm2reg, mwmem, malu, mb, mrn);

    // pipemem mem_stage (mwmem, malu, mb, clock, memclock, memclock, mmo);
    // ppt
    // eg: malu 是地址 mb是 datain
    // mmo: dataout
    // mb:  datain
    // addr: malu
    // mwmem: 写使能信号
    pipemem mem_stage (clock, mmo, mb, malu, mwmem);

    pipemwreg mw_reg (mwreg, mm2reg, mmo, malu, mrn, clock, resetn,
                      wwreg, wm2reg, wmo, walu, wrn);

    // 选择要写入的数据
    // wm2reg momery to register标志。
    // 如果执行lw命令则写入寄存器的数据来自wmo，否则来自walu
    mux2x32 wb_stage (walu, wmo, wm2reg, wdi);

endmodule
