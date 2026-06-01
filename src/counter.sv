module ctr (
	input logic [95:0] nonce,
	input logic clk, rst_n, load_en,
	output logic [127:0] counter_v
);
	logic [31:0] counter;

	always_ff@(posedge clk or negedge rst_n) begin
if(!rst_n) begin
	counter <= 32'b0;
end
else if(load_en) begin
	counter <= counter + 1'b1;
end
end
	
assign counter_v = {nonce[95:0], counter[31:0]};
endmodule