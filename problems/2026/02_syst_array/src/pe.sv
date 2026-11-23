module pe #(
    parameter int WIDTH = 16,
    parameter int ACC_WIDTH = 2 * WIDTH
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic [WIDTH-1:0]     i_a,
    input  logic [WIDTH-1:0]     i_b,
    input  logic                 i_a_valid,
    input  logic                 i_b_valid,
    output logic [WIDTH-1:0]     o_a,
    output logic [WIDTH-1:0]     o_b,
    output logic                 o_a_valid,
    output logic                 o_b_valid,
    output logic [ACC_WIDTH-1:0] o_sum
);

wire [2*WIDTH-1:0] product = i_a * i_b;

sr #(.WIDTH(WIDTH)) u_a (
    .clk(clk), .rst_n(rst_n),
    .i_data(i_a), .i_valid(i_a_valid), .o_data(o_a), .o_valid(o_a_valid)
);

sr #(.WIDTH(WIDTH)) u_b (
    .clk(clk), .rst_n(rst_n),
    .i_data(i_b), .i_valid(i_b_valid), .o_data(o_b), .o_valid(o_b_valid)
);

always_ff @(posedge clk) begin
    if (!rst_n)
        o_sum <= '0;
    else if (i_a_valid && i_b_valid)
        o_sum <= o_sum + ACC_WIDTH'(product);
end

endmodule
