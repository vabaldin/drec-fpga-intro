module sa_zynq (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK",
       X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil:m_axi, ASSOCIATED_RESET rst_n" *)
    input wire clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_n RST",
       X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
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
    output wire [31:0] m_axi_araddr,
    output wire [7:0] m_axi_arlen,
    output wire [2:0] m_axi_arsize,
    output wire [1:0] m_axi_arburst,
    output wire m_axi_arvalid,
    input  wire m_axi_arready,
    input  wire [63:0] m_axi_rdata,
    input  wire [1:0] m_axi_rresp,
    input  wire m_axi_rlast, m_axi_rvalid,
    output wire m_axi_rready,

    output wire [31:0] m_axi_awaddr,
    output wire [7:0] m_axi_awlen,
    output wire [2:0] m_axi_awsize,
    output wire [1:0] m_axi_awburst,
    output wire m_axi_awvalid,
    input  wire m_axi_awready,
    output wire [63:0] m_axi_wdata,
    output wire [7:0] m_axi_wstrb,
    output wire m_axi_wlast, m_axi_wvalid,
    input  wire m_axi_wready,
    input  wire [1:0] m_axi_bresp,
    input  wire m_axi_bvalid,
    output wire m_axi_bready,
    output wire m_axi_arid, m_axi_awid,
    input wire m_axi_rid, m_axi_bid,
    output wire m_axi_arlock, m_axi_awlock,
    output wire [2:0] m_axi_arprot, m_axi_awprot,
    output wire [3:0] m_axi_arcache, m_axi_awcache

);
    assign m_axi_arid = 1'b0;
    assign m_axi_awid = 1'b0;
    assign m_axi_arlock = 1'b0;
    assign m_axi_awlock = 1'b0;
    assign m_axi_arprot = 3'b000;
    assign m_axi_awprot = 3'b000;
    assign m_axi_arcache = 4'b0000;
    assign m_axi_awcache = 4'b0000;

    sa_axil #(.AXIL_ADDR_WIDTH(16)) accelerator (
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
        .s_axil_bready(s_axil_bready), .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen), .m_axi_arsize(m_axi_arsize),
        .m_axi_arburst(m_axi_arburst), .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready), .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp), .m_axi_rlast(m_axi_rlast),
        .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready),
        .m_axi_awaddr(m_axi_awaddr), .m_axi_awlen(m_axi_awlen),
        .m_axi_awsize(m_axi_awsize), .m_axi_awburst(m_axi_awburst),
        .m_axi_awvalid(m_axi_awvalid), .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata), .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast), .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready), .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid), .m_axi_bready(m_axi_bready)
    );
endmodule
