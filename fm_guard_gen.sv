/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191126

Modify:

Notes:
1. 

TODO:
? 32 bit -> 8 bit ?
=========================================================*/
`include "diff_core_pkg.sv"
module fm_guard_gen(
    input  logic clk,
    input  logic rst_n,
    //
    input  logic                             valid,
    output logic                             ready,
    output logic                             finish,
    input  logic [7:0] w_num_i,    //less bit?
    input  logic [7:0] h_num_i,
    input  logic [7:0] c_num_i ,
    input  logic kernal_mode_i,
    input  logic bit_mode_i,
    //
    input  logic psum_almost_valid,
    input  logic [3 * 6 * PSUM_WIDTH - 1 : 0 ] psum_ans_i,
    //
    output logic fm_buf_wr_en_o,
    output logic fm_buf_wr_addr_o,
    output logic [7 : 0]    fm_buf_data_o
);
// - stream protcal ------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        ready  <= 1;
    end else begin
        if (valid && ready)     ready <= 0;
        if (finish && !ready)   ready <= 1;
    end
// - data reg and counter -------------------------------------------------------
logic [7:0] w_num;
logic [7:0] h_num;
logic [7:0] c_num;
logic kernal_mode;
logic bit_mode;
logic [7:0] count_w;
logic [7:0] count_h;
logic [7:0] count_c;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)
        { 
            w_num,
            h_num,
            c_num,
            kernal_mode,
            bit_mode
        } <= '0;
    else if (ready && valid) begin
        w_num           <= w_num_i; 
        h_num           <= h_num_i;
        c_num           <= c_num_i;
        kernal_mode     <= kernal_mode_i;
        bit_mode        <= bit_mode_i;
    end

always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        { 
            count_w,
            count_h,
            count_c,
        } <= '0;
    end else begin
        if (ready && valid) begin
            count_w     <= w_num_i; 
            count_h     <= h_num_i;
            count_c     <= c_num_i;
        end else if(psum_almost_valid)begin
            if(count_w == 0) count_w <= w_num;
            else  count_w--;
            if(count_w == 0 && count_h == 0) count_h <= h_num;
            else if(count_w == 0) count_h--;
            if (count_w == 0 && count_h == 0) count_c --;
        end
    end
// - buffer --------------------------------------------------
logic [$clog2(FM_GUARD_GEN_BUF_DEPTH) - 1 : 0] buf_addr;
//logic [$clog2(FM_GUARD_GEN_BUF_DEPTH) - 1 : 0] buf_rd_addr;
logic [3*8*PSUM_WIDTH - 1 : 0] buf_data_out_1, buf_data_out_2;
logic buf_wr_en;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) buf_wr_en <= 0;
    else buf_wr_en <= psum_almost_valid;

two_port_mem #(
    .BIT_LENGTH(3*6*PSUM_WIDTH),
    .DRPTH(FM_GUARD_GEN_BUF_DEPTH)
) mem1 (
    .clka       (clk),
    .clkb       (clk),
    .addra      (buf_addr),
    .addrb      (buf_addr),
    .dina       (psum_ans_i),
    .wea        (~buf_rd_addr[0]),
    .ena        ('1),
    .enb        (psum_almost_valid),
    .doutb      (buf_data_out_1)
);
two_port_mem #(
    .BIT_LENGTH(3*6*PSUM_WIDTH),
    .DRPTH(FM_GUARD_GEN_BUF_DEPTH)
) mem2 (
    .clka       (clk),
    .clkb       (clk),
    .addra      (buf_addr),
    .addrb      (buf_addr),
    .dina       (psum_ans_i),
    .wea        (buf_rd_addr[0]),
    .ena        ('1),
    .enb        (psum_almost_valid),
    .doutb      (buf_data_out_2)
);
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        {
            buf_wr_addr,
            buf_wr_en,
        }<= '0;
    else if (psum_almost_valid)begin
        if (buf_rd_addr == w_num) buf_rd_addr <= 1;
        else buf_rd_addr++;
    end

endmodule
