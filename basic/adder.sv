/*======================================================
Descripton:
normal adder

Create:  
Yipeng   wangyipengv@outlook.com  20191126

Modify:

Notes:
1. 
=========================================================*/
import diff_demo_pkg::*;
module adder#(
    parameter WIDTH = 32
)(
    input  logic [WIDTH - 1 : 0] a,
    input  logic [WIDTH - 1 : 0] b,
    output logic [WIDTH - 1 : 0] ans
);
always_comb ans = a + b;
endmodule