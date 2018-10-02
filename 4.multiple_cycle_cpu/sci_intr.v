module sci_intr (a,inst);  // instruction memory, rom
    input [31:0] a;         // address
    output [31:0] inst;     // instruction
    wire [31:0] rom [255:0]; // rom cells: 32 words * 32 bits
    // reg [7:0] mema[255:0] 这个例子定义了一个名为mema的存储器，该存储器有256个8位的存储器。
    // rom[word_addr] = instruction     
    assign rom[6'h00] = 32'h0800001d;
    assign rom[6'h01] = 32'h00000000;
    assign rom[6'h02] = 32'h401a6800;
    assign rom[6'h03] = 32'h335b000c;
    assign rom[6'h04] = 32'h8f7b0020;
    assign rom[6'h05] = 32'h00000000;
    assign rom[6'h06] = 32'h03600008;
    assign rom[6'h07] = 32'h00000000;

    assign rom[6'h0C] = 32'h00000000;
    assign rom[6'h0D] = 32'h42000018; 
    assign rom[6'h0E] = 32'h00000000;
    assign rom[6'h0F] = 32'h00000000; 
    assign rom[6'h10] = 32'h401a7000; 
    assign rom[6'h11] = 32'h235a0004; 
    assign rom[6'h12] = 32'h409a7000;
    assign rom[6'h13] = 32'h42000018; 
    assign rom[6'h14] = 32'h00000000; 
    assign rom[6'h15] = 32'h00000000; 
    assign rom[6'h16] = 32'h08000010; 
    assign rom[6'h17] = 32'h00000000; 

    assign rom[6'h1A] = 32'h00000000; 
    assign rom[6'h1B] = 32'h08000010; 
    assign rom[6'h1C] = 32'h00000000; 
    assign rom[6'h1D] = 32'h2008000f; 
    assign rom[6'h1E] = 32'h40886000;
    assign rom[6'h1F] = 32'h8c080048;
    // 之后都无法访问？？
    assign rom[6'h20] = 32'h8c09004C; 
    assign rom[6'h21] = 32'h01094020; 
    assign rom[6'h22] = 32'h00000000; 
    assign rom[6'h23] = 32'h0000000C; 
    assign rom[6'h24] = 32'h00000000; 
    assign rom[6'h25] = 32'h0128001a;
    assign rom[6'h26] = 32'h00000000;
    assign rom[6'h27] = 32'h34040050;
    assign rom[6'h28] = 32'h20050004;
    assign rom[6'h29] = 32'h00004020;
    assign rom[6'h2A] = 32'h8c890000;
    assign rom[6'h2B] = 32'h20840004;
    assign rom[6'h2C] = 32'h01094020;
    assign rom[6'h2D] = 32'h20a5ffff;
    assign rom[6'h2E] = 32'h14a0fffb;
    assign rom[6'h2F] = 32'h00000000;
    assign rom[6'h30] = 32'h08000030;

    assign inst = rom[a[7:2]];  // use word address to read rom
endmodule

/*
0: 0800001d;
1: 00000000;
2: 401a6800; 
3: 335b000c;
4: 8f7b0020; 
5: 00000000; 
6: 03600008; 
7: 00000000;


C: 00000000; 
d: 42000018; 
e: 00000000;
F: 00000000;

10:401a7000; 
11:235a0004; 
12:409a7000; 
13:42000018; 
14:00000000;
15:00000000;
16:08000010; 
17:00000000;

la:00000000; 
1b:08000010; 
1C:00000000;

1d:2008000f; 
1e:40886000; 
1f:8c080048; 
20:8c09004C;


21:01094020;
22:00000000;
23:0000000C; 
24:00000000;
25:0128001a; 
26:00000000;
27:34040050; 
28:20050004; 
29:00004020;
2a:8c890000; 
2b:20840004; 
2c:01094020; 
2d:20a5ffff; 
2e:14a0fffb; 
2f:00000000;
30:08000030;
*/