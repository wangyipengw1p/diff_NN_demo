/*======================================================
Descripton:
simple two port RAM with single clk

Create:  
Yipeng   wangyipengv@outlook.com  20191126

Modify:

Notes:
1. 

TODO:
=========================================================*/
module two_port_mem#(
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
    output logic [BIT_LENGTH       - 1 : 0 ] doutb                      
);

    reg [BIT_LENGTH - 1 : 0] BRAM [ (1 << $clog2(DEPTH)) - 1 : 0 ];

  always @(posedge clk)
    if (ena)
      if (wea)
        BRAM[addra] <= dina;

  always @(posedge clk)
    if (enb)
        doutb <= BRAM[addrb];

endmodule