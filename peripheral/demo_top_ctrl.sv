/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191130

Modify:

Notes:
1. 

TODO:
=========================================================*/
import diff_demo_pkg::*;
module demo_top_ctrl(
    input  logic      								                                            clk,
    input  logic      								                                            rst_n,
    // ctrl reg
    input  logic                                                                                conv_tri,
    input  logic                                                                                frm_is_ref,
    input  logic                                                                                new_wt,
    input  logic                                                                                frm_is_diff,
    input  logic  [7 : 0]                                                                       frm_index,
    input  logic  [CTRL_REG_LENGTH - 1 : 0 ]                                                    dma_addr,
    // interface with datamover cmd stream
    output logic                                                                                m_axis_mm2s_cmd_tvalid,     //rd
    input  logic                                                                                m_axis_mm2s_cmd_tready,
    output logic [71 : 0]                                                                       m_axis_mm2s_cmd_tdata,

    output logic                                                                                m_axis_s2mm_cmd_tvalid,     //wr
    input  logic                                                                                m_axis_s2mm_cmd_tready,
    output logic [71 : 0]                                                                       m_axis_s2mm_cmd_tdata,
    // interface with stream data
    input  logic                                                                                s_axis_mm2s_tvalid,     //rd
    output logic                                                                                s_axis_mm2s_tready,
    input  logic [7 : 0]                                                                        s_axis_mm2s_tdata,
    input  logic [0 : 0]                                                                        s_axis_mm2s_tkeep,
    input  logic                                                                                s_axis_mm2s_tlast,

    output logic                                                                                m_axis_s2mm_tvalid,     //wr
    input  logic                                                                                m_axis_s2mm_tready,
    output logic [7 : 0]                                                                        m_axis_s2mm_tdata,
    output logic [0 : 0]                                                                        m_axis_s2mm_tkeep,
    output logic                                                                                m_axis_s2mm_tlast,
    // interface with core
    input  logic                                                                                core_ready,
    output logic                                                                                core_valid,
    input  logic                                                                                core_finish,
    output logic                                                                                core_is_diff_i,
    output logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       load_fm_wr_addr,
    output logic [CONF_PE_COL - 1 : 0][71 : 0]                                                  load_fm_din,
    output logic [CONF_PE_COL - 1 : 0]                                                          load_fm_wr_en,     
    output logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       save_fm_rd_addr,
    input  logic [CONF_PE_COL - 1 : 0][71 : 0]                                                  save_fm_dout,    
    output logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]                    load_gd_wr_addr,
    output logic [CONF_PE_COL - 1 : 0][71 : 0]                                                  load_gd_din,
    output logic [CONF_PE_COL - 1 : 0]                                                          load_gd_wr_en,      
    output logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0][$clog2(CONF_WT_BUF_DEPTH) - 1 : 0]  load_wt_wr_addr,
    output logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0][25*8 - 1 : 0]                       load_wt_din,
    output logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0]                                     load_wt_wr_en,         
    output logic [CONF_PE_ROW - 1 : 0][$clog2(CONF_BIAS_BUF_DEPTH) - 1 : 0]                     load_bias_wr_addr,
    output logic [CONF_PE_ROW - 1 : 0][7 : 0]                                                   load_bias_din,
    output logic [CONF_PE_ROW - 1 : 0]                                                          load_bias_wr_en,       
    // IRQ
    output	logic								                                                IRQ_event
);
// 
genvar i, j;
enum logic[2:0] { IDLE, LOAD_FM, LOAD_WT, CORE, SAVE, FINISH } state, next_state;


//  - addr regs from outside --------------------------------------   dma_addr
logic  [CTRL_REG_LENGTH - 1 : 0 ]        fm_addr;    // feature map
logic  [CTRL_REG_LENGTH - 1 : 0 ]        wt_addr;    // weight and bias
logic  [CTRL_REG_LENGTH - 1 : 0 ]        sv_addr;    // write back

always_comb begin
    fm_addr = dma_addr + 32'h00060000 * frm_index;
    wt_addr = dma_addr + 32'h00060000 * 16;
    sv_addr = dma_addr + 32'h00060000 * 17;
end



// - top state machine -----------------------------------------------------
logic load_fm_finish, load_wt_finish, save_finish, load_bias_finish;

always_ff @ (posedge clk or negedge rst_n) 
    if (!rst_n) state <= IDLE;
    else state <= next_state;

always_comb 
    case (state)
        IDLE:       next_state = conv_tri ? new_wt ? LOAD_WT : LOAD_FM : IDLE;
        LOAD_WT:    next_state = load_bias_finish ? LOAD_FM : LOAD_WT;
        LOAD_FM:    next_state = load_fm_finish ? CORE : LOAD_FM;
        CORE:       next_state = core_finish ? SAVE : CORE;
        SAVE:       next_state = save_finish ? FINISH : SAVE;
        FINISH:     next_state = IDLE;
        default:    next_state = IDLE;
    endcase

// - datamover signal management --------------------------------------------
logic           fm_cmd_tvalid, wt_cmd_tvalid;
logic [71 : 0]  fm_cmd_tdata, wt_cmd_tdata;
logic           fm_tready, wt_tready;
always_comb begin
    m_axis_mm2s_cmd_tvalid = state == LOAD_WT ? wt_cmd_tvalid : fm_cmd_tvalid;
    m_axis_mm2s_cmd_tdata  = state == LOAD_WT ? wt_cmd_tdata  : fm_cmd_tdata;
    s_axis_mm2s_tready = state == LOAD_WT ? wt_tready : fm_tready;
end 

// - signal management for core ---------------------------------------------
always_comb core_valid = load_fm_finish;        // for easy
always_comb core_is_diff_i = frm_is_diff;

// - state machine for load and save ----------------------------------------
enum logic[1:0] { STOP, CONFIG, PROCESS, PROCESS_2 } fm_state, wt_state, sv_state, fm_next_state, wt_next_state, sv_next_state;
always_ff @ (posedge clk or negedge rst_n) 
    if (!rst_n) begin
        fm_state <= STOP;
        wt_state <= STOP;
        sv_state <= STOP;
    end else begin
        fm_state <= fm_next_state;
        wt_state <= wt_next_state;
        sv_state <= sv_next_state;
    end

// - load fm ---------------------------------------------------------------- 
logic [2:0] fm_en_col_8, fm_en_col_4;
logic [7:0] ref_frame_din, ref_frame_dout;
logic       data_bit_mode;
logic       data_is_zero;
logic signed [7:0] data_after_diff;
logic       ref_frame_we, ref_frame_re;             // write en, read en
logic       ref_frame_empty, ref_frame_full;        // not used.  TODO: add error logic
logic       s_data_valid;
logic       empty_flag;

always_comb 
    case(fm_state)
        STOP:    fm_next_state = state == LOAD_FM ? CONFIG : STOP;
        CONFIG:  fm_next_state = m_axis_mm2s_cmd_tready && fm_cmd_tvalid ? PROCESS : CONFIG;
        PROCESS: fm_next_state = load_fm_finish ? STOP : PROCESS;
        default: fm_next_state = STOP;
    endcase

always_ff@(posedge clk or negedge rst_n)
    if (!rst_n)empty_flag <= '0;
    else if(fm_state == CONFIG && fm_next_state == PROCESS && ref_frame_empty)  empty_flag <= '1;
    else if(fm_state == CONFIG && fm_next_state == PROCESS && !ref_frame_empty) empty_flag <= '0;

always_comb begin
    fm_cmd_tvalid       = fm_state == CONFIG && m_axis_mm2s_cmd_tready;
    fm_cmd_tdata        = {8'd0, fm_addr, 8'd0, 1'd0, LOAD_FM_LENGTH};
    load_fm_finish      = fm_state == PROCESS && s_axis_mm2s_tlast;          //ok?
    fm_tready           = fm_state == PROCESS;
    s_data_valid        = fm_state == PROCESS && fm_tready && s_axis_mm2s_tvalid;
    // for ref frame buf
    ref_frame_din       = s_axis_mm2s_tdata;
    ref_frame_we        = s_data_valid && !ref_frame_full;
    ref_frame_re        = s_data_valid && !ref_frame_empty && !empty_flag || ref_frame_full;            // special here!!!! the size shoube correspond to depth
    data_after_diff     = frm_is_ref ? s_axis_mm2s_tdata : s_axis_mm2s_tdata - ref_frame_din;           //sub
    data_bit_mode       = (data_after_diff[7:3] == 0 || data_after_diff[7:3] == '1) ? '1 : '0; //4bit: 1
    data_is_zero        = data_after_diff == 0;
end
// first layer's ci is fixed to 3, so ...
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) fm_en_col_8 <= 3'b001;
    else if (s_data_valid) fm_en_col_8 <= {fm_en_col_8[1:0], fm_en_col_8[2]};

always_comb 
    case(fm_en_col_8)
        3'b001: fm_en_col_4 = 3'b001;
        3'b010: fm_en_col_4 = 3'b001;
        3'b100: fm_en_col_4 = 3'b010;
        default: fm_en_col_4 = 3'b000;
    endcase

fifo_sync#(                                                                                 // use XILINX FIFO micro to save BRAM
    .DATA_WIDE(8),
    .FIFO_DEPT(REF_FRAME_BUF_DEPTH)
) ref_frame_buf (
    .*,
    .din(ref_frame_din),
    .wr_en(ref_frame_we),
    .rd_en(ref_frame_re),
    .dout(ref_frame_dout),
    .empty(ref_frame_empty),
    .full(ref_frame_full)
);

generate
for (j = 2; j >= 0; j--) begin:gen_load_fm
    // cnt and shift reg
    logic [4:0]  cnt_wfm_8, cnt_wgd_8;      //0-8
    logic [7:0]  cnt_wfm_4, cnt_wgd_4;      //0-71
    logic [63:0] shift_wfm_8;
    logic [67:0] shift_wfm_4;
    logic [70:0] shift_wgd_8;
    logic [70:0] shift_wgd_4;
    always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) {
        shift_wfm_8,
        shift_wfm_4,
        shift_wgd_8,
        shift_wgd_4,
        cnt_wfm_8,
        cnt_wfm_4,
        cnt_wgd_8,
        cnt_wgd_4
    } <= '0;
    else if(fm_state == STOP)begin
        {
            cnt_wfm_8,
            cnt_wfm_4,
            cnt_wgd_8,
            cnt_wgd_4
        } <= '0;
    end else if(s_data_valid)begin
    //fm
        //8bit
        if(fm_en_col_8[j] && !data_bit_mode && !data_is_zero) begin
            if(cnt_wfm_8 == 8) cnt_wfm_8 <= 0;
            else cnt_wfm_8 <= cnt_wfm_8 + 1;

            shift_wfm_8 <= {shift_wfm_8[55:0], data_after_diff};

        end
        // 4bit
        if(fm_en_col_4[j] && data_bit_mode && !data_is_zero)begin
            if(cnt_wfm_4 == 17) cnt_wfm_4 <= 0;
            else cnt_wfm_4 <= cnt_wfm_4 + 1;

            shift_wfm_4 <={shift_wfm_4[64:0], data_after_diff[3:0]};
        end
    // gd
        //8bit
        if(cnt_wgd_8 == 71) cnt_wgd_8 <= 0;
        else cnt_wgd_8 <= cnt_wgd_8 + 1;
        shift_wgd_8 <= {shift_wgd_8[69:0], ~data_is_zero};
        //4bit
        if(cnt_wgd_4 == 71) cnt_wgd_4 <= 0;
        else cnt_wgd_4 <= cnt_wgd_4 + 1;
        shift_wgd_4 <= fm_en_col_8 == 3'b010 ? {shift_wgd_4[70:1], shift_wgd_4[0] | ~data_is_zero} : {shift_wgd_4[69:0], ~data_is_zero};
    end 
    // addr
    logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]    load_fm_wr_addr_8, load_fm_wr_addr_4;
    logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0] load_gd_wr_addr_8, load_gd_wr_addr_4;
    always_ff@(posedge clk or negedge rst_n)
    if(!rst_n) begin {
        load_fm_wr_addr_8, 
        load_gd_wr_addr_8
    } <= '0;
    load_fm_wr_addr_4 <= FM_4_BIT_BASE_ADDR;
    load_gd_wr_addr_4 <= GD_4_BIT_BASE_ADDR;
    end else if(fm_state == STOP) begin {
        load_fm_wr_addr_8, 
        load_gd_wr_addr_8
    } <= '0;
    load_fm_wr_addr_4 <= FM_4_BIT_BASE_ADDR;
    load_gd_wr_addr_4 <= GD_4_BIT_BASE_ADDR;
    end else if(s_data_valid) begin
        if(fm_en_col_8[j] && !data_bit_mode && cnt_wfm_8 == 11) load_fm_wr_addr_8 <= load_fm_wr_addr_8 + 1;
        if(fm_en_col_8[j] && !data_bit_mode && cnt_wgd_8 == 71) load_gd_wr_addr_8 <= load_gd_wr_addr_8 + 1;
        if(fm_en_col_4[j] && data_bit_mode && cnt_wfm_4 == 17)  load_fm_wr_addr_4 <= load_fm_wr_addr_4 + 1;
        if(fm_en_col_4[j] && data_bit_mode && cnt_wgd_4 == 71 && fm_en_col_8 == 3'b010)  load_fm_wr_addr_4 <= load_fm_wr_addr_4 + 1;

    end

    always_comb begin
        load_fm_wr_addr[j] = frm_is_diff ? data_bit_mode ? load_fm_wr_addr_4 : load_fm_wr_addr_8 : load_fm_wr_addr_8; 
        load_gd_wr_addr[j] = frm_is_diff ? data_bit_mode ? load_gd_wr_addr_4 : load_gd_wr_addr_8 : load_gd_wr_addr_8;
        load_fm_din[j]     = frm_is_diff ? data_bit_mode ? {shift_wfm_4, data_after_diff[3:0]} : {shift_wfm_8, data_after_diff} : {shift_wfm_8, data_after_diff};
        load_gd_din[j]     = frm_is_diff ? data_bit_mode ? {shift_wgd_4, shift_wgd_4[0] | ~data_is_zero} : {shift_wgd_8, ~data_is_zero} : {shift_wgd_8, ~data_is_zero};
        load_fm_wr_en[j]   = s_data_valid && (fm_en_col_8[j] && !data_bit_mode && cnt_wfm_8 == 11 || fm_en_col_4[j] && data_bit_mode && cnt_wfm_4 == 17);
        load_gd_wr_en[j]   = s_data_valid && (fm_en_col_8[j] && !data_bit_mode && cnt_wgd_8 == 71 || fm_en_col_4[j] && data_bit_mode && cnt_wgd_4 == 71 && fm_en_col_8 == 3'b010);

        // special for last
        if(s_axis_mm2s_tlast) begin
            load_fm_wr_en[j]   = '1;
            load_gd_wr_en[j]   = '1;
            load_fm_din[j]     = frm_is_diff ? data_bit_mode ? {shift_wfm_4, data_after_diff[3:0]} << (4*(17 - cnt_wfm_4)): {shift_wfm_8, data_after_diff} << (8*(8 - cnt_wfm_8)) : {shift_wfm_8, data_after_diff} << (8*(8 - cnt_wfm_8));
            load_gd_din[j]     = frm_is_diff ? data_bit_mode ? {shift_wgd_4, shift_wgd_4[0] | ~data_is_zero} << (71 - cnt_wgd_4): {shift_wgd_8, ~data_is_zero} << (71 - cnt_wgd_8): {shift_wgd_8, ~data_is_zero} << (71 - cnt_wgd_8);

        end
    end
end
endgenerate

// [3]th col set to 0
always_comb begin
    load_fm_wr_addr[3] = '0;
    load_gd_wr_addr[3] = '0;
    load_fm_wr_en[3] = '0;
    load_gd_wr_en[3] = '0;
    load_fm_din[3] = '0;
    load_gd_din[3] = '0;
end
// - load wt and bias -------------------------------------------------------
//s_axis_mm2s_tvalid   s_axis_mm2s_tdata   
logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0] ld_wt_en;
logic [CONF_PE_ROW - 1 : 0]                      ld_bias_en;
logic                                            ld_kernel_mode;
logic                                            wt_data_valid;
logic                                            bias_data_valid;
logic [2:0]                                      ld_wt_layer;
logic                                            fin_ld_one_layer;
logic [7:0]                                      ci_num, co_num;
logic [7:0]                                      cnt_ci, cnt_co;
logic [7:0]                                      wt_row_ptr;

// manage en    
// [Contain preknown knowledge about the network parameters]
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) begin
        ld_bias_en  <= 1;        // Note here 32'd1
        ld_wt_en    <= 1;
        ld_wt_layer <= 1;
        cnt_ci      <= '0;
        cnt_co      <= '0;
        wt_row_ptr  <= '0;
    end else if(wt_state == STOP) begin
        ld_bias_en  <= 1;        // Note here 32'd1
        ld_wt_en    <= 1;
        ld_wt_layer <= 1;
        cnt_ci      <= '0;
        cnt_co      <= '0;
        wt_row_ptr  <= '0;
    end else if(wt_state == CONFIG) begin
        ld_bias_en  <= 1;        // Note here 32'd1
        ld_wt_en    <= 1;
        ld_wt_layer <= 1;
        cnt_ci      <= ci_num - 1;
        cnt_co      <= co_num - 1;
        wt_row_ptr  <= '0;
    end else begin
        if(bias_data_valid) ld_bias_en <= {ld_bias_en[CONF_PE_ROW - 2 : 0], ld_bias_en[CONF_PE_ROW - 1]};
        if(cnt_co == 0 && cnt_ci == 1 && |load_wt_wr_en) ld_wt_layer <= ld_wt_layer + 1;    // layer need to change previous than fin_ld_one_layer
        //  load wt en

        // counters
        if(|load_wt_wr_en) begin
            if(cnt_co == 0 && cnt_ci == 0) begin
                cnt_ci      <= ci_num - 1;
                cnt_co      <= co_num - 1;
                wt_row_ptr <= wt_row_ptr == CONF_PE_ROW - 1 ? '0 : wt_row_ptr + 1;
                ld_wt_en    <= 1;
            end else if(cnt_ci == 0) begin
                cnt_ci <= ci_num - 1;
                cnt_co <= cnt_co - 1;
                ld_wt_en[wt_row_ptr] <= '0;
                ld_wt_en[(wt_row_ptr == CONF_PE_ROW - 1 ? 0 : wt_row_ptr + 1)] <= 1;
                wt_row_ptr <= wt_row_ptr == CONF_PE_ROW - 1 ? '0 : wt_row_ptr + 1;
                
            end else begin
                ld_wt_en[wt_row_ptr] <= {ld_wt_en[wt_row_ptr][CONF_PE_COL - 2 : 0], ld_wt_en[wt_row_ptr][CONF_PE_COL - 1]};
                cnt_ci <= cnt_ci - 1;
            end
        end
    end

always_comb case(ld_wt_layer)
    3'd1: begin
        ci_num = 8'd3;
        co_num = 8'd24;
        ld_kernel_mode = '1;
    end
    3'd2:begin
        ci_num = 8'd24;
        co_num = 8'd36;
        ld_kernel_mode = '1;
    end
    3'd3:begin
        ci_num = 8'd36;
        co_num = 8'd48;
        ld_kernel_mode = '1;
    end
    3'd4:begin
        ci_num = 8'd48;
        co_num = 8'd64;
        ld_kernel_mode = '0;
    end
    4'd5:begin
        ci_num = 8'd64;
        co_num = 8'd64;
        ld_kernel_mode = '0;
    end
    default:begin
        ci_num = 8'd0;
        co_num = 8'd0;
        ld_kernel_mode = '1;
    end
endcase       
// state machine
always_comb 
    case(wt_state)
        STOP:       wt_next_state = state == LOAD_WT ? CONFIG : STOP;
        CONFIG:     wt_next_state = m_axis_mm2s_cmd_tready && wt_cmd_tvalid ? PROCESS : CONFIG;
        PROCESS:    wt_next_state = (ld_wt_layer == 6 && fin_ld_one_layer) ? PROCESS_2 : PROCESS;
        PROCESS_2:  wt_next_state = load_bias_finish ? STOP : PROCESS_2;
        default:    wt_next_state = STOP;
    endcase
    
always_comb load_wt_finish    =  (ld_wt_layer == 6) && fin_ld_one_layer;       //special here    
always_comb begin
    wt_cmd_tvalid     = (wt_state == CONFIG) && m_axis_mm2s_cmd_tready;
    wt_cmd_tdata      = {8'd0, wt_addr, 8'd0, 1'd0, LOAD_WT_LENGTH};
    load_bias_finish  = (wt_state == PROCESS_2) && s_axis_mm2s_tlast;
    wt_data_valid     = (wt_state == PROCESS) && s_axis_mm2s_tvalid;
    bias_data_valid   = (wt_state == PROCESS_2) && s_axis_mm2s_tvalid;
    wt_tready         = (wt_state == PROCESS) || (wt_state == PROCESS_2);
    fin_ld_one_layer  = |load_wt_wr_en && cnt_co == 0 && cnt_ci == 0;
end

generate
for(i = CONF_PE_ROW - 1; i >= 0; i --) begin: gen_ld_wt_row
    for(j = CONF_PE_COL - 1; j >= 0; j --) begin: gen_ld_wt_col
        logic [23:0][7:0] shift_k; //kernel 25 8bit reg
        logic [4:0] cnt_k;
        always_ff@(posedge clk or negedge rst_n)
        if (!rst_n) begin   
            shift_k <= '0;
            cnt_k <= '0;
            load_wt_wr_addr[i][j] <= '0;
        end else if(wt_state == STOP)  load_wt_wr_addr[i][j] <= '0;
        else if(ld_wt_en[i][j] && wt_data_valid) begin
            if(cnt_k == (ld_kernel_mode ? 24 : 17)) begin
                cnt_k <= '0;
                load_wt_wr_addr[i][j] <= load_wt_wr_addr[i][j] + 1;
            end else 
                cnt_k <= cnt_k + 1;

            shift_k <= {shift_k[22:0], s_axis_mm2s_tdata};
        end

        always_comb begin
            load_wt_din[i][j] = load_wt_wr_en[i][j] ? ld_kernel_mode ? {shift_k, m_axis_s2mm_tdata} : {shift_k, m_axis_s2mm_tdata} << (7*8) : '0;
            load_wt_wr_en[i][j] = wt_data_valid && ld_wt_en[i][j] && cnt_k == (ld_kernel_mode ? 24 : 17);
            if(load_wt_finish) begin
                load_wt_wr_en[i][j] = '1;
                load_wt_din[i][j] = {shift_k, m_axis_s2mm_tdata} << ((24 - cnt_k) * 8);
            end
        end
    end
end
endgenerate

generate
for(i = CONF_PE_ROW - 1; i >= 0; i --) begin: gen_ld_bias
    always_ff@(posedge clk or negedge rst_n)
        if (!rst_n) load_bias_wr_addr[i] <= '0;
        else if(wt_state == STOP) load_bias_wr_addr[i] <= '0;
        else if(bias_data_valid && ld_bias_en[i]) load_bias_wr_addr[i] <= load_bias_wr_addr[i] + 1;

    always_comb begin
        load_bias_din[i] = s_axis_mm2s_tdata;
        load_bias_wr_en[i] = bias_data_valid;
    end
end
endgenerate
// - save -------------------------------------------------------------------s_axis_s2mm_tvalid s_axis_s2mm_tready s_axis_s2mm_tdata
logic [CONF_PE_COL - 1 : 0][7:0] data_to_save;
logic [7:0]                      sv_ptr;
logic [7:0]                      cnt_18, cnt_64; // 18 data per bank with 64 channels

always_comb 
    case(sv_state)
        STOP:    sv_next_state = state == SAVE ? CONFIG : STOP;
        CONFIG:  sv_next_state = m_axis_s2mm_cmd_tready && m_axis_s2mm_cmd_tvalid ? PROCESS : CONFIG;
        PROCESS: sv_next_state = save_finish ? STOP : PROCESS;
        default: sv_next_state = STOP;
    endcase

always_comb begin
    m_axis_s2mm_cmd_tvalid  = sv_state == CONFIG && m_axis_s2mm_cmd_tready;
    m_axis_s2mm_cmd_tdata   = {8'd0, sv_addr, 8'd0, 1'd0, SAVE_LENGTH};
    save_finish             = cnt_18 == 0 && cnt_64 == 0 && m_axis_s2mm_tvalid && m_axis_s2mm_tready;
    m_axis_s2mm_tvalid  = sv_state == PROCESS;
    m_axis_s2mm_tdata   = data_to_save[sv_ptr];
    m_axis_s2mm_tlast   = save_finish;
    m_axis_s2mm_tkeep   = '0;
end

//cnt
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) {
        cnt_18, cnt_64, sv_ptr
    } <= '0;
    else if(sv_state != PROCESS) begin
        cnt_18 = 8'd17;
        cnt_64 = 8'd63;
        sv_ptr = '0;
    end else if(m_axis_s2mm_tvalid && m_axis_s2mm_tready) begin
        if(cnt_18 == 0) begin
            cnt_64 <= cnt_64 - 1;
            cnt_18 <= 8'd17;
            if(sv_ptr == CONF_PE_COL - 1) sv_ptr <= '0;
            else sv_ptr <= sv_ptr + 1;
        end else cnt_18 <= cnt_18 - 1;
    end
//read 18 per bank
generate 
for (j = CONF_PE_COL - 1; j >= 0; j--) begin:gen_sv
    logic [71:0] shift_sv;
    always_ff@(posedge clk or negedge rst_n)
        if (!rst_n) {
            save_fm_rd_addr[j],
            shift_sv
        }<= '0;
        else if(sv_state == CONFIG) begin
            save_fm_rd_addr[j] <= '0;
            shift_sv <= save_fm_dout;
        end else if(sv_ptr == j && m_axis_s2mm_tvalid && m_axis_s2mm_tready) begin
            if(cnt_18 == 16) save_fm_rd_addr[j] <= save_fm_rd_addr[j] + 1;          // addr increase early enough
            if(cnt_18 == 0) shift_sv <= save_fm_dout;
            else shift_sv <= {shift_sv[63:0], 8'd0};
        end
    
    always_comb data_to_save[j] = shift_sv[71 -: 8];
end
endgenerate
// - IRQ -----------------------------------------------
always_comb IRQ_event = state == FINISH;

endmodule