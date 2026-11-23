module delay_line #(
    parameter int WIDTH = 16,
    parameter int DEPTH = 1
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] i_data,
    input  logic             i_valid,
    output wire  [WIDTH-1:0] o_data,
    output wire              o_valid
);

wire [WIDTH-1:0] data_pipe [0:DEPTH];
wire             valid_pipe [0:DEPTH];

assign data_pipe[0]  = i_data;
assign valid_pipe[0] = i_valid;
assign o_data        = data_pipe[DEPTH];
assign o_valid       = valid_pipe[DEPTH];

for (genvar stage = 0; stage < DEPTH; stage++) begin : g_stage
    sr #(.WIDTH(WIDTH)) u_sr (
        .clk(clk),
        .rst_n(rst_n),
        .i_data(data_pipe[stage]),
        .i_valid(valid_pipe[stage]),
        .o_data(data_pipe[stage+1]),
        .o_valid(valid_pipe[stage+1])
    );
end

endmodule
