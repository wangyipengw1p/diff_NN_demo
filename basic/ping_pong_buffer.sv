/*======================================================
Descripton:
special ping pong buffer for this design only

Create:  
Yipeng   wangyipengv@outlook.com  20191127

Modify:

Notes:
1. ping pong means read ping pong

TODO:
=========================================================*/
module ping_pong_buffer#(
    parameter BIT_LENGTH = 64,
    parameter DEPTH = 16,
    parameter MODE = "block",       // block; distribute; ultra
    parameter INIT_FILE = ""
) (
    input  logic                             clk,
    input  logic [$clog2(DEPTH) - 1 : 0 ]    addr1,
    input  logic [$clog2(DEPTH) - 1 : 0 ]    addr2,
    input  logic [BIT_LENGTH       - 1 : 0 ] din1,
    input  logic [BIT_LENGTH       - 1 : 0 ] din2,
    input  logic                             we1,   
    input  logic                             we2,
    output logic [BIT_LENGTH       - 1 : 0 ] dout1,
    output logic [BIT_LENGTH       - 1 : 0 ] dout2,
    input  logic                             ping_pong                    
);
logic [$clog2(DEPTH) - 1 : 0 ] addr_ping, addr_pong;
logic [BIT_LENGTH  - 1 : 0 ] din_ping, din_pong;
logic we_ping, we_pong;
logic [BIT_LENGTH       - 1 : 0 ] dout_ping, dout_pong;
always_comb begin
  addr_ping = ping_pong ? addr1 : addr2;
  addr_pong = ping_pong ? addr2 : addr1;
  din_ping  = ping_pong ? din1  : din2;
  din_pong  = ping_pong ? din2  : din1;
  we_ping   = ping_pong ? we1   : we2;
  we_pong   = ping_pong ? we2   : we1;
  dout1     = ping_pong ? dout_ping : dout_pong;
  dout2     = ping_pong ? dout_pong : dout_ping;
end

two_port_mem #(
    .BIT_LENGTH(BIT_LENGTH),
    .DEPTH(DEPTH)
) ping_mem (
  .*,
  .addra(addr_ping),
  .addrb(addr_ping),
  .dina(din_ping),
  .wea(we_ping),
  .enb('1),
  .doutb(dout_ping)
);

two_port_mem #(
    .BIT_LENGTH(BIT_LENGTH),
    .DEPTH(DEPTH)
) pong_mem (
  .*,
  .addra(addr_pong),
  .addrb(addr_pong),
  .dina(din_pong),
  .wea(we_pong),
  .enb('1),
  .doutb(dout_pong)
);

endmodule