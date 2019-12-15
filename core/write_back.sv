/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191128

Modify:

Notes:
1. 

TODO:
critical path here
=========================================================*/
import diff_demo_pkg::*;
module write_back(
    input  logic                                                clk,
    input  logic                                                rst_n,
    input  logic                                                ctrl_valid,
    output logic                                                ctrl_ready,
    output logic                                                ctrl_finish,
    input  logic [$clog2(FM_GUARD_GEN_PSUM_BUF_DEPTH) - 1 : 0]  stop_addr_i,
    input  logic                                                is_diff_i,
    //                      
    input  logic [5:0][PSUM_WIDTH - 1 : 0]                      data_i,
    output logic [$clog2(FM_GUARD_GEN_PSUM_BUF_DEPTH) - 1 : 0]  addr_o,
    //output logic                                                rd_en,
    //
    output logic [7 : 0]                                        data_o,
    //input  logic                                                fm_buf_ready,           //un-necessary
    output logic                                                data_o_valid,
    //
    output logic [5:0]                                          guard_o,
    //input  logic                                                guard_buf_ready,
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
logic [5:0] guard_map_8, guard_map_4, guard_map_4_8;
logic [5:0][7:0] data_reg;
logic [$clog2(FM_GUARD_GEN_PSUM_BUF_DEPTH) - 1 : 0] stop_addr;
logic almost_finish;
logic is_diff;
logic count2; //0: diff 8bit    1: diff 4bit
logic bit_mode;
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

always_comb almost_finish = addr_o == stop_addr ? is_diff ?  count2 ? 1 : 0 : 1 : 0;

always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)
        {
            stop_addr,
            is_diff ,
            count2
        } <= '0;
    else begin
        if(ctrl_ready && ctrl_valid) begin
            stop_addr <= stop_addr_i;
            is_diff <= is_diff_i;
        end 
        if(is_diff && !count2 && addr_o == stop_addr) count2 <= 1;
        else if(is_diff && count2 && addr_o == stop_addr) count2 <= 0;

    end

always_comb bit_mode = is_diff  ?  count2 ? 1 :  0 :  0;
// - state ------------------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) 
        state <= IDLE;
    else 
        state <= next_state;

always_comb begin
    next_state = state;
    case(state)
        IDLE:   next_state =  ctrl_valid && ctrl_ready ? START : IDLE;
        START:
            if (bit_mode) next_state = ONE;
            else
                case(guard_o)                                                         //---------------might be critical path
                    6'b1?????: next_state = ONE;
                    6'b01????: next_state = TWO;
                    6'b001???: next_state = THREE;
                    6'b0001??: next_state = FOUR;
                    6'b00001?: next_state = FIVE;
                    6'b000001: next_state = SIX;
                    default:   next_state = almost_finish ? IDLE : START;
                endcase
        ONE:
            if (bit_mode) next_state = TWO;
            else
                case(guard_o[4:0])
                    5'b1????: next_state = TWO;
                    5'b01???: next_state = THREE;
                    5'b001??: next_state = FOUR;
                    5'b0001?: next_state = FIVE;
                    5'b00001: next_state = SIX;
                    default:  next_state = almost_finish ? IDLE : START;
                endcase
        TWO:
            if (bit_mode) next_state = THREE;
            else
                case(guard_o[3:0])
                    4'b1???:  next_state = THREE;
                    4'b01??:  next_state = FOUR;
                    4'b001?:  next_state = FIVE;
                    4'b0001:  next_state = SIX;
                    default:  next_state = almost_finish ? IDLE : START;
                endcase
        THREE:
            if (bit_mode) next_state = FOUR;
                else
                case(guard_o[2:0])
                    3'b1??:   next_state = FOUR;
                    3'b01?:   next_state = FIVE;
                    3'b001:   next_state = SIX;
                    default:  next_state = almost_finish ? IDLE : START;
                endcase
        FOUR:
            if (bit_mode) next_state = FIVE;
                else
                case(guard_o[1:0])
                    2'b1?:   next_state = FIVE;
                    2'b01:   next_state = SIX;
                    default:  next_state = almost_finish ? IDLE : START;
                endcase
        FIVE:
            if (bit_mode) next_state = SIX;
            else if(guard_o[0] == 1) next_state = SIX;
            else next_state = almost_finish ? IDLE : START;
        SIX:
            next_state = almost_finish ? IDLE : START;
    endcase
end
//  - data i and relu --------------------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) 
        addr_o <= '0;
    else if(state == IDLE || addr_o == stop_addr)begin
        addr_o <= '0;
    end else if(state == START)
        addr_o ++;

generate
    for (genvar i = 5; i >= 0; i--)begin:relu
        always_comb begin
            guard_map_4_8[i] = state == START ?  data_i[i][7 : 0] == 0 ? 0 : 1 : 0;      //---------------might be critical path
            guard_map_4[i] = state == START ? data_i[i][7 : 0] == 0 ? 0: data_i[i][7 : 4] ==  0  ?  1 : 0: 0;
            guard_map_8[i] = state == START ? data_i[i][7 : 0] == 0 ? 0: data_i[i][7 : 4] !=  0  ?  1 : 0: 0;
        end
        always_ff@(posedge clk or negedge rst_n)
            if (!rst_n) 
                data_reg[i] <= '0;
            else if (state == START) 
                data_reg[i] <= data_i[i][7:0];
            
    end
endgenerate

always_comb guard_o = is_diff ? bit_mode  ? guard_map_4 : guard_map_8 : guard_map_4_8;


//  - data o --------------------------------------------------------------------


always_comb begin
    if (!bit_mode) data_o = data_i[6 - state];
    else data_o = {data_reg[7-state][3:0], data_reg[6-state][3:0]}; 
end 
always_comb begin
    data_o_valid = bit_mode ? state != 0 && state[0] == 0 ? 1 : 0 : state != IDLE && state != START;
    guard_o_valid = bit_mode ? 0 : state == START && next_state != START;
end
endmodule