module AXI_Diff_cnn
	#(
		parameter	REVISION			=	32'h20200117,
		parameter	STREAM_DATA_WIDTH	=	8,
		parameter	C_S_AXI_DATA_WIDTH	=	32,
		parameter	C_S_AXI_ADDR_WIDTH	=	4
	)
	(
		//	========	System Interface
		input	S_AXI_ACLK,
		input	S_AXI_ARESETN,
		output	reg	IRQ_out,
		//	========	AXI_Lite Interface
		//	--------------	Write Addr Channel
		input	S_AXI_AWVALID,
		input	[2:0]	S_AXI_AWPROT,
		input	[C_S_AXI_ADDR_WIDTH-1:0]	S_AXI_AWADDR,
		output	reg	S_AXI_AWREADY,
		//	--------------	Write Data Channel
		input	S_AXI_WVALID,
		input	[3:0]	S_AXI_WSTRB,
		input	[31:0]	S_AXI_WDATA,
		output	reg	S_AXI_WREADY,
		//	--------------	Write Resp Channel
		input	S_AXI_BREADY,
		output	reg	S_AXI_BVALID,
		output	[1:0]	S_AXI_BRESP,
		//	--------------	Read Addr Channel
		input	S_AXI_ARVALID,
		input	[2:0]	S_AXI_ARPROT,
		input	[C_S_AXI_ADDR_WIDTH-1:0]	S_AXI_ARADDR,
		output	reg	S_AXI_ARREADY,
		//	--------------	Read Data Channel
		input	S_AXI_RREADY,
		output	reg	S_AXI_RVALID,
		output	[1:0]	S_AXI_RRESP,
		output	reg	[31:0]	S_AXI_RDATA,
		//	========	Datamover Interface
		//	--------------	MM2S cmd
		input	m_axis_mm2s_cmd_tready,
		output	m_axis_mm2s_cmd_tvalid,
		output	[71:0]	m_axis_mm2s_cmd_tdata,
		//	--------------	MM2S data
		input	s_axis_mm2s_tvalid,
		input	s_axis_mm2s_tlast,
		input	[0:0]	s_axis_mm2s_tkeep,
		input	[STREAM_DATA_WIDTH-1:0]	s_axis_mm2s_tdata,
		output	s_axis_mm2s_tready,
		//	--------------	S2MM
		input	m_axis_s2mm_cmd_tready,
		output	m_axis_s2mm_cmd_tvalid,
		output	[71:0]	m_axis_s2mm_cmd_tdata,
		//	--------------	S2MM data
		input	m_axis_s2mm_tready,
		output	m_axis_s2mm_tvalid,
		output	m_axis_s2mm_tlast,
		output	[0:0]	m_axis_s2mm_tkeep,
		output	[STREAM_DATA_WIDTH-1:0]	m_axis_s2mm_tdata
	);



reg	axi_reg_wren;
reg	[C_S_AXI_ADDR_WIDTH-1:0]	axi_awaddr;
reg	[31:0]	axi_wdata;
reg	[C_S_AXI_ADDR_WIDTH-1:0]	axi_araddr;
wire	axi_waddr_latch;
wire	axi_wdata_latch;
wire	axi_raddr_latch;

reg	IRQ_flag;
reg	[31:0]	Proc_ctrl;
reg	[31:0]	DMA_addr;
wire	IRQ_event;
wire	conv_tri;
wire	IRQ_clr;
wire	IRQ_en;
wire	frm_is_ref;
wire	frm_is_diff;
wire	[7:0]	frm_index;
wire	[31:0]	Proc_status;

//	***********************************************************	//
//	*************** AXI Lite Register Operation ***************	//
//	***********************************************************	//

assign	axi_waddr_latch	=	&{~S_AXI_AWREADY,S_AXI_AWVALID,S_AXI_WVALID};
assign	axi_wdata_latch	=	&{~S_AXI_WREADY,S_AXI_AWVALID,S_AXI_WVALID};
assign	S_AXI_BRESP		=	2'b00;

always @(posedge S_AXI_ACLK,negedge S_AXI_ARESETN) begin
	if(~S_AXI_ARESETN)	S_AXI_AWREADY	<=	1'b0;
	else				S_AXI_AWREADY	<=	axi_waddr_latch;
	if(~S_AXI_ARESETN)	S_AXI_WREADY	<=	1'b0;
	else				S_AXI_WREADY	<=	axi_wdata_latch;
	if(~S_AXI_ARESETN)	axi_awaddr		<=	{C_S_AXI_ADDR_WIDTH{1'b0}};
	else				axi_awaddr		<=	S_AXI_AWADDR;
	if(~S_AXI_ARESETN)	axi_wdata		<=	32'd0;
	else				axi_wdata		<=	S_AXI_WDATA;
	if(~S_AXI_ARESETN)	axi_reg_wren	<=	1'b0;
	else				axi_reg_wren	<=	&{S_AXI_AWREADY,S_AXI_WREADY};
	if(~S_AXI_ARESETN)	S_AXI_BVALID	<=	1'b0;
	else				S_AXI_BVALID	<=	S_AXI_BVALID	?	~S_AXI_BREADY	:	axi_reg_wren;
end

always @(posedge S_AXI_ACLK, negedge S_AXI_ARESETN) begin
	if(~S_AXI_ARESETN)								Proc_ctrl	<=	32'd0;
	else if(&{axi_reg_wren,axi_awaddr[3:2]==2'd1})	Proc_ctrl	<=	axi_wdata;
	else											Proc_ctrl	<=	Proc_ctrl&32'hFFFFFFF8;
	if(~S_AXI_ARESETN)								DMA_addr	<=	32'd0;
	else if(&{axi_reg_wren,axi_awaddr[3:2]==2'd2})	DMA_addr	<=	axi_wdata;
	else	;
end

assign	axi_raddr_latch	=	&{~S_AXI_ARREADY,S_AXI_ARVALID};
assign	S_AXI_RRESP		=	2'b00;
always @(posedge S_AXI_ACLK,negedge S_AXI_ARESETN) begin
	if(~S_AXI_ARESETN)	S_AXI_ARREADY	<=	1'b0;
	else				S_AXI_ARREADY	<=	axi_raddr_latch;
	if(~S_AXI_ARESETN)	S_AXI_RVALID	<=	1'b0;
	else				S_AXI_RVALID	<=	S_AXI_RVALID	?	~S_AXI_RREADY	:	S_AXI_ARREADY;
	if(~S_AXI_ARESETN)	axi_araddr		<=	{C_S_AXI_ADDR_WIDTH{1'b0}};
	else				axi_araddr		<=	S_AXI_ARADDR;
end

always @(posedge S_AXI_ACLK,negedge S_AXI_ARESETN) begin
	if(~S_AXI_ARESETN)	S_AXI_RDATA	<=	32'd0;
	else begin
		case(axi_araddr[11:2])
			10'd0	:	S_AXI_RDATA	<=	REVISION;
			10'd1	:	S_AXI_RDATA	<=	Proc_status;
			10'd2	:	S_AXI_RDATA	<=	DMA_addr;
			default	:	S_AXI_RDATA	<=	32'd0;
		endcase
	end
end


assign	conv_tri	=	Proc_ctrl[0];
assign	load_param	=	Proc_ctrl[1];
assign	IRQ_clr		=	Proc_ctrl[2];
assign	IRQ_en		=	Proc_ctrl[3];
assign	frm_is_ref	=	Proc_ctrl[4];
assign	frm_is_diff	=	Proc_ctrl[5];
assign	frm_index	=	Proc_ctrl[15:8];


always @(posedge S_AXI_ACLK, negedge S_AXI_ARESETN) begin
	if(~S_AXI_ARESETN) begin
		IRQ_out		<=	1'b0;
		IRQ_flag	<=	1'b0;
	end
	else begin
		IRQ_out	<=	IRQ_en&IRQ_flag;
		if(IRQ_event)		IRQ_flag	<=	1'b1;
		else if(IRQ_clr)	IRQ_flag	<=	1'b0;
		else	;
	end
end







conv_core #(
		.REVISION(REVISION)
) inst_core (
		//	========	System Interface
		.sys_clk(S_AXI_ACLK),		//	Input
		.sys_rstn(S_AXI_ARESETN),	//	Input
		.IRQ_event(IRQ_event),		//	Output
		//	========	Param & Ctrl Interface
		.conv_tri(conv_tri),		//	Input
		.frm_is_ref(frm_is_ref),	//	Input
		.frm_is_diff(frm_is_diff),	//	Input
		.frm_index(frm_index),		//	Input[7:0]
		.dma_addr(DMA_addr),		//	Input[31:0]
		//	========	Datamover Interface
		//	--------------	MM2S cmd
		.m_axis_mm2s_cmd_tready(m_axis_mm2s_cmd_tready),	//	Input
		.m_axis_mm2s_cmd_tvalid(m_axis_mm2s_cmd_tvalid),	//	Input
		.m_axis_mm2s_cmd_tdata(m_axis_mm2s_cmd_tdata),		//	Output[71:0]
		//	--------------	MM2S data
		.s_axis_mm2s_tvalid(s_axis_mm2s_tvalid),			//	Input
		.s_axis_mm2s_tlast(s_axis_mm2s_tlast),				//	Input
		.s_axis_mm2s_tkeep(s_axis_mm2s_tkeep),				//	Input[0:0]
		.s_axis_mm2s_tdata(s_axis_mm2s_tdata),				//	Input[STREAM_DATA_WIDTH-1:0]
		.s_axis_mm2s_tready(s_axis_mm2s_tready),			//	Output
		//	--------------	S2MM
		.m_axis_s2mm_cmd_tready(m_axis_s2mm_cmd_tready),	//	Input
		.m_axis_s2mm_cmd_tvalid(m_axis_s2mm_cmd_tvalid),	//	Input
		.m_axis_s2mm_cmd_tdata(m_axis_s2mm_cmd_tdata),		//	Output[71:0]
		//	--------------	S2MM data
		.m_axis_s2mm_tready(m_axis_s2mm_tready),			//	Input
		.m_axis_s2mm_tvalid(m_axis_s2mm_tvalid),			//	Output
		.m_axis_s2mm_tlast(m_axis_s2mm_tlast),				//	Output
		.m_axis_s2mm_tkeep(m_axis_s2mm_tkeep),				//	Output[0:0]
		.m_axis_s2mm_tdata(m_axis_s2mm_tdata)				//	Output[STREAM_DATA_WIDTH-1:0]

	);







endmodule






























