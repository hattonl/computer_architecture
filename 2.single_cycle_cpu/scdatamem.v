module scdatamem (clk,dataout,datain,addr,we);
    input clk;
    input we;
    input [31:0] datain;
    input [31:0] addr;
    output [31:0] dataout;
    reg [31:0] ram[0:31];

    assign dataout = ram[addr[6:2]];

    always @ (posedge clk)
        if (we) ram[addr[6:2]] = datain;
    
    integer i;
    initial begin
      for (i = 0; i < 32; i = i + 1)
        ram[i] = 0;
        // ram[word_addr] = data
        ram[5'h14] = 32'h000000a3;
        ram[5'h15] = 32'h00000027;
        ram[5'h16] = 32'h00000079;
        ram[5'h17] = 32'h00000115;
        // ram[5'h18] should be 0x00000258, the sum stored by sw instruction
    end
endmodule
