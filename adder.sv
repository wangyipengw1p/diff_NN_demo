/*======================================================
Descripton:
normal adder

Create:  
Yipeng   wangyipengv@outlook.com  20191126

Modify:

Notes:
1. 
=========================================================*/
`include "diff_core_pkg.sv"
module adder(
    input  logic [PSUM_WIDTH - 1 : 0] a,
    input  logic [PSUM_WIDTH - 1 : 0] b,
    output logic [PSUM_WIDTH - 1 : 0] ans,
);
always_comb ans = a + b;
endmodule