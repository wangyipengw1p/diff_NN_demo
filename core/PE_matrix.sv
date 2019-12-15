/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191127

Modify:

Notes:
1. 4-bit mode is implemented as full dense activation

TODO:
adder tree
weight en
reduce redundant logic

=========================================================*/
import diff_demo_pkg::*;
module PE_matrix(
    input  logic                                        clk,
    input  logic                                        rst_n,
    //                          
    input  logic [CONF_PE_COL - 1 : 0]                  PE_col_ctrl_valid,
    output logic [CONF_PE_COL - 1 : 0]                  PE_col_ctrl_ready,
    output logic [CONF_PE_COL - 1 : 0]                  PE_col_ctrl_finish,
    input  logic                                        fm_guard_gen_ctrl_valid,
    output logic                                        fm_guard_gen_ctrl_ready,
    output logic                                        fm_guard_gen_ctrl_finish,
    input  logic [7 : 0 ]                               w_num_i,
    input  logic [7 : 0 ]                               h_num_i,
    input  logic [7 : 0 ]                               c_num_i,
    input  logic                                        bit_mode_i,             //0: normal 8-bit  1: 2-4bit, no reg
    input  logic                                        kernel_mode_i,   
    input  logic                                        is_diff_i,
    input  logic                                        is_first_i,
    input  logic [CONF_PE_COL - 1 : 0]                  is_odd_row_i,
    input  logic [CONF_PE_COL - 1 : 0]                  end_of_row_i, 
    //
    input  logic [CONF_PE_COL - 1 : 0][7 : 0]           activation_i,
    output logic [CONF_PE_COL - 1 : 0]                  activation_en_o,
    input  logic [CONF_PE_COL - 1 : 0][5 : 0]           guard_map_i,
    //
    input  logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0][25 * 8 - 1 : 0]  weight_i,
    input  logic [CONF_PE_ROW - 1 : 0][5 : 0][7 : 0]                         bias_i,
    //     
    output logic [CONF_PE_ROW - 1 : 0]                  write_back_finish,
    output logic [CONF_PE_ROW - 1 : 0][7 : 0]           write_back_data_o,      
    input  logic [CONF_PE_ROW - 1 : 0]                  fm_buf_ready,           
    output logic [CONF_PE_ROW - 1 : 0]                  write_back_data_o_valid,
    output logic [CONF_PE_ROW - 1 : 0][5 : 0]           guard_o,                
    input  logic [CONF_PE_ROW - 1 : 0]                  guard_buf_ready,        
    output logic [CONF_PE_ROW - 1 : 0]                  guard_o_valid          
);
genvar i, j, k;
// - ctrl - for each column ---------------------------------------------------------------------
// the following generate if for a column
logic [CONF_PE_COL - 1 : 0] connect_PE_col_ctrl_finish;
(*DONT_TOUCH = "true"*)PE_state_t                  connect_state       [CONF_PE_COL - 1 : 0];
(*DONT_TOUCH = "true"*)PE_weight_mode_t            connect_weight_mode [CONF_PE_COL - 1 : 0];
logic [CONF_PE_COL - 1 : 0] connect_end_of_row;
logic [CONF_PE_COL - 1 : 0] connect_bit_mode;
logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0] fifo_full;
always_comb PE_col_ctrl_finish = connect_PE_col_ctrl_finish;
generate
    for(j = CONF_PE_COL - 1; j >= 0; j--)begin:inst_col_ctrl
    PE_col_ctrl inst_PE_col_ctrl(
        .*,
        .ctrl_valid        (PE_col_ctrl_valid[j]),
        .ctrl_ready        (PE_col_ctrl_ready[j]),
        .ctrl_finish       (connect_PE_col_ctrl_finish[j]),
        .bit_mode_i        (bit_mode_i),        
        .kernel_mode_i     (kernel_mode_i),        
        .guard_map_i       (guard_map_i  [j]),        
        .is_odd_row_i      (is_odd_row_i [j]),        
        .end_of_row_i      (end_of_row_i [j]),   
        .fifo_full         (fifo_full[CONF_PE_ROW - 1][j]),             //only the first row of fifo full is connected;
        .state             (connect_state[j]),        
        .weight_mode       (connect_weight_mode[j]),        
        .end_of_row        (connect_end_of_row[j]), 
        .bit_mode          (connect_bit_mode[j]),   
        .activation_en_o   (activation_en_o[j])            
    );
    end
endgenerate

// - PEs and adder tree ----------------------------------------------------------------
logic [CONF_PE_ROW - 1 : 0][3*6*PSUM_WIDTH - 1 : 0] psum_ans;
logic [CONF_PE_ROW - 1 : 0] psum_almost_valid;
// generate COL * ROW of PE
generate
    for(i = CONF_PE_ROW - 1; i >= 0; i--)begin:inst_matrix
        logic                           fifo_rd_en;
        logic [CONF_PE_COL - 1 : 0]     fifo_empty;
        //logic [CONF_PE_COL - 1 : 0]     fifo_full;
        always_comb fifo_rd_en = ~|fifo_empty;                      // && psum gen ready
        for(j = CONF_PE_COL - 1; j >= 0; j--)begin:inst_row
            logic [3*6*PSUM_WIDTH - 1:0] fifo_dout;
            PE inst_PE(
                .*,
                .state          (connect_state[j]),
                .weight_mode    (connect_weight_mode[j]),
                .finish         (connect_PE_col_ctrl_finish[j]),
                .end_of_row     (connect_end_of_row[j]),
                .weight_i       (weight_i[i][j]), 
                .activation_i   (activation_i[j]),
                .bit_mode       (connect_bit_mode[j]),
                .fifo_rd_en_o   (fifo_rd_en),
                .fifo_dout_o    (fifo_dout),
                .fifo_empty_o   (fifo_empty[j]),
                .fifo_full_o    (fifo_full[i][j])
            );
        end
        // adder tree
        logic [17 : 0][CONF_PE_COL*PSUM_WIDTH - 1 : 0] to_add;
        for(k = 17; k >= 0; k--)begin:gen_18_adder_tree      //3*6 adder
            for(genvar m = CONF_PE_COL - 1; m >= 0; m--)begin:trans_to_add_matrix   //comb transform
                always_comb to_add[k][m] = inst_row[m].fifo_dout[(k+1)*PSUM_WIDTH - 1 -: PSUM_WIDTH];
            end
            adder_tree #(
                .IN_WIDTH(PSUM_WIDTH),
                .NUM(CONF_PE_COL),
                .OUT_WIDTH(PSUM_WIDTH)
            ) inst_adder_tree(
                .a(to_add[k]),
                .ans(psum_ans[i][(k+1)*PSUM_WIDTH - 1 -: PSUM_WIDTH])
            );
        end
        always_comb psum_almost_valid[i] = fifo_rd_en;     //will be valid next clk cycle
    end
endgenerate

// - fm_guard_gen ---------------------------------------------------------------------
logic [7:0]  connect_w_num;
logic [7:0]  connect_h_num;
logic [7:0]  connect_c_num;
logic        connect_kernel_mode;
logic [7:0]  connect_count_w;
logic [7:0]  connect_count_h;
logic [7:0]  connect_count_c;
logic        connect_is_even_row;
logic        connect_is_diff;
logic        connect_is_first;
logic        con_bit_mode;
logic        connect_is_even_even_row;
logic [1:0]  connect_count_3;
// fm_guard_gen_col_control
fm_guard_gen_ctrl inst_fm_guard_gen_ctrl(
    .*,
    .ctrl_valid       (fm_guard_gen_ctrl_valid),      //add in top
    .ctrl_ready       (fm_guard_gen_ctrl_ready),      
    .ctrl_finish      (fm_guard_gen_ctrl_finish),          
    .w_num_i          (w_num_i),          
    .h_num_i          (h_num_i),      
    .c_num_i          (c_num_i),      
    .kernel_mode_i    (kernel_mode_i),          
    .bit_mode_i       (bit_mode_i), 
    .is_diff_i        (is_diff_i),    
    .is_first_i (is_first_i),
    .psum_almost_valid(psum_almost_valid[CONF_PE_ROW - 1]),
    .w_num            (connect_w_num),  
    .h_num            (connect_h_num),  
    .c_num            (connect_c_num),  
    .is_diff          (connect_is_diff),
    .is_first         (connect_is_first),
    .kernel_mode      (connect_kernel_mode),          
    .bit_mode         (con_bit_mode),      
    .count_w          (connect_count_w),      
    .count_h          (connect_count_h),      
    .count_c          (connect_count_c),      
    .is_even_row      (connect_is_even_row),          
    .is_even_even_row (connect_is_even_even_row),              
    .count_3          (connect_count_3)     
);
//generate fm_guard_gen per row
generate
    for(i = CONF_PE_ROW - 1; i >= 0; i--)begin:fm_guard_gen_per_row
        fm_guard_gen inst_fm_guard_gen(
            .w_num                    (connect_w_num), 
            .h_num                    (connect_h_num), 
            //.c_num                    (connect_c_num), 
            .kernel_mode              (connect_kernel_mode),         
            .bit_mode                 (con_bit_mode),     
            .count_w                  (connect_count_w),     
            .count_h                  (connect_count_h),     
            .count_c                  (connect_count_c),     
            .is_even_row              (connect_is_even_row),                     
            .is_even_even_row         (connect_is_even_even_row),
            .is_first                 (connect_is_first),             
            .count_3                  (connect_count_3),     
            .psum_almost_valid        (psum_almost_valid[i]),             
            .psum_ans_i               (psum_ans[i]),     
            .bias_i                   (bias_i[i]),
            .write_back_finish        (write_back_finish[i]),
            .write_back_data_o        (write_back_data_o[i]),             
            //.fm_buf_ready             (fm_buf_ready[i]),                 
            .write_back_data_o_valid  (write_back_data_o_valid[i]),                     
            .guard_o                  (guard_o[i]),     
            //.guard_buf_ready          (guard_buf_ready[i]),             
            .guard_o_valid            (guard_o_valid[i])
        );       
    end
endgenerate
endmodule