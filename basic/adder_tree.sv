/*======================================================
Descripton:
parameterized adder tree

Create:  
Yipeng   wangyipengv@outlook.com  20191126

Modify:

Notes:
1. 
=========================================================*/
module adder_tree#(
    parameter IN_WIDTH = 8,
    parameter NUM   = 4,
    parameter OUT_WIDTH = 32
)(
    input  logic [NUM * IN_WIDTH - 1 : 0] a,
    output logic [OUT_WIDTH - 1 : 0] ans
);
always_comb for (integer i = NUM ; i > 0; i--)begin:add_all
    ans = ans + a[i*IN_WIDTH - 1 -: IN_WIDTH];
end
endmodule