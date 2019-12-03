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
    input  logic                                                                                core_fm_ping_pong_i,
    input  logic                                                                                core_bit_mode_i,
    // for PE matrix                    
    output logic [CONF_PE_COL - 1 : 0]                                                          PE_col_ctrl_valid,
    input  logic [CONF_PE_COL - 1 : 0]                                                          PE_col_ctrl_ready,
    input  logic [CONF_PE_COL - 1 : 0]                                                          PE_col_ctrl_finish,
    output logic                                                                                fm_guard_gen_ctrl_valid  ,
    input  logic                                                                                fm_guard_gen_ctrl_ready  ,//?
    input  logic                                                                                fm_guard_gen_ctrl_finish ,//no use
    output logic [7 : 0 ]                                                                       w_num,
    output logic [7 : 0 ]                                                                       h_num,
    output logic [7 : 0 ]                                                                       c_num,
    output logic [CONF_PE_COL - 1 : 0]                                                          bit_mode,             
    output logic [CONF_PE_COL - 1 : 0]                                                          kernel_mode,
    output logic [CONF_PE_COL - 1 : 0]                                                          is_odd_row,
    output logic [CONF_PE_COL - 1 : 0]                                                          end_of_row,
    output logic [7 : 0][CONF_PE_COL - 1 : 0]                                                   activation,
    input  logic [CONF_PE_COL - 1 : 0]                                                          activation_en,//?
    output logic [5 : 0][CONF_PE_COL - 1 : 0]                                                   guard_map,   
    output logic [25 * 8 - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                     weight,
    output logic [7 : 0][5 : 0][CONF_PE_ROW - 1 : 0]                                            bias,
    input  logic        [CONF_PE_ROW - 1 : 0]                                                   write_back_finish,
    input  logic [7 : 0][CONF_PE_ROW - 1 : 0]                                                   fm_write_back_data,      
    output logic        [CONF_PE_ROW - 1 : 0]                                                   fm_buf_ready,              
    input  logic        [CONF_PE_ROW - 1 : 0]                                                   fm_write_back_data_o_valid,
    input  logic [5 : 0][CONF_PE_ROW - 1 : 0]                                                   guard_o,                
    output logic        [CONF_PE_ROW - 1 : 0]                                                   guard_buf_ready,        
    input  logic        [CONF_PE_ROW - 1 : 0]                                                   guard_o_valid,
    // load from outside core
    input  logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                       load_fm_wr_addr,
    input  logic [7 : 0][CONF_PE_COL - 1 : 0]                                                   load_fm_din,
    input  logic [CONF_PE_COL - 1 : 0]                                                          load_fm_wr_en,         //rd_en for energy save
    input  logic [CONF_PE_COL - 1 : 0]                                                          load_fm_ping_pong,
    input  logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                    load_gd_wr_addr,
    input  logic [5 : 0][CONF_PE_COL - 1 : 0]                                                   load_gd_din,
    input  logic [CONF_PE_COL - 1 : 0]                                                          load_gd_wr_en,         //rd_en for energy save
    input  logic [CONF_PE_COL - 1 : 0]                                                          load_gd_ping_pong,      //not used
    // for fm buf
    output logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                       fm_wr_addr,
    output logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                       fm_rd_addr,
    output logic [7 : 0][CONF_PE_COL - 1 : 0]                                                   fm_din,
    input  logic [7 : 0][CONF_PE_COL - 1 : 0]                                                   fm_dout,
    output logic [CONF_PE_COL - 1 : 0]                                                          fm_rd_en,          
    output logic [CONF_PE_COL - 1 : 0]                                                          fm_wr_en,          
    output logic [CONF_PE_COL - 1 : 0]                                                          fm_ping_pong,
    // for guard buf    
    output logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                    gd_rd_addr,
    output logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                    gd_wr_addr,
    input  logic [5 : 0][CONF_PE_COL - 1 : 0]                                                   gd_dout,
    output logic [5 : 0][CONF_PE_COL - 1 : 0]                                                   gd_din,
    output logic [CONF_PE_COL - 1 : 0]                                                          gd_rd_en,          
    output logic [CONF_PE_COL - 1 : 0]                                                          gd_wr_en,          
    output logic [CONF_PE_COL - 1 : 0]                                                          gd_ping_pong,
    // for weight buf   
    output logic [$clog2(CONF_WT_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]  wt_rd_addr,
    input  logic [5 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                              wt_dout,
    output logic [CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]                                     wt_rd_en,          
    // for bias buf 
    output logic [$clog2(CONF_BIAS_BUF_DEPTH) - 1 : 0][CONF_PE_ROW - 1 : 0]                     bias_rd_addr,
    input  logic [5 : 0][CONF_PE_ROW - 1 : 0]                                                   bias_dout,
    output logic [CONF_PE_ROW - 1 : 0]                                                          bias_rd_en          
);
genvar i, j;
// - ctrl protcol -----------------------------------------------------
logic core_fm_ping_pong;
logic core_bit_mode;
logic one_layer_finish, finish_all,one_co_finish;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        core_ready   <= 1;
        {
            core_finish,
            core_fm_ping_pong,
            core_bit_mode
        } <= '0;
    end else begin
        core_finish <= 0;
        if (core_valid  && core_ready )begin
            core_ready  <= 0;
            core_fm_ping_pong <= core_fm_ping_pong_i;
            core_bit_mode <= core_bit_mode_i;
        end
        if (core_finish  && !core_ready )   core_ready  <= 1;
        // ctrl finish here
        if (finish_all) core_finish <= 1;
    end
// - state machine -------------------------------------------------------
enum logic [2:0] {IDLE, START, PROCESS, FINISH_ONE_LAYER, FINISH} state;

always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) state <= IDLE;
    else 
        case(state)
            IDLE:               state <= core_ready && core_valid ? START : IDLE;
            START:              state <= PROCESS;
            PROCESS:            state <= finish_all ? FINISH : one_layer_finish ? FINISH_ONE_LAYER  : PROCESS;
            FINISH_ONE_LAYER:   state <= START;
            FINISH:             state <= IDLE;
        endcase
// - layer and parameters -------------------------------------------------------------
logic [2:0] layer_num; 
logic [7:0] co_num;
logic ping_pong_now;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) begin
    {
        layer_num
    } <= '0;
    end else begin
        if(core_valid  && core_ready) layer_num <= 3'd1;
        else if (state == IDLE) layer_num <= '0;
        else if(one_layer_finish) layer_num++;
    end
// hard-coded network parameters, actually could be calculated, but for easy ...
always_comb begin
    // bit_mode
    bit_mode = core_bit_mode;
    // w h c
    // kernel mode
    case (layer_num)
        3'd1:begin
            w_num = 8'd200;     // ceil(200/4)
            h_num = 8'd66;
            c_num = 8'd3;
            co_num= 8'd24;
            kernel_mode = 1;
            ping_pong_now = core_fm_ping_pong;
        end
        3'd2:begin
            w_num = 8'd98;
            h_num = 8'd31;
            c_num = 8'd24;
            co_num= 8'd36;
            kernel_mode = 1;
            ping_pong_now = ~core_fm_ping_pong;
        end
        3'd3: begin
            w_num = 8'd47;
            h_num = 8'd14;
            c_num = 8'd36;
            co_num= 8'd48;
            kernel_mode = 1;
            ping_pong_now = core_fm_ping_pong;
        end
        3'd4: begin
            w_num = 8'd22;
            h_num = 8'd5;
            c_num = 8'd48;
            co_num= 8'd64;
            kernel_mode = 0;
            ping_pong_now = ~core_fm_ping_pong;
        end
        3'd5:begin
            w_num = 8'd20;
            h_num = 8'd3;
            c_num = 8'd64;
            co_num= 8'd64;
            kernel_mode = 0;
            ping_pong_now = core_fm_ping_pong;
        end
        default:begin
            w_num = 8'd0;
            h_num = 8'd0;
            c_num = 8'd0;
            co_num= 8'd0;
            kernel_mode = 1;
            ping_pong_now = core_fm_ping_pong;
        end
    endcase
end

always_comb begin
    fm_ping_pong = ping_pong_now;
    gd_ping_pong = ping_pong_now;
end
// - In PE matrix ctrl --------------------------------------------------

logic [CONF_PE_COL - 1 : 0] col_finish_input_for_a_layer;
logic input_one_layer_finish;
always_comb fm_guard_gen_ctrl_valid = state == START || state == FINISH_ONE_LAYER;      //?
always_comb input_one_layer_finish = &col_finish_input_for_a_layer;
generate
for(j = CONF_PE_COL; j >=0; j--)begin:fm_gd_in
    //counters
    logic [7:0] count_w, count_h, count_co, count_ci;
    always_ff@(posedge clk or negedge rst_n)
        if(!rst_n) begin
        {
            count_w, count_h, count_ci, count_co
        } <= '0;
        end else begin
            if(state == START ) begin
                count_w  <= w_num;
                count_h  <= h_num;
                count_ci <= j;              //ok?
                count_co <= '0;
            end else if(state == PROCESS && activation_en[j]) begin
                if (count_h == 1 && count_w == 1)begin
                    count_w <= w_num;
                    count_h <=  h_num;
                    if (count_ci + CONF_PE_COL > c_num)begin
                        count_ci <= count_ci + CONF_PE_COL - c_num;
                        count_co ++; 
                    end else count_ci <= count_ci + CONF_PE_COL;

                end else if (count_w == 1)begin
                    count_w <= w_num;
                    count_h --;
                end else count_w --;
            end
        end
    always_comb col_finish_input_for_a_layer = count_co == co_num - 1;          //?
    always_ff@(posedge clk or negedge rst_n)
        if(!rst_n)  col_finish_input_for_a_layer[j] <= 0;
        else if (count_co == co_num - 1) col_finish_input_for_a_layer[j] <= 1;
        else if (input_one_layer_finish) col_finish_input_for_a_layer[j] <= 0;
    //addr magagement
    always_comb PE_col_ctrl_valid = PE_col_ctrl_ready;              // save clk cycle, but ok?
    always_ff@(posedge clk or negedge rst_n)
        if(!rst_n) begin
        {
            fm_rd_addr[j],
            gd_rd_addr[j]
        } <= '0;
        end else begin
            if(PE_col_ctrl_valid && PE_col_ctrl_ready) gd_rd_addr[j]++;
            if(state == PROCESS && activation_en[j]) begin
                if(count_h == 1 && count_w == 1)begin
                    fm_rd_addr[j] <= '0;
                    gd_rd_addr[j] <= '0;
                end else fm_rd_addr[j] ++;                          //[think]!!
            end
        end
end
endgenerate
// - fm and gd write signals -------------------------------------------------
logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                ctrl_fm_wr_addr;
logic [7 : 0][CONF_PE_COL - 1 : 0]                                            ctrl_fm_din;
logic [CONF_PE_COL - 1 : 0]                                                   ctrl_fm_wr_en;          
logic [CONF_PE_COL - 1 : 0]                                                   ctrl_fm_ping_pong;
logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]             ctrl_gd_wr_addr;
logic [5 : 0][CONF_PE_COL - 1 : 0]                                            ctrl_gd_din;
logic [CONF_PE_COL - 1 : 0]                                                   ctrl_gd_wr_en;          
logic [CONF_PE_COL - 1 : 0]                                                   ctrl_gd_ping_pong;
always_comb 
    if(core_ready) begin        //not run
        fm_wr_addr  = ctrl_fm_wr_addr;
        fm_din      = ctrl_fm_din;
        fm_wr_en    = ctrl_fm_wr_en;
        fm_ping_pong= ctrl_fm_ping_pong;
        gd_wr_addr  = ctrl_gd_wr_addr;
        gd_din      = ctrl_gd_din;
        gd_wr_en    = ctrl_gd_wr_en;
        gd_ping_pong= ctrl_gd_ping_pong;
    end else begin
        fm_wr_addr  = load_fm_wr_addr;
        fm_din      = load_fm_din;
        fm_wr_en    = load_fm_wr_en;   
        fm_ping_pong= load_fm_ping_pong;
        gd_wr_addr  = load_gd_wr_addr;
        gd_din      = load_gd_din;
        gd_wr_en    = load_gd_wr_en;   
        gd_ping_pong= load_gd_ping_pong;
    end
// - finish logic -------------------------------------------------------------------
logic [CONF_PE_ROW - 1 : 0] wr_back_finish; 
logic all_row_wr_back_finish;
logic count_co;
always_comb all_row_wr_back_finish = & wr_back_finish;
generate 
for(i = CONF_PE_ROW; i >= 0; i--)begin:gen_row
    always_ff@(posedge clk or negedge rst_n)
        if(!rst_n) wr_back_finish[i] <= 0;
        else begin
            if(write_back_finish[i]) wr_back_finish <= 1;
            if(all_row_wr_back_finish) wr_back_finish <= 0;
        end
end
endgenerate
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) count_co <= '0;
    else if (state == START || state == FINISH_ONE_LAYER) count_co <= co_num;
    else if (all_row_wr_back_finish) count_co -= CONF_PE_ROW;
//
always_comb one_layer_finish = count_co <= CONF_PE_ROW && all_row_wr_back_finish;

endmodule