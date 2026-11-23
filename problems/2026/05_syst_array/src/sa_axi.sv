module sa_axi #(
    parameter int SIZE = 4,
    parameter int WIDTH = 16,
    localparam int WORDS = SIZE*SIZE,
    localparam int ACC_WIDTH = 2*WIDTH + $clog2(SIZE)
) (
    input  logic clk, rst_n,
    input  logic start_b, start_a,
    input  logic [31:0] addr_a, addr_b, addr_c,
    output wire busy,
    output logic done, error, b_loaded,

    output wire [31:0] m_axi_araddr,
    output wire [7:0] m_axi_arlen,
    output wire [2:0] m_axi_arsize,
    output wire [1:0] m_axi_arburst,
    output wire m_axi_arvalid,
    input  logic m_axi_arready,
    input  logic [63:0] m_axi_rdata,
    input  logic [1:0] m_axi_rresp,
    input  logic m_axi_rlast, m_axi_rvalid,
    output wire m_axi_rready,

    output wire [31:0] m_axi_awaddr,
    output wire [7:0] m_axi_awlen,
    output wire [2:0] m_axi_awsize,
    output wire [1:0] m_axi_awburst,
    output wire m_axi_awvalid,
    input  logic m_axi_awready,
    output wire [63:0] m_axi_wdata,
    output wire [7:0] m_axi_wstrb,
    output wire m_axi_wlast, m_axi_wvalid,
    input  logic m_axi_wready,
    input  logic [1:0] m_axi_bresp,
    input  logic m_axi_bvalid,
    output wire m_axi_bready
);
    localparam int INDEX_W = (WORDS > 1) ? $clog2(WORDS) : 1;
    localparam int K_W = (SIZE > 1) ? $clog2(SIZE) : 1;
    typedef enum logic [2:0] {IDLE, READ_ADDR, READ_DATA, FEED, WAIT_C,
                              WRITE_ADDR, WRITE_DATA, WRITE_RESP} state_t;
    state_t state;
    logic reading_b;
    logic [31:0] read_base, write_base, index;
    logic [7:0] beats_left;
    logic [K_W-1:0] k;
    logic a_sent, b_sent;
    logic [WIDTH-1:0] a [0:WORDS-1], b [0:WORDS-1];
    wire [31:0] next_addr;
    wire [7:0] next_len;
    wire [SIZE*WIDTH-1:0] a_vector, b_vector;
    wire [WORDS*ACC_WIDTH-1:0] c;
    wire a_ready, b_ready, c_valid;
    wire final_word = index == 32'(WORDS-1);
    wire a_valid = state == FEED && !a_sent;
    wire b_valid = state == FEED && !b_sent;
    wire pop_c = m_axi_bready && m_axi_bvalid &&
                 (m_axi_bresp != 0 || index == 32'(WORDS));
    wire read_fault = m_axi_rresp != 0 || (m_axi_rlast != (beats_left == 0));

    function automatic logic usable(input logic [31:0] addr);
        return addr[2:0] == 0 && addr <= (32'hffff_ffff - 32'(8*WORDS-1));
    endfunction

    sa_burst #(.WORDS(WORDS)) bursts (
        .base(state == READ_ADDR ? read_base : write_base), .index,
        .addr(next_addr), .len(next_len)
    );

    for (genvar lane = 0; lane < SIZE; lane++) begin : g_lane
        assign a_vector[lane*WIDTH +: WIDTH] = a[lane*SIZE + int'(k)];
        assign b_vector[lane*WIDTH +: WIDTH] = b[int'(k)*SIZE + lane];
    end

    sa_stream #(.SIZE(SIZE), .WIDTH(WIDTH), .INPUT_DEPTH(1), .OUTPUT_DEPTH(1)) array (
        .clk, .rst_n, .i_a(a_vector), .i_b(b_vector),
        .i_a_valid(a_valid), .i_b_valid(b_valid), .o_a_ready(a_ready), .o_b_ready(b_ready),
        .o_c(c), .o_c_valid(c_valid), .i_c_ready(pop_c)
    );

    assign busy = state != IDLE;
    assign m_axi_araddr = next_addr;
    assign m_axi_arlen = next_len;
    assign m_axi_arsize = 3'd3;
    assign m_axi_arburst = 2'b01;
    assign m_axi_arvalid = state == READ_ADDR;
    assign m_axi_rready = state == READ_DATA;
    assign m_axi_awaddr = next_addr;
    assign m_axi_awlen = next_len;
    assign m_axi_awsize = 3'd3;
    assign m_axi_awburst = 2'b01;
    assign m_axi_awvalid = state == WRITE_ADDR;
    assign m_axi_wdata = 64'(c[INDEX_W'(index)*ACC_WIDTH +: ACC_WIDTH]);
    assign m_axi_wstrb = '1;
    assign m_axi_wlast = beats_left == 0;
    assign m_axi_wvalid = state == WRITE_DATA;
    assign m_axi_bready = state == WRITE_RESP;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            error <= 0;
            b_loaded <= 0;
            index <= 0;
            k <= 0;
            a_sent <= 0;
            b_sent <= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE: if (start_b || start_a) begin
                    error <= 0;
                    index <= 0;
                    reading_b <= start_b;
                    if (start_b)
                        b_loaded <= 0;
                    if (start_b ? usable(addr_b) : (b_loaded && usable(addr_a) && usable(addr_c))) begin
                        read_base <= start_b ? addr_b : addr_a;
                        write_base <= addr_c;
                        state <= READ_ADDR;
                    end else begin
                        error <= 1;
                        done <= 1;
                    end
                end
                READ_ADDR: if (m_axi_arready) begin
                    beats_left <= next_len;
                    state <= READ_DATA;
                end
                READ_DATA: if (m_axi_rvalid) begin
                    if (!error && !read_fault) begin
                        if (reading_b)
                            b[INDEX_W'(index)] <= WIDTH'(m_axi_rdata);
                        else
                            a[INDEX_W'(index)] <= WIDTH'(m_axi_rdata);
                    end
                    if (read_fault)
                        error <= 1;
                    if (!m_axi_rlast && beats_left != 0) begin
                        beats_left <= beats_left - 1'b1;
                        index <= index + 1'b1;
                    end
                    if (m_axi_rlast) begin
                        if (error || read_fault || (reading_b && final_word)) begin
                            b_loaded <= reading_b ? !(error || read_fault) : b_loaded;
                            done <= 1;
                            state <= IDLE;
                        end else if (final_word) begin
                            k <= 0;
                            a_sent <= 0;
                            b_sent <= 0;
                            state <= FEED;
                        end else begin
                            index <= index + 1'b1;
                            state <= READ_ADDR;
                        end
                    end
                end
                FEED: begin
                    a_sent <= a_sent || a_ready;
                    b_sent <= b_sent || b_ready;
                    if ((a_sent || a_ready) && (b_sent || b_ready)) begin
                        a_sent <= 0;
                        b_sent <= 0;
                        if (k == K_W'(SIZE-1))
                            state <= WAIT_C;
                        else
                            k <= k + 1'b1;
                    end
                end
                WAIT_C: if (c_valid) begin
                    index <= 0;
                    state <= WRITE_ADDR;
                end
                WRITE_ADDR: if (m_axi_awready) begin
                    beats_left <= next_len;
                    state <= WRITE_DATA;
                end
                WRITE_DATA: if (m_axi_wready) begin
                    index <= index + 1'b1;
                    beats_left <= beats_left - 1'b1;
                    if (m_axi_wlast)
                        state <= WRITE_RESP;
                end
                WRITE_RESP: if (m_axi_bvalid) begin
                    if (pop_c) begin
                        error <= m_axi_bresp != 0;
                        done <= 1;
                        state <= IDLE;
                    end else
                        state <= WRITE_ADDR;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
