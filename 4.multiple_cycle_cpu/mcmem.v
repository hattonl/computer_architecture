module mcmem(clk, dataout, datain, addr, we);
    input clk;
    input we;
    input [31:0] datain;
    input [31:0] addr;
    
    output [31:0] dataout;

    reg [31:0] ram[0:63];

    assign dataout = ram[addr[7:2]];

    integer i;

    always @ (posedge clk)
        if (we) ram[addr[7:2]] = datain;
    
    initial begin
        for (i = 0; i < 64; i = i + 1)
            ram[i] = 0;

        // ram[word_addr] = data
        ram[6'h0]  = 32'h3c010000;
        ram[6'h1]  = 32'h34240080;
        ram[6'h2]  = 32'h20050004;
        ram[6'h3]  = 32'h0c000018;
        ram[6'h4]  = 32'hac820000;
        ram[6'h5]  = 32'h8c890000;
        ram[6'h6]  = 32'h01244022;
        ram[6'h7]  = 32'h20050003;
        ram[6'h8]  = 32'h20a5ffff;
        ram[6'h9]  = 32'h34a8ffff;
        ram[6'ha]  = 32'h39085555;
        ram[6'hb]  = 32'h2009ffff;
        ram[6'hc]  = 32'h312affff;
        ram[6'hd]  = 32'h01493025;
        ram[6'he]  = 32'h01494026;
        ram[6'hf]  = 32'h01463824;
        ram[6'h10] = 32'h10a00001;
        ram[6'h11] = 32'h08000008;
        ram[6'h12] = 32'h2005ffff;
        ram[6'h13] = 32'h000543c0;
        ram[6'h14] = 32'h00084400;
        ram[6'h15] = 32'h00084403;
        ram[6'h16] = 32'h000843c2;
        ram[6'h17] = 32'h08000017;
        ram[6'h18] = 32'h00004020;
        ram[6'h19] = 32'h8c890000;
        ram[6'h1a] = 32'h20840004;
        ram[6'h1b] = 32'h01094020;
        ram[6'h1c] = 32'h20a5ffff;
        ram[6'h1d] = 32'h14a0fffb;
        ram[6'h1e] = 32'h00081000;
        ram[6'h1f] = 32'h03e00008;
        ram[6'h20] = 32'h000000a3;
        ram[6'h21] = 32'h00000027;
        ram[6'h22] = 32'h00000079;
        ram[6'h23] = 32'h00000115;
        ram[6'h24] = 32'h00000000;
    end

endmodule