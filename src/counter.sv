module counter #(parameter N = 32) (
    input logic ld, en_cnt, clk,
    output logic cnt_last
);
logic [$clog2(N)-1:0] cnt;
always_ff @( posedge clk ) begin
    if (ld) begin
        cnt <= '0;
    end else begin
        if (en_cnt) begin
            cnt <= cnt + 1'b1;
        end
    end
end

// combinatorio: vale 1 durante l'ultima iterazione, non dopo
assign cnt_last = (cnt == ($clog2(N))'(N-1));

endmodule
