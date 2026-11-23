module axil_led_tb;
    logic clk = 0;
    always #5 clk = !clk;
    logic rst_n = 0;
    logic [15:0] s_axil_araddr = 0, s_axil_awaddr = 0;
    logic [2:0] s_axil_arprot = 0, s_axil_awprot = 0;
    logic s_axil_arvalid = 0, s_axil_awvalid = 0, s_axil_wvalid = 0;
    logic s_axil_rready = 0, s_axil_bready = 0;
    logic [31:0] s_axil_wdata = 0;
    logic [3:0] s_axil_wstrb = 0;
    wire s_axil_arready, s_axil_awready, s_axil_wready, s_axil_rvalid, s_axil_bvalid;
    wire [1:0] s_axil_rresp, s_axil_bresp;
    wire [31:0] s_axil_rdata;
    wire [3:0] led;

    axil_led dut (.*);

    task automatic write_led(input logic [15:0] addr, input logic [31:0] data,
                             input logic [3:0] strb, input logic [1:0] resp);
        @(negedge clk);
        s_axil_wvalid = 1;
        s_axil_wdata = data;
        s_axil_wstrb = strb;
        @(negedge clk);
        s_axil_awvalid = 1;
        s_axil_awaddr = addr;
        do @(posedge clk); while (!(s_axil_awready && s_axil_wready));
        @(negedge clk);
        s_axil_awvalid = 0;
        s_axil_wvalid = 0;
        s_axil_awaddr = ~addr;
        repeat (3) begin
            if (!s_axil_bvalid || s_axil_bresp !== resp)
                $fatal(1, "Wrong AXI-Lite write response");
            @(negedge clk);
        end
        s_axil_bready = 1;
        @(negedge clk);
        s_axil_bready = 0;
    endtask

    task automatic read_led(input logic [15:0] addr, input logic [31:0] value,
                            input logic [1:0] resp);
        @(negedge clk);
        s_axil_araddr = addr;
        s_axil_arvalid = 1;
        do @(posedge clk); while (!s_axil_arready);
        @(negedge clk);
        s_axil_arvalid = 0;
        s_axil_araddr = ~addr;
        repeat (3) begin
            if (!s_axil_rvalid || s_axil_rresp !== resp || s_axil_rdata !== value)
                $fatal(1, "Wrong AXI-Lite read response");
            @(negedge clk);
        end
        s_axil_rready = 1;
        @(negedge clk);
        s_axil_rready = 0;
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1;
        read_led(0, 0, 0);
        write_led(0, 'hfeedbeea, 15, 0);
        read_led(0, 10, 0);
        write_led(0, 5, 14, 0);
        write_led(4, 5, 15, 2);
        read_led(4, 0, 2);
        read_led(0, 10, 0);
        if (led !== 10)
            $fatal(1, "Wrong pins");
        write_led(0, 5, 1, 0);
        if (led !== 5)
            $fatal(1, "LED pins did not update");
        $display("PASS axil_led");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "AXI GPIO timeout");
    end
endmodule
