module fa_structural (a, b, ci, s, co);
    input a, b, ci;
    output s, co;

    wire ab, bc, ca;

    xor (s, a, b, ci);
    and (ab, a, b);
    and (bc, b, ci);
    and (ca, ci, a);
    or  (co, ab, bc, ca);

endmodule


module fa_dataflow(a, b, ci, s, co);
    input a, b, ci;
    output s, co;

    assign s = a^b^c;
    assign co = a^b | b&ci | ci&a;
endmodule

module fa_behavioral (a, b, ci, s, co);
    input a, b, ci;
    output s, co;

    assign {co, s} = a + b + ci;
endmodule
