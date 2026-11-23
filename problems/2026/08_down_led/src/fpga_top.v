module fpga_top (
    input wire clk, rst_n,
    output wire [3:0] led
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_sync <= 2'b00;
        else
            reset_sync <= {reset_sync[0], 1'b1};
    end

    wire [25:0] count;
    down_cnt counter (.clk(clk), .rst_n(reset_sync[1]), .count(count));
    assign led = count[25:22];
endmodule
