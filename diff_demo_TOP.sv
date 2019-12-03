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
    input      								        clk,
    input      								        rst_n,
    //Interface to Inst
    input   logic [CONF_INS_WIDTH-1:0]              s_axis_ins_tdata,
    input   logic   						        s_axis_ins_tlast,
    output  logic   						        s_axis_ins_tready,
    input   logic   	                            s_axis_ins_tvalid,
    //AXI LITE master interface,Use to control DMA
    output  logic [CONF_AXI_ADDR_WIDTH-1:0]   		m_axi_lite_araddr,  
    input   logic 									m_axi_lite_arready, 
    output  logic  					 	   			m_axi_lite_arvalid,
    output  logic [CONF_AXI_ADDR_WIDTH-1:0]  		m_axi_lite_awaddr,  
    input   logic 									m_axi_lite_awready, 
    output  logic  									m_axi_lite_awvalid,
    output  logic   								m_axi_lite_bready,
    input   logic [1:0]					 			m_axi_lite_bresp,  
    input   logic 									m_axi_lite_bvalid, 
    input   logic [CONF_AXI_DATA_WIDTH-1:0]			m_axi_lite_rdata,  
    output  logic 	 								m_axi_lite_rready,
    input   logic [1:0]					 			m_axi_lite_rresp,
    input   logic 									m_axi_lite_rvalid,
    output  logic [CONF_AXI_DATA_WIDTH-1:0]			m_axi_lite_wdata,
    input   logic 									m_axi_lite_wready,
    output  logic   								m_axi_lite_wvalid,
    //AXI Stream dma out operation interface
    output  logic[CONF_DDR_DATA_WIDTH-1:0]			s_axis_s2mm_tdata,
    output  logic[7:0]							    s_axis_s2mm_tkeep,
    output  logic    								s_axis_s2mm_tlast,
    input   logic   								s_axis_s2mm_tready,
    output  logic    	                    		s_axis_s2mm_tvalid,
    //AXI Stream dma in operation interface
    input   logic [CONF_DDR_DATA_WIDTH-1:0]			m_axis_mm2s_tdata,
    input   logic [7:0]							    m_axis_mm2s_tkeep,
    input   logic    								m_axis_mm2s_tlast,
    output  logic     								m_axis_mm2s_tready,
    input   logic    								m_axis_mm2s_tvalid,
    // IRQ
    output	logic								    IRQ_REQ
);
//
// for fm buf
logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                      fm_wr_addr;
logic [$clog2(CONF_FM_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                      fm_rd_addr;
logic [7 : 0][CONF_PE_COL - 1 : 0]                                                  fm_din;
logic [7 : 0][CONF_PE_COL - 1 : 0]                                                  fm_dout;
logic [CONF_PE_COL - 1 : 0]                                                         fm_rd_en;         //rd_en for energy save
logic [CONF_PE_COL - 1 : 0]                                                         fm_wr_en;         //rd_en for energy save
logic [CONF_PE_COL - 1 : 0]                                                         fm_ping_pong;
// for guard buf
logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                   gd_rd_addr;
logic [$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0][CONF_PE_COL - 1 : 0]                   gd_wr_addr;
logic [5 : 0][CONF_PE_COL - 1 : 0]                                                  gd_dout;
logic [5 : 0][CONF_PE_COL - 1 : 0]                                                  gd_din;
logic [CONF_PE_COL - 1 : 0]                                                         gd_rd_en;         //rd_en for energy save
logic [CONF_PE_COL - 1 : 0]                                                         gd_wr_en;         //rd_en for energy save
logic [CONF_PE_COL - 1 : 0]                                                         gd_ping_pong;
// - CORE -----------------------------------------------------------------------
diff_core_top  inst_diff_core_top(

);

endmodule