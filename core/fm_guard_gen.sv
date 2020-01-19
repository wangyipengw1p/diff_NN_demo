/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191128

Modify:

Notes:
1. 

TODO:
? 32 bit -> 8 bit ?
optimise the adder
bian zhi
bias
=========================================================*/
import diff_demo_pkg::*;
module fm_guard_gen(
    input  logic                                clk,
    input  logic                                rst_n,
    //
    input  logic [7:0]                          w_num,
    input  logic [7:0]                          h_num,
    input  logic                                kernel_mode,
    input  logic                                bit_mode,
    input  logic                                running,
    input  logic [7:0]                          count_w,
    input  logic [7:0]                          count_h,
    input  logic [7:0]                          count_c,
    input  logic [7:0]                          wb_w_num_i,
    input  logic [7:0]                          wb_h_num_i,
    input  logic [7:0]                          wb_w_cut_i,
    input  logic [3:0]                          shift_bias,
    input  logic [3:0]                          shift_wb,
    input  logic                                is_diff,
    input  logic                                frm_is_ref,
    input  logic                                is_first,
    input  logic                                is_last,
    input  logic                                is_even_row,              // distinguish odd and even lines
    input  logic                                is_even_even_row,         // 0 0 1 1 0 0 1 1 0 0 ...
    input  logic [1:0]                          count_3,
    //
    input  logic                                psum_almost_valid,
    input  logic [3 * 6 * PSUM_WIDTH - 1 : 0 ]  psum_ans_i,
    //
    input  logic [7:0]                          bias_i,
    //
    output logic                                write_back_finish,
    output logic [7:0]                          write_back_data_o,   
    //output logic                                fm_buf_ready,           
    output logic                                write_back_data_o_valid, 
    output logic [5:0]                          guard_o,       
    //output logic                                guard_buf_ready,         
    output logic                                guard_o_valid,
    output logic                                wb_bit_mode           

);
// - declearation -------------------------------------------------------
logic psum_valid;       // delayed psum_almost_valid
always_ff@(posedge clk or negedge rst_n) if(!rst_n) psum_valid <= 0; else psum_valid <= psum_almost_valid;
logic write_back_ready; //                                                                              !!!
genvar i, j;
// - tmp line buffer -----------------------------------------------------------------
logic [$clog2(FM_GUARD_GEN_TMP_BUF_DEPTH) - 1 : 0] tmp_buf_rd_addr, tmp_buf_wr_addr;
//logic [$clog2(FM_GUARD_GEN_BUF_DEPTH) - 1 : 0] buf_rd_addr;
logic [3*6*PSUM_WIDTH - 1 : 0] buf_data_in, buf_data_out_1, buf_data_out_2;
logic buf_wr_en_1, buf_wr_en_2;
logic [5:0][PSUM_WIDTH - 1 : 0] add_a, add_b, add_c, add_d, add_ans_1, add_ans_2;
logic [5:0][PSUM_WIDTH - 1 : 0] add_1, add_2, add_3, add_4, add_ans_m, add_ans_n;

two_port_mem #(
    .BIT_LENGTH(3*6*PSUM_WIDTH),
    .DEPTH(FM_GUARD_GEN_TMP_BUF_DEPTH)
) tmp_buf_1 (
    .*,
    .addra      (tmp_buf_wr_addr),
    .addrb      (tmp_buf_rd_addr),
    .dina       (buf_data_in),
    .wea        (buf_wr_en_1),
    .enb        ('1),
    .doutb      (buf_data_out_1)
);
two_port_mem #(
    .BIT_LENGTH(3*6*PSUM_WIDTH),
    .DEPTH(FM_GUARD_GEN_TMP_BUF_DEPTH)
) tmp_buf_2 (
    .*,
    .addra      (tmp_buf_wr_addr),
    .addrb      (tmp_buf_rd_addr),
    .dina       (buf_data_in),
    .wea        (buf_wr_en_2),
    .enb        ('1),
    .doutb      (buf_data_out_2)
);

always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)
        {
            tmp_buf_rd_addr,tmp_buf_wr_addr
        } <= '0;
    else if(!running) {
            tmp_buf_rd_addr,tmp_buf_wr_addr
        } <= '0;
    else begin
        if (psum_valid)
            if (count_w < (kernel_mode ? 12 : 6)) tmp_buf_wr_addr <= 0;
            else tmp_buf_wr_addr <= tmp_buf_wr_addr + 1;
        if (psum_almost_valid)
            if (count_w < (kernel_mode ? 12 : 6)) tmp_buf_rd_addr <= 0;
            else tmp_buf_rd_addr <= tmp_buf_rd_addr + 1;
    end
//  - en and din assignment -----------------------------------------------------------------------------
generate 
    for(j = 5; j >= 0; j--) begin:inst_add_even_row_5kernel
        adder #(
            .WIDTH(PSUM_WIDTH)
        )adder1(
            .a(add_1[j]),
            .b(add_2[j]),
            .ans(add_ans_m[j]),
            .bit_mode(bit_mode)
        );
        adder #(
            .WIDTH(PSUM_WIDTH)
        )adder2(
            .a(add_3[j]),
            .b(add_4[j]),
            .ans(add_ans_n[j]),
            .bit_mode(bit_mode)
        );
    end
endgenerate
always_comb begin
    buf_wr_en_1 = kernel_mode ?  ~is_even_even_row & psum_valid : ~is_even_row & psum_valid;
    buf_wr_en_2 = kernel_mode ?  is_even_even_row & psum_valid  : is_even_row & psum_valid;
    if(kernel_mode) begin //5*5
        case (count_3)
            2'b00:                                                                  
                buf_data_in = ~is_even_row ? ~is_even_even_row ? {psum_ans_i[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH], add_ans_m, add_ans_n}     //for even row of 5*5 kernel
                                                              : {psum_ans_i[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH], add_ans_m, add_ans_n}
                                          : psum_ans_i;
            2'b01:
                buf_data_in = ~is_even_row ? ~is_even_even_row ? {add_ans_n, psum_ans_i[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH], add_ans_m}
                                                              : {add_ans_n, psum_ans_i[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH], add_ans_m}
                                          : {psum_ans_i[6*PSUM_WIDTH - 1 : 0], psum_ans_i[3*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH]};
            2'b10:
                buf_data_in = ~is_even_row ? ~is_even_even_row ? {add_ans_m, add_ans_n, psum_ans_i[6*PSUM_WIDTH - 1 : 0]}
                                                              : {add_ans_m, add_ans_n, psum_ans_i[6*PSUM_WIDTH - 1 : 0]}
                                          :{psum_ans_i[2*6*PSUM_WIDTH - 1 : 0], psum_ans_i[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH]};
            default:
                buf_data_in = '0;
        endcase
    end else begin  //3*3
        case (count_3)
            2'b00:
                buf_data_in = psum_ans_i;
            2'b01:
                buf_data_in = {psum_ans_i[6*PSUM_WIDTH - 1 : 0], psum_ans_i[3*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH]};
            2'b10:
                buf_data_in = {psum_ans_i[2*6*PSUM_WIDTH - 1 : 0], psum_ans_i[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH]};
            default:
                buf_data_in = '0;
        endcase
    end
end
always_comb begin
    {add_1, add_2, add_3, add_4} = '0;
    if(kernel_mode) begin
        add_1 = psum_ans_i[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
        add_3 = psum_ans_i[6*PSUM_WIDTH - 1 : 0];
        case (count_3)
            2'b00:begin
                add_2 = ~is_even_even_row ? buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH] : buf_data_out_2[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                add_4 = ~is_even_even_row ? buf_data_out_1[6*PSUM_WIDTH - 1 : 0] : buf_data_out_2[6*PSUM_WIDTH - 1 : 0];
            end
            2'b01:begin
                add_2 = ~is_even_even_row ? buf_data_out_1[6*PSUM_WIDTH - 1 : 0] : buf_data_out_2[6*PSUM_WIDTH - 1 : 0];
                add_4 = ~is_even_even_row ? buf_data_out_1[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH] : buf_data_out_2[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
            end
            2'b10:begin
                add_2 = ~is_even_even_row ? buf_data_out_1[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH] : buf_data_out_2[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                add_4 = ~is_even_even_row ? buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH] : buf_data_out_2[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
            end
        endcase
        
    end
end
//  - adder assignment, with corner value considered --------------------------------------------------------
generate 
    for(j = 5; j >= 0; j--) begin:inst_add_lines_of_psum
        adder #(
            .WIDTH(PSUM_WIDTH)
        )adder1(
            .a(add_a[j]),
            .b(add_b[j]),
            .ans(add_ans_1[j]),
            .bit_mode(bit_mode)
        );
        adder #(
            .WIDTH(PSUM_WIDTH)
        )adder2(
            .a(add_d[j]),
            .b(add_c[j]),
            .ans(add_ans_2[j]),
            .bit_mode(bit_mode)
        );
    end
endgenerate
always_comb begin
{
    add_a,
    add_b,
    add_c,
    add_d
} = '0;
if(kernel_mode)//5*5
    /*case(count_h)
        h_num - 1 : begin
            add_a = psum_ans_i[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
            add_b = '0;
            add_c = '0;
            add_d = add_ans_1;
        end
        h_num - 2: begin
            add_a = '0;
            add_b = '0;
            add_c = psum_ans_i[6*PSUM_WIDTH - 1 : 0];
            add_d = is_even_even_row ? buf_data_out_2[6*PSUM_WIDTH - 1 : 0] : buf_data_out_1[6*PSUM_WIDTH - 1 : 0];
        end
        h_num - 3:begin
            add_a = psum_ans_i[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
            add_b = is_even_even_row ? buf_data_out_2[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH] : buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
            add_c = '0;
            add_d = add_ans_1;
        end
        default:*/
        if (is_even_row) //even row
            case (count_3)
                2'b00:begin
                    add_a = psum_ans_i[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                    add_b = is_even_even_row ? buf_data_out_2[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH] : buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                    add_c = psum_ans_i[6*PSUM_WIDTH - 1 : 0];
                    add_d = is_even_even_row ? buf_data_out_2[6*PSUM_WIDTH - 1 : 0] : buf_data_out_1[6*PSUM_WIDTH - 1 : 0];
                end
                2'b01:begin
                    add_a = psum_ans_i[6*PSUM_WIDTH - 1 : 0];
                    add_b = is_even_even_row ? buf_data_out_2[6*PSUM_WIDTH - 1 : 0] : buf_data_out_1[6*PSUM_WIDTH - 1 : 0];
                    add_c = psum_ans_i[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH - 1];
                    add_d = is_even_even_row ? buf_data_out_2[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH - 1] : buf_data_out_1[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH - 1];
                end
                2'b10:begin
                    add_a = psum_ans_i[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                    add_b = is_even_even_row ? buf_data_out_2[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH] : buf_data_out_1[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                    add_c = psum_ans_i[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH - 1];
                    add_d = is_even_even_row ? buf_data_out_2[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH - 1] : buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH - 1];
                end
                default:begin
                    add_a = '0;
                    add_b = '0;
                    add_c = '0;
                    add_d = '0;
                end
            endcase
        else begin  //odd row
            add_d = add_ans_1;
            case (count_3)
                2'b00:begin
                    add_a = psum_ans_i[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                    add_b = buf_data_out_1[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                    add_c = buf_data_out_2[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                end
                2'b01:begin
                    add_a = psum_ans_i[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                    add_b = buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                    add_c = buf_data_out_2[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                end
                2'b10:begin
                    add_a = psum_ans_i[6*PSUM_WIDTH - 1 : 0];
                    add_b = buf_data_out_1[6*PSUM_WIDTH - 1 : 0];
                    add_c = buf_data_out_2[6*PSUM_WIDTH - 1 : 0];
                end
                default:begin
                    add_a = '0;
                    add_b = '0;
                    add_c = '0;
                end
            endcase
        end
    /*endcase*/
else begin       //3*3
    add_d = add_ans_1;
    /*if(count_h == h_num - 1) begin                                  //corner value
        add_a = psum_ans_i[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
        add_b = '0;
        add_c = '0;
    end else if (count_h == h_num - 2)begin
        add_a = psum_ans_i[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
        add_b = buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
        add_c = '0;
    end else*/
    case (count_3)
        2'b00:begin
            add_a = psum_ans_i[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
            add_b = buf_data_out_1[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
            add_c = buf_data_out_2[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
        end
        2'b01:begin
            add_a = psum_ans_i[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
            add_b = buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
            add_c = buf_data_out_2[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
        end
        2'b10:begin
            add_a = psum_ans_i[6*PSUM_WIDTH - 1 : 0];
            add_b = buf_data_out_1[6*PSUM_WIDTH - 1 : 0];
            add_c = buf_data_out_2[6*PSUM_WIDTH - 1 : 0];
        end
        default:begin
            add_a = '0;
            add_b = '0;
            add_c = '0;
        end
    endcase
end
end
// - psum buffer -----------------------------------------------------
logic [$clog2(FM_GUARD_GEN_PSUM_BUF_DEPTH) - 1 : 0] psum_buf_wr_addr, psum_buf_rd_addr, writeback_rd_addr;
logic [5:0][PSUM_WIDTH - 1 : 0]                     psum_buf_data_in, psum_buf_data_out;
logic signed [5:0][PSUM_WIDTH - 1 : 0]              psum_buf_data_out_for_write_back;
logic [5:0][PSUM_WIDTH - 1 : 0]                     psum_add_ans, psum_add_ans_for_4_bit, psum_add_bias_ans;
logic                                               psum_buf_ping_pong, psum_buf_wr_en;
logic signed [5:0][PSUM_WIDTH - 1 : 0]              bias_to_add;
logic [5:0][PSUM_WIDTH - 1 : 0]                     after_diff;
logic                                               psum_buf_wr_addr_dont_increase;




always_comb psum_buf_wr_en = ~psum_buf_wr_addr_dont_increase && psum_valid;
ping_pong_buffer #(
    .BIT_LENGTH(6*PSUM_WIDTH),
    .DEPTH(FM_GUARD_GEN_PSUM_BUF_DEPTH)
) psum_buf (
    .*,
    .addr1w     (psum_buf_wr_addr),
    .addr1r     (psum_buf_rd_addr),
    .addr2      (writeback_rd_addr),
    .din1       (psum_buf_data_in),
    .din2       ('0),
    .we1        (psum_buf_wr_en),
    .we2        ('0),
    .dout1      (psum_buf_data_out),
    .dout2      (psum_buf_data_out_for_write_back),
    .ping_pong  (psum_buf_ping_pong)
);

generate 
    for( i = 5; i >=0; i--)begin:add_for_psum_buf
        logic [PSUM_WIDTH - 1 : 0] adder_psum_a;
        always_comb adder_psum_a = bit_mode ? psum_add_ans_for_4_bit[i] : add_ans_2[i];
        always_comb bias_to_add[i] = $signed(bias_i) <<< shift_bias;                            //shift
        //always_comb tmp_add_a = count_c < (bit_mode ? 2*CONF_PE_COL : CONF_PE_COL) ? is_diff && bit_mode ?  after_diff[i] : bias_to_add[i] + add_ans_2[i] : add_ans_2[i];       //to be optimised
        adder #(
            .WIDTH(PSUM_WIDTH)
        )adder_psum(
            .a(adder_psum_a),
            .b(psum_buf_data_out[i]),
            .ans(psum_add_ans[i]),
            .bit_mode(bit_mode)
        );
        adder #(
            .WIDTH(PSUM_WIDTH / 2)
        )adder_for_4_bit(
            .a(add_ans_2[i][PSUM_WIDTH - 1 : PSUM_WIDTH / 2]),
            .b(add_ans_2[i][PSUM_WIDTH / 2 - 1 : 0]),
            .ans(psum_add_ans_for_4_bit[i]),
            .bit_mode('0)
        );
        adder #(
            .WIDTH(PSUM_WIDTH)
        )add_bias(
            .a(bias_to_add[i]),
            .b(psum_add_ans[i]),
            .ans(psum_add_bias_ans[i]),
            .bit_mode('0)
        );
    

    //main diff process
    always_comb 
        if(count_c < (bit_mode ? 2*CONF_PE_COL : CONF_PE_COL))
            if(is_diff && bit_mode) begin
                psum_buf_data_in[i] = frm_is_ref ? psum_add_ans[i] < 0 ? '0 : psum_add_ans[i] : after_diff[i];
            end else 
                psum_buf_data_in[i] = psum_add_bias_ans[i];
        else 
            psum_buf_data_in[i] = psum_add_ans[i];


    end     //for
endgenerate

always_ff@(posedge clk or negedge rst_n)
    if(!rst_n){
            psum_buf_wr_addr,
            psum_buf_rd_addr
        } <= '0;
    else if(!running) {
            psum_buf_wr_addr,
            psum_buf_rd_addr
        } <= '0;
    else if(!psum_buf_wr_addr_dont_increase && psum_almost_valid) 
        if (count_h == 0 && count_w < (kernel_mode ? 24 : 12) && count_w >= (kernel_mode ? 12 : 6)) psum_buf_rd_addr <= 0;                 
        else psum_buf_rd_addr <= psum_buf_rd_addr + 1;
    else if(!psum_buf_wr_addr_dont_increase && psum_valid) begin
        if (count_h == 0 && count_w < (kernel_mode ? 12 : 6)) psum_buf_wr_addr <= 0;                 
        else psum_buf_wr_addr <= psum_buf_wr_addr + 1;
    end
always_comb 
    if(kernel_mode)  //5*5
        psum_buf_wr_addr_dont_increase =  count_h < h_num - 4 || count_h[0] == 0 ? 1 : 0;
    else //3*3
        psum_buf_wr_addr_dont_increase = count_h < h_num - 2 ? 1 : 0;
    

// - diff process -------------------------------------------------------------
logic signed [5:0][PSUM_WIDTH - 1 : 0] after_sum_with_ref, after_sum_with_ref_and_relu;
logic signed [5:0][PSUM_WIDTH - 1 : 0] ref_after_relu, minus_ref_after_relu, add_ref_a;
logic signed [5:0][7 : 0]  ref_buf_data_in,ref_buf_data_out;
generate 
    for( i = 5; i >=0; i--)begin:add_for_diff_process
        adder #(
            .WIDTH(PSUM_WIDTH)
        ) add_ref (
            .a(add_ref_a[i]),      
            .b(psum_add_ans[i]),
            .ans(after_sum_with_ref[i]),
            .bit_mode('0)
        );
        always_comb add_ref_a[i] = ref_buf_data_out[i];
        //relu
        always_comb after_sum_with_ref_and_relu[i] =  after_sum_with_ref[i] < 0 ?  '0 : after_sum_with_ref[i];
        always_comb ref_after_relu[i] = ref_buf_data_out[i] < 0 ?  '0 : ref_buf_data_out[i];
        always_comb minus_ref_after_relu[i] = (~ref_after_relu[i]) + 1;
        always_comb ref_buf_data_in[i] = frm_is_ref ? {psum_add_ans[i][PSUM_WIDTH - 1], psum_add_ans[i][6:0]} : {after_sum_with_ref[i][PSUM_WIDTH - 1], after_sum_with_ref[i][6:0]};     // truncate with sign bit
        adder #(
            .WIDTH(PSUM_WIDTH)
        ) minus_after_relu (
            .a(after_sum_with_ref_and_relu[i]),
            .b(minus_ref_after_relu[i]),
            .ans(after_diff[i]),
            .bit_mode('0)
        );
    end
endgenerate

// - ref buf ------------------------------------------------------------------
// 8 bit for ref, maybe not desired
logic [$clog2(FM_GUARD_GEN_REF_BUF_DEPTH) - 1 : 0] ref_buf_rd_addr, ref_buf_wr_addr;
logic ref_buf_wr_en;
logic is_first_d;
two_port_mem #(
    .BIT_LENGTH(6*8),
    .DEPTH(FM_GUARD_GEN_REF_BUF_DEPTH)
) ref_buf (
    .*,
    .addra      (ref_buf_wr_addr),
    .addrb      (ref_buf_rd_addr),
    .dina       (ref_buf_data_in),
    .wea        (ref_buf_wr_en),
    .enb        ('1),
    .doutb      (ref_buf_data_out)
);
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) {ref_buf_wr_addr, ref_buf_rd_addr , is_first_d} <=  '0;
    else begin
        if(is_first && !is_first_d) {ref_buf_wr_addr, ref_buf_rd_addr} <=  '0;
        else if(count_c < (bit_mode ? 2*CONF_PE_COL : CONF_PE_COL) && bit_mode && !psum_buf_wr_addr_dont_increase)begin
            if(psum_valid)ref_buf_wr_addr <= ref_buf_wr_addr + 1;
            if(psum_almost_valid) ref_buf_rd_addr <= ref_buf_rd_addr + 1;
        end
    end
always_comb ref_buf_wr_en = count_c < (bit_mode ? 2*CONF_PE_COL : CONF_PE_COL) && bit_mode && !psum_buf_wr_addr_dont_increase && psum_valid?  1 : 0;
// - relu_guard_write_back ----------------------------------------------------
logic write_back_valid;                                       ///ready output
write_back inst_relu_guard_write_back(
    .*,
    .ctrl_valid          (write_back_valid),       
    .ctrl_ready          (write_back_ready),                                                    // no connection now 
    .ctrl_finish         (write_back_finish),  
    .wb_w_num_i          (wb_w_num_i),
    .wb_h_num_i          (wb_h_num_i),
    .wb_w_cut_i          (wb_w_cut_i),
    .is_last             (is_last),
    //.bit_mode_i          (bit_mode),
    .is_diff_i           (is_diff),
    .shift_wb            (shift_wb),
    .data_i              (psum_buf_data_out_for_write_back),   
    .addr_o              (writeback_rd_addr),   
    .data_o              (write_back_data_o), 
    //.fm_buf_ready        (fm_buf_ready),           
    .data_o_valid        (write_back_data_o_valid),           
    .guard_o             (guard_o),       
    //.guard_buf_ready     (guard_buf_ready),               
    .guard_o_valid       (guard_o_valid),
    .wb_bit_mode         (wb_bit_mode)           
);
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)
        {
            write_back_valid,
            psum_buf_ping_pong
        } <= '0;
    else begin
        write_back_valid <= 0;
        if(count_c < (bit_mode ? 2*CONF_PE_COL : CONF_PE_COL) && count_h == 0 && count_w < (kernel_mode ? 12 : 6) && psum_almost_valid && ((!bit_mode && !is_diff) || (bit_mode && is_diff)) && running) begin        
            write_back_valid <= 1;
            psum_buf_ping_pong <= ~psum_buf_ping_pong;
        end
    end
endmodule
