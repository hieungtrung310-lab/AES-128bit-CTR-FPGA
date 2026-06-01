module uart_rx(
	input logic clk, rst_n,
	input logic baud_rx_en,
	input logic rx,
	output logic [7:0] rx_data,
	output logic rx_valid
);
	enum logic [1:0] {IDLE, START, DATA, STOP} state;
	logic [3:0] sample;
	logic [2:0] bit_cnt;
	
	always_ff @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			state <= IDLE;
			sample <= 4'b0;
			bit_cnt <= 3'b0;
			rx_data <= 8'b0;
			rx_valid <= 1'b0;
		end
		else begin
			rx_valid <= 1'b0;
			case(state)
				IDLE: begin
					if(~rx) begin
						state <= START;
						sample <= 4'b0;
					end
				end
				START: begin
					if(baud_rx_en) begin
						if (sample == 4'd7)begin
							state <= DATA;
							bit_cnt <= 3'b0;
							sample <= 4'b0;
						end
						else 
							sample <= sample +4'b1;
					end
				end
				DATA: begin
					if(baud_rx_en) begin
						if(sample == 4'd15) begin
							rx_data[bit_cnt] <= rx;
							sample <= 4'b0;
							bit_cnt <= bit_cnt + 3'b1;
							if (bit_cnt == 3'd7)
								state <= STOP;
						end
						else sample <= sample +4'b1;
					end
				end
				STOP: begin
					if(baud_rx_en) begin
						if(sample == 4'd15)begin
							state <= IDLE;
							rx_valid <= 1'b1;
						end
						else sample <= sample + 4'b1;
					end
				end
			endcase
		end
	end
endmodule