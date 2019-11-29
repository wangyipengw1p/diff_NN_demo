/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191129

Modify:

Notes:
1. 

TODO:
=========================================================*/
import diff_core_pkg::*;
module core_top_ctrl(
    input  logic clk,
    input  logic rst_n,
    // std ctrl
    output logic core_ready,
    input  logic core_valid,
    output logic core_finish,
    // signals from outside core
    input  logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0] fm_buf_addr_i,
    input  logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0] wt_buf_addr_i,
    input  logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0] bias_buf_addr_i,
    input  logic                                     fm_buf_wr_en_i,
    input  logic                                     wt_buf_wr_en_i,
    input  logic                                     bias_buf_wr_en_i,
    input  logic [CONF_DDR_ADDR_WIDTH - 1 : 0]       stream_data_i,
    // for PE matrix
    output logic [CONF_PE_COL - 1 : 0]                                      PE_col_ctrl_valid,
    input  logic [CONF_PE_COL - 1 : 0]                                      PE_col_ctrl_ready,
    input  logic [CONF_PE_COL - 1 : 0]                                      PE_col_ctrl_finish,
    output logic [CONF_PE_COL - 1 : 0]                                      bit_mode,             
    output logic [CONF_PE_COL - 1 : 0]                                      kernal_mode,
    output logic [5 : 0][CONF_PE_COL - 1 : 0]                               guard_map,
    output logic [CONF_PE_COL - 1 : 0]                                      is_odd_row,
    output logic [CONF_PE_COL - 1 : 0]                                      end_of_row,
    output logic [25 * 8 - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0] weight,
    output logic [7 : 0][CONF_PE_COL - 1 : 0]                               activation,
    input  logic [CONF_PE_COL - 1 : 0]                                      activation_en,   
    output logic [7 : 0][5 : 0][CONF_PE_ROW - 1 : 0]                        bias_i,
    input  logic [CONF_PE_ROW - 1 : 0]                                      bias_en_o, 
    input  logic [7 : 0][CONF_PE_ROW - 1 : 0]                               fm_write_back_data,      
    output logic        [CONF_PE_ROW - 1 : 0]                               fm_buf_ready,              
    input  logic        [CONF_PE_ROW - 1 : 0]                               fm_write_back_data_o_valid,
    input  logic [5 : 0][CONF_PE_ROW - 1 : 0]                               guard_o,                
    output logic        [CONF_PE_ROW - 1 : 0]                               guard_buf_ready,        
    input  logic        [CONF_PE_ROW - 1 : 0]                               guard_o_valid,
    // for fm buf
    output logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                      fm_wr_addr,
    output logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                      fm_rd_addr,
    output logic [7 : 0][CONF_PE_COL - 1 : 0]                                                  fm_din,
    input  logic [7 : 0][CONF_PE_COL - 1 : 0]                                                  fm_dout,
    output logic [CONF_PE_COL - 1 : 0]                                                         fm_rd_en,          
    output logic [CONF_PE_COL - 1 : 0]                                                         fm_wr_en,          
    output logic [CONF_PE_COL - 1 : 0]                                                         fm_ping_pong,
    // for guard buf
    output logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                   gd_rd_addr,
    output logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                   gd_wr_addr,
    input  logic [5 : 0][CONF_PE_COL - 1 : 0]                                                  gd_dout,
    output logic [5 : 0][CONF_PE_COL - 1 : 0]                                                  gd_din,
    output logic [CONF_PE_COL - 1 : 0]                                                         gd_rd_en,          
    output logic [CONF_PE_COL - 1 : 0]                                                         gd_wr_en,          
    output logic [CONF_PE_COL - 1 : 0]                                                         gd_ping_pong,
    // for weight buf 
    output logic [$clog2(CONF_WT_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0] wt_rd_addr,
    output logic [$clog2(CONF_WT_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0] wt_wr_addr,
    input  logic [5 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                             wt_dout,
    output logic [5 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                             wt_din,
    output logic [CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                                    wt_rd_en,          
    output logic [CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                                    wt_wr_en,          
    // for bias buf
    output logic [$clog2(CONF_BIAS_BUF_DEPTH) - 1 : 0][CONF_PE_ROW - 1 : 0]                    bias_rd_addr,
    output logic [$clog2(CONF_BIAS_BUF_DEPTH) - 1 : 0][CONF_PE_ROW - 1 : 0]                    bias_wr_addr,
    input  logic [5 : 0][CONF_PE_ROW - 1 : 0]                                                  bias_dout,
    output logic [5 : 0][CONF_PE_ROW - 1 : 0]                                                  bias_din,
    output logic [CONF_PE_ROW - 1 : 0]                                                         bias_rd_en,          
    output logic [CONF_PE_ROW - 1 : 0]                                                         bias_wr_en           
);

endmodule