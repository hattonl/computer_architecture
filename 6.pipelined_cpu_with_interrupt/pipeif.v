`include "pipeimem.v"

// input
//  pcsource
//  pc
//  bpc
//  rpc
//  jpc
// output
//  npc
//  pc4
//  ins

module pipeif (pcsource, pc, bpc, rpc, jpc, npc, pc4, ins);
    input [31:0] pc, bpc, rpc, jpc;
    input [1:0]  pcsource;
    output [31:0] npc, pc4, ins;

    mux4x32 next_pc (pc4, bpc, rpc, jpc, pcsource, npc);
    
    // cla32 pc_plus4 (pc, 32'h4, 1'b0, pc4);
    assign pc4 = pc + 32'h4;

    // 根据pc从指令寄存器取指令
    pipeimem inst_mem (pc, ins);
endmodule
