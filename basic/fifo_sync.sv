/*======================================================
Descripton:
standard sync fifo

Create:  
YuanZhe   yuanzhe@newthu.com  20190824

Modify:
Yipeng  wangyipengcn@outlook.com  20191026 : resolve some bugs and add an output reg.

Notes:
1. 1 clk read latency

=========================================================*/
module fifo_sync#(
    parameter DATA_WIDE = 64,
    parameter FIFO_DEPT = 16,
    parameter MODE = "block"
)
(
    //interface to top
    input clk,
    input rst_n,
    //write interface
    input [DATA_WIDE - 1: 0] din,
    input wr_en,

    //read interface    
    input rd_en,
    output logic [DATA_WIDE - 1: 0] dout,

    //status interface
    output logic empty,
    output logic full
);
parameter ADDR_WIDE = $clog2(FIFO_DEPT);
logic [ADDR_WIDE - 1 : 0] rd_addr;
logic [ADDR_WIDE - 1 : 0] wr_addr;
logic [ADDR_WIDE     : 0] count;

//signal count
always_ff @(posedge clk or negedge rst_n)
if (!rst_n) begin
    count <= '0;
end else if (rd_en || wr_en) begin
    count <= count + (wr_en & !full) - (rd_en & !empty);
end


//read addr signal
always_ff @(posedge clk or negedge rst_n)
if (!rst_n) begin
    rd_addr <= '0;
end else if (!empty && rd_en) begin
    rd_addr <= rd_addr + 1;
end

//write signal

always_ff @(posedge clk or negedge rst_n)
if (!rst_n) begin
    wr_addr <= '0;
end else if (!full && wr_en) begin
    wr_addr <= wr_addr + 1;
end

//memory
(*ram_style = MODE*)logic [ DATA_WIDE - 1 : 0 ] FIFO [ FIFO_DEPT ];
always @(posedge clk) begin
    if (wr_en && !full)  FIFO [wr_addr] <= din;
    if (rd_en) dout  <= empty ? {DATA_WIDE{1'b0}} : FIFO[rd_addr];
end

assign empty = (count == '0);
assign full  = (count == FIFO_DEPT);

endmodule



