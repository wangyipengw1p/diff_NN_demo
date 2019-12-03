/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191128

Modify:

Notes:
1. 

TODO:
=========================================================*/
import diff_demo_pkg::*;
module PE_col_ctrl(
    input  logic                clk,
    input  logic                rst_n,
    //
    input  logic                ctrl_valid,
    output logic                ctrl_ready,
    output logic                ctrl_finish,
    input  logic                bit_mode_i,   
    input  logic                kernel_mode_i,
    input  logic [5:0]          guard_map_i,
    input  logic                is_odd_row_i,
    input  logic                end_of_row_i,
    //
    input  logic                fifo_full,
    //
    output PE_state_t           state,      
    output PE_weight_mode_t     weight_mode, 
    output logic                end_of_row,
    output logic                bit_mode,
    //
    output logic                activation_en_o
);
// - stream data ctrl-------------------------------------------
PE_state_t next_state;
logic [5 : 0]                            guard_map;
logic                                    is_odd_row;
logic                                    kernel_mode;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        ctrl_ready   <= 1;
        ctrl_finish  <= 0;
    end else begin
        if (ctrl_valid  && ctrl_ready )     ctrl_ready  <= 0;
        if (ctrl_finish  && !ctrl_ready )   ctrl_ready  <= 1;
        if (fifo_full  && ctrl_ready )    ctrl_ready  <= 0;          //?
        if (fifo_full  && !ctrl_ready )   ctrl_ready  <= 1;
        ctrl_finish  <= 0;
        case(state)
            IDLE:
                if(ctrl_valid  && ctrl_ready  && guard_map_i == 0) ctrl_finish  <= 1;
            ONE:
                if(guard_map[4:0] == 0) ctrl_finish  <= 1;
            TWO:
                if(guard_map[3:0] == 0) ctrl_finish  <= 1;
            THREE:
                if(guard_map[2:0] == 0) ctrl_finish  <= 1;
            FOUR:
                if(guard_map[1:0] == 0) ctrl_finish  <= 1;
            FIVE:
                if(guard_map[0] == 0) ctrl_finish  <= 1;
            SIX:
                ctrl_finish  <= 1;
        endcase 
    end

always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)
        {
            guard_map,
            is_odd_row,
            kernel_mode,
            bit_mode,
            end_of_row
        } <= '0;
    else begin
    if (ctrl_valid  && ctrl_ready ) begin
            guard_map   <= bit_mode_i ? '1 : guard_map_i;                   //dense when 4bit !!!!!
            bit_mode    <= bit_mode_i;
            is_odd_row  <= is_odd_row_i;
            kernel_mode <= kernel_mode_i;
            end_of_row   <= end_of_row_i;
        end
    end
// activation_en_o
always_comb activation_en_o  = state == IDLE && !(ctrl_valid  && ctrl_ready ) ? 0 : 1;
// - state & mode ---------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) state <= IDLE;
    else if (!fifo_full )                 //only first row's fifo full signals were connected, may cause reliablity problem
        state <= next_state;

always_comb 
    case(state)
        IDLE:
            if(ctrl_valid && ctrl_ready)
                case(guard_map_i)
                    6'b1?????: next_state <= ONE;
                    6'b01????: next_state <= TWO;
                    6'b001???: next_state <= THREE;
                    6'b0001??: next_state <= FOUR;
                    6'b00001?: next_state <= FIVE;
                    6'b000001: next_state <= SIX;
                    default:   next_state <= IDLE;
                endcase
        ONE:
            case(guard_map[4:0])
                5'b1????: next_state <= TWO;
                5'b01???: next_state <= THREE;
                5'b001??: next_state <= FOUR;
                5'b0001?: next_state <= FIVE;
                5'b00001: next_state <= SIX;
                default:  next_state <= IDLE;
            endcase
        TWO:
            case(guard_map[3:0])
                4'b1???:  next_state <= THREE;
                4'b01??:  next_state <= FOUR;
                4'b001?:  next_state <= FIVE;
                4'b0001:  next_state <= SIX;
                default:  next_state <= IDLE;
            endcase
        THREE:
            case(guard_map[2:0])
                3'b1??:   next_state <= FOUR;
                3'b01?:   next_state <= FIVE;
                3'b001:   next_state <= SIX;
                default:  next_state <= IDLE;
            endcase
        FOUR:
            case(guard_map[1:0])
                2'b1?:   next_state <= FIVE;
                2'b01:   next_state <= SIX;
                default:  next_state <= IDLE;
            endcase
        FIVE:
            if(guard_map[0] == 1) next_state <= SIX;
            else next_state <= IDLE;
        SIX:
            next_state <= IDLE;
    endcase
// weight mode
always_comb 
    if(kernel_mode == 0) weight_mode = E_MODE;
    else 
        case(state)
            ONE,THREE,FIVE: 
                weight_mode = is_odd_row ? A_MODE : B_MODE;
            TWO,FOUR,SIX:
                weight_mode = is_odd_row ? C_MODE : D_MODE;
        endcase
endmodule