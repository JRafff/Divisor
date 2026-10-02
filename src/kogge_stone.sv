module G_block (
input logic Gik,Pik,Gkj,
output logic Gij
);
assign Gij = Gik | (Pik & Gkj);
endmodule

module PG_block (
input logic Gik,Pik,Gkj,Pkj,
output logic Gij, Pij
);
assign Gij = Gik | (Pik & Gkj);
assign Pij = Pik & Pkj;
endmodule

module PG_network #(parameter int N = 32)(
input logic [N-1:0] a,b,
input logic cin,
output logic [N-1:0] p,g
);

   for (genvar  i = 0;i < N; i++) begin
    if (i==0) begin
        // bit 0 considero il cin
    assign p[i] = a[i] ^ b[i] ;
    assign g[i] = (a[i] & b[i]) | ((a[i] ^ b[i])& cin);
    end else begin
    //dal bit 1 in poi
    assign p[i] = a[i] ^ b[i] ;
    assign g[i] = (a[i] & b[i]) ;
    end
   end 
endmodule


module kogge_stone #(parameter int N = 32)
(
input  logic [N-1:0] a, b,
      input  logic         cin,
      output logic [N-1:0] s,
      output logic         cout
);
localparam int lev = $clog2(N);
logic [N-1:0] G [lev:0];
logic [N-1:0] P [lev:0];

PG_network #(.N(N)) network (.a(a), .b(b), .cin(cin), .p(P[0]), .g(G[0]));

   for (genvar  i = 0;i < lev; i++) begin : outer
    localparam int step = 2**i;
       for (genvar  j = 0;j < N; j++) begin : inner
        if (j-step < 0) begin
            //pass trough
            assign G[i+1][j] = G[i][j];
            assign P[i+1][j] = P[i][j];
        end else begin
            if (j-step == 0) begin
            //G
            G_block u_G (.Gik(G[i][j]), .Pik(P[i][j]), .Gkj(G[i][j-step]), .Gij(G[i+1][j]));
            // P non serve piu' (il gruppo arriva al bit 0), la passo solo per non lasciarla flottante
            assign P[i+1][j] = P[i][j];
            end else begin
            //PG
            PG_block u_PG (.Gik(G[i][j]), .Pik(P[i][j]), .Gkj(G[i][j-step]),.Pkj(P[i][j-step]), .Gij(G[i+1][j]), .Pij(P[i+1][j]));
            end
        end
       end : inner
   end : outer
   assign cout = G[lev][N-1];
   assign s[0] = P[0][0] ^ cin;
   assign s[N-1:1] = P[0][N-1:1] ^ G[lev][N-2:0];

endmodule
