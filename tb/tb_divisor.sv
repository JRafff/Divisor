module tb_divisor;

localparam int N = 8;

logic         clk;
logic         rst_n;
logic         start;
logic [N-1:0] dividend;
logic [N-1:0] divisor;
logic [N-1:0] quotient;
logic [N-1:0] remainder;
logic         done;

int errors = 0;

divisor #(.N(N)) dut (.*);

initial clk = 1'b0;
always #5 clk = ~clk;

// one division: drive the operands, wait for done, compare with the golden model
task automatic check(input int z, input int d);
    int q_ref, r_ref;
    int cycles = 0;

    // inputs change on the falling edge
    @(negedge clk);
    dividend = N'(z);
    divisor  = N'(d);
    start    = 1'b1;
    @(negedge clk);
    start = 1'b0;

    while (done !== 1'b1) begin
        @(negedge clk);
        cycles++;
        if (cycles > N + 4) begin
            $display("TIMEOUT  %0d / %0d", z, d);
            errors++;
            return;
        end
    end

    // golden model; division by zero gives Q = all ones, R = Z
    if (d == 0) begin
        q_ref = 2**N - 1;
        r_ref = z;
    end else begin
        q_ref = z / d;
        r_ref = z % d;
    end

    if (quotient !== N'(q_ref) || remainder !== N'(r_ref)) begin
        $display("ERROR    %3d / %3d : Q = %3d R = %3d, expected Q = %3d R = %3d",
                 z, d, quotient, remainder, q_ref, r_ref);
        errors++;
    end else begin
        $display("ok       %3d / %3d : Q = %3d R = %3d", z, d, quotient, remainder);
    end
endtask

initial begin
    rst_n    = 1'b0;
    start    = 1'b0;
    dividend = '0;
    divisor  = '0;
    repeat (2) @(negedge clk);
    rst_n = 1'b1;

    check(11, 4);      // example of the README, needs the correction
    check(173, 13);    // no correction
    check(100, 10);    // exact division
    check(7, 7);       // Z = D
    check(3, 5);       // Z < D
    check(0, 9);       // Z = 0
    check(200, 1);     // D = 1
    check(128, 3);     // MSB of Z set
    check(250, 7);
    check(255, 255);   // largest values
    check(255, 1);
    check(255, 2);
    check(1, 255);
    check(200, 0);     // division by zero
    check(0, 0);

    if (errors == 0) $display("PASS");
    else             $display("FAIL: %0d errors", errors);
    $finish;
end

endmodule
