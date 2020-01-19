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

module diff_demo_TOP (
    input      								        sys_clk,
    input      								        sys_rstn,
    // ctrl reg
    input  logic                                    conv_tri,
    input  logic                                    frm_is_ref,
    input  logic                                    frm_is_diff,
    input  logic                                    new_wt,
    input  logic  [7 : 0]                           frm_index,
    input  logic  [CTRL_REG_LENGTH - 1 : 0 ]        dma_addr,
    // interface with datamover cmd stream
    output logic                                    m_axis_mm2s_cmd_tvalid,
    input  logic                                    m_axis_mm2s_cmd_tready,
    output logic [71 : 0]                           m_axis_mm2s_cmd_tdata,

    output logic                                    m_axis_s2mm_cmd_tvalid,
    input  logic                                    m_axis_s2mm_cmd_tready,
    output logic [71 : 0]                           m_axis_s2mm_cmd_tdata,
    // interface with stream data
    input  logic                                    s_axis_mm2s_tvalid,
    output logic                                    s_axis_mm2s_tready,
    input  logic [7 : 0]                            s_axis_mm2s_tdata,
    input  logic [0 : 0]                            s_axis_mm2s_tkeep,
    input  logic                                    s_axis_mm2s_tlast,

    output logic                                    m_axis_s2mm_tvalid,
    input  logic                                    m_axis_s2mm_tready,
    output logic [7 : 0]                            m_axis_s2mm_tdata,
    output logic [0 : 0]                            m_axis_s2mm_tkeep,
    output logic                                    m_axis_s2mm_tlast, 
    // IRQ
    output logic                                    IRQ_event
);
// - SIGNALS --------------------------------------------------------------------
logic                                                                                core_ready;
logic                                                                                core_valid;
logic                                                                                core_finish;
logic                                                                                core_is_diff_i;
logic                                                                                core_frm_is_ref_i;
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       load_fm_wr_addr;
logic [CONF_PE_COL - 1 : 0][71 : 0]                                                  load_fm_din;
logic [CONF_PE_COL - 1 : 0]                                                          load_fm_wr_en;    
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       save_fm_rd_addr;
logic [CONF_PE_COL - 1 : 0][71 : 0]                                                  save_fm_dout;    
logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]                    load_gd_wr_addr;
logic [CONF_PE_COL - 1 : 0][71 : 0]                                                  load_gd_din;
logic [CONF_PE_COL - 1 : 0]                                                          load_gd_wr_en;    
logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0][$clog2(CONF_WT_BUF_DEPTH) - 1 : 0]  load_wt_wr_addr;
logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0][25*8 - 1 : 0]                       load_wt_din;
logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0]                                     load_wt_wr_en;    
logic [CONF_PE_ROW - 1 : 0][$clog2(CONF_BIAS_BUF_DEPTH) - 1 : 0]                     load_bias_wr_addr;
logic [CONF_PE_ROW - 1 : 0][7 : 0]                                                   load_bias_din;
logic [CONF_PE_ROW - 1 : 0]                                                          load_bias_wr_en;  

// - CTRL -----------------------------------------------------------------------
demo_top_ctrl inst_demo_top_ctrl(
    .*,
    .clk(sys_clk),
    .rst_n(sys_rstn)
);

// - CORE -----------------------------------------------------------------------
diff_core_top  inst_diff_core_top(
    .*,
    .clk(sys_clk),
    .rst_n(sys_rstn),
    .core_frm_is_ref_i(frm_is_ref)
);


endmodule