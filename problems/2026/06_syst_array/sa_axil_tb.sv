module sa_axil_tb;
    logic clk = 0;
    always #5 clk = !clk;
    logic rst_n = 0;
    logic [5:0] s_axil_araddr = 0, s_axil_awaddr = 0;
    logic [2:0] s_axil_arprot = 0, s_axil_awprot = 0;
    logic s_axil_arvalid = 0, s_axil_rready = 0;
    logic s_axil_awvalid = 0, s_axil_wvalid = 0, s_axil_bready = 0;
    logic [31:0] s_axil_wdata = 0;
    logic [3:0] s_axil_wstrb = 0;
    wire s_axil_arready, s_axil_rvalid, s_axil_awready, s_axil_wready, s_axil_bvalid;
    wire [1:0] s_axil_rresp, s_axil_bresp;
    wire [31:0] s_axil_rdata;

    wire [31:0] m_axi_araddr, m_axi_awaddr;
    wire [7:0] m_axi_arlen, m_axi_awlen, m_axi_wstrb;
    wire [2:0] m_axi_arsize, m_axi_awsize;
    wire [1:0] m_axi_arburst, m_axi_awburst;
    wire m_axi_arvalid, m_axi_awvalid, m_axi_rready, m_axi_wvalid, m_axi_wlast, m_axi_bready;
    wire [63:0] m_axi_wdata;
    logic [63:0] m_axi_rdata;
    logic m_axi_rvalid = 0, m_axi_bvalid = 0, m_axi_arready = 0;
    wire m_axi_awready = 1, m_axi_wready = 1, m_axi_rlast = 1;
    wire [1:0] m_axi_rresp = 0, m_axi_bresp = 0;
    logic [63:0] result = 0;

    sa_axil #(.SIZE(1)) dut (.*);

    always @(posedge clk) begin
        if (m_axi_arvalid && m_axi_arready) begin
            case (m_axi_araddr)
                32'h1020: m_axi_rdata <= 7;
                32'h2040: m_axi_rdata <= 9;
                default: $fatal(1, "Unexpected AXI read address");
            endcase
            m_axi_rvalid <= 1;
        end else if (m_axi_rready)
            m_axi_rvalid <= 0;
        if (m_axi_awvalid && m_axi_awaddr !== 32'h3080)
            $fatal(1, "Unexpected AXI write address");
        if (m_axi_wvalid) begin
            result <= m_axi_wdata;
            m_axi_bvalid <= 1;
        end else if (m_axi_bready)
            m_axi_bvalid <= 0;
    end

    task automatic write_reg(input logic [5:0] addr, input logic [31:0] data,
                             input logic [3:0] strb, input logic [1:0] resp);
        @(negedge clk);
        s_axil_awaddr = addr;
        s_axil_awvalid = 1;
        repeat (2) @(negedge clk);
        s_axil_wdata = data;
        s_axil_wstrb = strb;
        s_axil_wvalid = 1;
        do @(posedge clk); while (!(s_axil_awready && s_axil_wready));
        @(negedge clk);
        s_axil_awvalid = 0;
        s_axil_wvalid = 0;
        s_axil_awaddr = 0;
        s_axil_wdata = 0;
        repeat (3) begin
            @(negedge clk);
            if (!s_axil_bvalid || s_axil_bresp !== resp)
                $fatal(1, "Write response mismatch at %h", addr);
        end
        s_axil_bready = 1;
        @(negedge clk);
        s_axil_bready = 0;
    endtask

    task automatic read_reg(input logic [5:0] addr, input logic [31:0] expected,
                            input logic [1:0] resp);
        @(negedge clk);
        s_axil_araddr = addr;
        s_axil_arvalid = 1;
        do @(posedge clk); while (!s_axil_arready);
        @(negedge clk);
        s_axil_arvalid = 0;
        s_axil_araddr = 0;
        repeat (3) begin
            @(negedge clk);
            if (!s_axil_rvalid || s_axil_rresp !== resp || s_axil_rdata !== expected)
                $fatal(1, "Read %h: got %h expected %h", addr, s_axil_rdata, expected);
        end
        s_axil_rready = 1;
        @(negedge clk);
        s_axil_rready = 0;
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1;
        read_reg(4, 0, 0);
        read_reg(5, 0, 2);
        write_reg(4, 0, 15, 2);
        write_reg(0, 3, 15, 2);
        write_reg(0, 2, 15, 0);
        read_reg(4, 6, 0);
        write_reg(8, 'h2000, 15, 0);
        write_reg(8, 'h990040, 1, 0);
        read_reg(8, 'h2040, 0);
        write_reg(12, 'h1020, 15, 0);
        write_reg(16, 'h3080, 15, 0);

        write_reg(0, 1, 1, 0);
        read_reg(4, 1, 0);
        write_reg(0, 2, 1, 2);
        m_axi_arready = 1;
        repeat (8) @(negedge clk);
        read_reg(4, 10, 0);

        write_reg(0, 2, 1, 0);
        repeat (30) @(negedge clk);
        read_reg(4, 10, 0);
        if (result !== 63)
            $fatal(1, "Incorrect result");
        $display("PASS sa_axil");
        $finish;
    end

    initial begin
        #20000;
        $fatal(1, "AXI-Lite timeout");
    end
endmodule
