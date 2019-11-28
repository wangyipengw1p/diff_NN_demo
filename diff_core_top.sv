/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191128

Modify:

Notes:
1. 

TODO:
=========================================================*/
`include "diff_core_pkg.sv"
module diff_core_top(
    input  logic                            clk,
    input  logic                            rst_n,
    //                          
    output logic                            core_ready,
    input  logic                            core_valid,
    output logic                            core_finish
);
PE_matrix inst_PE_matrix(
    .*,
    .PE_col_ctrl_valid         (),         
    .PE_col_ctrl_ready         (),         
    .PE_col_ctrl_finish        (),         
    .bit_mode_i                (),             
    .kernal_mode_i             (),     
    .guard_map_i               (),     
    .is_odd_row_i              (),     
    .end_of_row_i              (),     
    .weight_i                  (), 
    .activation_i              (),     
    .activation_en_o           (),         
    .write_back_ready          (),             
    .write_back_data_o         (),             
    .fm_buf_ready              (),             
    .write_back_data_o_valid   (),                 
    .guard_o                   (),             
    .guard_buf_ready           (),             
    .guard_o_valid             ()     
); 
generate 
    for(j = CONF_PE_COL - 1; j >= 0; j--) begin:gen_fm_guard
        ping_pong_buffer #(
            .BIT_LENGTH(8),
            .DEPTH(CONF_FM_BUF_DEPTH)
        )fm_buf(
            .clka           (clk),
            .clkb           (clk),
            .addra          (),
            .addrb          (),
            .dina           (),
            .wea            (),
            .ena            (),
            .enb            (),
            .doutb          (),
            .ping_pong      ()
        );
        ping_pong_buffer #(
            .BIT_LENGTH(6),
            .DEPTH(CONF_GUARD_BUF_DEPTH)
        )guard_buf(
            .clka           (clk),
            .clkb           (clk),
            .addra          (),
            .addrb          (),
            .dina           (),
            .wea            (),
            .ena            (),
            .enb            (),
            .doutb          (),
            .ping_pong      ()
        );
    end
endgenerate
generate 
    for(i = CONF_PE_ROW - 1; i >= 0; i--) begin:gen_wt
        for(j = CONF_PE_COL - 1; j >= 0; j--) begin:gen_wt_line
            two_port_mem #(
                .BIT_LENGTH(25 * 8),
                .DEPTH(CONF_GUARD_BUF_DEPTH)
            )wt_buf(

            );
        end
    end
endgenerate
endmodule