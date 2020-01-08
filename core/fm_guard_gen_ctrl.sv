/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191128

Modify:

Notes:
1. 

TODO:
=========================================================*/
import diff_demo_pkg::*;
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
    input  logic [7:0]  co_num_i ,
    input  logic        kernel_mode_i,
    input  logic        bit_mode_i,
    input  logic        is_diff_i,
    input  logic        is_first_i,
    //
    input  logic        psum_almost_valid,
    //
    output logic        running,
    output logic [7:0]  w_num,
    output logic [7:0]  h_num,
    output logic [7:0]  c_num,
    output logic        kernel_mode,
    output logic        bit_mode,
    output logic [7:0]  count_w,
    output logic [7:0]  count_h,
    output logic [7:0]  count_c,
    output logic        is_even_row,        //distinguish odd and even lines
    output logic        is_even_even_row,
    output logic        is_diff,
    output logic        is_first,
    output logic [1:0]  count_3
);
// - ctrl and reg ---------------------------------------------------------
logic [7:0]  co_num, count_co;
logic tick_tock;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        ctrl_ready  <= 1;
        ctrl_finish <= 0;
    end else begin
        ctrl_finish <= 0;
        if (ctrl_valid && ctrl_ready)     ctrl_ready <= 0;
        if (ctrl_finish && !ctrl_ready)   ctrl_ready <= 1;
        if (count_w < (kernel_mode ? 12 : 6) && count_h == 0 && count_c < (bit_mode ? 2*CONF_PE_COL : CONF_PE_COL) && !ctrl_ready && count_co < CONF_PE_ROW && tick_tock && psum_almost_valid) ctrl_finish <= 1; //[co!4]
    end
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)
        { 
            w_num,
            h_num,
            c_num,
            co_num,
            kernel_mode,
            //bit_mode,
            is_diff,
            is_first
        } <= '0;
    else if (ctrl_ready && ctrl_valid) begin
        w_num           <= w_num_i;         
        h_num           <= h_num_i;
        c_num           <= c_num_i;
        co_num          <= co_num_i;
        //bit_mode        <= bit_mode_i;
        is_diff         <= is_diff_i;
        is_first         <= is_first_i;
        kernel_mode     <= kernel_mode_i;
    end
always_comb running = ~ctrl_ready;
// - counter for local ctrl ---------------------------------------------------------
logic fin_a_row;
always_comb fin_a_row = (kernel_mode && count_w < 12) || (!kernel_mode && count_w < 6);
always_comb bit_mode = is_diff ? tick_tock : 0;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        { 
            count_w,
            count_h,
            count_c,
            count_co,
            is_even_row,
            tick_tock,
            count_3,
            is_even_even_row
        } <= '0;
    end else begin
        if (ctrl_ready && ctrl_valid) begin
            count_w     <= w_num_i - 1; 
            count_h     <= h_num_i - 1;
            count_c     <= c_num_i - 1;         //                   !!special here for COL is 4, if not consider other logic
            count_co    <= co_num_i - 1;
            is_even_row <= 0;
            count_3     <= '0;
            tick_tock    <= is_diff_i ? 0 : 1;
        end else  if(ctrl_ready){
            count_w, count_h, count_c, count_co
        } <= '0;
        else if(psum_almost_valid)begin
            if(fin_a_row && count_h == 0) begin
                if(count_c < (bit_mode ? 2*CONF_PE_COL : CONF_PE_COL)) begin
                    count_c <= c_num - 1;
                end else count_c <= count_c - (bit_mode ? 2*CONF_PE_COL : CONF_PE_COL);
                count_h <= h_num - 1;
                count_w <= w_num - 1;
            end else if (fin_a_row) begin
                count_w <= w_num - 1;       // avoid negetive value             !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                count_h <= count_h - 1;
                is_even_row <= is_even_row + 1;
                if(is_even_row) is_even_even_row <= is_even_even_row + 1;
                if(kernel_mode && is_even_row || !kernel_mode) begin
                    count_3  <= count_3 == 2'd2 ? '0 : count_3 + 1;
                end
            end else 
                count_w <= kernel_mode ?  count_w - 12 : count_w - 6;           // 
            // co logic
            if (count_w < (kernel_mode ? 12 : 6) && count_h == 0 && count_c < (bit_mode ? 2*CONF_PE_COL : CONF_PE_COL) && !ctrl_ready && count_co < CONF_PE_ROW && psum_almost_valid) begin
                tick_tock <= 1;
                count_co <= co_num - 1;
            end else if (count_w < (kernel_mode ? 12 : 6) && count_h == 0 && count_c < (bit_mode ? 2*CONF_PE_COL : CONF_PE_COL))count_co <= count_co - CONF_PE_ROW;//[co!4]
        end
    end
endmodule