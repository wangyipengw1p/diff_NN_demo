/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191128

Modify:

Notes:
1. 

TODO:
=========================================================*/
import diff_core_pkg::*;
module diff_core_top(
    input  logic                                        clk,
    input  logic                                        rst_n,
    //                                      
    output logic                                        core_ready,
    input  logic                                        core_valid,
    output logic                                        core_finish,
    //
    input  logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]    fm_buf_addr_i,
    input  logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]    wt_buf_addr_i,
    input  logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]    bias_buf_addr_i,
    input  logic                                        fm_buf_wr_en_i,
    input  logic                                        wt_buf_wr_en_i,
    input  logic                                        bias_buf_wr_en_i,
    input  logic [CONF_DDR_ADDR_WIDTH - 1 : 0]          stream_data_i
);
// - signals -----------------!! the same name with the ctrl !!--------------
genvar i, j;
// for PE matrix
logic [CONF_PE_COL - 1 : 0]                                          PE_col_ctrl_valid;
logic [CONF_PE_COL - 1 : 0]                                          PE_col_ctrl_ready;
logic [CONF_PE_COL - 1 : 0]                                          PE_col_ctrl_finish;
logic [CONF_PE_COL - 1 : 0]                                          bit_mode;             
logic [CONF_PE_COL - 1 : 0]                                          kernal_mode;
logic [5 : 0][CONF_PE_COL - 1 : 0]                                   guard_map;
logic [CONF_PE_COL - 1 : 0]                                          is_odd_row;
logic [CONF_PE_COL - 1 : 0]                                          end_of_row;
logic [25 * 8 - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]     weight;
logic [7 : 0][CONF_PE_COL - 1 : 0]                                   activation;
logic [CONF_PE_COL - 1 : 0]                                          activation_en;     
logic [7 : 0][5 : 0][CONF_PE_ROW - 1 : 0]                            bias;
logic [CONF_PE_ROW - 1 : 0]                                          bias_en;
logic [7 : 0][CONF_PE_ROW - 1 : 0]                                   fm_write_back_data;      
logic        [CONF_PE_ROW - 1 : 0]                                   fm_buf_ready;              //ready to be written         
logic        [CONF_PE_ROW - 1 : 0]                                   fm_write_back_data_o_valid;
logic [5 : 0][CONF_PE_ROW - 1 : 0]                                   guard_o;                
logic        [CONF_PE_ROW - 1 : 0]                                   guard_buf_ready;        
logic        [CONF_PE_ROW - 1 : 0]                                   guard_o_valid;
// for fm buf
logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                      fm_wr_addr;
logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                      fm_rd_addr;
logic [7 : 0][CONF_PE_COL - 1 : 0]                                                  fm_din;
logic [7 : 0][CONF_PE_COL - 1 : 0]                                                  fm_dout;
logic [CONF_PE_COL - 1 : 0]                                                         fm_rd_en;         //rd_en for energy save
logic [CONF_PE_COL - 1 : 0]                                                         fm_wr_en;         //rd_en for energy save
logic [CONF_PE_COL - 1 : 0]                                                         fm_ping_pong;
// for guard buf
logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                   gd_rd_addr;
logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                   gd_wr_addr;
logic [5 : 0][CONF_PE_COL - 1 : 0]                                                  gd_dout;
logic [5 : 0][CONF_PE_COL - 1 : 0]                                                  gd_din;
logic [CONF_PE_COL - 1 : 0]                                                         gd_rd_en;         //rd_en for energy save
logic [CONF_PE_COL - 1 : 0]                                                         gd_wr_en;         //rd_en for energy save
logic [CONF_PE_COL - 1 : 0]                                                         gd_ping_pong;
// for weight buf 
logic [$clog2(CONF_WT_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0] wt_rd_addr;
logic [$clog2(CONF_WT_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0] wt_wr_addr;
logic [5 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                             wt_dout;
logic [5 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                             wt_din;
logic [CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                                    wt_rd_en;         //rd_en for energy save
logic [CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                                    wt_wr_en;         //rd_en for energy save
// for bias buf
logic [$clog2(CONF_BIAS_BUF_DEPTH) - 1 : 0][CONF_PE_ROW - 1 : 0]                    bias_rd_addr;
logic [$clog2(CONF_BIAS_BUF_DEPTH) - 1 : 0][CONF_PE_ROW - 1 : 0]                    bias_wr_addr;
logic [5 : 0][CONF_PE_ROW - 1 : 0]                                                  bias_dout;
logic [5 : 0][CONF_PE_ROW - 1 : 0]                                                  bias_din;
logic [CONF_PE_ROW - 1 : 0]                                                         bias_rd_en;         //rd_en for energy save
logic [CONF_PE_ROW - 1 : 0]                                                         bias_wr_en;         //rd_en for energy save

// - instanciation ---------------------------------------------------------------------------------------------------

PE_matrix inst_PE_matrix(
    .*,
    .PE_col_ctrl_valid         (PE_col_ctrl_valid),         
    .PE_col_ctrl_ready         (PE_col_ctrl_ready),         
    .PE_col_ctrl_finish        (PE_col_ctrl_finish),         
    .bit_mode_i                (bit_mode),             
    .kernal_mode_i             (kernal_mode),     
    .guard_map_i               (guard_map),     
    .is_odd_row_i              (is_odd_row),     
    .end_of_row_i              (end_of_row),
    .weight_i                  (weight), 
    .activation_i              (activation),     
    .activation_en_o           (activation_en),
    .bias_i                    (bias),
    .bias_en_o                 (bias_en),
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
            .enb            (fm_rd_en[j]),
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
            .enb            (gd_rd_en[j]),
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
                .addra          (wt_wr_addr[i][j]),
                .addrb          (wt_rd_addr[i][j]),
                .dina           (wt_din[i][j]),
                .wea            (wt_wr_en[i][j]),
                .ena            (1),
                .enb            (wt_wr_en[i][j]),
                .doutb          (wt_dout[i][j])
            );
        end
        two_port_mem #(
                .BIT_LENGTH(6*8),
                .DEPTH(CONF_BIAS_BUF_DEPTH)
        )bias_buf(
            .clka           (clk),
            .clkb           (clk),
            .addra          (bias_wr_addr[i]),
            .addrb          (bias_rd_addr[i]),
            .dina           (bias_din[i]),
            .wea            (bias_wr_en[i]),
            .ena            (1),
            .enb            (bias_rd_en[i]),
            .doutb          (bias_dout[i])
        );
    end
endgenerate

core_top_ctrl inst_core_top_ctrl(
    .*
    /*
    .core_ready,
    .core_valid,
    .core_finish,
    .fm_buf_addr_i,
    .wt_buf_addr_i,
    .bias_buf_addr_i,
    .fm_buf_wr_en_i,
    .wt_buf_wr_en_i,
    .bias_buf_wr_en_i,
    .stream_data_i,
    .PE_col_ctrl_valid,
    .PE_col_ctrl_ready,
    .PE_col_ctrl_finish,
    .bit_mode,             
    .kernal_mode,
    .guard_map,
    .is_odd_row,
    .end_of_row,
    .weight,
    .activation,
    .activation_en,    
    .bias,
    .bias_en, 
    .fm_write_back_data,      
    .fm_buf_ready,              
    .fm_write_back_data_o_valid,
    .guard_o,                
    .guard_buf_ready,        
    .guard_o_valid,
    .fm_wr_addr, 
    .fm_rd_addr,
    .fm_din, 
    .fm_dout,
    .fm_wr_en,
    .fm_rd_en,    
    .fm_ping_pong,
    .gd_wr_addr, 
    .gd_rd_addr,
    .gd_din, 
    .gd_dout,
    .gd_wr_en, 
    .gd_rd_en,     
    .wt_wr_addr, 
    .wt_rd_addr,
    .wt_din,
    .wt_dout,
    .wt_wr_en,
    .wt_rd_en,
    .bias_wr_addr,
    .bias_rd_addr,
    .bias_din,
    .bias_dout,
    .bias_wr_en,
    .bias_rd_en*/    
);

endmodule