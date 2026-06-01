module aes_ctr (
    input  logic         clk,
    input  logic         rst_n,
    
    input  logic         start_en_i,   // Bat dau file moi
    input  logic         data_in_i,    // Co plaintext dang nap vao
    input  logic         last_block_i, // Khoi plaintext cuoi
    input  logic [127:0] key_i,        
    input  logic [95:0]  nonce_i,      
    input  logic [127:0] plaintext_i,  
    
	 output logic 			 data_out,
    output logic [127:0] ciphertext_o, // Ket qua ma hoa 
    output logic         ready_o,      // San sang nạn du lieu moi
    output logic         done_o        // Hoan thanh xong file
);

    // Tin hieu ket noi
    logic [127:0] ctr_to_aes;    // Gia tri counter dua vao aes
    logic [127:0] keystream_w;   // Key_stream tu aes
    logic         aes_load_w;    
    logic         aes_ready_w;   
    logic         cnt_en_w;      
    logic         cnt_rst_n_w;   

    // 1. FSM 
    aes_ctr_top_fsm u_controller (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in_i),
        .start_en(start_en_i),
        .last_block(last_block_i),
        .aes_ready(aes_ready_w),   // San sang ma hoa counter moi
        .aes_load(aes_load_w),     // Cho phep aes nap counter
        .cnt_rst_n(cnt_rst_n_w),   // Reset bo dem
        .cnt(cnt_en_w),            // Tang bo dem 
        .ready(ready_o),			  // San sang nhan du lieu moi
        .done(done_o)				  // Hoan thanh xong file
    );

    // 2. Counter
    ctr u_counter (
        .clk(clk),
        .rst_n(cnt_rst_n_w),      
        .nonce(nonce_i),
        .load_en(cnt_en_w),       
        .counter_v(ctr_to_aes)
    );

    // 3. Lõi mã hóa AES (Module aes)
    aes u_aes_core (
        .clk(clk),
        .rst_n(rst_n),
        .start(aes_load_w),       
        .key(key_i),
        .data_in(ctr_to_aes),      
        .key_stream(keystream_w),  
        .done(aes_ready_w)        
    );

    // 4. Logic XOR
    xor_block result(.A(plaintext_i), .B(keystream_w), .C(ciphertext_o));
assign data_out = aes_ready_w; // Xong
endmodule

module xor_block(
	input logic [127:0] A, B,
	output logic [127:0] C
);
	assign C = A ^ B;
endmodule