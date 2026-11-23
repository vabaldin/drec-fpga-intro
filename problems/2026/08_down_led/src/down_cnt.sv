module down_cnt #(
    parameter int WIDTH = 26
) (
    input  logic clk, rst_n,
    output logic [WIDTH-1:0] count
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= '0;
        else
            count <= count-1'b1;
    end
endmodule
