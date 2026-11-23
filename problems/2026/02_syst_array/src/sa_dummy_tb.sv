module sa_checker #(
    parameter int SIZE = 4,
    parameter int WIDTH = 16,
    localparam int ACC_WIDTH = 2 * WIDTH + $clog2(SIZE)
) (
    output logic done = 1'b0
);

logic clk = 1'b0;
always #5 clk = ~clk;

logic rst_n = 1'b0;
logic clear = 1'b0;
logic [SIZE*WIDTH-1:0] i_a = '0, i_b = '0;
logic i_a_valid = 1'b0, i_b_valid = 1'b0;
wire [SIZE*SIZE*ACC_WIDTH-1:0] o_c;
wire o_valid;

logic [WIDTH-1:0] a [0:SIZE-1][0:SIZE-1];
logic [WIDTH-1:0] b [0:SIZE-1][0:SIZE-1];

sa_top #(.SIZE(SIZE), .WIDTH(WIDTH)) dut (
    .clk(clk), .rst_n(rst_n), .clear(clear),
    .i_a(i_a), .i_b(i_b), .i_a_valid(i_a_valid), .i_b_valid(i_b_valid),
    .o_c(o_c), .o_valid(o_valid)
);

// Use out-of-range indices to insert bubbles, with nonzero data on idle lanes.
task automatic step(input int a_index, input int b_index);
    @(negedge clk);
    i_a_valid = (a_index >= 0 && a_index < SIZE);
    i_b_valid = (b_index >= 0 && b_index < SIZE);
    i_a = '1;
    i_b = '1;
    for (int lane = 0; lane < SIZE; lane++) begin
        if (i_a_valid)
            i_a[lane*WIDTH +: WIDTH] = a[lane][a_index];
        if (i_b_valid)
            i_b[lane*WIDTH +: WIDTH] = b[b_index][lane];
    end
    @(posedge clk);
    #1;
endtask

task automatic require_pending;
    if (o_valid !== 1'b0)
        $fatal(1, "SIZE=%0d: result asserted before the last pair settled", SIZE);
endtask

task automatic check_result;
    logic [ACC_WIDTH-1:0] expected;

    if (o_valid !== 1'b1)
        $fatal(1, "SIZE=%0d: result valid did not assert or stay asserted", SIZE);
    for (int row = 0; row < SIZE; row++) begin
        for (int col = 0; col < SIZE; col++) begin
            expected = '0;
            for (int k = 0; k < SIZE; k++)
                expected = expected + ACC_WIDTH'(a[row][k]) * ACC_WIDTH'(b[k][col]);
            if (o_c[(row*SIZE+col)*ACC_WIDTH +: ACC_WIDTH] !== expected)
                $fatal(1, "SIZE=%0d: C[%0d,%0d] expected %0d, got %0d",
                       SIZE, row, col, expected, o_c[(row*SIZE+col)*ACC_WIDTH +: ACC_WIDTH]);
        end
    end
endtask

task automatic finish_product;
    repeat (2 * SIZE - 2) begin
        step(-1, -1);
        require_pending();
    end
    step(-1, -1);
    check_result();
    repeat (SIZE + 1) begin
        // The result and valid flag must survive even if extra vectors arrive.
        step(0, 0);
        check_result();
    end
endtask

task automatic clear_product;
    @(negedge clk);
    clear = 1'b1;
    @(posedge clk);
    #1;
    require_pending();
    if (o_c !== '0)
        $fatal(1, "SIZE=%0d: clear left stale accumulators", SIZE);
    clear = 1'b0;
endtask

initial begin
    repeat (2) @(posedge clk);
    #1;
    require_pending();
    if (o_c !== '0)
        $fatal(1, "SIZE=%0d: reset left stale accumulators", SIZE);
    rst_n = 1'b1;

    // Back-to-back columns and rows, with a different value in every lane.
    for (int r = 0; r < SIZE; r++) begin
        for (int c = 0; c < SIZE; c++) begin
            a[r][c] = WIDTH'(1 + 3*r + 7*c);
            b[r][c] = WIDTH'(2 + 5*r + 11*c);
        end
    end
    for (int k = 0; k < SIZE; k++) begin
        step(k, k);
        require_pending();
    end
    finish_product();
    clear_product();

    // Queue all of A first, then deliver B with gaps between its rows.
    for (int k = 0; k < SIZE; k++) begin
        step(k, -1);
        require_pending();
    end
    repeat (2 * SIZE) begin
        step(-1, -1);
        require_pending();
    end
    for (int k = 0; k < SIZE; k++) begin
        step(-1, -1);
        require_pending();
        step(-1, k);
        require_pending();
    end
    finish_product();
    clear_product();

    // Alternate which input leads while keeping each stream in order.
    for (int k = 0; k < SIZE; k++) begin
        if (k % 2 == 0) begin
            step(-1, k);
            require_pending();
            step(k, -1);
        end else begin
            step(k, -1);
            require_pending();
            step(-1, k);
        end
        require_pending();
    end
    finish_product();
    clear_product();

    // Abort a transaction with a pair buffered or still moving through the grid.
    step(0, 0);
    require_pending();
    if (SIZE > 1) begin
        step(-1, -1);
        require_pending();
    end
    clear_product();

    // Queue B first and check the full accumulator width.
    for (int r = 0; r < SIZE; r++) begin
        for (int c = 0; c < SIZE; c++) begin
            a[r][c] = '1;
            b[r][c] = '1;
        end
    end
    for (int k = 0; k < SIZE; k++) begin
        step(-1, k);
        require_pending();
    end
    for (int k = 0; k < SIZE; k++) begin
        step(-1, -1);
        require_pending();
        step(k, -1);
        require_pending();
    end
    finish_product();

    $display("PASS: SIZE=%0d WIDTH=%0d", SIZE, WIDTH);
    done = 1'b1;
end

endmodule

module sa_dummy_tb;

wire done_default, done_single, done_odd;

sa_checker u_default (.done(done_default));
sa_checker #(.SIZE(1), .WIDTH(1)) u_single (.done(done_single));
sa_checker #(.SIZE(3), .WIDTH(5)) u_odd (.done(done_odd));

initial begin
    if ($test$plusargs("waves")) begin
        $dumpfile("dump.vcd");
        $dumpvars(0, sa_dummy_tb);
    end
    wait (done_default && done_single && done_odd);
    $finish;
end

initial begin
    #10000;
    $fatal(1, "Timed out waiting for the systolic array tests");
end

endmodule
