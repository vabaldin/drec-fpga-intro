module stream_fifo #(
    parameter int WIDTH = 32,
    parameter int DEPTH = 2
) (
    input  logic clk, rst_n,
    input  logic [WIDTH-1:0] s_data,
    input  logic s_valid,
    output wire s_ready,
    output wire [WIDTH-1:0] m_data,
    output wire m_valid,
    input  logic m_ready
);
    localparam int PTR_W = (DEPTH > 1) ? $clog2(DEPTH) : 1;
    localparam int CNT_W = $clog2(DEPTH+1);
    logic [WIDTH-1:0] data [0:DEPTH-1];
    logic [PTR_W-1:0] wr, rd;
    logic [CNT_W-1:0] count;

    assign m_valid = rst_n && (count != 0);
    assign s_ready = rst_n && ((count != CNT_W'(DEPTH)) || m_ready);
    assign m_data = data[rd];

    wire push = s_valid && s_ready;
    wire pop = m_valid && m_ready;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr <= '0;
            rd <= '0;
            count <= '0;
        end else begin
            if (push) begin
                data[wr] <= s_data;
                wr <= (wr == PTR_W'(DEPTH-1)) ? '0 : wr+1'b1;
            end
            if (pop)
                rd <= (rd == PTR_W'(DEPTH-1)) ? '0 : rd+1'b1;
            case ({push, pop})
                2'b10: count <= count+1'b1;
                2'b01: count <= count-1'b1;
                default: ;
            endcase
        end
    end
endmodule
