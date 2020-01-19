/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191127

Modify:

Notes:
1. weight format
2. 
=========================================================*/
import diff_demo_pkg::*;

module PE (
    input  logic                                    clk,
    input  logic                                    rst_n,
    //
    input  PE_state_t                               state,
    input  PE_weight_mode_t                         weight_mode,
    input  logic                                    finish,         //finish signal by col ctrl
    input  logic                                    is_first,       // activation of first layer needs sign extention    
    input  logic                                    end_of_row,
    input  logic [25 * 8 - 1 : 0]                   weight_i,
    //
    input  logic [7 : 0]                            activation_i,
    //
    input  logic                                    bit_mode,
    //
    input  logic                                    fifo_rd_en_o,
    output logic [3*6*PSUM_WIDTH - 1 : 0]           fifo_dout_o,
    output logic                                    fifo_empty_o,
    output logic                                    fifo_full_o
);
genvar i, j;
// - general ----------------------------------------------
logic signed [7 : 0][2 : 0][PSUM_WIDTH - 1 : 0] pre_psum, pre_psum_next;

// special for 5*5 kernel
logic tick_tock;            // even or odd row
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) 
        tick_tock <= 0;
    else begin
        if(end_of_row && finish)                                                // reset when start?
            tick_tock <= 0;
        else if(finish) 
            tick_tock <= tick_tock +  1;
    end 
// - weight -------------------------------------------------------
PE_weight_t weight;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) weight <= 0;
    else weight <= weight_i;
// - 9 muls--------------------------------------------------------
logic signed [8 : 0][7: 0] mul_b;  //for easy coding
logic [8 : 0][PSUM_WIDTH-1: 0] mul_ans;//for easy coding
generate
    for(i = 8; i >=0; i--) begin:mul
        multiplier inst_mul(
            .mode(bit_mode),
            .is_first(is_first),
            .a(activation_i),
            .b(mul_b[i]),
            .ans(mul_ans[i])
        );
    end
endgenerate
//mul assignment: considered balance and energy save
always_comb begin
    mul_b = '0;
    case(weight_mode)
        E_MODE,A_MODE:
            mul_b = weight.A_9;
        B_MODE:begin
            mul_b[8:3] = weight.B_6;
        end
        C_MODE:begin
            mul_b[5:0] = weight.C_6;
        end
        D_MODE:begin
            {mul_b[8:7],mul_b[1:0]} =  weight.D_4;
        end
    endcase
end

// - 6 adders -------------------------------------------------------
logic [5 : 0][PSUM_WIDTH - 1 : 0] add_a;  
logic [5 : 0][PSUM_WIDTH - 1 : 0] add_b;  
logic [5 : 0][PSUM_WIDTH - 1 : 0] add_ans;  
generate
    for(i = 5; i >=0; i--) begin:inst_add
        adder#(
            .WIDTH(PSUM_WIDTH)
        )an_adder(
            .a(add_a[i]),
            .b(add_b[i]),
            .ans(add_ans[i]),
            .bit_mode(bit_mode)
        );
    end
endgenerate
//add assignment: to be optimise for energy save
always_comb begin
    add_a = '0;
    add_b = '0;
    case(weight_mode)
        E_MODE:begin
            if(state != IDLE) add_a = {pre_psum[8-state], pre_psum[7-state]};
            add_b = mul_ans[8:3];
        end
        A_MODE, B_MODE:begin
            add_a = {pre_psum[8-(((state+1)) >> 1)], pre_psum[7-(((state+1)) >> 1)]};
            add_b = mul_ans[8:3];
        end
        C_MODE:begin
            add_a = {pre_psum[8-(((state+1)) >> 1)], pre_psum[7-(((state+1))  >> 1)]};
            add_b = {/*wasted*/mul_ans[0],mul_ans[5:4],/*wasted*/mul_ans[0],mul_ans[3:2]}; // adder[5],adder[2] are wasted
        end  
        D_MODE:begin
            add_a = {pre_psum[8-(((state+1)) >> 1)], pre_psum[7-(((state+1)) >> 1)]};
            add_b = {/*wasted*/mul_ans[0],mul_ans[8:7],/*wasted*/mul_ans[0],mul_ans[1:0]};
        end
    endcase
end

// - psum ---------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) 
        pre_psum <= '0;
    else if(finish == 1 && end_of_row)      // deal with corner value
        pre_psum <= '0;
    else if(finish == 1 && tick_tock)
        pre_psum <= pre_psum_next[1:0] << (6*3*PSUM_WIDTH);
    else if (state != IDLE) 
        pre_psum <= pre_psum_next;

always_comb begin
    pre_psum_next <= pre_psum;
    if (state != IDLE) 
    case(weight_mode)
        E_MODE: begin
            {pre_psum_next[8-state],pre_psum_next[7-state]} <= add_ans;
            pre_psum_next[6-state] <= mul_ans[2:0];
        end
        A_MODE: 
            if(!tick_tock) begin
                {pre_psum_next[8-(state/2 + 1)],pre_psum_next[7-(state/2 + 1)]} <= add_ans;
                pre_psum_next[6-(state/2 + 1)] <= mul_ans[2:0];
            end else begin
                {pre_psum_next[5-(state/2 + 1)],pre_psum_next[4-(state/2 + 1)]} <= add_ans;
                pre_psum_next[3-(state/2 + 1)] <= mul_ans[2:0];
            end
        B_MODE:
            if(!tick_tock) 
                {pre_psum_next[8-(state/2 + 1)],pre_psum_next[7-(state/2 + 1)]} <= add_ans;
            else 
                {pre_psum_next[5-(state/2 + 1)],pre_psum_next[4-(state/2 + 1)]} <= add_ans;
        C_MODE:
            if(!tick_tock) begin
                pre_psum_next[8-(state/2 + 1)][1:0] <= add_ans[4:3];
                pre_psum_next[7-(state/2 + 1)][1:0] <= add_ans[1:0];
                //pre_psum_next[8-(state/2 + 1)][2] <= '0;                                //clear: unnecessary
                //pre_psum_next[7-(state/2 + 1)][2] <= '0;
                pre_psum_next[6 - (state/2 + 1)][1:0] <= mul_ans[1:0];
            end else begin
                pre_psum_next[5-(state/2 + 1)][1:0] <= add_ans[4:3];
                pre_psum_next[4-(state/2 + 1)][1:0] <= add_ans[1:0];
                //pre_psum_next[8-(state/2 + 1)][2] <= '0;                                //clear: unnecessary
                //pre_psum_next[7-(state/2 + 1)][2] <= '0;
                pre_psum_next[3 - (state/2 + 1)][1:0] <= mul_ans[1:0];

            end
        D_MODE:
            if(!tick_tock) begin
                pre_psum_next[8-(state/2 + 1)][1:0] <= add_ans[4:3];
                pre_psum_next[7-(state/2 + 1)][1:0] <= add_ans[1:0];
                //pre_psum_next[8-(state/2 + 1)][2] <= '0;
                //pre_psum_next[7-(state/2 + 1)][2] <= '0;
            end else begin
                pre_psum_next[5-(state/2 + 1)][1:0] <= add_ans[4:3];
                pre_psum_next[4-(state/2 + 1)][1:0] <= add_ans[1:0];
                //pre_psum_next[5-(state/2 + 1)][2] <= '0;
                //pre_psum_next[4-(state/2 + 1)][2] <= '0;
            end
    endcase
end
// - fifo ----------------------------------------------------------
logic [2 : 0][5 : 0][PSUM_WIDTH - 1 : 0] fifo_din;
// Trans                                                                                   how to avoid strange logic gen by systhesis tool?
generate 
    for(i = 5; i >= 0; i --) begin: trans_i
        for(j = 2; j >= 0; j --) begin:trans_j
            assign fifo_din[j][i] = pre_psum_next[i][j];             //now op for performance, could op for timing here: pospone 1 clk cycle wr
        end
    end
endgenerate

fifo_sync #(
    .DATA_WIDE(3*6*PSUM_WIDTH),
    .FIFO_DEPT(FIFO_DEPTH),
    .MODE("block")
)inst_fifo(
    .*,
    .din(fifo_din),
    .wr_en(finish && (weight_mode == E_MODE || weight_mode != E_MODE && (tick_tock || end_of_row))),
    .dout(fifo_dout_o),
    .rd_en(fifo_rd_en_o),
    .full(fifo_full_o),
    .empty(fifo_empty_o)
);
endmodule