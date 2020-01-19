/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191128

Modify:

Notes:
1. 

TODO:
critical path here maybe

special 4 + 18 + 2
=========================================================*/
import diff_demo_pkg::*;
module write_back(
    input  logic                                                clk,
    input  logic                                                rst_n,
    input  logic                                                ctrl_valid,
    output logic                                                ctrl_ready,
    output logic                                                ctrl_finish,
    input  logic [7:0]                                          wb_w_num_i,
    input  logic [7:0]                                          wb_h_num_i,
    input  logic [7:0]                                          wb_w_cut_i,
    input  logic                                                is_diff_i,
    input  logic                                                is_last,
    input  logic [3:0]                                          shift_wb,
    //                      
    input  logic signed [5:0][PSUM_WIDTH - 1 : 0]               data_i,         // will be trucated
    output logic [$clog2(FM_GUARD_GEN_PSUM_BUF_DEPTH) - 1 : 0]  addr_o,
    //output logic                                                rd_en,
    //
    output logic [7 : 0]                                        data_o,
    //input  logic                                                fm_buf_ready,           //un-necessary
    output logic                                                data_o_valid,
    //
    output logic [5:0]                                          guard_o,                  // only for 8bit-diff or non-diff
    //input  logic                                                guard_buf_ready,
    output logic                                                guard_o_valid,
    output logic                                                wb_bit_mode               // mark if it's 4bit-diff
);
typedef enum logic[2:0] {  
    IDLE  = 3'd0, 
    ONE   = 3'd1, 
    TWO   = 3'd2, 
    THREE = 3'd3, 
    FOUR  = 3'd4, 
    FIVE  = 3'd5, 
    SIX   = 3'd6,
    START = 3'd7
} state_t;

state_t state, next_state;
logic [5:0] guard_map_8, guard_map_4, guard_map_4_8, guard_o_r;
//logic [5:0][7:0] data_reg;
logic almost_finish;
logic is_diff;
logic [7:0] wb_w_num;
logic [7:0] wb_h_num;
logic [7:0] wb_w_cut;
logic [7:0] count_w, count_h;
logic signed [5:0][7:0] data_after_shift;
logic signed [5:0][PSUM_WIDTH-1:0] data_tmp;
logic corner_value;         //don't write back
// - protacal ---------------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        ctrl_ready <= 1;
        ctrl_finish <= 0;
    end else begin
        ctrl_finish <= 0;
        if(ctrl_ready && ctrl_valid) ctrl_ready <= 0;
        if(ctrl_finish && !ctrl_ready) ctrl_ready <= 1;
        if(almost_finish  && (state != IDLE && next_state == IDLE)) ctrl_finish <= 1;
    end

always_comb almost_finish = (count_w == 0 && count_h == 0);// && !ctrl_ready ? is_diff ?  tick_tock ? 1 : 0 : 1 : 0;

always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)
        {
            is_diff ,
            wb_w_num,
            wb_h_num,
            wb_w_cut
        } <= '0;
    else begin
        if(ctrl_ready && ctrl_valid) begin
            is_diff     <= is_diff_i;
            wb_w_num    <= wb_w_num_i;
            wb_h_num    <= wb_h_num_i;
            wb_w_cut    <= wb_w_cut_i;
        end 

    end
// - counters ---------------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) {
        count_w, count_h
    } <= '0;
    else begin
        if(ctrl_ready && ctrl_valid)begin
            count_w <= wb_w_num_i - 1;
            count_h <= wb_h_num_i - 1;
        end
        if(state == START && count_w == 0) begin
            count_h <= count_h - 1;
            count_w <= wb_w_num_i - 1;
        end else if(state == START) count_w <= count_w - 1;                 //win size
    end
// - state ------------------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) 
        state <= IDLE;
    //else if(ctrl_ready && !ctrl_valid)                      //?
    //    state <= IDLE;
    else 
        state <= next_state;

always_comb begin
    next_state = state;
    case(state)
        IDLE: next_state =  ctrl_valid && ctrl_ready ? START : IDLE;
        START:
            if(is_last || guard_o[5] == 1) next_state = ONE;
            else if(guard_o[4] == 1) next_state = TWO;
            else if(guard_o[3] == 1)  next_state = THREE;
            else if(guard_o[2] == 1)  next_state = FOUR;
            else if(guard_o[1] == 1)  next_state = FIVE;
            else if(guard_o[0] == 1)  next_state = SIX;
            else  next_state = almost_finish ? IDLE : START;    
        ONE:
            if(is_last || guard_o_r[4] == 1) next_state = TWO;
            else if(guard_o_r[3] == 1) next_state = THREE;
            else if(guard_o_r[2] == 1) next_state = FOUR;
            else if(guard_o_r[1] == 1) next_state = FIVE;
            else if(guard_o_r[0] == 1) next_state = SIX;
            else  next_state = almost_finish ? IDLE : START;
        TWO:
            if(is_last || guard_o_r[3] == 1) next_state = THREE;
            else if(guard_o_r[2] == 1) next_state = FOUR;
            else if(guard_o_r[1] == 1) next_state = FIVE;
            else if(guard_o_r[0] == 1) next_state = SIX;
            else next_state = almost_finish ? IDLE : START;
        THREE:
            if(is_last || guard_o_r[2] == 1)next_state = FOUR;
            else if(guard_o_r[1] == 1) next_state = FIVE;
            else if(guard_o_r[0] == 1) next_state = SIX;
            else next_state = almost_finish ? IDLE : START;
        FOUR:
            if(is_last || guard_o_r[1] == 1) next_state = FIVE;
            else if(guard_o_r[0] == 1) next_state = SIX;
            else next_state = almost_finish ? IDLE : START;
        FIVE:
            if(is_last || guard_o_r[0] == 1) next_state = SIX;
            else next_state = almost_finish ? IDLE : START;
        SIX:
            next_state = almost_finish ? IDLE : START;
    endcase
end
//  - data i and relu --------------------------------------------------------------------
logic [5:0] guard_4_r;
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) 
        {addr_o, guard_o_r, guard_4_r} <= '0;
    else begin
        if(state == START) begin
            guard_o_r <= guard_map_4_8;
            guard_4_r <= guard_map_4;
        end
        if(state == IDLE || almost_finish)begin
            addr_o <= '0;
        end else if(state == START)
            addr_o <= count_w == 0 ? addr_o + wb_w_cut + 1 : addr_o + 1;
    end
generate
    for (genvar i = 5; i >= 0; i--)begin:relu
        always_comb begin
            data_tmp[i] = data_i[i] >>> shift_wb;
            data_after_shift[i] = {data_tmp[i][PSUM_WIDTH - 1], data_tmp[6:0]};
            guard_map_4_8[i] = state == START ?  data_after_shift[i] == 0 ? 0 : 1 : 0;      //---------------might be critical path
            guard_map_4[i] = state == START ? data_after_shift[i] == 0 ? 0: (data_after_shift[i][7 : 3] ==  0 || data_after_shift[i][7 : 3] == '1) ?  1 : 0: 0;                       // not used here        [4bit]
            guard_map_8[i] = state == START ? data_after_shift[i] == 0 ? 0: !(data_after_shift[i][7 : 3] ==  0 || data_after_shift[i][7 : 3] == '1)  ?  1 : 0: 0;
        end
        /*
        always_ff@(posedge clk or negedge rst_n)
            if (!rst_n) 
                data_reg[i] <= '0;
            else if (state == START) 
                data_reg[i] <= data_i[i][7:0];*/
    end
endgenerate


//  - data o --------------------------------------------------------------------

always_comb begin
    corner_value = 0;
    if(count_w == wb_w_num - 1)
        case(state)
            ONE, TWO, THREE, FOUR: corner_value = 1;
        endcase
    if(count_w == 0)
        case(state)
            FIVE, SIX: corner_value = 1;
        endcase
end
// to be optimised for power
always_comb guard_o = is_diff ? wb_bit_mode ? guard_map_4 : guard_map_8 : guard_map_4_8;
always_comb data_o = state == IDLE || state == START ? '0 : wb_bit_mode ? {4'd0, data_after_shift[6 - state][3:0]} : data_after_shift[6 - state];
always_comb data_o_valid = !(state == IDLE || state == START) && !corner_value;
always_comb wb_bit_mode = is_last || !is_diff || state == IDLE || state == START ? '0 : guard_4_r[6 - state];
always_comb guard_o_valid = !is_last && (state == START) && next_state != START && !corner_value;
/*
// rethink about 4bit
always_comb guard_o = is_diff ? bit_mode  ? '1 : guard_map_8 : guard_map_4_8;      //valid when state == START for a clk            [4bit]
always_comb 
    if (!bit_mode) data_o = state == IDLE || state == START ? '0 : data_i[6 - state];
    else data_o = state == IDLE || state == START ? '0 :{data_reg[7-state][3:0], data_reg[6-state][3:0]}; 
 
always_comb begin
    data_o_valid = bit_mode ? state != 0 && state[0] == 0 ? 1 : 0 : state != IDLE && state != START;
    guard_o_valid = state == START && next_state != START;       // tmp: when 4bit, guard will behave as usual                  [4bit]
end

*/
endmodule