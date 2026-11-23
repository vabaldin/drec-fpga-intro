module sa_axil #(
    parameter int SIZE = 4,
    parameter int WIDTH = 16,
    parameter int AXIL_ADDR_WIDTH = 6
) (
    input logic clk, rst_n,
    input  logic [AXIL_ADDR_WIDTH-1:0]  s_axil_araddr,
    input  logic            [2:0]  s_axil_arprot,
    input  logic                   s_axil_arvalid,
    output logic                   s_axil_arready,
    output logic [32-1:0]  s_axil_rdata,
    output logic            [1:0]  s_axil_rresp,
    output logic                   s_axil_rvalid,
    input  logic                   s_axil_rready,
    input  logic [AXIL_ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  logic            [2:0]  s_axil_awprot,
    input  logic                   s_axil_awvalid,
    output logic                   s_axil_awready,
    input  logic [32-1:0]  s_axil_wdata,
    input  logic [4-1:0]  s_axil_wstrb,
    input  logic                   s_axil_wvalid,
    output logic                   s_axil_wready,
    output logic            [1:0]  s_axil_bresp,
    output logic                   s_axil_bvalid,
    input  logic                   s_axil_bready,
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
    localparam int CMD = 0, STATUS = 4, ADDR_A = 8, ADDR_B = 12, ADDR_C = 16;
    logic [31:0] addr_a, addr_b, addr_c;
    wire busy, done, error, b_loaded;
    logic completed;

    wire [AXIL_ADDR_WIDTH-1:0] reg_rd_addr, reg_wr_addr;
    wire reg_rd_en, reg_wr_en;
    wire [31:0] reg_wr_data;
    wire [3:0] reg_wr_strb;
    logic [31:0] reg_rd_data;
    logic reg_rd_okay, reg_wr_okay, write_okay;

    wire [1:0] command = reg_wr_strb[0] ? reg_wr_data[1:0] : 2'b00;
    wire start_b = reg_wr_en && write_okay && reg_wr_addr == AXIL_ADDR_WIDTH'(CMD) && command == 1;
    wire start_a = reg_wr_en && write_okay && reg_wr_addr == AXIL_ADDR_WIDTH'(CMD) && command == 2;

    axil2reg #(.ADDR_WIDTH(AXIL_ADDR_WIDTH)) control (.*);
    sa_axi #(.SIZE(SIZE), .WIDTH(WIDTH)) accelerator (.*);

    function automatic logic [31:0] merge(
        input logic [31:0] previous, value,
        input logic [3:0] strobes
    );
        for (int n = 0; n < 4; n++)
            merge[n*8 +: 8] = strobes[n] ? value[n*8 +: 8] : previous[n*8 +: 8];
    endfunction

    always_comb begin
        case (int'(reg_wr_addr))
            CMD: write_okay = command == 0 || (!busy && command != 3);
            ADDR_A, ADDR_B, ADDR_C: write_okay = 1;
            default: write_okay = 0;
        endcase
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            addr_a <= 0;
            addr_b <= 0;
            addr_c <= 0;
            completed <= 0;
            reg_rd_data <= 0;
            reg_rd_okay <= 0;
            reg_wr_okay <= 0;
        end else begin
            if (start_a || start_b)
                completed <= 0;
            else if (done)
                completed <= 1;

            if (reg_wr_en) begin
                reg_wr_okay <= write_okay;
                case (int'(reg_wr_addr))
                    ADDR_A: addr_a <= merge(addr_a, reg_wr_data, reg_wr_strb);
                    ADDR_B: addr_b <= merge(addr_b, reg_wr_data, reg_wr_strb);
                    ADDR_C: addr_c <= merge(addr_c, reg_wr_data, reg_wr_strb);
                    default: ;
                endcase
            end

            if (reg_rd_en) begin
                reg_rd_okay <= 1;
                case (int'(reg_rd_addr))
                    STATUS: reg_rd_data <= {28'b0, b_loaded, error, completed || done, busy};
                    ADDR_A: reg_rd_data <= addr_a;
                    ADDR_B: reg_rd_data <= addr_b;
                    ADDR_C: reg_rd_data <= addr_c;
                    default: begin
                        reg_rd_data <= 0;
                        reg_rd_okay <= 0;
                    end
                endcase
            end
        end
    end
endmodule
