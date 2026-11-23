module sa_axi_tb #(
    parameter int SIZE = 5
);
    localparam int A = 'h0fe8, B = 'h1ff8, C = 'h2ff0;
    localparam int WORDS = SIZE*SIZE;
    logic clk = 0;
    always #5 clk = !clk;
    logic rst_n = 0, start_a = 0, start_b = 0;
    logic [31:0] addr_a = A, addr_b = B, addr_c = C;
    wire busy, done, error, b_loaded;
    wire [31:0] m_axi_araddr, m_axi_awaddr;
    wire [7:0] m_axi_arlen, m_axi_awlen, m_axi_wstrb;
    wire [2:0] m_axi_arsize, m_axi_awsize;
    wire [1:0] m_axi_arburst, m_axi_awburst;
    wire m_axi_arvalid, m_axi_awvalid, m_axi_rready, m_axi_wvalid, m_axi_wlast, m_axi_bready;
    wire [63:0] m_axi_wdata;
    wire [63:0] m_axi_rdata;
    wire [1:0] m_axi_rresp, m_axi_bresp;
    wire m_axi_rlast, m_axi_rvalid, m_axi_bvalid, m_axi_wready, m_axi_arready, m_axi_awready;

    sa_axi #(.SIZE(SIZE)) dut (.*);

    logic [63:0] mem [0:2047];
    int cycle = 0, nread = 0, nwrite = 0;
    int raddr, waddr, rleft = 0, wleft = 0;
    bit returning_b, bad_read, bad_write;

    assign m_axi_arready = rleft == 0 && cycle % 5 == 1;
    assign m_axi_rvalid = rleft != 0 && cycle % 3 != 0;
    assign m_axi_rdata = mem[raddr];
    assign m_axi_rlast = rleft == 1;
    assign m_axi_rresp = bad_read && rleft == 1 ? 2'b10 : 2'b00;
    assign m_axi_awready = wleft == 0 && !returning_b && cycle % 5 == 2;
    assign m_axi_wready = wleft != 0 && cycle % 4 != 0;
    assign m_axi_bvalid = returning_b && cycle % 7 == 3;
    assign m_axi_bresp = bad_write ? 2'b10 : 2'b00;

    task automatic check_burst(input int addr, len, beat_size, burst);
        if (beat_size != 3 || burst != 1 || len >= 16 ||
            (addr & 'hfff) + (len+1)*8 > 4096)
            $fatal(1, "Invalid AXI burst %h + %0d", addr, len+1);
    endtask

    always @(posedge clk) begin
        cycle <= cycle + 1;
        if (m_axi_arvalid && m_axi_arready) begin
            check_burst(m_axi_araddr, int'(m_axi_arlen), int'(m_axi_arsize), int'(m_axi_arburst));
            raddr <= int'(m_axi_araddr >> 3);
            rleft <= int'(m_axi_arlen)+1;
            nread <= nread+1;
        end else if (m_axi_rvalid && m_axi_rready) begin
            raddr <= raddr+1;
            rleft <= rleft-1;
        end
        if (m_axi_awvalid && m_axi_awready) begin
            check_burst(m_axi_awaddr, int'(m_axi_awlen), int'(m_axi_awsize), int'(m_axi_awburst));
            waddr <= int'(m_axi_awaddr >> 3);
            wleft <= int'(m_axi_awlen)+1;
            nwrite <= nwrite+1;
        end else if (m_axi_wvalid && m_axi_wready) begin
            if (m_axi_wlast !== (wleft == 1) || m_axi_wstrb !== 8'hff)
                $fatal(1, "Invalid AXI write beat");
            mem[waddr] <= m_axi_wdata;
            waddr <= waddr+1;
            wleft <= wleft-1;
            if (wleft == 1)
                returning_b <= 1;
        end
        if (m_axi_bvalid && m_axi_bready)
            returning_b <= 0;
    end

    task automatic command(input bit load_b, expected_error);
        @(negedge clk);
        start_b = load_b;
        start_a = !load_b;
        @(negedge clk);
        start_a = 0;
        start_b = 0;
        while (!done)
            @(negedge clk);
        if (busy || error !== expected_error)
            $fatal(1, "Unexpected command status: load_b=%b error=%b", load_b, error);
    endtask

    task automatic check_c;
        logic [63:0] expected;
        for (int row = 0; row < SIZE; row++) begin
            for (int col = 0; col < SIZE; col++) begin
                expected = 0;
                for (int k = 0; k < SIZE; k++)
                    expected += mem[A/8+row*SIZE+k]*mem[B/8+k*SIZE+col];
                if (mem[C/8+row*SIZE+col] !== expected)
                    $fatal(1, "Wrong result C[%0d,%0d]", row, col);
            end
        end
    endtask

    initial begin
        for (int index = 0; index < WORDS; index++) begin
            mem[A/8+index] = 64'(index*13+2);
            mem[B/8+index] = 64'(index*9+5);
        end
        repeat (2) @(negedge clk);
        rst_n = 1;
        command(0, 1);
        bad_read = 1;
        command(1, 1);
        if (b_loaded)
            $fatal(1, "Failed B read marked valid");
        bad_read = 0;
        command(1, 0);
        if (!b_loaded)
            $fatal(1, "B did not load");
        addr_a = A+1;
        command(0, 1);
        addr_a = A;
        bad_write = 1;
        command(0, 1);
        bad_write = 0;
        command(0, 0);
        check_c();
        for (int index = 0; index < WORDS; index++)
            mem[A/8+index] = 64'(index*17+9);
        command(0, 0);
        check_c();
        if (nread < 8 || nwrite < 5)
            $fatal(1, "Did not exercise split bursts");
        $display("PASS sa_axi SIZE=%0d", SIZE);
        $finish;
    end

    initial begin
        #50000;
        $fatal(1, "AXI timeout");
    end
endmodule
