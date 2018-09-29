// 器件描述
module alu1 (a,b,aluc,s);
    input [31:0] a,b;
    input [1:0] aluc;
    output [31:0] s;
    wire [31:0] d_and = a & b; // AND
    wire [31:0]d_or =a|b;//OR
    wire [31:0] d_ao,d_as; // 32-bit wires // invoke other modules:
    mux2x32  mx_ao (d_and,d_or,aluc[0],d_ao);
    addsub32 as    (a,b,aluc[0],d_as);
    mux2x32  mx_la (d_ao,d_as,aluc[1],s);
endmodule


// use function case
module alu2 (a,b,aluc,s);
    input [31:0] a,b;
    input [1:0] aluc;
    output [31:0] s;
    assign s = operate(a,b,aluc); // call function

    function [31:0] operate; // function
        input [31:0] x,y;
        input  [1:0] c;
        case (c)
            2’b00: operate = x & y;
            2’b01: operate = x | y;
            2’b10: operate = x + y;
            2’b11: operate = x - y; // or default: ...
        endcase
    endfunction
endmodule

// use function if-else
module alu3 (a,b,aluc,s);
    input [31:0] a,b;
    input [1:0] aluc;
    output [31:0] s;
    assign s = operate(a,b,aluc); // call function

    function [31:0] operate; // function
        input [31:0] x,y;
        input  [1:0] c;

        if      (c == 2’b00) operate = x & y; 
        else if (c == 2’b01) operate = x | y; 
        else if (c == 2’b10) operate = x + y; 
        else                 operate = x - y;
    endfunction
endmodule

// use always case
module alu4 (a,b,aluc,s);
    input  [31:0] a,b;
    input   [1:0] aluc;
    output [31:0] s;
    reg [31:0] s; // s will be a net (wire)
    always @ (a or b or aluc) begin // event
        case (aluc)
            2’b00: s = a & b;
            2’b01: s = a | b;
            2’b10: s = a + b;
            2’b11: s = a - b; // or default: ...
        endcase 
    end
endmodule


// use always if-else
module alu5 (a,b,aluc,s);
    input  [31:0] a,b;
    input   [1:0] aluc;
    output [31:0] s;
    reg [31:0] s; // s will be a net (wire) 
    always @ (a or b or aluc) begin // event
        if      (aluc == 2’b00) s = a & b;
        else if (aluc == 2’b01) s = a | b;
        else if (aluc == 2’b10) s = a + b;
        else                    s = a - b;
    end
endmodule

