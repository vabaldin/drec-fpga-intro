module sa_stream #(
    parameter int WIDTH = 16,
    parameter int SIZE = 4,
    parameter int INPUT_DEPTH = 2,
    parameter int OUTPUT_DEPTH = 2,
    localparam int C_WIDTH = SIZE*SIZE*(2*WIDTH + $clog2(SIZE))
) (
    input  logic clk, rst_n,
    input  logic [SIZE*WIDTH-1:0] i_a, i_b,
    input  logic i_a_valid, i_b_valid,
    output wire o_a_ready, o_b_ready,
    output wire [C_WIDTH-1:0] o_c,
    output wire o_c_valid,
    input  logic i_c_ready
);
    localparam int COUNT_W = $clog2(SIZE+1);
    localparam int CREDIT_W = $clog2(OUTPUT_DEPTH+1);
    logic [COUNT_W-1:0] sent;
    logic [CREDIT_W-1:0] credits;
    wire [SIZE*WIDTH-1:0] a, b;
    wire a_valid, b_valid, c_valid, c_ready;
    wire [C_WIDTH-1:0] c;
    wire issue_pair = a_valid && b_valid &&
                      ((sent == 0) ? (credits != 0) : (sent < COUNT_W'(SIZE)));
    wire reserve = issue_pair && (sent == 0);
    wire release_credit = o_c_valid && i_c_ready;
    wire store_result = c_valid && c_ready;

    stream_fifo #(.WIDTH(SIZE*WIDTH), .DEPTH(INPUT_DEPTH)) a_fifo (
        .clk, .rst_n, .s_data(i_a), .s_valid(i_a_valid), .s_ready(o_a_ready),
        .m_data(a), .m_valid(a_valid), .m_ready(issue_pair)
    );
    stream_fifo #(.WIDTH(SIZE*WIDTH), .DEPTH(INPUT_DEPTH)) b_fifo (
        .clk, .rst_n, .s_data(i_b), .s_valid(i_b_valid), .s_ready(o_b_ready),
        .m_data(b), .m_valid(b_valid), .m_ready(issue_pair)
    );
    sa_top #(.WIDTH(WIDTH), .SIZE(SIZE)) array (
        .clk, .rst_n, .clear(store_result), .i_a(a), .i_b(b),
        .i_a_valid(issue_pair), .i_b_valid(issue_pair), .o_c(c), .o_valid(c_valid)
    );
    stream_fifo #(.WIDTH(C_WIDTH), .DEPTH(OUTPUT_DEPTH)) c_fifo (
        .clk, .rst_n, .s_data(c), .s_valid(c_valid), .s_ready(c_ready),
        .m_data(o_c), .m_valid(o_c_valid), .m_ready(i_c_ready)
    );

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            sent <= '0;
            credits <= CREDIT_W'(OUTPUT_DEPTH);
        end else begin
            if (store_result)
                sent <= '0;
            else if (issue_pair)
                sent <= sent+1'b1;

            case ({reserve, release_credit})
                2'b10: credits <= credits-1'b1;
                2'b01: credits <= credits+1'b1;
                default: ;
            endcase
        end
    end
endmodule
