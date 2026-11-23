module axis_fifo_tb #(
    parameter int DEPTH = 3
);
    logic clk = 0;
    always #5 clk = !clk;
    logic rst_n = 0, valid = 0, ready = 0;
    logic [15:0] data = 0;
    wire in_ready, out_valid;
    wire [15:0] out_data;

    axis_fifo #(.DATA_WIDTH(16), .DEPTH(DEPTH)) dut (
        .clk, .rst_n, .s_axis_tdata(data), .s_axis_tvalid(valid),
        .s_axis_tready(in_ready), .m_axis_tdata(out_data),
        .m_axis_tvalid(out_valid), .m_axis_tready(ready)
    );

    int sent = 0, received = 0;
    bit push, stalled, full_replaced, empty, held;
    logic [15:0] held_data;

    initial begin
        repeat (2) @(posedge clk);
        for (int cycle = 0; cycle < 400; cycle++) begin
            @(negedge clk);
            rst_n = 1;
            if (!valid || push) begin
                valid = sent < 64 && (cycle < 25 || cycle % 7 < 4);
                data = 16'(sent*257 + 19);
            end
            ready = cycle >= 20 && cycle % 11 < 8;
            @(posedge clk);
            if (held && (!out_valid || out_data !== held_data))
                $fatal(1, "FIFO output changed under backpressure");
            push = valid && in_ready;
            stalled |= valid && !in_ready;
            empty |= !out_valid;
            held = out_valid && !ready;
            held_data = out_data;
            if (push && out_valid && ready && sent - received == DEPTH)
                full_replaced = 1;
            if (out_valid && ready) begin
                if (received >= sent || out_data !== 16'(received*257 + 19))
                    $fatal(1, "Invalid FIFO output at beat %0d", received);
                received++;
            end
            if (push)
                sent++;
        end
        if (sent != 64 || received != 64 || !stalled || !full_replaced || !empty)
            $fatal(1, "FIFO traffic coverage failed");
        $display("PASS axis_fifo DEPTH=%0d", DEPTH);
        $finish;
    end
endmodule
