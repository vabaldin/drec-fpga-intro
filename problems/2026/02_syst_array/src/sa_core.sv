module sa_core #(
    parameter int WIDTH = 16,
    parameter int SIZE = 4,
    localparam int ACC_WIDTH = 2 * WIDTH + $clog2(SIZE)
) (
    input  logic                           clk,
    input  logic                           rst_n,
    input  logic [SIZE*WIDTH-1:0]          i_a,
    input  logic [SIZE*WIDTH-1:0]          i_b,
    input  logic [SIZE-1:0]                i_a_valid,
    input  logic [SIZE-1:0]                i_b_valid,
    output wire  [SIZE*SIZE*ACC_WIDTH-1:0] o_c
);

// A flows east and B flows south. The wrapper skews the input lanes
// so matching terms arrive together at each PE.
wire [WIDTH-1:0] a_grid [0:SIZE-1][0:SIZE];
wire [WIDTH-1:0] b_grid [0:SIZE][0:SIZE-1];
wire             a_valid [0:SIZE-1][0:SIZE];
wire             b_valid [0:SIZE][0:SIZE-1];

for (genvar lane = 0; lane < SIZE; lane++) begin : g_input
    assign a_grid[lane][0]  = i_a[lane*WIDTH +: WIDTH];
    assign b_grid[0][lane]  = i_b[lane*WIDTH +: WIDTH];
    assign a_valid[lane][0] = i_a_valid[lane];
    assign b_valid[0][lane] = i_b_valid[lane];
end

for (genvar row = 0; row < SIZE; row++) begin : g_row
    for (genvar col = 0; col < SIZE; col++) begin : g_col
        pe #(.WIDTH(WIDTH), .ACC_WIDTH(ACC_WIDTH)) u_pe (
            .clk(clk),
            .rst_n(rst_n),
            .i_a(a_grid[row][col]),
            .i_b(b_grid[row][col]),
            .i_a_valid(a_valid[row][col]),
            .i_b_valid(b_valid[row][col]),
            .o_a(a_grid[row][col+1]),
            .o_b(b_grid[row+1][col]),
            .o_a_valid(a_valid[row][col+1]),
            .o_b_valid(b_valid[row+1][col]),
            .o_sum(o_c[(row*SIZE+col)*ACC_WIDTH +: ACC_WIDTH])
        );
    end
end

endmodule
