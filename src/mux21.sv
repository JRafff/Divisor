module mux21 #(parameter N = 32) (
input logic [N-1 : 0] a,
input logic [N-1 : 0] b,
input logic sel,
output logic [N-1 : 0] c
);
assign c = sel ? b : a ;
endmodule
