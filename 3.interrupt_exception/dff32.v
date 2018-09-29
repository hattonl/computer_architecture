module dff32 (d, clk, clrn, q);
    input [31:0] d;
    input clk, clrn;
    output [31:0] q;

    reg [31:0] q;
    initial
    begin
      q <= 0;
    end
    always @ (negedge clrn or posedge clk)
        if (clrn == 0) begin
          q <= 0;
        end else begin
          q <= d;
        end

endmodule
