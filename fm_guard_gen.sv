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
    input  logic [7:0]                          count_w,
    input  logic [7:0]                          count_h,
    input  logic [7:0]                          count_c,
    input  logic                                is_even_row,              //distinguish odd and even lines
    input  logic                                is_even_even_row,         // 0 0 1 1 0 0 1 1 0 0 ...
    input  logic [1:0]                          count_3,
    //
    input  logic                                psum_almost_valid,
    input  logic [3 * 6 * PSUM_WIDTH - 1 : 0 ]  psum_ans_i,
    //
    input  logic [7:0][5:0]                     bias_i,
    //
    output logic                                write_back_finish,
    output logic [7:0]                          write_back_data_o,   
    output logic                                fm_buf_ready,           
    output logic                                write_back_data_o_valid, 
    output logic [5:0]                          guard_o,       
    output logic                                guard_buf_ready,         
    output logic                                guard_o_valid           

);
// - declearation -------------------------------------------------------
logic psum_valid;       // delayed psum_almost_valid
logic write_back_ready; //                                                                              !!!
genvar i, j;
// - tmp line buffer -----------------------------------------------------------------
logic [$clog2(FM_GUARD_GEN_TMP_BUF_DEPTH) - 1 : 0] buf_addr;
//logic [$clog2(FM_GUARD_GEN_BUF_DEPTH) - 1 : 0] buf_rd_addr;
logic [3*6*PSUM_WIDTH - 1 : 0] buf_data_in, buf_data_out_1, buf_data_out_2;
logic buf_wr_en_1, buf_wr_en_2;
logic [PSUM_WIDTH - 1 : 0][5:0] add_a, add_b, add_c, add_d, add_ans_1, add_ans_2;

two_port_mem #(
    .BIT_LENGTH(3*6*PSUM_WIDTH),
    .DRPTH(FM_GUARD_GEN_TMP_BUF_DEPTH)
) tmp_buf_1 (
    .clka       (clk),
    .clkb       (clk),
    .addra      (buf_addr),
    .addrb      (buf_addr),
    .dina       (buf_data_in),
    .wea        (buf_wr_en_1),
    .ena        ('1),
    .enb        (psum_almost_valid),
    .doutb      (buf_data_out_1)
);
two_port_mem #(
    .BIT_LENGTH(3*6*PSUM_WIDTH),
    .DRPTH(FM_GUARD_GEN_TMP_BUF_DEPTH)
) tmp_buf_2 (
    .clka       (clk),
    .clkb       (clk),
    .addra      (buf_addr),
    .addrb      (buf_addr),
    .dina       (buf_data_in),
    .wea        (buf_wr_en_2),
    .ena        ('1),
    .enb        (psum_almost_valid),
    .doutb      (buf_data_out_2)
);
generate 
    for(j = 5; j >= 0; j--) begin:inst_adder_line
        adder #(
            .WIDTH(PSUM_WIDTH)
        )adder1(
            .a(add_a[j]),
            .b(add_b[j]),
            .ans(add_ans_1[j])
        );
        adder #(
            .WIDTH(PSUM_WIDTH)
        )adder2(
            .a(add_d[j]),
            .b(add_c[j]),
            .ans(add_ans_2[j])
        );
    end
endgenerate
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)
        {
            buf_addr
        } <= '0;
    else if (psum_valid)begin
        if (buf_addr == (w_num - 1)) buf_addr <= 0;
        else buf_addr++;
    end
//  - en and din assignment -----------------------------------------------------------------------------
always_comb begin
    buf_wr_en_1 = kernel_mode ?  ~is_even_even_row & psum_valid : ~is_even_row & psum_valid;
    buf_wr_en_2 = kernel_mode ?  is_even_even_row & psum_valid  : is_even_row & psum_valid;
    if(kernel_mode) begin //3*3
        case (count_3)
            2'b00:                                                                  
                buf_data_in = is_even_row ? ~is_even_even_row ? {buf_data_out_1[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH], add_ans_1, add_ans_2}
                                                              : {buf_data_out_2[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH], add_ans_1, add_ans_2}
                                          : psum_ans_i;
            2'b01:
                buf_data_in = is_even_row ? ~is_even_even_row ? {add_ans_2, buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH], add_ans_1}
                                                              : {add_ans_2, buf_data_out_2[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH], add_ans_1}
                                          : {psum_ans_i[6*PSUM_WIDTH - 1 : 0], psum_ans_i[3*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH]};
            2'b10:
                buf_data_in = is_even_row ? ~is_even_even_row ? {add_ans_1, add_ans_2, buf_data_out_1[6*PSUM_WIDTH - 1 : 0]}
                                                              : {add_ans_1, add_ans_2, buf_data_out_2[6*PSUM_WIDTH - 1 : 0]}
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
//  - adder assignment, with corner value considered --------------------------------------------------------
always_comb 
if(kernel_mode)
    case(count_h)
        h_num - 1: begin
            add_a = buf_data_in[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
            add_b = '0;
            add_c = '0;
            add_d = add_ans_1;
        end
        h_num - 2: begin
            add_a = '0;
            add_b = '0;
            add_c = buf_data_in[6*PSUM_WIDTH - 1 : 0];
            add_d = is_even_even_row ? buf_data_out_2[6*PSUM_WIDTH - 1 : 0] : buf_data_out_1[6*PSUM_WIDTH - 1 : 0];
        end
        h_num - 3:begin
            add_a = buf_data_in[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
            add_b = is_even_even_row ? buf_data_out_2[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH] : buf_data_out_1[2*66*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
            add_c = '0;
            add_d = add_ans_1;
        end
        default:
            if (is_even_row) //even row
                case (count_3)
                    2'b00:begin
                        add_a = buf_data_in[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                        add_b = is_even_even_row ? buf_data_out_2[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH] : buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                        add_c = buf_data_in[6*PSUM_WIDTH - 1 : 0];
                        add_d = is_even_even_row ? buf_data_out_2[6*PSUM_WIDTH - 1 : 0] : buf_data_out_1[6*PSUM_WIDTH - 1 : 0];
                    end
                    2'b01:begin
                        add_a = buf_data_in[6*PSUM_WIDTH - 1 : 0];
                        add_b = is_even_even_row ? buf_data_out_2[6*PSUM_WIDTH - 1 : 0] : buf_data_out_1[6*PSUM_WIDTH - 1 : 0];
                        add_c = buf_data_in[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH - 1];
                        add_d = is_even_even_row ? buf_data_out_2[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH - 1] : buf_data_out_1[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH - 1];
                    end
                    2'b10:begin
                        add_a = buf_data_in[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                        add_b = is_even_even_row ? buf_data_out_2[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH] : buf_data_out_1[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                        add_c = buf_data_in[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH - 1];
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
                        add_a = buf_data_in[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                        add_b = buf_data_out_1[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                        add_c = buf_data_out_2[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                    end
                    2'b01:begin
                        add_a = buf_data_in[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                        add_b = buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                        add_c = buf_data_out_2[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                    end
                    2'b10:begin
                        add_a = buf_data_in[6*PSUM_WIDTH - 1 : 0];
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
    endcase
else begin       //3*3
    add_d = add_ans_1;
    if(count_h == h_num - 1) begin                                  //corner value
        add_a = buf_data_in[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
        add_b = '0;
        add_c = '0;
    end else if (count_h == h_num - 2)begin
        add_a = buf_data_in[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
        add_b = buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
        add_c = '0;
    end else
        case (count_3)
            2'b00:begin
                add_a = buf_data_in[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                add_b = buf_data_out_1[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
                add_c = buf_data_out_2[3*6*PSUM_WIDTH - 1 : 2*6*PSUM_WIDTH];
            end
            2'b01:begin
                add_a = buf_data_in[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                add_b = buf_data_out_1[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
                add_c = buf_data_out_2[2*6*PSUM_WIDTH - 1 : 6*PSUM_WIDTH];
            end
            2'b10:begin
                add_a = buf_data_in[6*PSUM_WIDTH - 1 : 0];
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
// - psum buffer -----------------------------------------------------
logic [$clog2(FM_GUARD_GEN_PSUM_BUF_DEPTH) - 1 : 0] psum_buf_wr_addr, psum_buf_rd_addr;
logic [PSUM_WIDTH - 1 : 0][5:0] psum_buf_data_in, psum_buf_data_out;
logic [PSUM_WIDTH - 1 : 0][5:0] psum_add_ans, psum_add_ans_for_4_bit;
logic psum_buf_ping_pong;
logic psum_buf_rd_en;
logic [PSUM_WIDTH - 1 : 0][5:0] bias_to_add;
always_comb psum_buf_data_in = bit_mode ? psum_add_ans_for_4_bit : psum_add_ans;
ping_pong_buffer #(
    .BIT_LENGTH(6*PSUM_WIDTH),
    .DRPTH(FM_GUARD_GEN_PSUM_BUF_DEPTH)
) psum_buf (
    .clka       (clk),
    .clkb       (clk),
    .addra      (psum_buf_wr_addr),
    .addrb      (psum_buf_rd_addr),
    .dina       (psum_buf_data_in),
    .wea        (psum_buf_wr_en),
    .ena        ('1),
    .enb        (psum_buf_rd_en),
    .doutb      (psum_buf_data_out),
    .ping_pong  (psum_buf_ping_pong)
);

generate 
    for( i = 5; i >=0; i--)begin:add_for_psum_buf
        logic [PSUM_WIDTH - 1 : 0] tmp_add_a;
        always_comb bias_to_add[i] = {24'd0,bias_i};
        always_comb tmp_add_a = count_c == 1 ? bias_to_add[i] : add_ans_2[i];
        adder #(
            .WIDTH(PSUM_WIDTH)
        )adder_psum(
            .a(tmp_add_a),
            .b(psum_buf_data_out[i]),
            .ans(psum_add_ans[i])
        );
        adder #(
            .WIDTH(PSUM_WIDTH / 2)
        )adder_for_4_bit(
            .a(psum_add_ans[i][PSUM_WIDTH - 1 : PSUM_WIDTH / 2]),
            .b(psum_add_ans[i][PSUM_WIDTH / 2 - 1 : 0]),
            .ans(psum_add_ans_for_4_bit[i][PSUM_WIDTH / 2 - 1 : 0])
        );

        always_comb psum_add_ans_for_4_bit[i][PSUM_WIDTH - 1 : PSUM_WIDTH / 2] = '0;
    end
endgenerate

always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)
        {
            psum_buf_wr_addr,
            psum_buf_ping_pong
        } <= '0;
    else if (psum_valid)begin
        if (psum_buf_wr_addr == (w_num * h_num - 1)) psum_buf_wr_addr <= 0;                 //whether the synthesis tool will optimise this?
        else psum_buf_wr_addr++;
        if(count_c == 0 && count_h == 0 && count_w < 6) begin
            psum_buf_ping_pong <= ~psum_buf_ping_pong;  //++ ok?
        end
    end

// - relu_guard_write_back ----------------------------------------------------
logic write_back_valid;                                       ///ready output
relu_guard_write_back inst_relu_guard_write_back(
    .ctrl_valid          (write_back_valid),       
    .ctrl_ready          (write_back_ready),                                                    // no connection now 
    .ctrl_finish         (write_back_finish),    
    .h_num_i             (h_num),
    .w_num_i             (w_num),
    .bit_mode_i          (bit_mode),
    .data_i              (psum_buf_data_out),   
    .addr_o              (psum_buf_rd_addr),   
    .data_o              (write_back_data_o), 
    .rd_en               (psum_buf_rd_en),  
    .fm_buf_ready        (fm_buf_ready),           
    .data_o_valid        (write_back_data_o_valid),           
    .guard_o             (guard_o),       
    .guard_buf_ready     (guard_buf_ready),               
    .guard_o_valid       (guard_o_valid)           
);
always_ff@(posedge clk or negedge rst_n)
    if(!rst_n)
        {
            write_back_valid
        } <= '0;
    else begin
        write_back_valid <= 0;
        if(count_c == 0 && count_h == 0 && count_w < 6 && psum_valid) begin
            write_back_valid <= 1;
        end
    end
endmodule
