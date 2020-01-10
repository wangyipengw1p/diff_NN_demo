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
    input  logic [CONF_PE_ROW - 1 : 0][5 : 0]                                                   guard_o_4,                
    //output logic [CONF_PE_ROW - 1 : 0]                                                          guard_buf_ready,        
    input  logic [CONF_PE_ROW - 1 : 0]                                                          guard_o_valid,
    input  logic [CONF_PE_ROW - 1 : 0]                                                          wb_bit_mode,
    // load from outside core
    input  logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       load_fm_wr_addr,
    input  logic [CONF_PE_COL - 1 : 0][71 : 0]                                                   load_fm_din,
    input  logic [CONF_PE_COL - 1 : 0]                                                          load_fm_wr_en,         //rd_en for energy save
    //input  logic [CONF_PE_COL - 1 : 0]                                                          load_fm_ping_pong,
    input  logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]                    load_gd_wr_addr,
    input  logic [CONF_PE_COL - 1 : 0][71 : 0]                                                   load_gd_din,
    input  logic [CONF_PE_COL - 1 : 0]                                                          load_gd_wr_en,         //rd_en for energy save
    //input  logic [CONF_PE_COL - 1 : 0]                                                          load_gd_ping_pong,      //not used
    // for fm buf
    output logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       fm_wr_addr,
    output logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       fm_rd_addr,
    output logic [CONF_PE_COL - 1 : 0][71 : 0]                                                  fm_din,
    input  logic [CONF_PE_COL - 1 : 0][71 : 0]                                                  fm_dout,
    //output logic [CONF_PE_COL - 1 : 0]                                                          fm_rd_en,          
    output logic [CONF_PE_COL - 1 : 0]                                                          fm_wr_en,          
    //output logic [CONF_PE_COL - 1 : 0]                                                          fm_ping_pong,
    // for guard buf    
    output logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]                    gd_rd_addr,
    output logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]                    gd_wr_addr,
    input  logic [CONF_PE_COL - 1 : 0][71 : 0]                                                   gd_dout,
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
    input  logic [CONF_PE_ROW - 1 : 0][7 : 0]                                            bias_dout
    //output logic [CONF_PE_ROW - 1 : 0]                                                          bias_rd_en          
);
genvar i, j;
// - ctrl protcol -----------------------------------------------------
//logic core_fm_ping_pong;
logic in_one_layer_finish, wb_one_layer_finish, in_finish_all, wb_finish_all;
logic wb_tick_tock, in_tick_tock;                    // for diff
logic [2:0] in_layer_num, wb_layer_num;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        core_ready   <= '1;
        {
            core_finish,
            //core_fm_ping_pong,
            is_diff
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
    end
// - state machine -------------------------------------------------------
enum logic [2:0] {IDLE, START, PROCESS, FINISH_ONE_LAYER, FINISH} in_state, next_in_state, wb_state, next_wb_state;        // this state is for in matrix


always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) {in_state, wb_state} <= IDLE;
    else begin
        in_state <= next_in_state;
        wb_state <= next_wb_state;
    end

always_comb begin
    case(in_state)
        IDLE:               next_in_state = core_ready && core_valid ? START : IDLE;
        START:              next_in_state = in_layer_num - wb_layer_num <= 2 ? PROCESS : START;
        PROCESS:            next_in_state = in_finish_all ? FINISH : in_one_layer_finish ? FINISH_ONE_LAYER  : PROCESS;
        FINISH_ONE_LAYER:   next_in_state = START;
        FINISH:             next_in_state = IDLE;
    endcase
    case(wb_state)
        IDLE:               next_wb_state = core_ready && core_valid ? START : IDLE;
        START:              next_wb_state = in_layer_num - wb_layer_num <= 2 ? PROCESS : START;
        PROCESS:            next_wb_state = wb_finish_all ? FINISH : wb_one_layer_finish ? FINISH_ONE_LAYER  : PROCESS;
        FINISH_ONE_LAYER:   next_wb_state = START;
        FINISH:             next_wb_state = IDLE;
    endcase
end
// - layer and parameters -------------------------------------------------------------

// - finish logic -------------------------------------------
always_comb in_finish_all = in_one_layer_finish && in_layer_num == 5 && in_tick_tock;
always_comb wb_finish_all = wb_one_layer_finish && wb_layer_num == 5;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) begin
    {
        in_layer_num,
        wb_layer_num,
        wb_tick_tock,
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
logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                fm_base_addr_4;
logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]             gd_base_addr_4;
always_comb begin
    // bit_mode
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


always_comb in_one_layer_finish = &in_layer_finish_col;
//
//always_comb fm_guard_gen_ctrl_valid = (wb_state == START || wb_state == PROCESS) && ((!in_bit_mode && !is_diff) || (in_bit_mode && is_diff));      //?
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)fm_guard_gen_ctrl_valid <= '0;
    else begin
        if(in_state == START && in_tick_tock == (is_diff ? '0 : '1)) fm_guard_gen_ctrl_valid <= '1;
        if(fm_guard_gen_ctrl_valid && fm_guard_gen_ctrl_ready) fm_guard_gen_ctrl_valid <= '0;
    end 
generate
for(j = CONF_PE_COL - 1; j >=0; j--)begin:fm_gd_in
    //counters
    logic [7:0] count_w, count_h, count_co, count_ci;
    logic [3:0] cnt_fm, cnt_gd;
    
    //special counter for input
    always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) {
        cnt_fm,         // from 1 to 9
        cnt_gd          // from 1 to 12
    } <= '0;
    else begin
        if(activation_en[j]) 
            if(cnt_fm == 8) cnt_fm <= 0;
            else cnt_fm <= cnt_fm + 1;
        
        if(PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j])
            if(cnt_gd == 11) cnt_gd <= 0;
            else cnt_gd <= cnt_gd + 1;
    end
    // counter for data managment
    // input finish one layer signal for a collum 
    always_ff@(posedge clk or negedge rst_n)
        if(!rst_n) begin
        {
            count_w, count_h, count_ci, count_co,
            in_layer_finish_col[j],
            in_gate_col[j]
        } <= '0;
        is_odd_row[j] <= 1;
        end else begin
            if((in_state == START) || in_one_layer_finish) begin
                count_w  <= w_num - 1;
                count_h  <= h_num -1;
                count_ci <= j;
                count_co <= 0;
                if(j > c_num - 1) in_gate_col[j] <= 1;                  //special: if COL NUM > ci num, there will be a rol in IDLE (to be optimised for power)
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

            if((in_state != IDLE) && count_co == co_num && !in_layer_finish_col[j])        //[co!4]
                in_layer_finish_col[j] <= 1;
            if(in_one_layer_finish) in_layer_finish_col[j] <= 0;

        end

    //addr magagement
    always_comb PE_col_ctrl_valid[j] = PE_col_ctrl_ready[j] && in_state == PROCESS && !in_layer_finish_col[j];              // save clk cycle,ok?; wait here!!!!!!!!!!!!!!!!!!!!!!
    always_comb end_of_row[j] = (count_w < 6 && count_w != 0) ? 1 : 0;
    always_ff@(posedge clk or negedge rst_n)
        if(!rst_n) begin
        {
            fm_rd_addr[j],
            gd_rd_addr[j]
        } <= '0;
        end else begin
            if(PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j] && cnt_gd == 1) gd_rd_addr[j] <= gd_rd_addr[j] + 1;   //1 here?
            if(in_state == PROCESS && activation_en[j]) begin
                if(count_h == 0 && count_w < 6)begin
                    fm_rd_addr[j] <= '0;
                    gd_rd_addr[j] <= '0;
                end else if(cnt_fm == 1) fm_rd_addr[j] <= fm_rd_addr[j] + 1;                          //[think]!!
            end
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
                if(cnt_fm == 8) shift_fm <= fm_dout[j];
                else  shift_fm <= {shift_fm[63:0], 8'd0};
            else if(cnt_fm == 0) shift_fm <= fm_dout[j];
            if(PE_col_ctrl_valid[j] && PE_col_ctrl_ready[j])
                if(cnt_gd == 11)shift_gd  <= gd_dout[j];
                else  shift_gd <= {shift_gd[65:0], 6'd0};
            else if(cnt_gd == 0) shift_gd  <= gd_dout[j];
        end
    always_comb activation[j] =  shift_fm[71:64];
    always_comb guard_map[j] = shift_gd[71:66];

end
endgenerate
// - out PE matrix, fm and gd write signals, finish logic -------------------------------------------------
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                ctrl_fm_wr_addr;
logic [CONF_PE_COL - 1 : 0][7 : 0]                                            ctrl_fm_din;
logic [CONF_PE_COL - 1 : 0][71 : 0]                                           ctrl_fm_din_f;        //shift reg for write back
logic [CONF_PE_COL - 1 : 0]                                                   ctrl_fm_wr_en;      
logic [CONF_PE_COL - 1 : 0]                                                   ctrl_fm_wr_en_f;      
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]             ctrl_gd_wr_addr;
logic [CONF_PE_COL - 1 : 0][5 : 0]                                            ctrl_gd_din;
logic [CONF_PE_COL - 1 : 0][71 : 0]                                           ctrl_gd_din_f;
logic [CONF_PE_COL - 1 : 0]                                                   ctrl_gd_wr_en;      
logic [CONF_PE_COL - 1 : 0]                                                   ctrl_gd_wr_en_f;      
logic [CONF_PE_ROW - 1 : 0]                                                   wr_back_finish; //all row finish, then one layer finish
logic [CONF_PE_ROW - 1 : 0][7:0]                                              now_wb_port;
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                fm_wb_addr;
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]             gd_wb_addr;

logic [CONF_PE_COL - 1 : 0][7 : 0]                                            fm_dout_for_wb_f;
logic [CONF_PE_ROW - 1 : 0][5 : 0]                                            gd_dout_for_wb_f;

logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                fm_pointer_addr;
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]             gd_pointer_addr;
logic [CONF_PE_COL - 1 : 0]                                                   tick_tock_for_4bit_wb;
logic [CONF_PE_ROW - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                fm_wb_addr_8;
logic [CONF_PE_ROW - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                fm_wb_addr_4;
logic [CONF_PE_ROW - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]             gd_wb_addr_8;
logic [CONF_PE_ROW - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]             gd_wb_addr_4;
logic [CONF_PE_ROW - 1 : 0][7 : 0]                                            fm_wb_data_row;
logic [CONF_PE_ROW - 1 : 0][5 : 0]                                            gd_wb_data_row;


always_comb     wb_one_layer_finish = &wr_back_finish;
always_comb 
    if(core_ready) begin        //not run
        fm_wr_addr  = ctrl_fm_wr_addr;
        fm_din      = ctrl_fm_din_f;
        fm_wr_en    = ctrl_fm_wr_en_f;
        gd_wr_addr  = ctrl_gd_wr_addr;
        gd_din      = ctrl_gd_din_f;
        gd_wr_en    = ctrl_gd_wr_en_f;
    end else begin
        fm_wr_addr  = load_fm_wr_addr;
        fm_din      = load_fm_din;
        fm_wr_en    = load_fm_wr_en;   
        gd_wr_addr  = load_gd_wr_addr;
        gd_din      = load_gd_din;
        gd_wr_en    = load_gd_wr_en;   
    end
// - wb_address and data assignment -------------------------------------------------------
generate
for(i = CONF_PE_ROW - 1; i >= 0; i--)begin:gen_write_back_ctrl
    logic [7:0] count_co;
    
    // count and write port
    always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) {
        count_co,
        now_wb_port[i],
        wr_back_finish[i],
        fm_wb_addr_8[i],
        fm_wb_addr_4[i],
        gd_wb_addr_8[i],
        gd_wb_addr_4[i]
        
    } <= '0;
    else begin
        if (core_ready && core_valid) begin
            {
                fm_wb_addr_8[i], 
                gd_wb_addr_8[i],
                fm_wb_addr_4[i],
                gd_wb_addr_4[i]
             } <= '0;
        end else if(wb_state == START || wb_state == FINISH_ONE_LAYER) begin
            count_co <= i;
            now_wb_port[i] <= CONF_PE_ROW - i - 1;
        end else begin
            if (write_back_finish[i]) begin
                count_co <= count_co + CONF_PE_ROW;
                now_wb_port[i] += CONF_PE_ROW;
            end
            //wb finish
            if(write_back_finish[i] && (count_co + CONF_PE_ROW) > wb_co_num - 1) wr_back_finish[i] <= 1;
            if(wb_one_layer_finish) wr_back_finish[i] <= 0;
            //addr counter
            if(fm_write_back_data_o_valid[i]) begin
                fm_wb_addr_8[i] <= is_diff ? wb_bit_mode[i] ? fm_wb_addr_8[i] : fm_wb_addr_8[i] + 1 : fm_wb_addr_8[i] + 1;
                fm_wb_addr_4[i] <= is_diff ? wb_bit_mode[i] ? fm_wb_addr_4[i] + 1 : fm_wb_addr_4[i] : fm_wb_addr_4[i];
            end
            if(guard_o_valid[i]) begin
                gd_wb_addr_8[i] <= is_diff ? wb_bit_mode[i] ? gd_wb_addr_8[i] : gd_wb_addr_8[i] + 1 : gd_wb_addr_8[i] + 1;
                gd_wb_addr_4[i] <= is_diff ? wb_bit_mode[i] ? gd_wb_addr_4[i] + 1 : gd_wb_addr_4[i] : gd_wb_addr_4[i];
            end
        end
    end
end
endgenerate

// for reconfigurablity of size of PE COL and ROW
// What will be generated -----------------------------------------------------------------------------
generate
for(j = CONF_PE_COL - 1; j >= 0; j--) begin:gen_write_back_din_en_mux
    always_comb begin
        {
            ctrl_fm_wr_en[j]  ,
            ctrl_gd_wr_en[j]  ,
            ctrl_fm_din[j]    ,
            ctrl_gd_din[j]    ,
            ctrl_fm_wr_addr[j],
            ctrl_gd_wr_addr[j]
        } = '0;
        for( integer i = CONF_PE_ROW - 1; i >= 0; i--) begin
            if(now_wb_port[i] == j)
                begin
                    ctrl_fm_wr_en[j]     = fm_write_back_data_o_valid[i];
                    ctrl_gd_wr_en[j]     = guard_o_valid[i];
                    ctrl_fm_din[j]       = is_diff && tick_tock_for_4bit_wb ? {fm_write_back_data[i][3:0], fm_dout_for_wb_f[3:0]} : fm_write_back_data[i];
                    ctrl_gd_din[j]       = is_diff && tick_tock_for_4bit_wb ? guard_o[i] & gd_dout_for_wb_f[i] : guard_o[i];
                    ctrl_fm_wr_addr[j]   = is_diff ? tick_tock_for_4bit_wb ? fm_pointer_addr[i] + fm_wb_addr_4[i] + fm_base_addr_4 : fm_pointer_addr[i] + fm_wb_addr_8[i] : fm_pointer_addr[i] + fm_wb_addr_8[i];
                    ctrl_gd_wr_addr[j]   = is_diff ? tick_tock_for_4bit_wb ? gd_pointer_addr[i] + gd_wb_addr_4[i] + gd_base_addr_4 : gd_pointer_addr[i] + gd_wb_addr_8[i] : gd_pointer_addr[i] + gd_wb_addr_8[i];
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
    //generate shift reg for writeback
    logic [3:0] cnt_wfm, cnt_wgd;
    logic [63:0] shift_wfm;
    logic [65:0] shift_wgd;
    always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) {
        shift_wfm,
        shift_wgd,
        cnt_wfm,
        cnt_wgd
    } <= '0;
    else begin
        if(ctrl_fm_wr_en[j]) begin
            if(cnt_wfm == 8) cnt_wfm <= 0;
            else cnt_wfm <= cnt_wfm + 1;

            shift_wfm <= {shift_wfm[55:0], ctrl_fm_din[j]};
        end
            
        if(ctrl_gd_wr_en[j]) begin
            if(cnt_wgd == 11) cnt_wgd <= 0;
            else cnt_wgd <= cnt_wgd + 1;

            shift_wgd <= {shift_wgd[59:0], ctrl_gd_din[j]};
        end
    end

    always_comb begin
        ctrl_fm_wr_en_f[j] = ctrl_fm_wr_en[j] && (cnt_wfm == 8);
        ctrl_gd_wr_en_f[j] = ctrl_gd_wr_en[j] && (cnt_wgd == 11);
        ctrl_fm_din_f[j]   = {shift_wfm, ctrl_fm_din[j]};
        ctrl_gd_din_f[j]   = {shift_wgd, ctrl_gd_din[j]};
        fm_dout_for_wb_f[j]= fm_dout[71 - cnt_wfm * 8 -: 8];
        gd_dout_for_wb_f[j]= gd_dout[71 - cnt_wgd * 6 -: 6];
    end
    /*/ gen writeback addr
    always_ff@(posedge clk or negedge rst_n)
        if(!rst_n)
        {
            ctrl_fm_wr_addr[j],
            ctrl_gd_wr_addr[j]
        } <= '0;
        else if(write_back_finish){
            ctrl_fm_wr_addr[j],
            ctrl_gd_wr_addr[j]
        } <= '0;
        else begin
            if(ctrl_fm_wr_en_f[j]) ctrl_fm_wr_addr[j] <= ctrl_fm_wr_addr[j] + 1;
            if(ctrl_gd_wr_en_f[j]) ctrl_gd_wr_addr[j] <= ctrl_gd_wr_addr[j] + 1;
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
            if(fm_guard_gen_ctrl_finish) bias_rd_addr <= bias_rd_addr + 1;
        end
    end
generate
for(i = CONF_PE_ROW - 1; i >= 0; i--) begin:gen_wt_addr
    for(j = CONF_PE_COL - 1; j >= 0; j--)begin:gen_wt_addr_col
        always_ff@(posedge clk or negedge rst_n)
        if(!rst_n) wt_rd_addr[i][j] <= '0;
        else if(is_first && !is_first_d) wt_rd_addr[i][j] <='0;
        else if(fm_gd_in[j].count_h == 1 && fm_gd_in[j].count_w == 1) wt_rd_addr[i][j] <= wt_rd_addr[i][j] + 1;
    end
end
endgenerate
// - out --------------------------------------------------------
//always_comb activation = fm_dout;
always_comb weight = wt_dout;
//always_comb guard_map = gd_dout;
always_comb bias = bias_dout;

endmodule