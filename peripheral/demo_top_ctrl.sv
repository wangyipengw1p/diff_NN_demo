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
    input  logic      								                                             clk,
    input  logic      								                                             rst_n,
    //Interface to instructions                                          
    input   logic [CONF_INS_WIDTH-1:0]                                                           s_axis_ins_tdata,
    input   logic   						                                                     s_axis_ins_tlast,
    output  logic   						                                                     s_axis_ins_tready,
    input   logic   	                                                                         s_axis_ins_tvalid,
    //AXI LITE master interface,Use to control DMA                                           
    output  logic [CONF_AXI_ADDR_WIDTH-1:0]   		                                             m_axi_lite_araddr,  
    input   logic 									                                             m_axi_lite_arready, 
    output  logic  					 	   			                                             m_axi_lite_arvalid,
    output  logic [CONF_AXI_ADDR_WIDTH-1:0]  		                                             m_axi_lite_awaddr,  
    input   logic 									                                             m_axi_lite_awready, 
    output  logic  									                                             m_axi_lite_awvalid,
    output  logic   								                                             m_axi_lite_bready,
    input   logic [1:0]					 			                                             m_axi_lite_bresp,  
    input   logic 									                                             m_axi_lite_bvalid, 
    input   logic [CONF_AXI_DATA_WIDTH-1:0]			                                             m_axi_lite_rdata,  
    output  logic 	 								                                             m_axi_lite_rready,
    input   logic [1:0]					 			                                             m_axi_lite_rresp,
    input   logic 									                                             m_axi_lite_rvalid,
    output  logic [CONF_AXI_DATA_WIDTH-1:0]			                                             m_axi_lite_wdata,
    input   logic 									                                             m_axi_lite_wready,
    output  logic   								                                             m_axi_lite_wvalid,
    //AXI Stream dma out operation interface                                             
    output  logic[CONF_DDR_DATA_WIDTH-1:0]			                                             s_axis_s2mm_tdata,
    output  logic[7:0]							                                                 s_axis_s2mm_tkeep,
    output  logic    								                                             s_axis_s2mm_tlast,
    input   logic   								                                             s_axis_s2mm_tready,
    output  logic    	                    		                                             s_axis_s2mm_tvalid,
    //AXI Stream dma in operation interface                                          
    input   logic [CONF_DDR_DATA_WIDTH-1:0]			                                             m_axis_mm2s_tdata,
    input   logic [7:0]							                                                 m_axis_mm2s_tkeep,
    input   logic    								                                             m_axis_mm2s_tlast,
    output  logic     								                                             m_axis_mm2s_tready,
    input   logic    								                                             m_axis_mm2s_tvalid,
    //                                                                              
    input   logic                                                                                core_ready,
    output  logic                                                                                core_valid,
    input   logic                                                                                core_finish,
    output  logic                                                                                core_bit_mode_i,
    output  logic                                                                                core_fm_ping_pong_i,
    //
    output  logic [CONF_PE_COL - 1 : 0][$clog2(CONF_FM_BUF_DEPTH) - 1 : 0]                       load_fm_wr_addr,
    output  logic [CONF_PE_COL - 1 : 0][7 : 0]                                                   load_fm_din,
    output  logic [CONF_PE_COL - 1 : 0]                                                          load_fm_wr_en,         
    output  logic [CONF_PE_COL - 1 : 0]                                                          load_fm_ping_pong,
    output  logic [CONF_PE_COL - 1 : 0][$clog2(CONF_GUARD_BUF_DEPTH) - 1 : 0]                    load_gd_wr_addr,
    output  logic [CONF_PE_COL - 1 : 0][5 : 0]                                                   load_gd_din,
    output  logic [CONF_PE_COL - 1 : 0]                                                          load_gd_wr_en,         
    output  logic [CONF_PE_COL - 1 : 0]                                                          load_gd_ping_pong,
    //
    output  logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0][$clog2(CONF_WT_BUF_DEPTH) - 1 : 0]  load_wt_wr_addr,
    output  logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0][5 : 0]                              load_wt_din,
    output  logic [CONF_PE_ROW - 1 : 0][CONF_PE_COL - 1 : 0]                                     load_wt_wr_en,         
    output  logic [CONF_PE_ROW - 1 : 0][$clog2(CONF_BIAS_BUF_DEPTH) - 1 : 0]                     load_bias_wr_addr,
    output  logic [CONF_PE_ROW - 1 : 0][5 : 0]                                                   load_bias_din,
    output  logic [CONF_PE_ROW - 1 : 0]                                                          load_bias_wr_en, 
    // IRQ
    input									                                                     IRQ_ACK,
    output	logic								                                                 IRQ_REQ
);
//  - instruction and top state machine --------------------------------------
logic [1 : 0][31 : 0] inst_addr;
logic inst_full, inst_empty;
logic inst_rd_en;
fifo_sync #(
    .DATA_WIDE(64),
    .FIFO_DEPT(FIFO_DEPTH)
)inst_fifo(
    .*,
    .din(s_axis_ins_tdata),
    .wr_en(s_axis_ins_tready && s_axis_ins_tvalid),
    .dout(inst_addr),
    .rd_en(fifo_rd_en_o),
    .full(fifo_full_o),
    .empty(fifo_empty_o)
);

/*-------------------TODO------------------------
    fm gd load
    wt bias load
    core valid
    save
    irq
-------------------------------------------------*/

// - IRQ -----------------------------------------------
always_ff@(posedge clk or negedge rst_n)
    if (!rst_n) IRQ_REQ <= '0;
    else if(IRQ_ACK) IRQ_REQ <= '0;
    else if(1/*to be filled*/) IRQ_REQ <= '1;
endmodule