module sr #(
    parameter int WIDTH = 16
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] i_data,
    input  logic             i_valid,
    output logic [WIDTH-1:0] o_data,
    output logic             o_valid
);

always_ff @(posedge clk) begin
    if (!rst_n) begin
        o_data  <= '0;
        o_valid <= 1'b0;
    end else begin
        o_valid <= i_valid;
        if (i_valid)
            o_data <= i_data;
    end
end

endmodule
