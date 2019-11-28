/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191127

Modify:

Notes:
1. 

TODO:
=========================================================*/
`include "diff_core_pkg.sv"
module fm_guard_gen_ctrl(
    input  logic        clk,
    input  logic        rst_n,
    //
    input  logic        ctrl_valid,
    output logic        ctrl_ready,
    output logic        ctrl_finish,
    input  logic [7:0]  w_num_i,            //less bit?
    input  logic [7:0]  h_num_i,
    input  logic [7:0]  c_num_i ,
    input  logic        kernal_mode_i,
    input  logic        bit_mode_i,
    //
    output logic [7:0]  w_num,
    output logic [7:0]  h_num,
    output logic [7:0]  c_num,
    output logic        kernal_mode,
    output logic        bit_mode,
    output logic [7:0]  count_w,
    output logic [7:0]  count_h,
    output logic [7:0]  count_c,
    output logic        tick_tock,        //distinguish odd and even lines
    output logic        is_even_even_row,
    output logic [1:0]  count_3
),
// - ctrl and reg ---------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        ctrl_ready  <= 1;
        ctrl_finish <= 0;
    end else begin
        ctrl_finish <= 0;
        if (ctrl_valid && ctrl_ready)     ctrl_ready <= 0;
        if (ctrl_finish && !ctrl_ready)   ctrl_ready <= 1;
        if (count_w == 0 && count_h == 0 && count_c == 0) ctrl_finish <= 1;
    end
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)
        { 
            w_num,
            h_num,
            c_num,
            kernal_mode,
            bit_mode
        } <= '0;
    else if (ctrl_ready && ctrl_valid) begin
        w_num           <= w_num_i; 
        h_num           <= h_num_i;
        c_num           <= c_num_i;
        kernal_mode     <= kernal_mode_i;
        bit_mode        <= bit_mode_i;
    end
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) psum_valid <= 0;
    else psum_valid <= psum_almost_valid;
// - counter for local ctrl ---------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        { 
            count_w,
            count_h,
            count_c,
            tick_tock,
            count_3,
            is_even_even_row
        } <= '0;
    end else begin
        if (ctrl_ready && ctrl_valid) begin
            count_w     <= w_num_i; 
            count_h     <= h_num_i;
            count_c     <= c_num_i;
            tick_tock   <= 0;
            count_3     <= '0;
        end else if(psum_almost_valid)begin
            if (count_w == 0 && count_h == 0 && count_c == 2) begin
                count_c --;
                count_h <= h_num;
            end else if(count_w == 0 && count_h == 0) begin
                count_c --;
                count_h <= h_num;
            end else if (count_w == 0) begin
                count_w <= w_num;
                tick_tock ++;
                if(tick_tock) is_even_even_row ++;
                if(kernal_mode && tick_tock || !kernal_mode) begin
                    count_3  <= count_3 == 2'd2 ? '0 : count_3 + 1;
                end
            end else 
                count_w --;
        end
    end

endmodule