/*======================================================
Descripton:
Special multiplier for 8-bit or 2-4bit mul

Create:  
Yipeng   wangyipengv@outlook.com  20191126

Modify:

Notes:
1. TODO
=========================================================*/
import diff_demo_pkg::*;
module multiplier(
    input  logic        mode,     //0: normal 8-bit  1: 2-4bit
    input  logic [7:0]  a,
    input  logic [7:0]  b,
    output logic [PSUM_WIDTH - 1 : 0] ans
);
logic [PSUM_WIDTH/2 - 1 : 0] ans1, ans2;
always_comb ans1[PSUM_WIDTH - 1 : 12] = '0;
always_comb ans2[PSUM_WIDTH - 1 : 12] = '0;
multi mul1(
    .a(a[7:4]),
    .b(b),
    .ans(ans1[11:0])
);
multi mul2(
    .a(a[3:0]),
    .b(b),
    .ans(ans2[11:0])
);

always_comb ans = mode ? {ans1, ans2} : (ans1 << 4) + ans2;

endmodule

module multi(
    input logic [3:0] a,
    input logic [7:0] b,
    output logic [11:0] ans 
);
always_comb ans = a*b;
endmodule