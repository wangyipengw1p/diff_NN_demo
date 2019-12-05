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
module diff_core_top(
    input  logic                                                                                clk,
    input  logic                                                                                rst_n,
    //                                                                              
    output logic                                                                                core_ready,
    input  logic                                                                                core_valid,
    output logic                                                                                core_finish,
    input  logic                                                                                core_bit_mode_i,
    input  logic                                                                                core_fm_ping_pong_i,
    //
    input  logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                       load_fm_wr_addr,
    input  logic [7 : 0][CONF_PE_COL - 1 : 0]                                                   load_fm_din,
    input  logic [CONF_PE_COL - 1 : 0]                                                          load_fm_wr_en,         
    input  logic [CONF_PE_COL - 1 : 0]                                                          load_fm_ping_pong,
    input  logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                    load_gd_wr_addr,
    input  logic [5 : 0][CONF_PE_COL - 1 : 0]                                                   load_gd_din,
    input  logic [CONF_PE_COL - 1 : 0]                                                          load_gd_wr_en,         
    input  logic [CONF_PE_COL - 1 : 0]                                                          load_gd_ping_pong,
    //
    input  logic [$clog2(CONF_WT_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]  load_wt_wr_addr,
    input  logic [5 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                              load_wt_din,
    input  logic [CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                                     load_wt_wr_en,         
    input  logic [$clog2(CONF_BIAS_BUF_DEPTH) - 1 : 0][CONF_PE_ROW - 1 : 0]                     load_bias_wr_addr,
    input  logic [5 : 0][CONF_PE_ROW - 1 : 0]                                                   load_bias_din,
    input  logic [CONF_PE_ROW - 1 : 0]                                                          load_bias_wr_en         

);
// - signals -----------------!! the same name with the ctrl !!--------------
genvar i, j;
// for PE matrix
logic [CONF_PE_COL - 1 : 0]                                          PE_col_ctrl_valid;
logic [CONF_PE_COL - 1 : 0]                                          PE_col_ctrl_ready;
logic [CONF_PE_COL - 1 : 0]                                          PE_col_ctrl_finish;
logic                                                                fm_guard_gen_ctrl_valid  ;
logic                                                                fm_guard_gen_ctrl_ready  ;
logic                                                                fm_guard_gen_ctrl_finish ;
logic [7 : 0 ]                                                       w_num;
logic [7 : 0 ]                                                       h_num;
logic [7 : 0 ]                                                       c_num;
logic [CONF_PE_COL - 1 : 0]                                          bit_mode;             
logic [CONF_PE_COL - 1 : 0]                                          kernel_mode;
logic [CONF_PE_COL - 1 : 0]                                          is_odd_row;
logic [CONF_PE_COL - 1 : 0]                                          end_of_row;
logic [7 : 0][CONF_PE_COL - 1 : 0]                                   activation;
logic [CONF_PE_COL - 1 : 0]                                          activation_en;
logic [5 : 0][CONF_PE_COL - 1 : 0]                                   guard_map;     
logic [7 : 0][5 : 0][CONF_PE_ROW - 1 : 0]                            bias;
logic [25 * 8 - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]     weight;
logic        [CONF_PE_ROW - 1 : 0]                                   write_back_finish;
logic [7 : 0][CONF_PE_ROW - 1 : 0]                                   fm_write_back_data;      
logic        [CONF_PE_ROW - 1 : 0]                                   fm_buf_ready;              //ready to be written         
logic        [CONF_PE_ROW - 1 : 0]                                   fm_write_back_data_o_valid;
logic [5 : 0][CONF_PE_ROW - 1 : 0]                                   guard_o;                
logic        [CONF_PE_ROW - 1 : 0]                                   guard_buf_ready;        
logic        [CONF_PE_ROW - 1 : 0]                                   guard_o_valid;
// for fm buf
logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                       fm_wr_addr;
logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                       fm_rd_addr;
logic [7 : 0][CONF_PE_COL - 1 : 0]                                                   fm_din;
logic [7 : 0][CONF_PE_COL - 1 : 0]                                                   fm_dout;
logic [CONF_PE_COL - 1 : 0]                                                          fm_rd_en;     
logic [CONF_PE_COL - 1 : 0]                                                          fm_wr_en;     
logic [CONF_PE_COL - 1 : 0]                                                          fm_ping_pong;
// 
logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                    gd_rd_addr;
logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                    gd_wr_addr;
logic [5 : 0][CONF_PE_COL - 1 : 0]                                                   gd_dout;
logic [5 : 0][CONF_PE_COL - 1 : 0]                                                   gd_din;
logic [CONF_PE_COL - 1 : 0]                                                          gd_rd_en;     
logic [CONF_PE_COL - 1 : 0]                                                          gd_wr_en;     
logic [CONF_PE_COL - 1 : 0]                                                          gd_ping_pong;
// for weight buf 
logic [$clog2(CONF_WT_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0] wt_rd_addr;
logic [5 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                             wt_dout;
logic [CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                                    wt_rd_en;         //rd_en for energy save
// for bias buf
logic [$clog2(CONF_BIAS_BUF_DEPTH) - 1 : 0][CONF_PE_ROW - 1 : 0]                    bias_rd_addr;
logic [5 : 0][CONF_PE_ROW - 1 : 0]                                                  bias_dout;
logic [CONF_PE_ROW - 1 : 0]                                                         bias_rd_en;         //rd_en for energy save

// - instanciation ---------------------------------------------------------------------------------------------------

PE_matrix inst_PE_matrix(
    .*,
    .PE_col_ctrl_valid         (PE_col_ctrl_valid),         
    .PE_col_ctrl_ready         (PE_col_ctrl_ready),         
    .PE_col_ctrl_finish        (PE_col_ctrl_finish), 
    .fm_guard_gen_ctrl_valid   (fm_guard_gen_ctrl_valid),                 
    .fm_guard_gen_ctrl_ready   (fm_guard_gen_ctrl_ready),                 
    .fm_guard_gen_ctrl_finish  (fm_guard_gen_ctrl_finish),                 
    .w_num_i                   (w_num), 
    .h_num_i                   (h_num), 
    .c_num_i                   (c_num),         
    .bit_mode_i                (bit_mode),             
    .kernel_mode_i             (kernel_mode),     
    .is_odd_row_i              (is_odd_row),     
    .end_of_row_i              (end_of_row),
    .activation_i              (activation),     
    .activation_en_o           (activation_en),
    .guard_map_i               (guard_map),
    .weight_i                  (weight),     
    .bias_i                    (bias),
    .write_back_finish         (write_back_finish),
    .write_back_data_o         (fm_write_back_data),             
    .fm_buf_ready              (fm_buf_ready),             
    .write_back_data_o_valid   (fm_write_back_data_o_valid ),                 
    .guard_o                   (guard_o),             
    .guard_buf_ready           (guard_buf_ready),             
    .guard_o_valid             (guard_o_valid )     
); 
generate 
    for(j = CONF_PE_COL - 1; j >= 0; j--) begin:gen_fm_guard
        ping_pong_buffer #(
            .BIT_LENGTH(8),
            .DEPTH(CONF_FM_BUF_DEPTH)
        )fm_buf(
            .clka           (clk),
            .clkb           (clk),
            .addra          (fm_wr_addr[j]),
            .addrb          (fm_rd_addr[j]),
            .dina           (fm_din[j]),
            .wea            (fm_wr_en[j]),
            .ena            (1),
            .enb            (1),
            .doutb          (fm_dout[j]),
            .ping_pong      (fm_ping_pong[j])
        );
        ping_pong_buffer #(
            .BIT_LENGTH(6),
            .DEPTH(CONF_GUARD_BUF_DEPTH)
        )guard_buf(
            .clka           (clk),
            .clkb           (clk),
            .addra          (gd_wr_addr[j]),
            .addrb          (gd_rd_addr[j]),
            .dina           (gd_din[j]),
            .wea            (gd_wr_en[j]),
            .ena            (1),
            .enb            (1),
            .doutb          (gd_dout[j]),
            .ping_pong      (gd_ping_pong[j])
        );
    end
endgenerate
generate 
    for(i = CONF_PE_ROW - 1; i >= 0; i--) begin:gen_wt
        for(j = CONF_PE_COL - 1; j >= 0; j--) begin:gen_wt_line
            two_port_mem #(
                .BIT_LENGTH(25 * 8),
                .DEPTH(CONF_WT_BUF_DEPTH)
            )wt_buf(
                .clka           (clk),
                .clkb           (clk),
                .addra          (load_wt_wr_addr[i][j]),
                .addrb          (wt_rd_addr[i][j]),
                .dina           (load_wt_din[i][j]),
                .wea            (load_wt_wr_en[i][j]),
                .ena            (1),
                .enb            (1),
                .doutb          (wt_dout[i][j])
            );
        end
        two_port_mem #(
                .BIT_LENGTH(6*8),
                .DEPTH(CONF_BIAS_BUF_DEPTH)
        )bias_buf(
            .clka           (clk),
            .clkb           (clk),
            .addra          (load_bias_wr_addr[i]),
            .addrb          (bias_rd_addr[i]),
            .dina           (load_bias_din[i]),
            .wea            (load_bias_wr_en[i]),
            .ena            (1),
            .enb            (1),
            .doutb          (bias_dout[i])
        );
    end
endgenerate

core_top_ctrl inst_core_top_ctrl(
    .*
);

endmodule