module pipeimem (a, inst);
    input [31:0] a;
    output [31:0] inst;
    wire [31:0] rom [0:63];

    assign rom[6'h00] = 32'h3c010000;
    assign rom[6'h01] = 32'h34240050;
    assign rom[6'h02] = 32'h0c00001b;  // (08) call:
    assign rom[6'h03] = 32'h20050004;  // (0c) dslot1: addi $5, $0,  4
    assign rom[6'h04] = 32'hac820000;  // (10) return: sw   $2, 0($4)
    assign rom[6'h05] = 32'h8c890000;  // (14)
    assign rom[6'h06] = 32'h01244022;  // (18)
    assign rom[6'h07] = 32'h20050003;  // (1c)
    assign rom[6'h08] = 32'h20a5ffff;
    assign rom[6'h09] = 32'h34a8ffff;
    assign rom[6'h0a] = 32'h39085555;
    assign rom[6'h0b] = 32'h2009ffff;
    assign rom[6'h0c] = 32'h312affff;
    assign rom[6'h0d] = 32'h01493025;
    assign rom[6'h0e] = 32'h01494026;
    assign rom[6'h0f] = 32'h01463824;
    assign rom[6'h10] = 32'h10a00003; // (40) beq $5, $0, shift 
    assign rom[6'h11] = 32'h00000000; // (44) dslot2: nop
    assign rom[6'h12] = 32'h08000008; // (48) j loop2
    assign rom[6'h13] = 32'h00000000; // (4c) dslot3: nop
    assign rom[6'h14] = 32'h2005ffff;
    assign rom[6'h15] = 32'h000543c0;
    assign rom[6'h16] = 32'h00084400;
    assign rom[6'h17] = 32'h00084403;  // (5c)
    assign rom[6'h18] = 32'h000843c2;  // (60)
    assign rom[6'h19] = 32'h08000019;  // (64) finish: j    finish
    assign rom[6'h1a] = 32'h00000000;  // (68) dslot4: nop
    assign rom[6'h1b] = 32'h00004020;  // (6c) sum:    add  $8, $0, $0
    assign rom[6'h1c] = 32'h8c890000;  // (70) loop:   lw   $9, 0($4)
    assign rom[6'h1d] = 32'h01094020;
    assign rom[6'h1e] = 32'h20a5ffff;
    assign rom[6'h1f] = 32'h14a0fffc;
    assign rom[6'h20] = 32'h20840004;
    assign rom[6'h21] = 32'h03e00008;
    assign rom[6'h22] = 32'h00081000;
    assign inst = rom[a[7:2]];
endmodule