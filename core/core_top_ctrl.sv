/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191129

Modify:

Notes:
1. 

TODO:
=========================================================*/
import diff_demo_pkg::*;
module core_top_ctrl(
    input  logic                                                                                clk,
    input  logic                                                                                rst_n,
    // std ctrl                                                                             
    output logic                                                                                core_ready,
    input  logic                                                                                core_valid,
    output logic                                                                                core_finish,
    //input  logic                                                                                core_fm_ping_pong_i,
    //input  logic                                                                                core_bit_mode_i,
    input  logic                                                                                core_is_diff_i,
    // for PE matrix                    
    output logic [CONF_PE_COL - 1 : 0]                                                          PE_col_ctrl_valid,
    input  logic [CONF_PE_COL - 1 : 0]                                                          PE_col_ctrl_ready,
    input  logic [CONF_PE_COL - 1 : 0]                                                          PE_col_ctrl_finish,
    output logic [CONF_PE_COL - 1 : 0]                                                          in_layer_finish_col,
    output logic [CONF_PE_COL - 1 : 0]                                                          in_gate_col,
    output logic                                                                                fm_guard_gen_ctrl_valid  ,
    input  logic                                                                                fm_guard_gen_ctrl_ready  ,
    input  logic                                                                                fm_guard_gen_ctrl_finish ,//no use
    // common 
    output logic                                                                                is_diff,
    // for write back
    output logic [7 : 0 ]                                                                       w_num,
    output logic [7 : 0 ]                                                                       h_num,
    output logic [7 : 0 ]                                                                       c_num,
    output logic [7 : 0 ]                                                                       co_num,
    output logic [7 : 0 ]                                                                       wb_w_num,
    output logic [7 : 0 ]                                                                       wb_w_cut,
    output logic [7 : 0 ]                                                                       wb_h_num,
    output logic                                                                                bit_mode,             
    output logic                                                                                kernel_mode,
    output logic                                                                                is_first,
    output logic                                                                                in_bit_mode,             
    output logic [CONF_PE_COL - 1 : 0]                                                          is_odd_row,
    output logic [CONF_PE_COL - 1 : 0]                                                          end_of_row,
    output logic [CONF_PE_COL - 1 : 0][7 : 0]                                                   activation,
    input  logic [CONF_PE_COL - 1 : 0]                                                          activation_en,//?
    output logic [CONF_PE_COL - 1 : 0][5 : 0]                                                   guard_map,   
    output logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0][25 * 8 - 1 : 0]                     weight,
    output logic [CONF_PE_ROW - 1 : 0][7 : 0]                                                   bias,
    input  logic [CONF_PE_ROW - 1 : 0]                                                          write_back_finish,
    input  logic [CONF_PE_ROW - 1 : 0][7 : 0]                                                   fm_write_back_data,      
    //output logic [CONF_PE_ROW - 1 : 0]                                                          fm_buf_ready,              
    input  logic [CONF_PE_ROW - 1 : 0]                                                          fm_write_back_data_o_valid,
    input  logic [CONF_PE_ROW - 1 : 0][5 : 0]                                                   guard_o,                
    //output logic [CONF_PE_ROW - 1 : 0]                                                          guard_buf_ready,        
    input  logic [CONF_PE_ROW - 1 : 0]                                                          guard_o_valid,
    input  logic [CONF_PE_ROW - 1 : 0]                                                          wb_bit_mode,
    // load from outside core
    input  logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       load_fm_wr_addr,
    input  logic [CONF_PE_COL - 1 : 0][71 : 0]                                                   load_fm_din,
    input  logic [CONF_PE_COL - 1 : 0]                                                          load_fm_wr_en,         //rd_en for energy save
    //input  logic [CONF_PE_COL - 1 : 0]                                                          load_fm_ping_pong,
    input  logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       save_fm_rd_addr,
    output logic [CONF_PE_COL - 1 : 0][71 : 0]                                                  save_fm_dout, 

    input  logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]                    load_gd_wr_addr,
    input  logic [CONF_PE_COL - 1 : 0][71 : 0]                                                   load_gd_din,
    input  logic [CONF_PE_COL - 1 : 0]                                                          load_gd_wr_en,         //rd_en for energy save
    //input  logic [CONF_PE_COL - 1 : 0]                                                          load_gd_ping_pong,      //not used
    // for fm buf
    output logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       fm_wr_addr,
    output logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       fm_rd_addr,
    output logic [CONF_PE_COL - 1 : 0][71 : 0]                                                  fm_din,
    input  logic [CONF_PE_COL - 1 : 0][71 : 0]                                                  fm_dout,
    input  logic [CONF_PE_COL - 1 : 0][71 : 0]                                                  fm_dout_for_4,
    //output logic [CONF_PE_COL - 1 : 0]                                                          fm_rd_en,          
    output logic [CONF_PE_COL - 1 : 0]                                                          fm_wr_en,          
    //output logic [CONF_PE_COL - 1 : 0]                                                          fm_ping_pong,
    // for guard buf    
    output logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]                    gd_rd_addr,
    output logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]                    gd_wr_addr,
    input  logic [CONF_PE_COL - 1 : 0][71 : 0]                                                   gd_dout,
    input  logic [CONF_PE_COL - 1 : 0][71 : 0]                                                   gd_dout_for_4,
    output logic [CONF_PE_COL - 1 : 0][71 : 0]                                                   gd_din,
    //output logic [CONF_PE_COL - 1 : 0]                                                          gd_rd_en,
    output logic [CONF_PE_COL - 1 : 0]                                                          gd_wr_en,
    //output logic [CONF_PE_COL - 1 : 0]                                                          gd_ping_pong,
    // for weight buf   
    output logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0][$clog2(CONF_WT_BUF_DEPTH) - 1 : 0]  wt_rd_addr,
    input  logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0][25*8 - 1 : 0]                       wt_dout,
    //output logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0]                                     wt_rd_en,          
    // for bias buf 
    output logic [CONF_PE_ROW - 1 : 0][$clog2(CONF_BIAS_BUF_DEPTH) - 1 : 0]                     bias_rd_addr,
    input  logic [CONF_PE_ROW - 1 : 0][7 : 0]                                                   bias_dout
    //output logic [CONF_PE_ROW - 1 : 0]                                                          bias_rd_en          
);
genvar i, j;
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       in_fm_rd_addr;
always_comb save_fm_dout = core_ready ? fm_dout : '0;
// - ctrl protcol -----------------------------------------------------
logic in_one_layer_finish, wb_one_layer_finish, wb_one_layer_finish_d, in_finish_all, wb_finish_all;
logic wb_tick_tock, in_tick_tock;                    // for diff
logic [2:0] in_layer_num, wb_layer_num;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        core_ready   <= '1;
        {
            core_finish,
            //core_fm_ping_pong,
            is_diff,
            wb_one_layer_finish_d
        } <= '0;
    end else begin
        core_finish <= '0;
        if (core_valid  && core_ready )begin
            core_ready  <= '0;
            //core_fm_ping_pong <= core_fm_ping_pong_i;
            is_diff <= core_is_diff_i;
        end
        if (core_finish  && !core_ready )   core_ready  <= '1;
        // ctrl finish here
        if (wb_finish_all) core_finish <= '1;

        wb_one_layer_finish_d <= wb_one_layer_finish;
    end
// - state machine -------------------------------------------------------
enum logic [2:0] {IDLE, START, PROCESS, FINISH_ONE_LAYER, FINISH} in_state, next_in_state, wb_state, next_wb_state;        // this state is for in matrix


always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) {in_state, wb_state} <= {IDLE, IDLE};
    else begin
        in_state <= next_in_state;
        wb_state <= next_wb_state;
    end

always_comb begin
    case(in_state)
        IDLE:               next_in_state = core_ready && core_valid ? START : IDLE;
        START:              next_in_state = in_layer_num - wb_layer_num <= 2 ? PROCESS : START;         // in case that wb is too slow, temp useless
        PROCESS:            next_in_state = in_finish_all ? FINISH : in_one_layer_finish ? FINISH_ONE_LAYER  : PROCESS;
        FINISH_ONE_LAYER:   next_in_state = START;
        FINISH:             next_in_state = IDLE;
        default:            next_in_state = IDLE;
    endcase
    case(wb_state)
        IDLE:               next_wb_state = core_ready && core_valid ? START : IDLE;
        START:              next_wb_state = in_layer_num - wb_layer_num <= 2 ? PROCESS : START;
        PROCESS:            next_wb_state = wb_finish_all ? FINISH : wb_one_layer_finish ? FINISH_ONE_LAYER  : PROCESS;
        FINISH_ONE_LAYER:   next_wb_state = START;
        FINISH:             next_wb_state = IDLE;
        default:            next_wb_state = IDLE;
    endcase
end
// - layer and parameters -------------------------------------------------------------

// - finish logic -
always_comb in_finish_all = in_one_layer_finish && in_layer_num == 5 && in_tick_tock;
always_comb wb_finish_all = wb_one_layer_finish && wb_layer_num == 5;                   //wb tick tock is controled by wb module
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) begin
    {
        in_layer_num,
        wb_layer_num,
        wb_tick_tock,               // not used by now
        in_tick_tock
    } <= '0;
    end else begin
        if(core_valid  && core_ready) begin
            in_layer_num <= 3'd1;
            wb_layer_num <= 3'd1;
            wb_tick_tock <= core_is_diff_i ? '0 : '1;                      // 8bit then 4bit for diff mode
            in_tick_tock <= core_is_diff_i ? '0 : '1;                      // 8bit then 4bit for diff mode
        end else if (core_ready) {in_layer_num, wb_layer_num, wb_tick_tock, in_tick_tock} <= '0;
        else begin
            if(in_one_layer_finish && in_tick_tock) in_layer_num <= in_layer_num + 1;
            if(wb_one_layer_finish) wb_layer_num <= wb_layer_num + 1;               //tick tock is controled by write back module
            if(wb_one_layer_finish && is_diff) wb_tick_tock <= ~wb_tick_tock;
            if(in_one_layer_finish && is_diff) in_tick_tock <= ~in_tick_tock;
        end
    end
// hard-coded network parameters, actually could be calculated, but for easy ..................................................................
logic [7:0] wb_co_num;
always_comb begin
    // bit_mode     `
    bit_mode = is_diff ? 1 : 0;
    is_first = 0;                           // will be high for the first layer
    in_bit_mode = is_diff ? in_tick_tock : 0;
    // kernel mode
    case (in_layer_num)
        3'd1:begin
            w_num = 8'd200;     // ceil(200/4)
            h_num = 8'd66;
            c_num = 8'd3;
            co_num= 8'd24;
            kernel_mode = 1;
            is_first = 1;
        end
        3'd2:begin
            w_num = 8'd98;
            h_num = 8'd31;
            c_num = 8'd24;
            co_num= 8'd36;
            kernel_mode = 1;
        end
        3'd3: begin
            w_num = 8'd47;
            h_num = 8'd14;
            c_num = 8'd36;
            co_num= 8'd48;
            kernel_mode = 1;
        end
        3'd4: begin
            w_num = 8'd22;
            h_num = 8'd5;
            c_num = 8'd48;
            co_num= 8'd64;
            kernel_mode = 0;
        end
        3'd5:begin
            w_num = 8'd20;
            h_num = 8'd3;
            c_num = 8'd64;
            co_num= 8'd64;
            kernel_mode = 0;
        end
        default:begin
            w_num = 8'd0;
            h_num = 8'd0;
            c_num = 8'd0;
            co_num= 8'd0;
            kernel_mode = 1;
        end
    endcase

    case(wb_layer_num)
        3'd1: begin
            wb_w_num  = 8'd17;      // 102/6
            wb_h_num  = 8'd31;
            wb_w_cut  = 8'd0;
            wb_co_num = 8'd24;
        end
        3'd2: begin
            wb_w_num  = 8'd8;       // 48/6
            wb_h_num  = 8'd14;
            wb_w_cut  = 8'd1;
            wb_co_num = 8'd36;
        end
        3'd3: begin
            wb_w_num  = 8'd4;       // 24/6
            wb_h_num  = 8'd5;
            wb_w_cut  = 8'd0;
            wb_co_num = 8'd48;
        end
        3'd4: begin
            wb_w_num  = 8'd4;       // 24/6
            wb_h_num  = 8'd3;
            wb_w_cut  = 8'd0;
            wb_co_num = 8'd64;
        end
        3'd5: begin
            wb_w_num  = 8'd3;       // 18/6
            wb_h_num  = 8'd1;
            wb_w_cut  = 8'd1;
            wb_co_num = 8'd64;
        end
        default: begin
            wb_co_num = 0;
            wb_w_num  = 0;
            wb_h_num  = 0;
            wb_w_cut  = 0;
        end
    endcase
end
/*
always_comb begin
    fm_ping_pong = core_ready ? load_fm_ping_pong : ping_pong_now;
    gd_ping_pong = core_ready ? load_gd_ping_pong :ping_pong_now;
end*/

/*logic [CONF_PE_COL - 1 : 0] col_ready_d;
always_ff@(posedge clk or negedge rst_n) 
    if(!rst_n) col_ready_d <= '0; 
    else col_ready_d <= PE_col_ctrl_ready; */

// - In PE matrix ctrl --------------------------------------------------
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       fm_rd_addr_8, fm_rd_addr_4;
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       fm_rd_addr_8_pp, fm_rd_addr_4_pp;          // pp: park pointer
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]                    gd_rd_addr_8, gd_rd_addr_4;
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]                    gd_rd_addr_8_pp, gd_rd_addr_4_pp;
logic [CONF_PE_COL - 1 : 0]                                                          fin_a_input_channel;

// wait for all cols to finish input
always_comb in_one_layer_finish = &in_layer_finish_col;

//* always_comb fm_guard_gen_ctrl_valid = (wb_state == START || wb_state == PROCESS) && ((!in_bit_mode && !is_diff) || (in_bit_mode && is_diff));      //?

//when starting input a new layer, this valid signal becomes high. indicating OK to accept new acc values in fm guard gen modules
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)fm_guard_gen_ctrl_valid <= '0;
    else begin
        if(in_state == START && in_tick_tock == (is_diff ? '0 : '1)) fm_guard_gen_ctrl_valid <= '1;
        if(fm_guard_gen_ctrl_valid && fm_guard_gen_ctrl_ready) fm_guard_gen_ctrl_valid <= '0;
    end 

// - MAIN matrix input logics ------------------------------------------------------------------------------------------- [in matrix]
/*
 ----------------
 | park pointer |
 ----------------
The same sets of input layer of fm will be input into matrix for different ci,
so after in_one_ci_finish, scene(cnt, addr...) should be recovered to park point.
Only after in_one_co_finish shoud the scene be increased.
 --------------------------
 | Why cnt and shift reg? |
 --------------------------
BRAM in XLINX board is tipically 72*512(36k), in order to save BRAM, bank width
of fm and gd is fixed to 72, while using cnt and shift reg for input and wb.
Indeed more tricky logic has been used.
*/
generate
for(j = CONF_PE_COL - 1; j >=0; j--)begin:fm_gd_in
    //counters
    logic [7:0] count_w, count_h, count_co, count_ci;
    logic [3:0] cnt_fm_8, cnt_gd_8;
    logic [3:0] cnt_fm_4, cnt_gd_4;
    logic [3:0] cnt_fm_8_pp, cnt_gd_8_pp;                               // pp: park pointer
    logic [3:0] cnt_fm_4_pp, cnt_gd_4_pp;
    logic in_one_ci_finish, in_one_co_finish;

    //* always_comb in_one_ci_finish = (in_state == PROCESS) && PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j] && count_h == 0 && count_w < 6;

    // in_one_ci_finish: this col finishes input for a input channel
    // in_one_co_finish: this col finishes input for an output channel
    always_comb in_one_ci_finish = (in_state == PROCESS) && PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j] && count_h == 0 && count_w < 6 &&
                                   (in_bit_mode && (count_ci + 2*CONF_PE_COL > c_num - 1) || !in_bit_mode && (count_ci + CONF_PE_COL > c_num - 1));
    always_comb in_one_co_finish = (in_state != IDLE) && count_co == co_num && !in_layer_finish_col[j];
    //if ci_num is not a multiple of COL_NUM, some cols should be gated when finishing a input channel
    always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) fin_a_input_channel[j] <= '0; 
    else begin 
        if(in_one_ci_finish) fin_a_input_channel[j] <= '1; 
        if (&fin_a_input_channel) fin_a_input_channel[j] <= '0; 
    end
    //special counter for input
    always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) {
        cnt_fm_8, cnt_gd_8,         // cnt fm from 0 to 8
        cnt_fm_4, cnt_gd_4,         // cnt gdfrom 0 to 11
        cnt_fm_8_pp, cnt_gd_8_pp,
        cnt_fm_4_pp, cnt_gd_4_pp
    } <= '0;
    else if(in_one_layer_finish) begin
        {
        cnt_fm_8, cnt_gd_8,         // cnt fm from 0 to 8
        cnt_fm_4, cnt_gd_4,         // cnt gdfrom 0 to 11
        cnt_fm_8_pp, cnt_gd_8_pp,
        cnt_fm_4_pp, cnt_gd_4_pp
    } <= '0;
    end else if(in_one_ci_finish && !in_one_co_finish) begin            // recover scene
        cnt_fm_8 <= cnt_fm_8_pp;
        cnt_gd_8 <= cnt_gd_8_pp;
        cnt_fm_4 <= cnt_fm_4_pp;
        cnt_gd_4 <= cnt_gd_4_pp;
    end else begin
        if(!in_bit_mode) begin
            if(activation_en[j]) 
                if(cnt_fm_8 == 8) cnt_fm_8 <= 0;
                else cnt_fm_8 <= cnt_fm_8 + 1;
            
            if(PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j])
                if(cnt_gd_8 == 11) cnt_gd_8 <= 0;
                else cnt_gd_8 <= cnt_gd_8 + 1;
        end else begin
            if(activation_en[j]) 
                if(cnt_fm_4 == 8) cnt_fm_4 <= 0;
                else cnt_fm_4 <= cnt_fm_4 + 1;
            
            if(PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j])
                if(cnt_gd_4 == 11) cnt_gd_4 <= 0;
                else cnt_gd_4 <= cnt_gd_4 + 1;
        end
        //update pp
        if(in_one_co_finish) begin
            cnt_fm_8_pp <= cnt_fm_8;
            cnt_gd_8_pp <= cnt_gd_8;
            cnt_fm_4_pp <= cnt_fm_4;
            cnt_gd_4_pp <= cnt_gd_4;
            if(!in_bit_mode) begin
                if(activation_en[j]) 
                    if(cnt_fm_8 == 8) cnt_fm_8_pp <= 0;
                    else cnt_fm_8_pp <= cnt_fm_8 + 1;
                
                if(PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j])
                    if(cnt_gd_8 == 11) cnt_gd_8_pp <= 0;
                    else cnt_gd_8_pp <= cnt_gd_8 + 1;
            end else begin
                if(activation_en[j]) 
                    if(cnt_fm_4 == 8) cnt_fm_4_pp <= 0;
                    else cnt_fm_4_pp <= cnt_fm_4 + 1;
                
                if(PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j])
                    if(cnt_gd_4 == 11) cnt_gd_4_pp <= 0;
                    else cnt_gd_4_pp <= cnt_gd_4 + 1;
            end
        end
    end
    // counter for data managment
    
    always_ff@(posedge clk or negedge rst_n)
        if(!rst_n) begin
        {
            count_w, count_h, count_ci, count_co,
            in_layer_finish_col[j],                 // input finish one layer signal for a collum 
            in_gate_col[j]
        } <= '0;
        is_odd_row[j] <= 1;
        end else begin
            if((in_state == START) || in_one_layer_finish) begin
                count_w  <= w_num - 1;
                count_h  <= h_num - 1;
                count_ci <= j;
                count_co <= 0;
                if(j > (in_bit_mode ? (c_num >> 1) : c_num - 1)) in_gate_col[j] <= 1;                  //special: if COL NUM > ci num, there will be a rol in IDLE (to be optimised for power)
                else in_gate_col[j] <= 0;
            end else if((in_state == PROCESS) && PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j]) begin
                if (count_h == 0 && count_w < 6)begin
                    count_w <= w_num - 1;
                    count_h <=  h_num - 1;
                    if (in_bit_mode && (count_ci + 2*CONF_PE_COL > c_num - 1) || !in_bit_mode && (count_ci + CONF_PE_COL > c_num - 1))begin                         // if 4bit, ci need add double
                        count_ci <= j; 
                        count_co <= count_co + CONF_PE_ROW; 
                    end else 
                        count_ci <=  in_bit_mode ?  count_ci + 2*CONF_PE_COL : count_ci + CONF_PE_COL;
                    
                end else if (count_w < 6)begin
                    count_w <= w_num - 1;
                    count_h <= count_h - 1;
                    is_odd_row[j] <= ~is_odd_row[j];
                end else count_w <= count_w - 6;
            end
            // in one layer finish logic 
            if((in_state != IDLE) && count_co == co_num && !in_layer_finish_col[j])        //[co!4]
                in_layer_finish_col[j] <= 1;
            if(in_one_layer_finish) in_layer_finish_col[j] <= 0;

            // 
            if(fin_a_input_channel[j] && (~&fin_a_input_channel)) in_gate_col[j] <= 1;
            else in_gate_col[j] <= 0;
        end

    //addr magagement
    always_comb PE_col_ctrl_valid[j] = PE_col_ctrl_ready[j] && in_state == PROCESS && !in_layer_finish_col[j];              // save clk cycle,ok?; wait here!!!!!!!!!!!!!!!!!!!!!!
    always_comb end_of_row[j] = (count_w < 6 && count_w != 0) ? 1 : 0;
    always_ff@(posedge clk or negedge rst_n)
        if(!rst_n) begin
        {
            fm_rd_addr_8[j], fm_rd_addr_4[j],
            gd_rd_addr_8[j], gd_rd_addr_4[j],
            fm_rd_addr_8_pp[j], fm_rd_addr_4_pp[j],
            gd_rd_addr_8_pp[j], gd_rd_addr_4_pp[j]
        } <= '0;
        end else if(core_valid && core_ready || in_one_layer_finish)begin
            fm_rd_addr_8[j] <= '0;
            gd_rd_addr_8[j] <= '0;
            fm_rd_addr_4[j] <= FM_4_BIT_BASE_ADDR;
            gd_rd_addr_4[j] <= GD_4_BIT_BASE_ADDR;
        end else if(in_one_ci_finish && !in_one_co_finish) begin
            fm_rd_addr_8[j] <= fm_rd_addr_8_pp[j]; 
            gd_rd_addr_8[j] <= gd_rd_addr_8_pp[j];
            fm_rd_addr_4[j] <= fm_rd_addr_4_pp[j];
            gd_rd_addr_4[j] <= gd_rd_addr_4_pp[j];
        end else begin
            if(!in_bit_mode) begin
                if(PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j] && cnt_gd_8 == 1) gd_rd_addr_8[j] <= gd_rd_addr_8[j] + 1;   //the addr changes when cnt == 1
                if(in_state == PROCESS && activation_en[j] && cnt_fm_8 == 1) fm_rd_addr_8[j] <= fm_rd_addr_8[j] + 1;
            end else begin
                if(PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j] && cnt_gd_4 == 1) gd_rd_addr_4[j] <= gd_rd_addr_4[j] + 1;   //the addr changes when cnt == 1
                if(in_state == PROCESS && activation_en[j] && cnt_fm_4 == 1) fm_rd_addr_4[j] <= fm_rd_addr_4[j] + 1;
            end

            //pp
            if(in_one_co_finish) begin
                fm_rd_addr_8_pp[j] <= fm_rd_addr_8[j];
                gd_rd_addr_8_pp[j] <= gd_rd_addr_8[j];
                fm_rd_addr_4_pp[j] <= fm_rd_addr_4[j];
                gd_rd_addr_4_pp[j] <= gd_rd_addr_4[j];
                if(!in_bit_mode) begin
                    if(PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j] && cnt_gd_8 == 1) gd_rd_addr_8_pp[j] <= gd_rd_addr_8[j] + 1;   //the addr changes when cnt == 1
                    if(in_state == PROCESS && activation_en[j] && cnt_fm_8 == 1) fm_rd_addr_8_pp[j] <= fm_rd_addr_8[j] + 1;
                end else begin
                    if(PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j] && cnt_gd_4 == 1) gd_rd_addr_4_pp[j] <= gd_rd_addr_4[j] + 1;   //the addr changes when cnt == 1
                    if(in_state == PROCESS && activation_en[j] && cnt_fm_4 == 1) fm_rd_addr_4_pp[j] <= fm_rd_addr_4[j] + 1;
                end
            end
        end
    
    always_comb begin
        in_fm_rd_addr[j] = in_bit_mode ? fm_rd_addr_4[j] : fm_rd_addr_8[j];
        gd_rd_addr[j] = in_bit_mode ? gd_rd_addr_4[j] : gd_rd_addr_8[j];
    end
    // input data management (shift reg for fm and gd)
    logic   [71:0] shift_fm, shift_gd;
    always_ff@(posedge clk or negedge rst_n)
        if(!rst_n){
            shift_fm,
            shift_gd
        } <= '0;
        else begin
            if(in_state == PROCESS && activation_en[j])
                if(cnt_fm_8 == 8 && !in_bit_mode || cnt_fm_4 == 8 && in_bit_mode) shift_fm <= fm_dout[j];
                else  shift_fm <= {shift_fm[63:0], 8'd0};
            else if(cnt_fm_8 == 0 && !in_bit_mode || cnt_fm_4 == 0 && in_bit_mode) shift_fm <= fm_dout[j];
            if(PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j])
                if(cnt_gd_8 == 11 && !in_bit_mode || cnt_gd_4 == 8 && in_bit_mode) shift_gd <= gd_dout[j];
                else  shift_gd <= {shift_gd[65:0], 6'd0};
            else if(cnt_gd_8 == 0 && !in_bit_mode || cnt_gd_4 == 0 && in_bit_mode) shift_gd <= gd_dout[j];
        end
    always_comb activation[j] =  shift_fm[71:64];
    always_comb guard_map[j] = shift_gd[71:66];

end
endgenerate
// - out PE matrix, write back, fm and gd write signals, finish logic -------------------------------------------------

// signals for col head, connected with write back modules via MUX
// for reconfigurablity of COL_NUM and ROW_NUM
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                col_fm_wr_addr;
logic [CONF_PE_COL - 1 : 0][7 : 0]                                            col_fm_din;
logic [CONF_PE_COL - 1 : 0][71 : 0]                                           col_fm_din_f;        
logic [CONF_PE_COL - 1 : 0]                                                   col_fm_wr_en;      
logic [CONF_PE_COL - 1 : 0]                                                   col_fm_wr_en_f;      
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]             col_gd_wr_addr;
logic [CONF_PE_COL - 1 : 0][5 : 0]                                            col_gd_din;
logic [CONF_PE_COL - 1 : 0][71 : 0]                                           col_gd_din_f;
logic [CONF_PE_COL - 1 : 0]                                                   col_gd_wr_en;      
logic [CONF_PE_COL - 1 : 0]                                                   col_gd_wr_en_f;      
logic [CONF_PE_COL - 1 : 0]                                                   col_wb_bit_mode;      
logic [CONF_PE_COL - 1 : 0]                                                   col_co_tick_tock;      
logic [CONF_PE_COL - 1 : 0]                                                   col_write_back_finish;      

logic [CONF_PE_ROW - 1 : 0]                                                   row_wb_finish; // all row finish, then one layer finish
logic [CONF_PE_ROW - 1 : 0][7 : 0]                                            now_wb_port;    // used to control MUX

//logic [CONF_PE_COL - 1 : 0][7 : 0]                                            fm_dout_for_wb_f;
//logic [CONF_PE_ROW - 1 : 0][5 : 0]                                            gd_dout_for_wb_f;

logic [CONF_PE_COL - 1 : 0]                                                   tick_tock_for_4bit_wb; // consecutive 2 input channels in 4bit mode are merged in one byte

//for 4bit mode, in order to merge 2 input channels (thus wb twice), pp is needed.
// And semi-true dule port, "No change" mdoe mem for fm and gd is needed 
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                fm_wb_addr_8;
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                fm_wb_addr_4;
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                fm_wb_addr_4_pp;
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]             gd_wb_addr_8;
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]             gd_wb_addr_4;
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]             gd_wb_addr_4_pp;

// MUX for demo top
always_comb 
    if(core_ready) begin        //not run
        fm_wr_addr  = col_fm_wr_addr;
        fm_rd_addr  = in_fm_rd_addr;
        fm_din      = col_fm_din_f;
        fm_wr_en    = col_fm_wr_en_f;
        gd_wr_addr  = col_gd_wr_addr;
        gd_din      = col_gd_din_f;
        gd_wr_en    = col_gd_wr_en_f;
    end else begin
        fm_wr_addr  = load_fm_wr_addr;
        fm_rd_addr  = save_fm_rd_addr;
        fm_din      = load_fm_din;
        fm_wr_en    = load_fm_wr_en;   
        gd_wr_addr  = load_gd_wr_addr;
        gd_din      = load_gd_din;
        gd_wr_en    = load_gd_wr_en;   
    end
// - wb_address and data assignment -------------------------------------------------------
always_comb     wb_one_layer_finish = &row_wb_finish;

generate
for(i = CONF_PE_ROW - 1; i >= 0; i--)begin:gen_write_back_ctrl
    logic [7:0] count_co;
    
    // count and write port
    always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) {
        count_co,
        now_wb_port[i],
        row_wb_finish[i],
        tick_tock_for_4bit_wb[i]
    } <= '0;
    else begin
        if (core_ready && core_valid) 
            tick_tock_for_4bit_wb[i] <= '0;
        else if(wb_state == START || wb_state == FINISH_ONE_LAYER) begin
            count_co <= i;
            now_wb_port[i] <= i;
        end else begin
            if (write_back_finish[i]) begin
                count_co <= count_co + CONF_PE_ROW;
                now_wb_port[i] <= now_wb_port[i] + CONF_PE_ROW >= CONF_PE_COL ? now_wb_port[i] + CONF_PE_ROW - CONF_PE_COL : now_wb_port[i] + CONF_PE_ROW;
                if(bit_mode)tick_tock_for_4bit_wb[i] <= ~tick_tock_for_4bit_wb[i];
            end
            //wb finish
            if(write_back_finish[i] && (count_co + CONF_PE_ROW) > wb_co_num - 1) row_wb_finish[i] <= 1;
            if(wb_one_layer_finish) begin 
                row_wb_finish[i] <= 0;
                tick_tock_for_4bit_wb[i] <= '0;
            end
            /*/addr counter
            if(fm_write_back_data_o_valid[i]) begin
                fm_wb_addr_8[i] <= is_diff ? wb_bit_mode[i] ? fm_wb_addr_8[i] : fm_wb_addr_8[i] + 1 : fm_wb_addr_8[i] + 1;
                fm_wb_addr_4[i] <= is_diff ? wb_bit_mode[i] ? fm_wb_addr_4[i] + 1 : fm_wb_addr_4[i] : fm_wb_addr_4[i];
            end
            if(guard_o_valid[i]) begin
                gd_wb_addr_8[i] <= is_diff ? wb_bit_mode[i] ? gd_wb_addr_8[i] : gd_wb_addr_8[i] + 1 : gd_wb_addr_8[i] + 1;
                gd_wb_addr_4[i] <= is_diff ? wb_bit_mode[i] ? gd_wb_addr_4[i] + 1 : gd_wb_addr_4[i] : gd_wb_addr_4[i];
            end*/
        end
    end
end
endgenerate

// for reconfigurablity of size of PE COL and ROW
// What will be generated ? expected MUX but ... -----------------------------------------------------------------------------
generate
for(j = CONF_PE_COL - 1; j >= 0; j--) begin:gen_write_back_din_en_mux
    always_comb begin
        {
            col_fm_wr_en[j]  ,
            col_gd_wr_en[j]  ,
            col_fm_din[j]    ,
            col_gd_din[j]    ,
            //col_fm_wr_addr[j],
            //col_gd_wr_addr[j],
            col_wb_bit_mode[j],
            col_co_tick_tock[j],
            col_write_back_finish[j]
        } = '0;
        for( integer i = CONF_PE_ROW - 1; i >= 0; i--) begin
            if(now_wb_port[i] == j)
                begin
                    col_fm_wr_en[j]     = fm_write_back_data_o_valid[i];
                    col_gd_wr_en[j]     = guard_o_valid[i];
                    col_wb_bit_mode[j]  = wb_bit_mode[i];
                    col_co_tick_tock[j] = tick_tock_for_4bit_wb[i];
                    //col_fm_din[j]       = is_diff && tick_tock_for_4bit_wb ? {fm_write_back_data[i][3:0], fm_dout_for_wb_f[3:0]} : fm_write_back_data[i];
                    col_fm_din[j]       = fm_write_back_data[i];
                    //col_gd_din[j]       = is_diff && tick_tock_for_4bit_wb ? guard_o[i] & gd_dout_for_wb_f[i] : guard_o[i];
                    col_gd_din[j]       = guard_o[i];
                    col_write_back_finish[j]=write_back_finish[i];
                    //col_fm_wr_addr[j]   = is_diff ? tick_tock_for_4bit_wb ? fm_pointer_addr[i] + fm_wb_addr_4[i] + FM_4_BIT_BASE_ADDR : fm_pointer_addr[i] + fm_wb_addr_8[i] : fm_pointer_addr[i] + fm_wb_addr_8[i];
                    //col_gd_wr_addr[j]   = is_diff ? tick_tock_for_4bit_wb ? gd_pointer_addr[i] + gd_wb_addr_4[i] + GD_4_BIT_BASE_ADDR : gd_pointer_addr[i] + gd_wb_addr_8[i] : gd_pointer_addr[i] + gd_wb_addr_8[i];
                end 
        end
    end
end
endgenerate

// ------------------------------------------------------------------------------------------------------
//
// fm guard gen ctrl transfer the main ctrl
generate
for(j = CONF_PE_COL - 1; j >= 0; j--) begin:gen_shift_reg_and_wb_addr
    //generate shift reg for writeback                                                  pp: park pointer, used to save scene for 4bit wb
    logic [3:0]  cnt_wfm_8, cnt_wgd_8;
    logic [3:0]  cnt_wfm_4, cnt_wgd_4;
    logic [3:0]  cnt_wfm_4_pp, cnt_wgd_4_pp;
    logic [63:0] shift_wfm_8;
    logic [63:0] shift_wfm_4;
    logic [65:0] shift_wgd_8;
    logic [65:0] shift_wgd_4;
    logic        tick_tock_r;           //special tick tock for last wb
    always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) {
        shift_wfm_8,
        shift_wfm_4,
        shift_wgd_8,
        shift_wgd_4,
        cnt_wfm_8,
        cnt_wfm_4,
        cnt_wgd_8,
        cnt_wgd_4,
        cnt_wfm_4_pp,
        cnt_wgd_4_pp,
        tick_tock_r
    } <= '0;
    else if(wb_one_layer_finish || core_ready && core_valid)begin
        {
            cnt_wfm_8,
            cnt_wfm_4,
            cnt_wgd_8,
            cnt_wgd_4,
            cnt_wfm_4_pp,
            cnt_wgd_4_pp
        } <= '0;
    end else begin
        tick_tock_r <= col_co_tick_tock;
        if(col_fm_wr_en[j]) begin
            if(cnt_wfm_8 == 8) cnt_wfm_8 <= 0;
            else cnt_wfm_8 <= cnt_wfm_8 + 1;

            shift_wfm_8 <= {shift_wfm_8[55:0], col_fm_din[j]};
        end
            
        if(col_gd_wr_en[j]) begin
            if(cnt_wgd_8 == 11) cnt_wgd_8 <= 0;
            else cnt_wgd_8 <= cnt_wgd_8 + 1;

            shift_wgd_8 <= {shift_wgd_8[59:0], col_gd_din[j]};
        end
        // 4bit
        if(is_diff && col_wb_bit_mode[j] && col_fm_wr_en[j])begin
            if(cnt_wfm_4 == 8) cnt_wfm_4 <= 0;
            else cnt_wfm_4 <= cnt_wfm_4 + 1;

            shift_wfm_4 <={shift_wfm_4[55:0], col_fm_din[j]};
        end
        if(is_diff && col_wb_bit_mode[j] && col_gd_wr_en[j])begin
            if(cnt_wgd_4 == 11) cnt_wgd_4 <= 0;
            else cnt_wgd_4 <= cnt_wgd_4 + 1;

            shift_wgd_4 <= {shift_wgd_4[59:0], col_gd_din[j]};
        end
        // pp
        if(is_diff && col_write_back_finish[j] && !col_co_tick_tock[j]) begin
            cnt_wfm_4 <= cnt_wfm_4_pp;
            cnt_wgd_4 <= cnt_wgd_4_pp;
            shift_wfm_4 <= '0;
            shift_wgd_4 <= '0;
        end
        if(is_diff && col_write_back_finish[j] && col_co_tick_tock[j]) begin
            cnt_wfm_4_pp <= cnt_wfm_4;
            cnt_wgd_4_pp <= cnt_wgd_4;
        end
    end 

    // generate addr
    always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) {
        fm_wb_addr_8[j],
        fm_wb_addr_4[j],
        fm_wb_addr_4_pp[j],
        gd_wb_addr_8[j],
        gd_wb_addr_4[j],
        gd_wb_addr_4_pp[j]
    } <= '0;
    else if (wb_one_layer_finish || core_ready && core_valid) begin
        {fm_wb_addr_8[j], gd_wb_addr_8[j]} <= '0;
        if(is_diff)begin
            fm_wb_addr_4[j] <= FM_4_BIT_BASE_ADDR;
            gd_wb_addr_4[j] <= GD_4_BIT_BASE_ADDR;
        end
    end else begin
        if(col_fm_wr_en[j] && cnt_wfm_8 == 8 && is_diff && !col_wb_bit_mode[j] || col_fm_wr_en[j] && cnt_wfm_8 == 8 && !is_diff) 
            fm_wb_addr_8[j] <= fm_wb_addr_8[j] + 1;

        if(col_gd_wr_en[j] && cnt_wgd_8 == 11 && is_diff && !col_wb_bit_mode[j] || col_gd_wr_en[j] && cnt_wgd_8 == 11 && !is_diff) 
            gd_wb_addr_8[j] <= gd_wb_addr_8[j] + 1;

        if(col_fm_wr_en[j] && cnt_wfm_4 == 8 && is_diff && col_wb_bit_mode[j]) 
            fm_wb_addr_4[j] <= fm_wb_addr_4[j] + 1;

        if(col_gd_wr_en[j] && cnt_wgd_4 == 11 && is_diff && col_wb_bit_mode[j]) 
            gd_wb_addr_4[j] <= gd_wb_addr_4[j] + 1;
        //pp
        if(is_diff && col_write_back_finish[j] && !col_co_tick_tock[j])begin
            fm_wb_addr_4[j] <= fm_wb_addr_4_pp[j];
            gd_wb_addr_4[j] <= gd_wb_addr_4_pp[j];
        end
        if(is_diff && col_write_back_finish[j] && col_co_tick_tock[j]) begin
            fm_wb_addr_4_pp[j] <= fm_wb_addr_4[j];
            gd_wb_addr_4_pp[j] <= gd_wb_addr_4[j];
        end
        
    end
    

    always_comb begin
        col_fm_wr_en_f[j] = col_fm_wr_en[j] && (cnt_wfm_8 == 8 || cnt_wfm_4 == 8) || wb_one_layer_finish;
        col_gd_wr_en_f[j] = col_gd_wr_en[j] && (cnt_wgd_8 == 11 || cnt_wgd_4 == 11) || wb_one_layer_finish;
        // - din - 
        col_fm_din_f[j]   = col_wb_bit_mode[j] ? col_co_tick_tock ? ({shift_wfm_4, col_fm_din[j]} << 4) | fm_dout_for_4[j]: {shift_wfm_4, col_fm_din[j]} : {shift_wfm_8, col_fm_din[j]};
        col_gd_din_f[j]   = col_wb_bit_mode[j] ? col_co_tick_tock ? {shift_wgd_4, col_gd_din[j]} | gd_dout_for_4[j]: {shift_wgd_4, col_gd_din[j]} : {shift_wgd_8, col_gd_din[j]};
        // specital for last write in a layer, need 2 cycles
        if(wb_one_layer_finish && !is_diff || wb_one_layer_finish_d && is_diff) begin
            col_fm_din_f[j] = {shift_wfm_8, col_fm_din[j]} << (8 - cnt_wfm_8) * 8;
            col_gd_din_f[j] = {shift_wgd_8, col_gd_din[j]} << (11 - cnt_wgd_8) * 6;
        end
        if(wb_one_layer_finish && is_diff) begin
            col_fm_din_f[j] = tick_tock_r ? ({shift_wfm_4, col_fm_din[j]} << (4 + (8 - cnt_wfm_4) * 8)) | fm_dout_for_4[j] : {shift_wfm_4, col_fm_din[j]} << (8 - cnt_wfm_4) * 8;
            col_gd_din_f[j] = tick_tock_r ? ({shift_wgd_4, col_gd_din[j]} << (11 - cnt_wgd_4) * 6) | gd_dout_for_4[j]: {shift_wgd_4, col_gd_din[j]} << (11 - cnt_wgd_4) * 6;
        end
        // - addr - 
        col_fm_wr_addr[j] = fm_wb_addr_8[j];
        col_gd_wr_addr[j] = gd_wb_addr_8[j];
        if(is_diff) begin                              //Note here: RAM need to be "No change" mode
            col_fm_wr_addr[j] = col_fm_wr_en[j] && cnt_wfm_8 == 8 && !col_wb_bit_mode[j] ?  fm_wb_addr_8[j] : fm_wb_addr_4[j];
            col_gd_wr_addr[j] = col_gd_wr_en[j] && cnt_wgd_8 == 11 && !col_wb_bit_mode[j] ? gd_wb_addr_8[j] : gd_wb_addr_4[j];
        end
        //fm_dout_for_wb_f[j]= fm_dout[71 - (col_wb_bit_mode[j] ? cnt_wfm_4 : cnt_wfm_8) * 8 -: 8];
        //gd_dout_for_wb_f[j]= gd_dout[71 - (col_wb_bit_mode[j] ? cnt_wgd_4 : cnt_wgd_8) * 6 -: 6];
    end
    /*/ gen writeback addr
    always_ff@(posedge clk or negedge rst_n)
        if(!rst_n)
        {
            col_fm_wr_addr[j],
            col_gd_wr_addr[j]
        } <= '0;
        else if(write_back_finish){
            col_fm_wr_addr[j],
            col_gd_wr_addr[j]
        } <= '0;
        else begin
            if(col_fm_wr_en_f[j]) col_fm_wr_addr[j] <= col_fm_wr_addr[j] + 1;
            if(col_gd_wr_en_f[j]) col_gd_wr_addr[j] <= col_gd_wr_addr[j] + 1;
        end*/
end
endgenerate


// - wt/bias rd addr --------------------------------------------
logic is_first_d;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) 
    {
        bias_rd_addr,
        is_first_d
    } <= '0;
    else begin
        is_first_d <= is_first;
        if(is_first && !is_first_d) begin
            bias_rd_addr <= '0;
            
        end else begin
            if(fm_guard_gen_ctrl_finish) bias_rd_addr <= bias_rd_addr + 1;              // change for every output channel  [check]
        end
    end

generate
for(i = CONF_PE_ROW - 1; i >= 0; i--) begin:gen_wt_addr
    for(j = CONF_PE_COL - 1; j >= 0; j--)begin:gen_wt_addr_col
        logic wt_tick_tock;                                 // for two 3*3 kernel are stroed in one data line

        always_ff@(posedge clk or negedge rst_n)
        if(!rst_n) {
            wt_rd_addr[i][j], 
            wt_tick_tock
        } <= '0;
        else if(is_first && !is_first_d) wt_rd_addr[i][j] <='0;
        else if(fm_gd_in[j].count_h == 0 && fm_gd_in[j].count_w < 6) begin
            if(kernel_mode || !kernel_mode && wt_tick_tock) wt_rd_addr[i][j] <= wt_rd_addr[i][j] + 1;
            if(kernel_mode == 0) wt_tick_tock <= ~wt_tick_tock;
        end
        // weight out
        always_comb weight[i][j] = !kernel_mode && wt_tick_tock ? wt_dout[i][j] << (9*8) : wt_dout[i][j];
    end
end
endgenerate
// - bias out -
always_comb bias = bias_dout;

endmodule