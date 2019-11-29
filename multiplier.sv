/*======================================================
Descripton:
Special multiplier for 8-bit or 2-4bit mul

Create:  
Yipeng   wangyipengv@outlook.com  20191126

Modify:

Notes:
1. TODO
=========================================================*/
module multiplier(
    input  logic        mode,     //0: normal 8-bit  1: 2-4bit
    input  logic [7:0]  a,
    input  logic [7:0]  b,
    output logic [15:0] ans
);
// could be optimised
always_comb ans = mode ? {a[7:4] * b[7:4], a[3:0] * b[3:0]} : a * b;
endmodule
