module add_sub #(parameter int N = 33) 
(
input  logic [N-1:0] a, b,
      input  logic         add_sub,
      output logic [N-1:0] s,
      output logic         cout
);

logic [N-1:0] xor_b;

for (genvar i = 0; i < N; i++) begin
assign xor_b[i] = b[i] ^ add_sub;
end

kogge_stone #(.N(N)) adder (.a(a),.b(xor_b),.cin(add_sub),.s(s), .cout(cout));
endmodule
