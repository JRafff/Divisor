module register #(parameter N = 32) (
    input logic ld, en_reg, clk,
    input logic [N-1:0] D,
    output logic [N-1:0] Q
);
always_ff @( posedge clk ) begin
    if (ld) begin
        Q <= '0;
    end else begin
        if (en_reg) begin
            Q <= D;
        end
    end
end

endmodule
