/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191126

Modify:

Notes:
1. 
=========================================================*/
package diff_core_pkg;
// BIT fixed
//parameter BIT_WIDTH = 8;

//kernal_mode: 0:3*3 1:5*5
//bit_mode： 0:8 1:4

// FM buf 570k (pingpong)
// WT buf 1M +

// PE
//parameter CONF_PE_PROCESS_WIDTH = 6; //fixed
parameter PSUM_WIDTH = 32;
parameter FIFO_DEPTH = 4;               //2.25k per PE

typedef enum logic[2:0] {  IDLE  = 3'b000, ONE, TWO, THREE, FOUR, FIVE, SIX } PE_state_t;

typedef enum  { A_MODE , B_MODE, C_MODE, D_MODE, E_MODE } PE_weight_mode_t; //E_mode: 3*3 others: 5*5

typedef struct packed {
    logic [7 : 0][8 : 0] A_9;
    logic [7 : 0][5 : 0] B_6;
    logic [7 : 0][5 : 0] C_6;
    logic [7 : 0][3 : 0] D_4;
} PE_weight_t;

// PE matrix
parameter CONF_PE_ROW = 2;
parameter CONF_PE_COL = 4;

// fm_guard_gen                                     //per row, sum264k
parameter FM_GUARD_GEN_TMP_BUF_DEPTH = 32;          //18k * 2
parameter FM_GUARD_GEN_PSUM_BUF_DEPTH = 512;        //96k * 2

//general
genvar i, j;
endpackage;

import diff_core_pkg::*;