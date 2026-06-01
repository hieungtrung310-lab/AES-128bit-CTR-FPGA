// 1. S-BOX Module
module s_box (
    input  logic [7:0] in,
    output logic [7:0] out 
);
    localparam logic [7:0] sbox[0:255] = '{
        8'h63,8'h7c,8'h77,8'h7b,8'hf2,8'h6b,8'h6f,8'hc5,8'h30,8'h01,8'h67,8'h2b,8'hfe,8'hd7,8'hab,8'h76,
        8'hca,8'h82,8'hc9,8'h7d,8'hfa,8'h59,8'h47,8'hf0,8'had,8'hd4,8'ha2,8'haf,8'h9c,8'ha4,8'h72,8'hc0,
        8'hb7,8'hfd,8'h93,8'h26,8'h36,8'h3f,8'hf7,8'hcc,8'h34,8'ha5,8'he5,8'hf1,8'h71,8'hd8,8'h31,8'h15,
        8'h04,8'hc7,8'h23,8'hc3,8'h18,8'h96,8'h05,8'h9a,8'h07,8'h12,8'h80,8'he2,8'heb,8'h27,8'hb2,8'h75,
        8'h09,8'h83,8'h2c,8'h1a,8'h1b,8'h6e,8'h5a,8'ha0,8'h52,8'h3b,8'hd6,8'hb3,8'h29,8'he3,8'h2f,8'h84,
        8'h53,8'hd1,8'h00,8'hed,8'h20,8'hfc,8'hb1,8'h5b,8'h6a,8'hcb,8'hbe,8'h39,8'h4a,8'h4c,8'h58,8'hcf,
        8'hd0,8'hef,8'haa,8'hfb,8'h43,8'h4d,8'h33,8'h85,8'h45,8'hf9,8'h02,8'h7f,8'h50,8'h3c,8'h9f,8'ha8,
        8'h51,8'ha3,8'h40,8'h8f,8'h92,8'h9d,8'h38,8'hf5,8'hbc,8'hb6,8'hda,8'h21,8'h10,8'hff,8'hf3,8'hd2,
        8'hcd,8'h0c,8'h13,8'hec,8'h5f,8'h97,8'h44,8'h17,8'hc4,8'ha7,8'h7e,8'h3d,8'h64,8'h5d,8'h19,8'h73,
        8'h60,8'h81,8'h4f,8'hdc,8'h22,8'h2a,8'h90,8'h88,8'h46,8'hee,8'hb8,8'h14,8'hde,8'h5e,8'h0b,8'hdb,
        8'he0,8'h32,8'h3a,8'h0a,8'h49,8'h06,8'h24,8'h5c,8'hc2,8'hd3,8'hac,8'h62,8'h91,8'h95,8'he4,8'h79,
        8'he7,8'hc8,8'h37,8'h6d,8'h8d,8'hd5,8'h4e,8'ha9,8'h6c,8'h56,8'hf4,8'hea,8'h65,8'h7a,8'hae,8'h08,
        8'hba,8'h78,8'h25,8'h2e,8'h1c,8'ha6,8'hb4,8'hc6,8'he8,8'hdd,8'h74,8'h1f,8'h4b,8'hbd,8'h8b,8'h8a,
        8'h70,8'h3e,8'hb5,8'h66,8'h48,8'h03,8'hf6,8'h0e,8'h61,8'h35,8'h57,8'hb9,8'h86,8'hc1,8'h1d,8'h9e,
        8'he1,8'hf8,8'h98,8'h11,8'h69,8'hd9,8'h8e,8'h94,8'h9b,8'h1e,8'h87,8'he9,8'hce,8'h55,8'h28,8'hdf,
        8'h8c,8'ha1,8'h89,8'h0d,8'hbf,8'he6,8'h42,8'h68,8'h41,8'h99,8'h2d,8'h0f,8'hb0,8'h54,8'hbb,8'h16
    };
    assign out = sbox[in];
endmodule

// 2. SubWord Module
module sub_word(
    input  logic [31:0] in,
    output logic [31:0] out
);
    s_box s0(.in(in[31:24]), .out(out[31:24]));
    s_box s1(.in(in[23:16]), .out(out[23:16]));
    s_box s2(.in(in[15:8]),  .out(out[15:8]));
    s_box s3(.in(in[7:0]),   .out(out[7:0]));
endmodule

// 3. H m g
module g_function(
    input  logic [31:0] w_in,     // T? w[i-1]
    input  logic [3:0]  i, 
    output logic [31:0] g     // K?t qu? sau h m g
);
    logic [31:0] rot_word;
    logic [31:0] sub_word_out;
    logic [31:0] rcon;

    // B?ng h?ng s? v ng Rcon
    always_comb begin
        case(i)
            4'd1: rcon = 32'h01000000; 4'd2: rcon = 32'h02000000;
            4'd3: rcon = 32'h04000000; 4'd4: rcon = 32'h08000000;
            4'd5: rcon = 32'h10000000; 4'd6: rcon = 32'h20000000;
            4'd7: rcon = 32'h40000000; 4'd8: rcon = 32'h80000000;
            4'd9: rcon = 32'h1b000000; 4'd10: rcon = 32'h36000000;
            default: rcon = 32'h00000000;
        endcase
    end

    // 1. RotWord: D?ch tr i v ng 1 byte
    assign rot_word = {w_in[23:16], w_in[15:8], w_in[7:0], w_in[31:24]};

    // 2. SubWord
    sub_word sw (.in(rot_word), .out(sub_word_out));

    // 3. XOR v?i Rcon: B??c cu?i c ng trong h m g
    assign g = sub_word_out ^ rcon;
endmodule

// 4. Key expansion
module key_expansion(
    input  logic [127:0] key,
    output logic [127:0] round_key [0:10]
);
    logic [31:0] w [0:43];

    // Kh a g?c n?p v o 4 t? ??u ti n
    assign w[0] = key[127:96];
    assign w[1] = key[95:64];
    assign w[2] = key[63:32];
    assign w[3] = key[31:0];

    genvar i;
    generate
        for (i = 4; i < 44; i++) begin : gen_keys
            if (i % 4 == 0) begin : use_g_func
                logic [31:0] g_out;
                // G?i h m g cho c?t ??u ti n c?a m?i round key

                g_function g_inst (
                    .w_in(w[i-1]), 
                    .i(4'(i/4)), 
                    .g(g_out)
                );

                assign w[i] = w[i-4] ^ g_out;
            end else begin : use_xor
                assign w[i] = w[i-4] ^ w[i-1];
            end
        end
    endgenerate


    integer k;
    always_comb begin
        for (k = 0; k < 11; k++)
            round_key[k] = {w[4*k], w[4*k+1], w[4*k+2], w[4*k+3]};
    end
endmodule

// 5. ShiftRows Module
module shift_rows (
    input  logic [127:0] in,
    output logic [127:0] state_shift
);
    //Sau khi d?ch
    // k0  k4    k8    k12
    // k5  k9    k13   k1
    // k10 k14   k2    k6
    // k15 k3    k7    k11

    assign state_shift = {
        // C?t 0: byte 0, 5, 10, 15
        in[127:120], in[87:80], in[47:40], in[7:0],
        // C?t 1: byte 4, 9, 14, 3
        in[95:88], in[55:48], in[15:8], in[103:96],
        // C?t 2: byte 8, 13, 2, 7
        in[63:56], in[23:16], in[111:104], in[71:64],
        // C?t 3: byte 12, 1, 6, 11
        in[31:24], in[119:112], in[79:72], in[39:32]
    };
endmodule

// 6. MixColumns Module
module mix_columns (
 input logic [127:0] state_in,
 output logic [127:0] state_mix
);
//=====column 0
logic [7:0] s0,s1,s2,s3;
logic [7:0] o0,o1,o2,o3;

assign s0 = state_in[127:120];
assign s1 = state_in[119:112];
assign s2 = state_in[111:104];
assign s3 = state_in[103:96];

assign o0 = ((s0<<1) ^ (8'h1b & {8{s0[7]}})) ^         //s0*2
(((s1<<1) ^ (8'h1b & {8{s1[7]}})) ^ s1) ^              //s1*2 ^ s1
s2 ^ s3; 

assign o1 = s0 ^ 
((s1<<1) ^ (8'h1b & {8{s1[7]}})) ^                     //s1*2
(((s2<<1) ^ (8'h1b & {8{s2[7]}})) ^ s2) ^              //s2*2 ^ s2
s3;

assign o2 = s0 ^ s1 ^
((s2<<1) ^ (8'h1b & {8{s2[7]}})) ^                     //s2*2
(((s3<<1) ^ (8'h1b & {8{s3[7]}})) ^ s3);               //s3*2 ^s3

assign o3 = (((s0<<1) ^ (8'h1b & {8{s0[7]}})) ^ s0) ^  //s0*2 ^ s0
 s1 ^ s2 ^
((s3<<1) ^ (8'h1b & {8{s3[7]}}));                      //s3*2

//=====column 1
logic [7:0] s4,s5,s6,s7;
logic [7:0] o4,o5,o6,o7;

assign s4 = state_in[95:88];
assign s5 = state_in[87:80];
assign s6 = state_in[79:72];
assign s7 = state_in[71:64];

assign o4 = ((s4<<1) ^ (8'h1b & {8{s4[7]}})) ^         
(((s5<<1) ^ (8'h1b & {8{s5[7]}})) ^ s5) ^
s6 ^ s7;

assign o5 = s4 ^
((s5<<1) ^ (8'h1b & {8{s5[7]}})) ^
(((s6<<1) ^ (8'h1b & {8{s6[7]}})) ^ s6) ^
 s7;

assign o6 = s4 ^ s5 ^
((s6<<1) ^ (8'h1b & {8{s6[7]}})) ^
(((s7<<1) ^ (8'h1b & {8{s7[7]}})) ^ s7);

assign o7 = (((s4<<1) ^ (8'h1b & {8{s4[7]}})) ^ s4) ^
s5 ^ s6 ^
((s7<<1) ^ (8'h1b & {8{s7[7]}}));

//=====column 2
logic [7:0] s8,s9,s10,s11;
logic [7:0] o8,o9,o10,o11;

assign s8  = state_in[63:56];
assign s9  = state_in[55:48];
assign s10 = state_in[47:40];
assign s11 = state_in[39:32];

assign o8  = ((s8<<1) ^ (8'h1b & {8{s8[7]}})) ^
(((s9<<1) ^ (8'h1b & {8{s9[7]}})) ^ s9) ^
s10 ^ s11;

assign o9  = s8 ^
((s9<<1) ^ (8'h1b & {8{s9[7]}})) ^
(((s10<<1) ^ (8'h1b & {8{s10[7]}})) ^ s10) ^
s11;

assign o10 = s8 ^ s9 ^
((s10<<1) ^ (8'h1b & {8{s10[7]}})) ^
(((s11<<1) ^ (8'h1b & {8{s11[7]}})) ^ s11);

assign o11 = (((s8<<1) ^ (8'h1b & {8{s8[7]}})) ^ s8) ^
s9 ^ s10 ^
((s11<<1) ^ (8'h1b & {8{s11[7]}}));

//=====column 3
logic [7:0] s12,s13,s14,s15;
logic [7:0] o12,o13,o14,o15;

assign s12 = state_in[31:24];
assign s13 = state_in[23:16];
assign s14 = state_in[15:8];
assign s15 = state_in[7:0];

assign o12 = ((s12<<1) ^ (8'h1b & {8{s12[7]}})) ^
(((s13<<1) ^ (8'h1b & {8{s13[7]}})) ^ s13) ^
s14 ^ s15;

assign o13 = s12 ^
((s13<<1) ^ (8'h1b & {8{s13[7]}})) ^
(((s14<<1) ^ (8'h1b & {8{s14[7]}})) ^ s14) ^
s15;

assign o14 = s12 ^ s13 ^
((s14<<1) ^ (8'h1b & {8{s14[7]}})) ^
(((s15<<1) ^ (8'h1b & {8{s15[7]}})) ^ s15);

assign o15 = (((s12<<1) ^ (8'h1b & {8{s12[7]}})) ^ s12) ^
s13 ^ s14 ^
((s15<<1) ^ (8'h1b & {8{s15[7]}}));


assign state_mix = {
    o0,o1,o2,o3,
    o4,o5,o6,o7,
    o8,o9,o10,o11,
    o12,o13,o14,o15
};
endmodule

// 7.Subbyte
module sub_bytes(
	input logic [127:0] state,
	output logic [127:0] state_sub
);
	sub_word s0(.in(state[127:96]), .out(state_sub[127:96]));
	sub_word s1(.in(state[95:64]), .out(state_sub[95:64]));
	sub_word s2(.in(state[63:32]), .out(state_sub[63:32]));
	sub_word s3(.in(state[31:0]), .out(state_sub[31:0]));
endmodule

// 8. Add_round_key
module add_round_key(
	input logic [127:0] state,
	input logic [127:0] key,
	output logic [127:0] state_xor
);
	assign state_xor = state ^ key;
endmodule

// Round 1-9
module aes_round(
    input logic [127:0] state_in,
    input logic [127:0] round_key,
    output logic [127:0] state_out
);
    logic [127:0] after_sub, after_shift, after_mix;

    sub_bytes u_sub(.state(state_in), .state_sub(after_sub));
    shift_rows u_shift(.in(after_sub), .state_shift(after_shift));
    mix_columns u_mix(.state_in(after_shift), .state_mix(after_mix));
    add_round_key u_add(.state(after_mix), .key(round_key), .state_xor(state_out));
endmodule

//Round 10
module aes_round_final(
    input logic [127:0] state_in,
    input logic [127:0] round_key,
    output logic [127:0] state_out
);
    logic [127:0] after_sub, after_shift;

    sub_bytes f_sub(.state(state_in), .state_sub(after_sub));
    shift_rows f_shift(.in(after_sub), .state_shift(after_shift));
    add_round_key f_add(.state(after_shift), .key(round_key), .state_xor(state_out));
endmodule

module aes_fsm (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       start,
    output logic [3:0] round_cnt,
    output logic       load_init,   // Ch?n n?p d? li?u ??u v o (Round 0)
    output logic       en_state,    // Cho ph p c?p nh?t thanh ghi d? li?u
    output logic       is_final,    // ?ang ? v ng cu?i c ng
    output logic       done         // Ho n th nh m  h a
);
    typedef enum logic [1:0] {IDLE, INIT, CALC, FINISH} state_t;
    state_t state, next_state;

    logic [3:0] cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cnt   <= 0;
        end else begin
            state <= next_state;
            if (state == CALC) cnt <= cnt + 1;
            else if (state == IDLE) cnt <= 0;
        end
    end

    always_comb begin
        next_state = state;
        load_init  = 0;
        en_state   = 0;
        is_final   = 0;
        done       = 0;

        case (state)
            IDLE: begin
                if (start) next_state = INIT;
            end
            INIT: begin
                load_init = 1;
                en_state  = 1;
                next_state = CALC;
            end
            CALC: begin
            en_state = 1;
                if (cnt == 4'd9) begin // V ng 1-9 l  round th??ng
                    is_final = 1;
                  en_state = 0;
                    next_state = FINISH;
                end
          end
            FINISH: begin
                en_state = 0;
                done     = 1;
                next_state = IDLE;
            end
        endcase
    end
    assign round_cnt = cnt;
endmodule
// 9. Top module AES 128 
module aes(
    input  logic         clk,    
    input  logic         rst_n, 
    input  logic         start,  // T n hi?u b?t ??u
    input  logic [127:0] key,
    input  logic [127:0] data_in,
    output logic [127:0] key_stream,
    output logic         done    // T n hi?u xong
);
    // T n hi?u k?t n?i t? Controller
    logic [3:0] round_cnt;
    logic       load_init, en_state, is_final;
    
    // T n hi?u d? li?u
    logic [127:0] rkey [0:10];
    logic [127:0] state; // Thanh ghi l?u tr?ng th i hi?n t?i
    logic [127:0] round_out, final_round_out, next_state;

    //Key_expansion
    key_expansion u_key_expansion(
        .key(key),
        .round_key(rkey)
    );

    //FSM
    aes_fsm u_fsm (
        .clk(clk), .rst_n(rst_n), .start(start),
        .round_cnt(round_cnt), .load_init(load_init),
        .en_state(en_state), .is_final(is_final), .done(done)
    );

    //Kh?i t nh to n Round
    aes_round u_r(
        .state_in(state), 
        .round_key(rkey[round_cnt+1]), 
        .state_out(round_out)
    );

    aes_round_final u_f(
        .state_in(state), 
        .round_key(rkey[10]), 
        .state_out(final_round_out)
    );

    //Mux ch?n d? li?u n?p v o thanh ghi
    always_comb begin
        if (load_init)
            next_state = data_in ^ rkey[0]; // N?p d? li?u ban ??u
        else if (is_final)
            next_state = final_round_out;   // N?p k?t qu? v ng 10
        else
            next_state = round_out;         // N?p k?t qu? v ng 1-9
    end

    //Thanh ghi tr?ng th i
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 128'd0;
	    key_stream <= 128'd0;
	end
        else begin
	if (en_state) begin
            state <= next_state;
end
	if (done) begin
    	    key_stream <= final_round_out;
	end
    end
end
endmodule