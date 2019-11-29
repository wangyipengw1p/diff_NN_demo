/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191127

Modify:

Notes:
1. weight format
2. 
=========================================================*/
import diff_core_pkg::*;

module PE (
    input  logic                                    clk,
    input  logic                                    rst_n,
    //
    input  PE_state_t                               state,
    input  PE_weight_mode_t                         weight_mode,
    input  logic                                    finish_i,
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
logic [PSUM_WIDTH - 1 : 0][2 : 0][7 : 0] pre_psum;

// special for 5*5 kernal
logic tick_tock;    
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) 
        tick_tock <= 0;
    else if(weight_mode == E_MODE)
        tick_tock <= 1;
    else if(end_of_row && finish) 
        tick_tock <= 0;
    else if(finish) 
        tick_tock += 1;
// - weight -------------------------------------------------------
PE_weight_t weight;
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) weight <= 0;
    else weight <= weight_i;
// - 9 muls--------------------------------------------------------
logic [7 : 0][8 : 0] mul_b;  //for easy coding
logic [15: 0][8 : 0] mul_ans;//for easy coding
logic [PSUM_WIDTH-1: 0][8 : 0] mul_ans_conv;//for bit length conversion
generate
    for(genvar i = 8; i >=0; i--) begin:mul
        multiplier inst_mul(
            .mode(bit_mode),
            .a(activation_i),
            .b(mul_b[i]),
            .ans(mul_ans[i])
        );
        always_comb mul_ans_conv[i] = mul_ans[i];
    end
endgenerate
//mul assignment: considered balance and energy save
always_comb begin
    case(weight_mode)
        E_MODE,A_MODE:
            mul_b = weight.A_9;
        B_MODE:begin
            mul_b[8:3] = weight.B_6;
            mul_b[2:0] = weight.A_9[2:0];   //hold, for energy save
        end
        C_MODE:begin
            mul_b[8:6] = weight.B_6[5:3];   //hold
            mul_b[5:0] = weight.C_6;
        end
        D_MODE:begin
            {mul_b[8:7],mul_b[1:0]} =  weight.D_4;
            mul_b[6] = weight.B_6[3];       //hold
            mul_b[5:2] = weight.C_6[5:2];    //hold
        end
    endcase
end

// - 6 adders -------------------------------------------------------
logic [PSUM_WIDTH - 1 : 0][5 : 0] add_a;  
logic [PSUM_WIDTH - 1 : 0][5 : 0] add_b;  
logic [PSUM_WIDTH - 1 : 0][5 : 0] add_ans;  
generate
    for(i = 5; i >=0; i--) begin:inst_add
        adder#(
            .WIDTH(PSUM_WIDTH)
        )an_adder(
            .a(add_a[i]),
            .b(add_b[i]),
            .ans(add_ans[i])
        );
    end
endgenerate
//add assignment: to be optimise for energy save
always_comb begin
    
    case(weight_mode)
        E_MODE:begin
            add_a = {pre_psum[8-state], pre_psum[7-state]};
            add_b = mul_ans_conv[8:3];
        end
        A_MODE, B_MODE:begin
            add_a = {pre_psum[8-(state+1 >> 1)], pre_psum[7-(state+1 >> 1)]};
            add_b = mul_ans_conv[8:3];
        end
        C_MODE:begin
            add_a = {pre_psum[8-(state+1 >> 1)], pre_psum[7-(state+1  >> 1)]};
            add_b = {/*wasted*/mul_ans_conv[0],mul_ans_conv[5:4],/*wasted*/mul_ans_conv[0],mul_ans_conv[3:2]}; // adder[5],adder[2] are wasted
        end  
        D_MODE:begin
            add_a = {pre_psum[8-(state+1 >> 1)], pre_psum[7-(state+1 >> 1)]};
            add_b = {/*wasted*/mul_ans_conv[0],mul_ans_conv[8:7],/*wasted*/mul_ans_conv[0],mul_ans_conv[1:0]};
        end
    endcase
end

// - psum ---------------------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) 
        pre_psum <= '0;
    else if(finish == 1 && end_of_row)
        pre_psum <= '0;
    else if(finish == 1 && tick_tock)
        pre_psum <= {pre_psum[1:0],'0};
    else if (state != IDLE) begin
        case(weight_mode)
            E_MODE: begin
                {pre_psum[8-state],pre_psum[7-state]} <= add_ans;
                pre_psum[6-state] <= mul_ans_conv[2:0];
            end
            A_MODE: 
                if(!tick_tock) begin
                    {pre_psum[8-(state+1 >> 1)],pre_psum[7-(state+1 >> 1)]} <= add_ans;
                    pre_psum[6-(state+1 >> 1)] <= mul_ans_conv[2:0];
                end else begin
                    {pre_psum[5-(state+1 >> 1)],pre_psum[4-(state+1 >> 1)]} <= add_ans;
                    pre_psum[3-(state+1 >> 1)] <= mul_ans_conv[2:0];
                end
            B_MODE:
                if(!tick_tock) 
                    {pre_psum[8-(state+1 >> 1)],pre_psum[7-(state+1 >> 1)]} <= add_ans;
                else 
                    {pre_psum[5-(state+1 >> 1)],pre_psum[4-(state+1 >> 1)]} <= add_ans;
            C_MODE:
                if(!tick_tock) begin
                    {pre_psum[8-(state+1 >> 1)],pre_psum[7-(state+1 >> 1)]} <= add_ans;
                    pre_psum[8-(state+1 >> 1)][2] <= '0;                                //clear
                    pre_psum[7-(state+1 >> 1)][2] <= '0;
                    pre_psum[6-(state+1 >> 1)] <= {{PSUM_WIDTH{1'b0}},mul_ans_conv[1:0]};
                end else begin
                    {pre_psum[5-(state+1 >> 1)],pre_psum[4-(state+1 >> 1)]} <= add_ans;
                    pre_psum[5-(state+1 >> 1)][2] <= '0;
                    pre_psum[4-(state+1 >> 1)][2] <= '0;
                    pre_psum[3-(state+1 >> 1)] <= {{PSUM_WIDTH{1'b0}},mul_ans_conv[1:0]};
                end
            D_MODE:
                if(!tick_tock) begin
                    {pre_psum[8-(state+1 >> 1)],pre_psum[7-(state+1 >> 1)]} <= add_ans;
                    pre_psum[8-(state+1 >> 1)][2] <= '0;
                    pre_psum[7-(state+1 >> 1)][2] <= '0;
                end else begin
                    {pre_psum[5-(state+1 >> 1)],pre_psum[4-(state+1 >> 1)]} <= add_ans;
                    pre_psum[5-(state+1 >> 1)][2] <= '0;
                    pre_psum[4-(state+1 >> 1)][2] <= '0;
                end
        endcase
    end
// - fifo ----------------------------------------------------------
logic [PSUM_WIDTH - 1 : 0][5 : 0][2 : 0] fifo_din;
// Trans                                                                                   ok?
generate 
    for(i = 5; i >= 0; i --) begin: trans_i
        for(j = 2; j >= 0; j --) begin:trans_j
            always_comb fifo_din[j][i] = pre_psum[i][j];
        end
    end
endgenerate

fifo_sync #(
    .DATA_WIDE(3*6*PSUM_WIDTH),
    .FIFO_DEPT(FIFO_DEPTH)
)inst_fifo(
    .*,
    .din(fifo_din),
    .wr_en(finish && tick_tock),
    .dout(fifo_dout_o),
    .rd_en(fifo_rd_en_o),
    .full(fifo_full_o),
    .empty(fifo_empty_o)
);
endmodule