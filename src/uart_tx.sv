module uart_tx(
	input logic clk, rst_n,
	input logic [7:0] tx_data, 
	input logic baud_tx_en,
	input logic tx_en,
	output logic tx, tx_busy
);
	enum logic [1:0] {IDLE, START, DATA, STOP} state;
	logic [2:0] bit_cnt;
	logic [7:0] shift_reg;
	
	always_ff @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			state <= IDLE;
			tx <= 1'b1;
			tx_busy <= 1'b0;
			bit_cnt <= 3'b0;
		end
		else begin 
			case (state)
					IDLE: begin
						tx <= 1'b1;
						if(tx_en) begin
							shift_reg <= tx_data;
							state <= START;
							tx_busy <= 1'b1;
						end
						else tx_busy <= 1'b0;
					end
					START: begin
						if(baud_tx_en) begin
							tx <= 1'b0; //start bit
							bit_cnt <= 3'b0;
							state <= DATA;
						end
					end
					DATA: begin
						if(baud_tx_en) begin
							tx <= shift_reg[bit_cnt];
							if(bit_cnt==3'd7)
								state <= STOP;
							else bit_cnt <= bit_cnt +3'b1;
						end
					end
					STOP: begin
						if(baud_tx_en) begin
							tx <= 1'b1;//stopbit
							state <= IDLE;
						end
					end
			endcase
		end
	end
	endmodule