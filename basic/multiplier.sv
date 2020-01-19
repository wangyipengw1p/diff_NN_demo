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
    input  logic        is_first,
    input  logic [7:0]  a,
    input  logic [7:0]  b,
    output logic [PSUM_WIDTH - 1 : 0] ans
);


logic signed [PSUM_WIDTH/2 - 1 : 0] ans1, ans2;
logic signed [PSUM_WIDTH - 1 : 0] tmp_ans, tmp_ans1;
logic [7:0] u_a;
always_comb begin
    u_a = !is_first && !mode ? a[7] ? ~a + 1 : a : a;
    tmp_ans = (ans1 << 4) + ans2;
    tmp_ans1 = a[7] ? ~tmp_ans + 1 : tmp_ans;
    if(is_first)begin        
        ans = mode ? {ans1, ans2} : tmp_ans;
    end else begin
        ans = mode ? {ans1, ans2} : tmp_ans1;
    end
end 


mul mul1(
    .a   (u_a[7:4]),
    .b   (b),
    .a_unsigned (is_first),
    .ans (ans1)
);
mul mul2(
    .a   (u_a[3:0]),
    .b   (b),
    .a_unsigned (is_first),
    .ans (ans2)
);
endmodule

// - std 4bit*8bit multiplier --------------------------------------------
module mul(
    input  logic [3:0]  a,
    input  logic [7:0]  b,
    input  logic        a_unsigned,
    output logic signed [11:0] ans 
);
logic [7:0] u_b;
logic [3:0] u_a;
always_comb begin
    u_b = b[7] ? ~b + 1: b;
    u_a = a_unsigned ? a : a[3] ? ~a + 1 : a;
    ans = (a_unsigned ? b[7] : a[3] ^ b[7]) ?  $signed(~(u_a * u_b) + 1) : $signed(u_a * u_b);
end

endmodule