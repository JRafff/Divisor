module divisor #(parameter int N = 32) (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic [N-1:0] dividend,
    input  logic [N-1:0] divisor,
    output logic [N-1:0] quotient,
    output logic [N-1:0] remainder,
    output logic         done
);

typedef enum logic[2:0] {IDLE, LOAD, SUB, ADD, CORR, DONE} state_t;
state_t current_state, next_state;
// segnali di controllo (uscite della FSM)
logic ld, en_r, en_z, en_cnt, sel_sh, add_sub;
// segnali di stato (ingressi della FSM)
logic s_sign, cnt_last;

// fili del datapath
logic [N-1:0] d_q;        // registro D
logic [N:0]   rh_q;       // registro RH, N+1 bit con segno
logic [N-1:0] z_q;        // registro Z/Q
logic [N:0]   rh_sh;      // {RH[N-1:0], Z[N-1]} = 2*RH + z
logic [N:0]   a_op;       // ingresso A dell'add/sub
logic [N:0]   b_op;       // ingresso B dell'add/sub = {0, D}
logic [N:0]   s;          // uscita dell'add/sub
logic         q_bit;      // bit di quoziente = ~S[N]
logic [N-1:0] z_sh;       // {Z[N-2:0], q}
logic [N-1:0] z_d;        // ingresso del registro Z
logic         z_en;       // enable del registro Z

// reg D
register #(.N(N)) u_d (
    .clk(clk), .ld(1'b0), .en_reg(ld),
    .D(divisor), .Q(d_q)
);

// muxA
assign rh_sh = {rh_q[N-1:0], z_q[N-1]};

mux21 #(.N(N+1)) u_mux_a (
    .a(rh_q), .b(rh_sh), .sel(sel_sh),
    .c(a_op)
);

// add_sub
assign b_op = {1'b0, d_q};

add_sub #(.N(N+1)) u_addsub (
    .a(a_op), .b(b_op), .add_sub(add_sub),
    .s(s), .cout()
);

assign s_sign = s[N];
assign q_bit  = ~s[N];

// reg R high
register #(.N(N+1)) u_rh (
    .clk(clk), .ld(ld), .en_reg(en_r),
    .D(s), .Q(rh_q)
);

// reg Z and Q (R low)
assign z_sh = {z_q[N-2:0], q_bit};
assign z_en = ld | en_z;

mux21 #(.N(N)) u_mux_z (
    .a(z_sh), .b(dividend), .sel(ld),
    .c(z_d)
);

register #(.N(N)) u_z (
    .clk(clk), .ld(1'b0), .en_reg(z_en),
    .D(z_d), .Q(z_q)
);

counter #(.N(N)) u_cnt (
    .clk(clk), .ld(ld), .en_cnt(en_cnt),
    .cnt_last(cnt_last)
);

assign quotient  = z_q;
assign remainder = rh_q[N-1:0];


// fsm
// in: start, s_sign, cnt_last
// out:   ld, en_r, en_z, en_cnt, sel_sh, add_sub, done
// states:    IDLE, LOAD, SUB, ADD, CORR, DONE 
always_ff @(posedge clk) begin
    if (rst_n == 1'b0) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// state updating
always_comb begin 
    case (current_state) 
IDLE : if (start) begin
    next_state  = LOAD;
end else begin 
    next_state = IDLE;
end
LOAD : next_state = SUB;
SUB : if  (s_sign == 1'b0) begin
    if (cnt_last) begin
    next_state  = DONE;
    end else begin
        next_state = SUB;
    end
end else begin 
    if (cnt_last) begin
    next_state  = CORR;
    end else begin
        next_state = ADD;
    end
end
ADD : if  (s_sign == 1'b0) begin
    if (cnt_last) begin
    next_state  = DONE;
    end else begin
        next_state = SUB;
    end
end else begin 
    if (cnt_last) begin
    next_state  = CORR;
    end else begin
        next_state = ADD;
    end
end
CORR : next_state = DONE;
DONE : next_state = IDLE;
default : next_state = IDLE;
    endcase
end

//output process
always_comb begin
// uscite:   ld, en_r, en_z, en_cnt, sel_sh, add_sub, done
ld = 1'b0;
en_r = 1'b0;
en_z = 1'b0;
en_cnt = 1'b0;
sel_sh = 1'b0;
add_sub = 1'b0;
done = 1'b0;
case (current_state)
IDLE : ;
LOAD : ld = 1'b1;
SUB : begin
    add_sub = 1'b1;
    sel_sh = 1'b1;
    en_r = 1'b1;
    en_z = 1'b1;
    en_cnt = 1'b1;
end
ADD : begin 
    add_sub = 1'b0;
    sel_sh = 1'b1;
    en_r = 1'b1;
    en_z = 1'b1;
    en_cnt = 1'b1;
end
CORR : begin
    add_sub = 1'b0;
    sel_sh = 1'b0;
    en_r = 1'b1;
end
DONE : done = 1'b1;
default: ;
endcase

end

endmodule
