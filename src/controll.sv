module aes_ctr_top_fsm (
    input  logic   clk,
    input  logic   rst_n,
    input  logic   data_in,    //Nap plaintext
    input  logic   start_en,   //Bat dau qua trinh ma hoa
    input  logic   last_block, //Kiem tra xem co phai la block cuoi chua
    input  logic   aes_ready,  //San sang ma hoa counter tu aes
    output logic   aes_load,   //cho phep nap counter de tinh keystream
    output logic   cnt_rst_n,  //Reset counter tich cuc thap
    output logic   cnt,
    output logic   ready,      //San sang nhan tin hieu moi
    output logic   done	       //Xong	         
);

    // Trạng thái FSM
    typedef enum logic [2:0] {
	ST_IDLE = 3'b000, 		//trang thai nghi	
	ST_INIT = 3'b001, 		//khoi tao nonce va key
	ST_WAIT = 3'b010,		//nap plaintext va cho phep aes nap counter
	ST_PROCESS = 3'b011,		//ma hoa	
	ST_CLEAR = 3'b100		//reset
} state_t;
    state_t curr_state, next_state;
 
    //Trang thai
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
		curr_state <= ST_IDLE;
	else 
		curr_state <= next_state;
end

    always_comb begin
        next_state = curr_state;
        aes_load   = 1'b0;
        ready      = 1'b0;
	     done	   = 1'b0;
	     cnt_rst_n  = 1'b1;
	     cnt	   = 1'b0;

        case (curr_state)
            ST_IDLE: begin
			ready = 1'b1;
                if (start_en) next_state = ST_INIT;
            end

            ST_INIT: begin
		cnt_rst_n = 1'b0;
		next_state = ST_WAIT;
	    end

	    ST_WAIT: begin
		ready = 1'b1;
		if (data_in) begin
			aes_load = 1'b1; //cho phep nap counter vao aes de tinh keystream
			next_state = ST_PROCESS;
	    	end
 	    end

	    ST_PROCESS: begin
		if (aes_ready) begin
			cnt = 1'b1; //tang bo dem cho block ke
			if (last_block) next_state = ST_CLEAR;
			else 		next_state = ST_WAIT;
		end
	end
	    ST_CLEAR: begin
		done = 1'b1;
		next_state = ST_IDLE;
	end
	default: next_state = ST_IDLE;
    endcase
 end
endmodule