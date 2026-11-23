module sa_burst #(
    parameter int WORDS = 16
) (
    input  logic [31:0] base, index,
    output wire [31:0] addr,
    output wire [7:0] len
);
    assign addr = base + (index << 3);
    wire [31:0] left = WORDS - index;
    wire [9:0] page_words = 10'd512 - {1'b0, addr[11:3]};
    wire [31:0] page_limit = (left < 32'(page_words)) ? left : 32'(page_words);
    wire [7:0] beats = (page_limit < 16) ? 8'(page_limit) : 8'd16;
    assign len = beats - 1'b1;
endmodule
