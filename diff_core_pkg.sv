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

// PE
//parameter CONF_PE_PROCESS_WIDTH = 6; //fixed
parameter PSUM_WIDTH = 32;
parameter FIFO_DEPTH = 4;

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

// fm_guard_gen
parameter FM_GUARD_GEN_BUF_DEPTH = 32;

endpackage;

import diff_core_pkg::*;