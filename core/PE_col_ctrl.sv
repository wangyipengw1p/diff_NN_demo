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
        ctrl_ready      <= '1;
    end else begin
        if (ctrl_ready && ctrl_valid)ctrl_ready <= '0;
        if (ctrl_finish) ctrl_ready <= '1;
        if (fifo_full) ctrl_ready <= '0;
        
    end
always_comb begin
    ctrl_finish  = '0;
    case(state)
        IDLE:
            if(ctrl_valid  && ctrl_ready  && guard_map_i == 0) ctrl_finish  = 1;
        ONE:
            if(guard_map[4:0] == 0) ctrl_finish  = 1;
        TWO:
            if(guard_map[3:0] == 0) ctrl_finish  = 1;
        THREE:
            if(guard_map[2:0] == 0) ctrl_finish  = 1;
        FOUR:
            if(guard_map[1:0] == 0) ctrl_finish  = 1;
        FIVE:
            if(guard_map[0] == 0) ctrl_finish  = 1;
        SIX:
            ctrl_finish  = 1;
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
always_comb activation_en_o  = state == IDLE  ? 0 : fifo_full ? 0:1;
//always_comb end_of_row = end_of_row_i;
// - state & mode ---------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) state <= IDLE;
    else if (!fifo_full )                 //only first row's fifo full signals were connected, may cause reliablity problem
        state <= next_state;

always_comb begin
    next_state = state;
    case(state)
        IDLE:
            if(ctrl_valid && ctrl_ready)
                if(guard_map_i[5] == 1) next_state = ONE;
                else if(guard_map_i[4] == 1) next_state = TWO;
                else if(guard_map_i[3] == 1)  next_state = THREE;
                else if(guard_map_i[2] == 1)  next_state = FOUR;
                else if(guard_map_i[1] == 1)  next_state = FIVE;
                else if(guard_map_i[0] == 1)  next_state = SIX;
                else  next_state = IDLE;
                
        ONE:
            if(guard_map[4] == 1) next_state = TWO;
            else if(guard_map[3] == 1) next_state = THREE;
            else if(guard_map[2] == 1) next_state = FOUR;
            else if(guard_map[1] == 1) next_state = FIVE;
            else if(guard_map[0] == 1) next_state = SIX;
            else  next_state = IDLE;
        TWO:
            if(guard_map[3] == 1) next_state = THREE;
            else if(guard_map[2] == 1) next_state = FOUR;
            else if(guard_map[1] == 1) next_state = FIVE;
            else if(guard_map[0] == 1) next_state = SIX;
            else next_state = IDLE;
        THREE:
            if(guard_map[2] == 1)next_state = FOUR;
            else if(guard_map[1] == 1) next_state = FIVE;
            else if(guard_map[0] == 1) next_state = SIX;
            else next_state = IDLE;
        FOUR:
            if(guard_map[1] == 1) next_state = FIVE;
            else if(guard_map[0] == 1) next_state = SIX;
            else next_state = IDLE;
        FIVE:
            if(guard_map[0] == 1) next_state = SIX;
            else next_state = IDLE;
        SIX:
            next_state = IDLE;
    endcase
end
// weight mode
always_comb begin
    weight_mode = E_MODE;
    if(kernel_mode) 
        case(state)
            ONE,THREE,FIVE: 
                weight_mode = is_odd_row ? A_MODE : C_MODE;
            TWO,FOUR,SIX:
                weight_mode = is_odd_row ? B_MODE : D_MODE;
        endcase
end
endmodule