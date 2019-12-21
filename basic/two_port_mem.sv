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
    output logic [BIT_LENGTH       - 1 : 0 ] doutb                      
);

(*ram_style = MODE*) logic [BIT_LENGTH - 1 : 0] BRAM [ (1 << $clog2(DEPTH)) - 1 : 0 ];
  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, BRAM, 0, DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < DEPTH; ram_index = ram_index + 1)
          BRAM[ram_index] = {(BIT_LENGTH/2){2'b10}};                                          //for test
    end
  endgenerate

//-------------------------------------------------
  always @(posedge clk)
      if (wea)
        BRAM[addra] <= dina;

  always @(posedge clk)
    if (enb)
        doutb <= BRAM[addrb];

endmodule