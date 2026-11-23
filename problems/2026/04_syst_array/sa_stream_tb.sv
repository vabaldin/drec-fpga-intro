module sa_stream_tb #(
    parameter int SIZE = 4,
    parameter int DEPTH = 2
);
    localparam int WIDTH = 8;
    localparam int ACC_WIDTH = 2*WIDTH + $clog2(SIZE);
    localparam int JOBS = 12;

    logic clk = 0;
    always #5 clk = !clk;
    logic rst_n = 0, a_valid = 0, b_valid = 0, c_ready = 0;
    logic [SIZE*WIDTH-1:0] a_data = 0, b_data = 0;
    wire a_ready, b_ready, c_valid;
    wire [SIZE*SIZE*ACC_WIDTH-1:0] c_data;
    logic [SIZE*SIZE*ACC_WIDTH-1:0] held_data;
    int a_sent = 0, b_sent = 0, received = 0;
    bit a_fire, b_fire, held, a_stalled, b_stalled, output_stalled, a_idle, b_idle;

    sa_stream #(.WIDTH(WIDTH), .SIZE(SIZE), .INPUT_DEPTH(DEPTH), .OUTPUT_DEPTH(DEPTH)) dut (
        .clk, .rst_n, .i_a(a_data), .i_b(b_data), .i_a_valid(a_valid), .i_b_valid(b_valid),
        .o_a_ready(a_ready), .o_b_ready(b_ready), .o_c(c_data), .o_c_valid(c_valid),
        .i_c_ready(c_ready)
    );

    function automatic int a(input int job, row, col);
        return (job*23 + row*17 + col*5 + 1) % 256;
    endfunction

    function automatic int b(input int job, row, col);
        return (job*11 + row*7 + col*19 + 3) % 256;
    endfunction

    initial begin
        repeat (2) @(posedge clk);
        for (int cycle = 0; cycle < 1500; cycle++) begin
            @(negedge clk);
            rst_n = 1;
            if (!a_valid || a_fire) begin
                a_valid = a_sent < JOBS*SIZE && cycle % 7 < 5;
                for (int row = 0; row < SIZE; row++)
                    a_data[row*WIDTH +: WIDTH] = WIDTH'(a(a_sent/SIZE, row, a_sent%SIZE));
            end
            if (!b_valid || b_fire) begin
                b_valid = b_sent < JOBS*SIZE && cycle >= 4 && cycle % 9 < 6;
                for (int col = 0; col < SIZE; col++)
                    b_data[col*WIDTH +: WIDTH] = WIDTH'(b(b_sent/SIZE, b_sent%SIZE, col));
            end
            c_ready = cycle >= 100 && cycle % 17 < 9;
            @(posedge clk);
            if (held && (!c_valid || c_data !== held_data))
                $fatal(1, "Result changed while stalled");
            held = c_valid && !c_ready;
            held_data = c_data;
            a_stalled |= a_valid && !a_ready;
            b_stalled |= b_valid && !b_ready;
            output_stalled |= held;
            a_idle |= !a_valid && b_valid;
            b_idle |= a_valid && !b_valid;
            a_fire = a_valid && a_ready;
            b_fire = b_valid && b_ready;
            if (a_fire)
                a_sent++;
            if (b_fire)
                b_sent++;
            if (c_valid && c_ready) begin
                if (received >= JOBS)
                    $fatal(1, "Extra matrix result");
                for (int row = 0; row < SIZE; row++) begin
                    for (int col = 0; col < SIZE; col++) begin
                        int expected;
                        expected = 0;
                        for (int k = 0; k < SIZE; k++)
                            expected += a(received, row, k)*b(received, k, col);
                        if (c_data[(row*SIZE+col)*ACC_WIDTH +: ACC_WIDTH] !== ACC_WIDTH'(expected))
                            $fatal(1, "Job %0d: wrong C[%0d,%0d]", received, row, col);
                    end
                end
                received++;
            end
        end
        if (a_sent != JOBS*SIZE || b_sent != JOBS*SIZE || received != JOBS ||
            !a_idle || !b_idle || !a_stalled || !b_stalled || !output_stalled)
            $fatal(1, "Traffic coverage failed");
        $display("PASS sa_stream SIZE=%0d DEPTH=%0d", SIZE, DEPTH);
        $finish;
    end
endmodule
