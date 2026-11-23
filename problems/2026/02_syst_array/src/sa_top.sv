module sa_top #(
    parameter int WIDTH = 16,
    parameter int SIZE = 4,
    localparam int ACC_WIDTH = 2 * WIDTH + $clog2(SIZE)
) (
    input  logic                           clk,
    input  logic                           rst_n,
    input  logic                           clear,
    input  logic [SIZE*WIDTH-1:0]          i_a,
    input  logic [SIZE*WIDTH-1:0]          i_b,
    input  logic                           i_a_valid,
    input  logic                           i_b_valid,
    output wire  [SIZE*SIZE*ACC_WIDTH-1:0] o_c,
    output logic                           o_valid
);

localparam int COUNT_WIDTH = $clog2(SIZE + 1);
localparam int INDEX_WIDTH = (SIZE > 1) ? $clog2(SIZE) : 1;

wire run = rst_n && !clear;
logic [SIZE*WIDTH-1:0] a_vectors [0:SIZE-1];
logic [SIZE*WIDTH-1:0] b_vectors [0:SIZE-1];
logic [COUNT_WIDTH-1:0] a_count, b_count, issue_count;

// Buffer each stream independently and pair the nth vector from each.
wire pair_valid = (issue_count < a_count) && (issue_count < b_count);
wire [INDEX_WIDTH-1:0] issue_index = INDEX_WIDTH'(issue_count);
wire [SIZE*WIDTH-1:0] a_vector = pair_valid ? a_vectors[issue_index] : '0;
wire [SIZE*WIDTH-1:0] b_vector = pair_valid ? b_vectors[issue_index] : '0;

always_ff @(posedge clk) begin
    if (!run) begin
        a_count     <= '0;
        b_count     <= '0;
        issue_count <= '0;
    end else begin
        if (i_a_valid && a_count < COUNT_WIDTH'(SIZE)) begin
            a_vectors[INDEX_WIDTH'(a_count)] <= i_a;
            a_count <= a_count + 1'b1;
        end
        if (i_b_valid && b_count < COUNT_WIDTH'(SIZE)) begin
            b_vectors[INDEX_WIDTH'(b_count)] <= i_b;
            b_count <= b_count + 1'b1;
        end
        if (pair_valid)
            issue_count <= issue_count + 1'b1;
    end
end

wire [SIZE*WIDTH-1:0] a_skewed, b_skewed;
wire [SIZE-1:0] a_valid_skewed, b_valid_skewed;

for (genvar lane = 0; lane < SIZE; lane++) begin : g_skew
    delay_line #(.WIDTH(WIDTH), .DEPTH(lane)) u_a (
        .clk(clk), .rst_n(run),
        .i_data(a_vector[lane*WIDTH +: WIDTH]), .i_valid(pair_valid),
        .o_data(a_skewed[lane*WIDTH +: WIDTH]), .o_valid(a_valid_skewed[lane])
    );

    delay_line #(.WIDTH(WIDTH), .DEPTH(lane)) u_b (
        .clk(clk), .rst_n(run),
        .i_data(b_vector[lane*WIDTH +: WIDTH]), .i_valid(pair_valid),
        .o_data(b_skewed[lane*WIDTH +: WIDTH]), .o_valid(b_valid_skewed[lane])
    );
end

sa_core #(.WIDTH(WIDTH), .SIZE(SIZE)) u_core (
    .clk(clk), .rst_n(run),
    .i_a(a_skewed), .i_b(b_skewed),
    .i_a_valid(a_valid_skewed), .i_b_valid(b_valid_skewed),
    .o_c(o_c)
);

// The last pair reaches PE (SIZE-1, SIZE-1) after one hop per row and column.
wire final_issue = pair_valid && (issue_count == COUNT_WIDTH'(SIZE - 1));
wire final_product;

delay_line #(.WIDTH(1), .DEPTH(2 * (SIZE - 1))) u_completion (
    .clk(clk), .rst_n(run),
    .i_data(1'b0), .i_valid(final_issue),
    .o_data(), .o_valid(final_product)
);

always_ff @(posedge clk) begin
    if (!run)
        o_valid <= 1'b0;
    else if (final_product)
        o_valid <= 1'b1;
end

endmodule
