module axis_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int DEPTH = 4
) (
    input  logic clk, rst_n,
    input  logic [DATA_WIDTH-1:0] s_axis_tdata,
    input  logic s_axis_tvalid,
    output wire s_axis_tready,
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input  logic m_axis_tready
);
    stream_fifo #(.WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) fifo (
        .clk, .rst_n,
        .s_data(s_axis_tdata), .s_valid(s_axis_tvalid), .s_ready(s_axis_tready),
        .m_data(m_axis_tdata), .m_valid(m_axis_tvalid), .m_ready(m_axis_tready)
    );
endmodule
