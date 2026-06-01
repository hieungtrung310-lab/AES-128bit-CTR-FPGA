module baud_gen(
    input  logic clk,      // 50MHz
    input  logic rst_n,    
    output logic tx_en,  // Xung baud cho TX
    output logic rx_en   // Xung baud cho RX
);
 
    logic [12:0] tx_cnt;
    logic [8:0]  rx_cnt;

    //TX
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            tx_cnt <= 13'b0;
            tx_en  <= 0;
        end else if (tx_cnt == 5208) begin
            tx_cnt <= 0;
            tx_en  <= 1;
        end else begin
            tx_cnt <= tx_cnt + 1'b1;
            tx_en  <= 0;
        end
    end

    //RX
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rx_cnt <= 0;
            rx_en  <= 0;
        end else if (rx_cnt == 325) begin
            rx_cnt <= 0;
            rx_en  <= 1;
        end else begin
            rx_cnt <= rx_cnt + 1'b1;
            rx_en  <= 0;
        end
    end

endmodule