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
    input  logic                                                                                wen_i,
    input  logic  [CTRL_REG_LENGTH - 1 : 0 ]                                                    din_i,
    input  logic  [7 : 0]                                                                       addr_i,
    output logic  [CTRL_REG_LENGTH - 1 : 0 ]                                                    dout_o,
    // interface with datamover cmd stream
    output logic                                                                                m_axis_mm2s_cmd_tvalid,     //rd
    input  logic                                                                                m_axis_mm2s_cmd_tready,
    output logic [71 : 0]                                                                       m_axis_mm2s_cmd_tdata,

    output logic                                                                                m_axis_s2mm_cmd_tvalid,     //wr
    input  logic                                                                                m_axis_s2mm_cmd_tready,
    output logic [71 : 0]                                                                       m_axis_s2mm_cmd_tdata,
    // interface with stream data
    input  logic                                                                                s_axis_mm2s_sts_tvalid,     //rd
    output logic                                                                                s_axis_mm2s_sts_tready,
    input  logic [7 : 0]                                                                        s_axis_mm2s_sts_tdata,
    input  logic [0 : 0]                                                                        s_axis_mm2s_sts_tkeep,
    input  logic                                                                                s_axis_mm2s_sts_tlast,

    input  logic                                                                                s_axis_s2mm_sts_tvalid,     //wr
    output logic                                                                                s_axis_s2mm_sts_tready,
    input  logic [7 : 0]                                                                        s_axis_s2mm_sts_tdata,
    input  logic [0 : 0]                                                                        s_axis_s2mm_sts_tkeep,
    input  logic                                                                                s_axis_s2mm_sts_tlast,
    // interface with core
    output logic                                                                                core_ready,
    output logic                                                                                core_valid,
    output logic                                                                                core_finish,
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
    input									                                                    IRQ_ACK,
    output	logic								                                                IRQ_REQ
);
// 
genvar i, j;
enum logic[2:0] { IDLE, LOAD_FM, LOAD_WT, CORE, SAVE, FINISH } state, next_state;
//  - ctrl regs from outside --------------------------------------
logic                                    is_diff;
logic                                    new_diff_frame;
logic                                    run;
logic  [CTRL_REG_LENGTH - 1 : 0 ]        fm_addr;    // feature map
logic  [CTRL_REG_LENGTH - 1 : 0 ]        wt_addr;    // weight and bias
logic  [CTRL_REG_LENGTH - 1 : 0 ]        sv_addr;    // write back

// write reg
always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n) {
        is_diff,
        fm_addr,
        wt_addr,
        sv_addr,
        run
    } <= '0;
    else if (wen_i) begin
        case(addr_i)
            8'd0: {new_diff_frame, is_diff, run} <= din_i[2:0];
            8'd1: fm_addr <= din_i;
            8'd2: wt_addr <= din_i;
            8'd3: sv_addr <= din_i;
         default: dout_o           <= '0;
        endcase
    end else begin
        if (state == FINISH) run <= '0;
    end
end

// read reg
always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n) 
        dout_o <= '0;
    else begin
        case (addr_i)
            8'd0: dout_o           <= {29'd0, new_diff_frame, is_diff, run};
            8'd1: dout_o           <= fm_addr;
            8'd2: dout_o           <= wt_addr;
            8'd3: dout_o           <= sv_addr;
         default: dout_o           <= '0;
        endcase
    end
end

// - top state machine -----------------------------------------------------
logic load_fm_finish, load_wt_finish, save_finish;

always_ff @ (posedge clk or negedge rst_n) 
    if (!rst_n) state <= IDLE;
    else state <= next_state;

always_comb 
    case (state)
        IDLE:       next_state = run ? LOAD_FM : IDLE;
        LOAD_FM:    next_state = load_fm_finish ? LOAD_WT : LOAD_FM;
        LOAD_WT:    next_state = load_wt_finish ? CORE : LOAD_WT;
        CORE:       next_state = core_finish ? SAVE : CORE;
        SAVE:       next_state = save_finish ? FINISH : SAVE;
        FINISH:     next_state = IDLE;
        default:    next_state = IDLE;
    endcase

// - datamover signal management --------------------------------------------
logic           fm_cmd_tvalid, wt_cmd_tvalid;
logic [71 : 0]  fm_cmd_tdata, wt_cmd_tdata;
logic           fm_sts_tready, wt_sts_tready;
always_comb begin
    m_axis_mm2s_cmd_tvalid = state == LOAD_WT ? wt_cmd_tvalid : fm_cmd_tvalid;
    m_axis_mm2s_cmd_tdata  = state == LOAD_WT ? wt_cmd_tdata  : fm_cmd_tdata;
    s_axis_mm2s_sts_tready = state == LOAD_WT ? wt_sts_tready : fm_sts_tready;
end 

// - signal management for core ---------------------------------------------
always_comb core_valid = load_wt_finish;        // for easy
always_comb core_is_diff_i = is_diff;

// - state machine for load and save ----------------------------------------
enum logic[1:0] { STOP, CONFIG, PROCESS } fm_state, wt_state, sv_state, fm_next_state, wt_next_state, sv_next_state;
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
always_comb 
    case(fm_state)
        STOP:    fm_next_state = state == LOAD_FM ? CONFIG : STOP;
        CONFIG:  fm_next_state = m_axis_mm2s_cmd_tready && fm_cmd_tvalid ? PROCESS : CONFIG;
        PROCESS: fm_next_state = load_fm_finish ? STOP : PROCESS;
    endcase
always_comb 
    case(wt_state)
        STOP:    fm_next_state = state == LOAD_WT ? CONFIG : STOP;
        CONFIG:  fm_next_state = m_axis_mm2s_cmd_tready && wt_cmd_tvalid ? PROCESS : CONFIG;
        PROCESS: fm_next_state = load_wt_finish ? STOP : PROCESS;
    endcase
always_comb 
    case(sv_state)
        STOP:    fm_next_state = state == SAVE ? CONFIG : STOP;
        CONFIG:  fm_next_state = m_axis_s2mm_cmd_tready && m_axis_s2mm_cmd_tvalid ? PROCESS : CONFIG;
        PROCESS: fm_next_state = save_finish ? STOP : PROCESS;
    endcase

// - load fm ---------------------------------------------------------------- s_axis_mm2s_sts_tvalid s_axis_mm2s_sts_tdata
logic [2:0] fm_en_col_8, fm_en_col_4;
logic [7:0] ref_frame_din, ref_frame_dout;
logic       data_bit_mode;
logic       data_is_zero;
logic [7:0] data_after_diff;
logic       ref_frame_we, ref_frame_re;             // write en, read en
logic       ref_frame_empty, ref_frame_full;        // not used.  TODO: add error logic
logic       s_data_valid;
logic       empty_flag;

always_ff@(posedge clk or negedge rst_n)
    if (!rst_n)empty_flag <= '0;
    else if(fm_state == CONFIG && fm_next_state == PROCESS && ref_frame_empty) empty_flag <= '1;
    else empty_flag <= '0;

always_comb begin
    fm_cmd_tvalid       = fm_state == CONFIG && m_axis_mm2s_cmd_tready;
    fm_cmd_tdata        = {8'd0, fm_addr, 8'd0, 1'd0, LOAD_FM_LENGTH};
    load_fm_finish      = fm_state == PROCESS && s_axis_mm2s_sts_tlast;          //ok?
    fm_sts_tready       = fm_state == PROCESS;
    s_data_valid        = fm_state == PROCESS && fm_sts_tready && s_axis_mm2s_sts_tvalid;
    // for ref frame buf
    ref_frame_din       = s_axis_mm2s_sts_tdata;
    ref_frame_we        = s_data_valid && !ref_frame_full;
    ref_frame_re        = s_data_valid && !ref_frame_empty && !empty_flag;
    data_after_diff     = new_diff_frame ? s_axis_mm2s_sts_tdata : s_axis_mm2s_sts_tdata - ref_frame_din;
    data_bit_mode       = data_after_diff[7:4] == 0 ? '1 : '0; //4bit: 1
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
    end else begin
        //8bit
        if(s_data_valid && fm_en_col_8[j] && !data_bit_mode) begin
            if(cnt_wfm_8 == 8) cnt_wfm_8 <= 0;
            else cnt_wfm_8 <= cnt_wfm_8 + 1;

            shift_wfm_8 <= {shift_wfm_8[55:0], data_after_diff};

            if(cnt_wgd_8 == 71) cnt_wgd_8 <= 0;
            else cnt_wgd_8 <= cnt_wgd_8 + 1;

            shift_wgd_8 <= {shift_wgd_8[69:0], ~data_is_zero};
        end
        // 4bit
        if(s_data_valid && fm_en_col_4[j] && data_bit_mode)begin
            if(cnt_wfm_4 == 17) cnt_wfm_4 <= 0;
            else cnt_wfm_4 <= cnt_wfm_4 + 1;

            shift_wfm_4 <={shift_wfm_4[64:0], data_after_diff[3:0]};
            if(cnt_wgd_4 == 71) cnt_wgd_4 <= 0;
            else cnt_wgd_4 <= cnt_wgd_4 + 1;

            shift_wgd_4 <= fm_en_col_8 == 3'b010 ? {shift_wgd_4[70:1], shift_wgd_4[0] | ~data_is_zero} : {shift_wgd_4[69:0], ~data_is_zero};
        end
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
        load_fm_wr_addr = is_diff ? data_bit_mode ? load_fm_wr_addr_4 : load_fm_wr_addr_8 : load_fm_wr_addr_8; 
        load_gd_wr_addr = is_diff ? data_bit_mode ? load_gd_wr_addr_4 : load_gd_wr_addr_8 : load_gd_wr_addr_8;
        load_fm_din = is_diff ? data_bit_mode ? {shift_wfm_4, data_after_diff[3:0]} : {shift_wfm_8, data_after_diff} : {shift_wfm_8, data_after_diff};
        load_gd_din = is_diff ? data_bit_mode ? {shift_wgd_4, shift_wgd_4[0] | ~data_is_zero} : {shift_wgd_8, ~data_is_zero} : {shift_wgd_8, ~data_is_zero};
        load_fm_wr_en = s_data_valid && (fm_en_col_8[j] && !data_bit_mode && cnt_wfm_8 == 11 || fm_en_col_4[j] && data_bit_mode && cnt_wfm_4 == 17);
        load_gd_wr_en = s_data_valid && (fm_en_col_8[j] && !data_bit_mode && cnt_wgd_8 == 71 || fm_en_col_4[j] && data_bit_mode && cnt_wgd_4 == 71 && fm_en_col_8 == 3'b010);

        
        if(s_axis_mm2s_sts_tlast) begin
            load_fm_wr_en = '1;
            load_gd_wr_en = '1;
            load_fm_din = is_diff ? data_bit_mode ? {shift_wfm_4, data_after_diff[3:0]} << (4*(17 - cnt_wfm_4)): {shift_wfm_8, data_after_diff} << (8*(8 - cnt_wfm_8)) : {shift_wfm_8, data_after_diff} << (8*(8 - cnt_wfm_8));
            load_gd_din = is_diff ? data_bit_mode ? {shift_wgd_4, shift_wgd_4[0] | ~data_is_zero} << (71 - cnt_wgd_4): {shift_wgd_8, ~data_is_zero} << (71 - cnt_wgd_8): {shift_wgd_8, ~data_is_zero} << (71 - cnt_wgd_8);

        end
    end
end
endgenerate

// - load wt and bias -------------------------------------------------------s_axis_mm2s_sts_tvalid s_axis_mm2s_sts_tdata
always_comb begin
    wt_cmd_tvalid = wt_state == CONFIG && m_axis_mm2s_cmd_tready;
    wt_cmd_tdata = {8'd0, wt_addr, 8'd0, 1'd0, LOAD_WT_LENGTH};
    load_wt_finish = wt_state == PROCESS && s_axis_mm2s_sts_tlast;
end


// - save -------------------------------------------------------------------s_axis_s2mm_sts_tvalid s_axis_s2mm_sts_tready s_axis_s2mm_sts_tdata
always_comb begin
    m_axis_s2mm_cmd_tvalid = sv_state == CONFIG && m_axis_s2mm_cmd_tready;
    m_axis_s2mm_cmd_tdata = {8'd0, sv_addr, 8'd0, 1'd0, SAVE_LENGTH};
    save_finish = s_axis_s2mm_sts_tlast;
end


// - IRQ -----------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) IRQ_REQ <= '0;
    else if(IRQ_ACK) IRQ_REQ <= '0;
    else if(state == FINISH) IRQ_REQ <= '1;
endmodule