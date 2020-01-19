 /*======================================================
Descripton:
specital true dule port mem for fm and gd

Create:  
Yipeng   wangyipengv@outlook.com  20191126

Modify:

Notes:
1. "No change" mode for douta

TODO:
=========================================================*/
module semi_ture_two_port_mem#(
    parameter BIT_LENGTH = 64,
    parameter DEPTH = 16,
    parameter MODE = "block",       // block; distribute; ultra
    parameter INIT_FILE = ""
) (
    input  logic                             clk,
    input  logic [$clog2(DEPTH) - 1 : 0 ]    addra,
    input  logic [$clog2(DEPTH) - 1 : 0 ]    addrb,
    input  logic [BIT_LENGTH       - 1 : 0 ] dina,
    output logic [BIT_LENGTH       - 1 : 0 ] douta,
    input  logic                             ena,   
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
          BRAM[ram_index] = '1;                                          //for test
    end
  endgenerate

//-------------------------------------------------
  always @(posedge clk)
    if(ena) begin
      if (wea)
        BRAM[addra] <= dina;
      else                                // "No Change" mode
        douta <= BRAM[addra];
    end

  always @(posedge clk)
    if (enb)
        doutb <= BRAM[addrb];

endmodule