/*======================================================
Descripton:
std ping pong buffer

Create:  
Yipeng   wangyipengv@outlook.com  20191127

Modify:

Notes:
1. ping pong means read ping pong

TODO:
=========================================================*/
module ping_pong_buffer#(
    parameter BIT_LENGTH = 64,
    parameter DEPTH = 16
) (
    input  logic                             clk,
    input  logic [$clog2(DEPTH) - 1 : 0 ]    addra,
    input  logic [$clog2(DEPTH) - 1 : 0 ]    addrb,
    input  logic [BIT_LENGTH       - 1 : 0 ] dina,
    input  logic                             wea,   
    input  logic                             ena,
    input  logic                             enb,
    output logic [BIT_LENGTH       - 1 : 0 ] doutb,
    input  logic                             ping_pong      //0: read upper half of RAM           
);

    reg [BIT_LENGTH - 1 : 0] BRAM [ (1 << $clog2(DEPTH)) : 0 ];

  always @(posedge clk)
    if (ena)
      if (wea)
        BRAM[{~ping_pong, addra}] <= dina;

  always @(posedge clk)
    if (enb)
        doutb <= BRAM[{ping_pong,addrb}];

endmodule