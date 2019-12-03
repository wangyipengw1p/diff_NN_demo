/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191128

Modify:

Notes:
1. 

TODO:
critical path here
Data truncation ok ?
=========================================================*/
import diff_demo_pkg::*;
module relu_guard_write_back(
    input  logic                                                clk,
    input  logic                                                rst_n,
    input  logic                                                ctrl_valid,
    output logic                                                ctrl_ready,
    output logic                                                ctrl_finish,
    input  logic [7:0]                                          w_num_i,
    input  logic [7:0]                                          h_num_i,
    input  logic                                                bit_mode_i,
    //                      
    input  logic [PSUM_WIDTH - 1 : 0][5:0]                      data_i,
    output logic [$clog2(FM_GUARD_GEN_PSUM_BUF_DEPTH) - 1 : 0]  addr_o,
    output logic                                                rd_en,
    //
    output logic [7 : 0]                                        data_o,
    input  logic                                                fm_buf_ready,           //un-necessary
    output logic                                                data_o_valid,
    //
    output logic [5:0]                                          guard_o,
    input  logic                                                guard_buf_ready,
    output logic                                                guard_o_valid
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
logic [5:0] guard_map;
logic [PSUM_WIDTH - 1 : 0][5:0] data_after_relu, data_after_relu_reg;
logic [7:0] count_w, count_h;
logic bit_mode;
logic [7:0] h_num, w_num;
logic almost_finish;
// - protacal ---------------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        ctrl_ready <= 1;
        ctrl_finish <= 0;
    end else begin
        ctrl_finish <= 0;
        if(ctrl_ready && ctrl_valid) ctrl_ready <= 0;
        if(ctrl_finish && !ctrl_ready) ctrl_ready <= 1;
        if(almost_finish) ctrl_finish <= 1;
    end

always_comb almost_finish = count_h == 0 && count_w == 0;

always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)
        {
            count_w ,
            count_h ,
            h_num   ,
            w_num   ,
            bit_mode
        } <= '0;
    else begin
        if(ctrl_ready && ctrl_valid) begin
            count_w <= w_num_i - 1;
            count_h <= h_num_i - 1;
            h_num   <= h_num_i - 1;
            w_num   <= w_num_i - 1;
        end else if(state != IDLE && state != START) begin
            if(count_w == 0) begin
                count_w <= w_num;
                count_h --;
            end else count_w --;
        end
        bit_mode <= bit_mode_i;
    end
// - state ------------------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) 
        state <= IDLE;
    else 
        state <= next_state;
always_comb 
    if(count_h != 0 && count_w == 0 && state != IDLE && state != START) 
        next_state <= START;
    else
        case(state)
            IDLE:   next_state =  ctrl_valid && ctrl_ready ? START : IDLE;
            START:
                if (bit_mode) next_state <= ONE;
                else
                    case(guard_map)                                                         //---------------might be critical path
                        6'b1?????: next_state <= ONE;
                        6'b01????: next_state <= TWO;
                        6'b001???: next_state <= THREE;
                        6'b0001??: next_state <= FOUR;
                        6'b00001?: next_state <= FIVE;
                        6'b000001: next_state <= SIX;
                        default:   next_state <= almost_finish ? IDLE : START;
                    endcase
            ONE:
                if (bit_mode) next_state <= TWO;
                else
                    case(guard_o[4:0])
                        5'b1????: next_state <= TWO;
                        5'b01???: next_state <= THREE;
                        5'b001??: next_state <= FOUR;
                        5'b0001?: next_state <= FIVE;
                        5'b00001: next_state <= SIX;
                        default:  next_state <= almost_finish ? IDLE : START;
                    endcase
            TWO:
                if (bit_mode) next_state <= THREE;
                else
                    case(guard_o[3:0])
                        4'b1???:  next_state <= THREE;
                        4'b01??:  next_state <= FOUR;
                        4'b001?:  next_state <= FIVE;
                        4'b0001:  next_state <= SIX;
                        default:  next_state <= almost_finish ? IDLE : START;
                    endcase
            THREE:
                if (bit_mode) next_state <= FOUR;
                    else
                    case(guard_o[2:0])
                        3'b1??:   next_state <= FOUR;
                        3'b01?:   next_state <= FIVE;
                        3'b001:   next_state <= SIX;
                        default:  next_state <= almost_finish ? IDLE : START;
                    endcase
            FOUR:
                if (bit_mode) next_state <= FIVE;
                    else
                    case(guard_o[1:0])
                        2'b1?:   next_state <= FIVE;
                        2'b01:   next_state <= SIX;
                        default:  next_state <= almost_finish ? IDLE : START;
                    endcase
            FIVE:
                if (bit_mode) next_state <= SIX;
                else if(guard_o[0] == 1) next_state <= SIX;
                else next_state <= almost_finish ? IDLE : START;
            SIX:
                next_state <= almost_finish ? IDLE : START;
        endcase
//  - data i and relu --------------------------------------------------------------------
always_comb rd_en = state == IDLE && ctrl_valid && ctrl_ready;
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) 
        addr_o <= '0;
    else if(state == IDLE)begin
        addr_o <= '0;
    end else if(state == START)
        addr_o ++;

always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) {
        data_after_relu_reg,
        guard_o
    }<= '0;
    else begin
        data_after_relu_reg <= data_after_relu;
        guard_o <= guard_map;
    end
        
generate
    for (genvar i = 5; i >= 0; i--)begin:relu
        always_comb begin
            data_after_relu[i] = state == START ? data_i[i][PSUM_WIDTH - 1] == 1 ? '0 : data_i[i][7:0] : '0; //Data truncation
            guard_map = state == START ? data_i[i][PSUM_WIDTH - 1] == 1 || data_i[i] == 0 ? 0 : 1 : 0;      //---------------might be critical path
        end
    end
endgenerate
//  - data o --------------------------------------------------------------------
always_comb begin
    data_o = data_after_relu_reg[6 - state];
    if(state == IDLE || state == START) data_o = '0;
    if(bit_mode && state != 0 && state[0] == 0)                 // even state
        data_o = {data_after_relu_reg[7-state][3:0], data_after_relu_reg[6-state][3:0]};
end 
always_comb begin
    data_o_valid = bit_mode ? state != 0 && state[0] == 0 ? 1 : 0 : state != IDLE && state != START;
    guard_o_valid = bit_mode ? 0 : state == START && next_state != START;
end
endmodule