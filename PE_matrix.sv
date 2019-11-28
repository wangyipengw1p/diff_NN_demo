/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191127

Modify:

Notes:
1. 4-bit mode is implemented as full dense activation

TODO:
adder tree
reduce redundant logic
=========================================================*/
`include "diff_core_pkg.sv"
module PE_matrix(
    input  logic                                                                clk,
    input  logic                                                                rst_n,
    //                          
    input  logic [CONF_PE_COL - 1 : 0]                                          PE_col_ctrl_valid,
    output logic [CONF_PE_COL - 1 : 0]                                          PE_col_ctrl_ready,
    output logic [CONF_PE_COL - 1 : 0]                                          PE_col_ctrl_finish,
    input  logic [CONF_PE_COL - 1 : 0]                                          bit_mode_i,             //0: normal 8-bit  1: 2-4bit, no reg
    input  logic [CONF_PE_COL - 1 : 0]                                          kernal_mode_i,
    input  logic [5 : 0][CONF_PE_COL - 1 : 0]                                   guard_map_i,
    input  logic [CONF_PE_COL - 1 : 0]                                          is_odd_row_i,
    input  logic [CONF_PE_COL - 1 : 0]                                          end_of_row_i,
    input  logic [25 * 8 - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]     weight_i,
    //
    input  logic [7 : 0][CONF_PE_COL - 1 : 0]                                   activation_i,
    output logic [CONF_PE_COL - 1 : 0]                                          activation_en_o,
    //
    output logic        [CONF_PE_ROW - 1 : 0]                                   write_back_ready,       
    output logic [7 : 0][CONF_PE_ROW - 1 : 0]                                   write_back_data_o,      
    input  logic        [CONF_PE_ROW - 1 : 0]                                   fm_buf_ready,           
    output logic        [CONF_PE_ROW - 1 : 0]                                   write_back_data_o_valid,
    output logic [5 : 0][CONF_PE_ROW - 1 : 0]                                   guard_o,                
    input  logic        [CONF_PE_ROW - 1 : 0]                                   guard_buf_ready,        
    output logic        [CONF_PE_ROW - 1 : 0]                                   guard_o_valid          
);

// - ctrl - for each collum ---------------------------------------------------------------------
// the following generate if for a collum
logic [CONF_PE_COL - 1 : 0] connect_PE_col_ctrl_finish;
PE_state_t                  connect_state       [CONF_PE_COL - 1 : 0];
PE_weight_mode_t            connect_weight_mode [CONF_PE_COL - 1 : 0];
logic [CONF_PE_COL - 1 : 0] connect_end_of_row;
always_comb PE_col_ctrl_finish = connect_PE_col_ctrl_finish;
generate
    for(j = CONF_PE_COL - 1; j >= 0; j--)begin:inst_col_ctrl
    PE_col_ctrl inst_PE_col_ctrl(
        .*,
        .valid             (PE_col_ctrl_valid[j]),
        .ready             (PE_col_ctrl_ready[j]),
        .finish            (connect_PE_col_ctrl_finish),
        .bit_mode_i        (bit_mode_i   [j]),        
        .kernal_mode_i     (kernal_mode_i[j]),        
        .guard_map_i       (guard_map_i  [j]),        
        .is_odd_row_i      (is_odd_row_i [j]),        
        .end_of_row_i      (end_of_row_i [j]),        
        .state             (connect_state[j]),        
        .weight_mode       (connect_weight_mode[j]),        
        .end_of_row        (connect_end_of_row[j]),    
        .activation_en_o   (activation_en_o)            
    );
    end
endgenerate

// - PEs and adder tree ----------------------------------------------------------------
logic [PSUM_WIDTH - 1 : 0][CONF_PE_ROW - 1 : 0] psum_ans;
logic [CONF_PE_ROW - 1 : 0] psum_almost_valid;
// generate COL * ROW of PE
generate
    for(i = CONF_PE_ROW - 1; i >= 0; i--)begin:inst_matrix
        logic                           fifo_rd_en;
        logic [CONF_PE_COL - 1 : 0]     fifo_empty;
        logic [CONF_PE_COL - 1 : 0]     fifo_full;
        logic [3*6*PSUM_WIDTH - 1 : 0]  psum_tmp;
        always_comb fifo_rd_en = ~|fifo_empty;                      // && psum gen ready
        for(j = CONF_PE_COL - 1; j >= 0; j--)begin:inst_row
            logic [3*6*PSUM_WIDTH - 1:0] fifo_dout;
            PE inst_PE(
                .*,
                .state          (connect_state[j]),
                .weight_mode    (connect_weight_mode[j]),
                .finish_i       (connect_PE_col_ctrl_finish[j]),
                .end_of_row     (connect_end_of_row[j]),
                .weight_i       (weight_i[i][j]), 
                .activation_i   (activation_i[j]),
                .fifo_rd_en_o   (fifo_rd_en),
                .fifo_dout_o    (fifo_dout),
                .fifo_empty_o   (fifo_empty[j]),
                .fifo_full_o    (fifo_full[j])
            );
            always_comb psum_tmp = psum_tmp + fifo_dout;                //could be optimised for less logic;       adder tree? ok here?
        end

        always_comb psum_ans[i] = psum_tmp;
        always_comb psum_almost_valid[i] = fifo_rd_en;     //will be valid next clk cycle
    end
endgenerate

// - fm_guard_gen ---------------------------------------------------------------------
logic [7:0]  connect_w_num;
logic [7:0]  connect_h_num;
logic [7:0]  connect_c_num;
logic        connect_kernal_mode;
logic        connect_bit_mode;
logic [7:0]  connect_count_w;
logic [7:0]  connect_count_h;
logic [7:0]  connect_count_c;
logic        connect_tick_tock;
logic        connect_is_even_even_row;
logic [1:0]  connect_count_3;
// fm_guard_gen_col_control
fm_guard_gen_ctrl inst_fm_guard_gen_ctrl(
    .*,
    .ctrl_valid       (fm_guard_gen_ctrl_valid),      //add in top
    .ctrl_ready       (fm_guard_gen_ctrl_ready),      
    .ctrl_finish      (fm_guard_gen_ctrl_finidh),          
    .w_num_i          (fm_guard_gen_ctrl_),          
    .h_num_i          (fm_guard_gen_ctrl_),      
    .c_num_i          (fm_guard_gen_ctrl_),      
    .kernal_mode_i    (fm_guard_gen_ctrl_),          
    .bit_mode_i       (fm_guard_gen_ctrl_),     
    .psum_almost_valid(psum_almost_valid[CONF_PE_ROW - 1]),
    .w_num            (connect_w_num),  
    .h_num            (connect_h_num),  
    .c_num            (connect_c_num),  
    .kernal_mode      (connect_kernal_mode),          
    .bit_mode         (connect_bit_mode),      
    .count_w          (connect_count_w),      
    .count_h          (connect_count_h),      
    .count_c          (connect_count_c),      
    .tick_tock        (connect_tick_tock),          
    .is_even_even_row (connect_is_even_even_row),              
    .count_3          (connect_count_3)     
);
//generate fm_guard_gen per row
generate
    for(i = CONF_PE_ROW - 1; i >= 0; i--)begin:fm_guard_gen_per_row
        fm_guard_gen inst_fm_guard_gen(
            .w_num                    (connect_w_num), 
            .h_num                    (connect_h_num), 
            .c_num                    (connect_c_num), 
            .kernal_mode              (connect_kernal_mode),         
            .bit_mode                 (connect_bit_mode),     
            .count_w                  (connect_count_w),     
            .count_h                  (connect_count_h),     
            .count_c                  (connect_count_c),     
            .tick_tock                (connect_tick_tock),                     
            .is_even_even_row         (connect_is_even_even_row),             
            .count_3                  (connect_count_3),     
            .psum_almost_valid        (psum_almost_valid[i]),             
            .psum_ans_i               (psum_ans[i]),     
            .write_back_ready         (write_back_ready[i]),             
            .write_back_data_o        (write_back_data_o[i]),             
            .fm_buf_ready             (fm_buf_ready[i]),                 
            .write_back_data_o_valid  (write_back_data_o_valid[i]),                     
            .guard_o                  (guard_o[i]),     
            .guard_buf_ready          (guard_buf_ready[i]),             
            .guard_o_valid            (guard_o_valid[i])
        );       
    end
endgenerate
endmodule