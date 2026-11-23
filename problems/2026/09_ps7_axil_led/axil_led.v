module axil_led (
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil, ASSOCIATED_RESET rst_n" *)
    input wire clk,
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input wire rst_n,
    input  wire [16-1:0]  s_axil_araddr,
    input  wire            [2:0]  s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [32-1:0]  s_axil_rdata,
    output wire            [1:0]  s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready,
    input  wire [16-1:0]  s_axil_awaddr,
    input  wire            [2:0]  s_axil_awprot,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,
    input  wire [32-1:0]  s_axil_wdata,
    input  wire [4-1:0]  s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,
    output wire            [1:0]  s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,
    output reg [3:0] led
);
    wire [15:0] reg_rd_addr, reg_wr_addr;
    wire [31:0] reg_wr_data;
    wire [3:0] reg_wr_strb;
    wire reg_rd_en, reg_wr_en;
    reg [31:0] reg_rd_data;
    reg reg_rd_okay, reg_wr_okay;

    axil2reg #(.ADDR_WIDTH(16)) bus (
        .clk(clk), .rst_n(rst_n),
        .s_axil_araddr(s_axil_araddr), .s_axil_arprot(s_axil_arprot),
        .s_axil_arvalid(s_axil_arvalid), .s_axil_arready(s_axil_arready),
        .s_axil_rdata(s_axil_rdata), .s_axil_rresp(s_axil_rresp),
        .s_axil_rvalid(s_axil_rvalid), .s_axil_rready(s_axil_rready),
        .s_axil_awaddr(s_axil_awaddr), .s_axil_awprot(s_axil_awprot),
        .s_axil_awvalid(s_axil_awvalid), .s_axil_awready(s_axil_awready),
        .s_axil_wdata(s_axil_wdata), .s_axil_wstrb(s_axil_wstrb),
        .s_axil_wvalid(s_axil_wvalid), .s_axil_wready(s_axil_wready),
        .s_axil_bresp(s_axil_bresp), .s_axil_bvalid(s_axil_bvalid),
        .s_axil_bready(s_axil_bready),
        .reg_rd_addr(reg_rd_addr), .reg_rd_en(reg_rd_en),
        .reg_rd_data(reg_rd_data), .reg_rd_okay(reg_rd_okay),
        .reg_wr_addr(reg_wr_addr), .reg_wr_data(reg_wr_data), .reg_wr_strb(reg_wr_strb),
        .reg_wr_en(reg_wr_en), .reg_wr_okay(reg_wr_okay)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            led <= 0;
            reg_rd_data <= 0;
            reg_rd_okay <= 0;
            reg_wr_okay <= 0;
        end else begin
            if (reg_wr_en) begin
                reg_wr_okay <= reg_wr_addr == 0;
                if (reg_wr_addr == 0 && reg_wr_strb[0])
                    led <= reg_wr_data[3:0];
            end

            if (reg_rd_en) begin
                reg_rd_okay <= reg_rd_addr == 0;
                reg_rd_data <= reg_rd_addr == 0 ? {28'b0, led} : 0;
            end
        end
    end
endmodule
