/*======================================================
Descripton:
normal adder， without data truncate

Create:  
Yipeng   wangyipengv@outlook.com  20191126

Modify:

Notes:
1. 
=========================================================*/
module adder#(
    parameter WIDTH = 32
)(
    input  logic [WIDTH - 1 : 0] a,
    input  logic [WIDTH - 1 : 0] b,
    input  logic                 bit_mode,
    output logic [WIDTH - 1 : 0] ans
);
logic signed [WIDTH/2 - 1 : 0] tmp1, tmp2;

always_comb begin
    tmp1 = $signed(a[WIDTH - 1 : WIDTH/2]) + $signed(b[WIDTH - 1 : WIDTH/2]);
    tmp2 = $signed(a[WIDTH/2 - 1 : 0]) + $signed(b[WIDTH/2 - 1 : 0]);
    ans = bit_mode ?  {tmp1, tmp2} : $signed(a) + $signed(b);
end
endmodule