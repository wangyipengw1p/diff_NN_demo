/*======================================================
Descripton:
Special multiplier for 8bit or two 4bit mul

Create:  
Yipeng   wangyipengv@outlook.com  20191126

Modify:

Notes:
1. this module is customed one rather than general multiplier
2. 8bit mode: regular 8bit*8bit
3. 4bit mode: a[7:4]*b, a[3:0]*b stored in upper and lower half of ans repectively
=========================================================*/
import diff_demo_pkg::*;
module multiplier(
    input  logic        mode,     //0: normal 8-bit  1: 2-4bit
    input  logic [7:0]  a,
    input  logic [7:0]  b,
    output logic [PSUM_WIDTH - 1 : 0] ans
);
logic [PSUM_WIDTH/2 - 1 : 0] ans1, ans2;

generate 
if (PSUM_WIDTH > 25)begin: set_zero
    always_comb ans1[PSUM_WIDTH/2 - 1 : 12] = '0;
    always_comb ans2[PSUM_WIDTH/2 - 1 : 12] = '0;
end
endgenerate

mul mul1(
    .a   (a[7:4]),
    .b   (b),
    .ans (ans1[11:0])
);
mul mul2(
    .a   (a[3:0]),
    .b   (b),
    .ans (ans2[11:0])
);

always_comb ans = mode ? {ans1, ans2} : (ans1 << 4) + ans2;
endmodule

// - std 4bit*8bit multiplier --------------------------------------------
module mul(
    input  logic [3:0]  a,
    input  logic [7:0]  b,
    output logic [11:0] ans 
);
always_comb ans = a * b;
endmodule