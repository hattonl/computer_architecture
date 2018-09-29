module dffe32 (d, clk, clrn, e, q);
    input  [31:0] d;
    input clk, clrn, e;
    output [31:0] q;
    reg [31:0] q; // real register type 
    always @ (posedge clk or negedge clrn) begin
    if (!clrn)  q <= 0;
        else if (e) q <= d;
    end
endmodule
