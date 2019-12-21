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
    parameter DEPTH = 16,
    parameter MODE = "block",       // block; distribute; ultra
    parameter INIT_FILE = ""
) (
    input  logic                             clk,
    input  logic [$clog2(DEPTH) - 1 : 0 ]    addra,
    input  logic [$clog2(DEPTH) - 1 : 0 ]    addrb,
    input  logic [BIT_LENGTH       - 1 : 0 ] dina,
    input  logic                             wea,   
    input  logic                             enb,
    output logic [BIT_LENGTH       - 1 : 0 ] doutb,
    input  logic                             ping_pong                    
);

(*ram_style = MODE*) logic [BIT_LENGTH - 1 : 0] BRAM [ (1 << $clog2(DEPTH)) : 0 ];
  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, BRAM, 0, 2*DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < 2*DEPTH; ram_index = ram_index + 1)
          BRAM[ram_index] = {BIT_LENGTH{1'b0}};
    end
  endgenerate

//-------------------------------------------------
  always @(posedge clk)
      if (wea)
        BRAM[{ping_pong,addra}] <= dina;

  always @(posedge clk)
    if (enb)
        doutb <= BRAM[{ping_pong,addrb}];

endmodule