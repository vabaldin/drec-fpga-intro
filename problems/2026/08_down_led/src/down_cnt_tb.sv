module down_cnt_tb;
    logic clk = 0, rst_n = 1;
    always #5 clk = !clk;
    wire [3:0] count;
    down_cnt #(.WIDTH(4)) dut (.clk, .rst_n, .count);

    initial begin
        #1 rst_n = 0;
        #1;
        if (count !== 0)
            $fatal(1, "Reset failed");
        @(negedge clk);
        rst_n = 1;
        for (int tick = 1; tick <= 35; tick++) begin
            @(posedge clk);
            #1;
            if (count !== 4'(-tick))
                $fatal(1, "Wrong count at tick %0d", tick);
        end
        #1 rst_n = 0;
        #1;
        if (count !== 0)
            $fatal(1, "Asynchronous reset failed");
        $display("PASS down_cnt");
        $finish;
    end
endmodule
