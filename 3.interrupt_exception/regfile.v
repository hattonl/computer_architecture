module regfile (rna,rnb,d,wn,we,clk,clrn,qa,qb);
    input   [4:0] rna,rnb,wn;
    input  [31:0] d;
    input         we,clk,clrn;
    output [31:0] qa,qb;
    reg [31:0] register [1:31];  // $1 - $31

    assign qa = (rna == 0)? 0 : register[rna]; //read
    assign qb = (rnb == 0)? 0 : register[rnb]; // read

    integer i;
    always @ (posedge clk or negedge clrn) begin
      if (clrn == 0) begin
        for (i = 0; i < 32; i = i + 1)
            register[i] <= 0;
      end else begin
        if ((wn != 0) && (we == 1))
            register[wn] <= d;
      end
    end
endmodule

/*
    rna[4:0]: register number of read port A 
    rnb[4:0]: register number of read port B 
    qa[31:0]: data output of read port A 
    qb[31:0]: data output of read port B 
    wn[4:0]: register number of write port 
    d[31:0]: data input of write port
    we: write enable
*/

// 这个 regfile 可以一次读取两个寄存器，写一个寄存器？
// 写需要使能，读不需要使能。