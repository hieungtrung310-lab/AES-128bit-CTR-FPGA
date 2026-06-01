
module uart_top (
    input  logic CLOCK_50,  
    input  logic [0:0] KEY, 
    input  logic UART_RXD,  
    output logic UART_TXD,  
    output logic [0:0] LEDG
);
    logic baud_rx_en, baud_tx_en;
    logic [7:0] rx_byte, tx_byte;
    logic rx_valid, tx_start, tx_busy;
    
    logic sys_start, sys_vld_in, sys_last_block;
    logic sys_ready, sys_vld_out, sys_done;
    logic [127:0] aes_plaintext, aes_ciphertext;
    
    baud_gen u_baud (
        .clk(CLOCK_50), 
		  .rst_n(KEY[0]), 
		  .rx_en(baud_rx_en), 
		  .tx_en(baud_tx_en)
    );
    
    uart_rx u_rx (
        .clk(CLOCK_50), 
		  .rst_n(KEY[0]), 
		  .baud_rx_en(baud_rx_en),
        .rx(UART_RXD), 
		  .rx_data(rx_byte), 
		  .rx_valid(rx_valid)
    );
    
    uart_tx u_tx (
        .clk(CLOCK_50), 
		  .rst_n(KEY[0]), 
		  .tx_data(tx_byte), 
		  .baud_tx_en(baud_tx_en),
        .tx_en(tx_start), 
		  .tx(UART_TXD), 
		  .tx_busy(tx_busy)
    );
    
    aes_ctr u_aes_ctr_core (
        .clk(CLOCK_50), 
		  .rst_n(KEY[0]),
        .start_en_i(sys_start), 
		  .data_in_i(sys_vld_in), 
		  .last_block_i(sys_last_block),
        .key_i(128'h2b7e151628aed2a6abf7158809cf4f3c),
        .nonce_i(96'hAAAA_BBBB_CCCC_DDDD_EEEE_FFFF),
        .plaintext_i(aes_plaintext),
        .ready_o(sys_ready), 
		  .data_out(sys_vld_out), 
		  .ciphertext_o(aes_ciphertext), 
		  .done_o(sys_done)
    );


    enum logic [2:0] {WAIT_RX, PULSE_START, WAIT_INIT, WAIT_READY, FEED_DATA, WAIT_VLD_OUT, WAIT_TX} sys_state;
    logic [4:0] byte_cnt;
    logic is_started; 

    assign LEDG[0] = (sys_state != WAIT_RX && sys_state != WAIT_TX);

    always_ff @(posedge CLOCK_50 or negedge KEY[0]) begin
        if (!KEY[0]) begin
            sys_state <= WAIT_RX;
            byte_cnt <= 5'd0;
            sys_start <= 1'b0;
            sys_vld_in <= 1'b0;
            sys_last_block <= 1'b0;
            tx_start <= 1'b0;
            aes_plaintext <= 128'd0;
            is_started <= 1'b0;
        end else begin
            sys_start <= 1'b0;
            sys_vld_in <= 1'b0;
            sys_last_block <= 1'b0; 
            tx_start <= 1'b0;
            
            case (sys_state)
                WAIT_RX: begin
                    if (rx_valid) begin
                        aes_plaintext <= {aes_plaintext[119:0], rx_byte};
                        byte_cnt <= byte_cnt + 5'b1;
                        if (byte_cnt == 5'd15) begin
                            if (!is_started) sys_state <= PULSE_START;
                            else sys_state <= WAIT_READY; 
                        end
                    end
                end
                
                PULSE_START: begin
                    sys_start <= 1'b1;
                    is_started <= 1'b1;
                    sys_state <= WAIT_INIT; 
                end
                
                WAIT_INIT: begin
                    sys_state <= WAIT_READY; 
                end
                
                WAIT_READY: begin
                    if (sys_ready) sys_state <= FEED_DATA;
                end
                
                FEED_DATA: begin
                    sys_vld_in <= 1'b1;
                    sys_last_block <= 1'b0;
                    sys_state <= WAIT_VLD_OUT;
                end
                
                WAIT_VLD_OUT: begin
                    if (sys_vld_out) begin
                        sys_state <= WAIT_TX;
                        byte_cnt <= 5'd0; 
                    end
                end
                
                WAIT_TX: begin
                    if (!tx_busy && !tx_start) begin
                        if (byte_cnt < 5'd16) begin
                            tx_start <= 1'b1;
                            tx_byte <= aes_ciphertext[127 - (byte_cnt * 8) -: 8]; 
                            byte_cnt <= byte_cnt + 5'b1;
                        end else begin
                            sys_state <= WAIT_RX; 
                            byte_cnt <= 5'd0;
                        end
                    end
                end
            endcase
        end
    end
endmodule