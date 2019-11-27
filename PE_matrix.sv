/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191126

Modify:

Notes:
1. 4-bit mode is implemented as full dense activation

TODO:
adder tree
=========================================================*/
`include "diff_core_pkg.sv"
module PE_matrix(
    input  logic                                                                clk,
    input  logic                                                                rst_n,
    //                          
    input  logic [CONF_PE_COL - 1 : 0]                                          valid,
    output logic [CONF_PE_COL - 1 : 0]                                          ready,
    output logic [CONF_PE_COL - 1 : 0]                                          finish,
    input  logic [CONF_PE_COL - 1 : 0]                                          bit_mode_i, //0: normal 8-bit  1: 2-4bit, no reg
    input  logic [CONF_PE_COL - 1 : 0]                                          kernal_mode_i,
    input  logic [5 : 0][CONF_PE_COL - 1 : 0]                                   guard_map_i,
    input  logic [CONF_PE_COL - 1 : 0]                                          is_odd_row_i,
    input  logic [CONF_PE_COL - 1 : 0]                                          end_of_row_i,
    input  logic [25 * 8 - 1 : 0][CONF_PE_COL - 1 : 0][CONF_PE_ROW - 1 : 0]     weight_i,
    //
    input  logic [7 : 0][CONF_PE_COL - 1 : 0]                                   activation_i,
    output logic [CONF_PE_COL - 1 : 0]                                          activation_en_o,
    //
    output logic [3*6*PSUM_WIDTH - 1 : 0] [CONF_PE_ROW - 1 : 0]                 psum_ans_o,
    output logic [CONF_PE_ROW - 1 : 0]                                          psum_almost_valid
);
genvar i, j;

// - ctrl - for each collum ---------------------------------------------------------------------
// the following generate if for a collum
generate
    for(j = CONF_PE_COL - 1; j >= 0; j--)begin:inst_col_ctrl
        // - stream data ctrl-------------------------------------------
        state_t state, next_state;               //used by each PE
        weight_mode_t weight_mode;               //used by each PE
        logic [5 : 0]                            guard_map;
        logic                                    is_odd_row;
        logic                                    kernal_mode;
        logic                                    end_of_row;
        always_ff@(posedge clk or negedge rst_n)
            if(!rst_n)begin
                ready[j]  <= 1;
                finish[j] <= 0;
            end else begin
                if (valid[j] && ready[j])     ready[j] <= 0;
                if (finish[j] && !ready[j])   ready[j] <= 1;
                if (inst_matrix[0].fifo_full[j] && ready[j])    ready[j] <= 0;          //?
                if (inst_matrix[0].fifo_full[j] && !ready[j])   ready[j] <= 1;
                finish[j] <= 0;
                case(state)
                    IDLE:
                        if(valid[j] && ready[j] && guard_map_i == 0) finish[j] <= 1;
                    ONE:
                        if(guard_map[4:0] == 0) finish[j] <= 1;
                    TWO:
                        if(guard_map[3:0] == 0) finish[j] <= 1;
                    THREE:
                        if(guard_map[2:0] == 0) finish[j] <= 1;
                    FOUR:
                        if(guard_map[1:0] == 0) finish[j] <= 1;
                    FIVE:
                        if(guard_map[0] == 0) finish[j] <= 1;
                    SIX:
                        finish[j] <= 1;
                endcase 
            end

        always_ff@(posedge clk or negedge rst_n)
            if(!rst_n)
                {
                    guard_map,
                    is_odd_row,
                    kernal_mode,
                    end_of_row
                } <= '0;
            else begin
            if (valid[j] && ready[j]) begin
                    guard_map   <= bit_mode_i ? '1 : guard_map_i;
                    is_odd_row  <= is_odd_row_i;
                    kernal_mode <= kernal_mode_i;
                    end_of_row   <= end_of_row_i;
                end
            end
        // activation_en_o
        always_comb activation_en_o[j] = state == IDLE && !(valid[j] && ready[j]) ? 0 : 1;
        // - state & mode ---------------------------------------------------------
        always_ff@(posedge clk or negedge rst_n)
            if (!rst_n) state <= IDLE;
            else state <= next_state;

        always_comb 
            case(state)
                IDLE:
                    if(valid && ready)
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
            if(kernal_mode == 0) weight_mode = E_MODE;
            else 
                case(state)
                    ONE,THREE,FIVE: 
                        weight_mode = is_odd_row ? A_MODE : B_MODE;
                    TWO,FOUR,SIX:
                        weight_mode = is_odd_row ? C_MODE : D_MODE;
                endcase
        
    end
endgenerate

// - PEs and adder tree ----------------------------------------------------------------

// generate COL * ROW of PE
generate
    for(i = CONF_PE_ROW - 1; i >= 0; i--)begin:inst_matrix
        logic                           fifo_rd_en;
        logic [CONF_PE_COL - 1 : 0]     fifo_empty;
        logic [CONF_PE_COL - 1 : 0]     fifo_full;
        logic [3*6*PSUM_WIDTH - 1 : 0]  psum_tmp;
        always_comb fifo_rd_en = ~|fifo_empty;
        for(j = CONF_PE_COL - 1; j >= 0; j--)begin:inst_row
            logic [3*6*PSUM_WIDTH - 1:0] fifo_dout;
            PE(
                .*,
                .state          (inst_col_ctrl[j].state),
                .weight_mode    (inst_col_ctrl[j].weight_mode),
                .finish         (inst_col_ctrl[j].finish),
                .end_of_row     (inst_col_ctrl[j].end_of_row),
                .weight_i       (weight_i[i][j]), 
                .activation_i   (activation_i[j]),
                .fifo_rd_en_o   (fifo_rd_en),
                .fifo_dout_o    (fifo_dout),
                .fifo_empty_o   (fifo_empty[j]),
                .fifo_full_o    (fifo_full[j])
            );
            always_comb psum_tmp = psum_tmp + fifo_dout;                //could be optimised for less logic;       adder tree? ok here?
        end

        always_comb psum_ans_o = psum_tmp;
        always_comb psum_almost_valid[i] = fifo_rd_en;     //will be valid next clk cycle
        /*always_ff@(posedge clk or negedge rst_n)
            if(!rst_n) psum_valid[i] <= 0;
            else psum_valid[i] <= fifo_rd_en;*/
    end
endgenerate

endmodule