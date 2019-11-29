/*======================================================
Descripton:


Create:  
Yipeng   wangyipengv@outlook.com  20191127

Modify:

Notes:
1. 
=========================================================*/
package diff_core_pkg;
// - fixed ---------------------------------
parameter BIT_WIDTH = 8;
parameter PE_PROCESS_WINDOW = 6;
// -----------------------------------------

//kernal_mode: 0:3*3 1:5*5
//bit_mode? 0:8 1:4

// FM buf 570k (pingpong)
// WT buf 1M +
// PE matrix
parameter CONF_PE_ROW = 4;
parameter CONF_PE_COL = 4;

// TOP          3154k
parameter CONF_DDR_ADDR_WIDTH = 32;
parameter CONF_FM_BUF_DEPTH   = 18432;   // since the second layer is bottleneck, the fm buf drpth is (98*31*24/CONF_PE_COL) round up to the nearest 512|1152k
parameter CONF_GUARD_BUF_DEPTH= 3072;    // (98*31*24/CONF_PE_COL/PE_PROCESS_WINDOW) round up to the nearest 512                                        |144k       
parameter CONF_WT_BUF_DEPTH   = 512;     // (3*24 + 24*36 + 36*48 + (48*64 + 64 *64) / 2) / CONF_PE_ROW / CONF_PE_COL       = 390.2                     |1600k|1.5625M
parameter CONF_BIAS_BUF_DEPTH = 64;     // (24 + 36 + 48 + 64 + 64) / CONF_PE_ROW = 2k                                                                  |12k

// PE
//parameter CONF_PE_PROCESS_WIDTH = 6; //fixed
parameter PSUM_WIDTH = 32;
parameter FIFO_DEPTH = 4;               //3*6*PSUM_WIDTH*FIFO_DEPTH = 2.25k per PE | 36k

// fm_guard_gen                                     //per row, sum 528k
parameter FM_GUARD_GEN_TMP_BUF_DEPTH = 32;          //18k * 2
parameter FM_GUARD_GEN_PSUM_BUF_DEPTH = 512;        //96k * 2

typedef enum logic[2:0] {  
    IDLE  = 3'd0, 
    ONE   = 3'd1, 
    TWO   = 3'd2, 
    THREE = 3'd3, 
    FOUR  = 3'd4, 
    FIVE  = 3'd5, 
    SIX   = 3'd6
} PE_state_t;

typedef enum logic[2:0]{ A_MODE , B_MODE, C_MODE, D_MODE, E_MODE } PE_weight_mode_t; //E_mode: 3*3 others: 5*5

typedef struct packed {
    logic [7 : 0][8 : 0] A_9;
    logic [7 : 0][5 : 0] B_6;
    logic [7 : 0][5 : 0] C_6;
    logic [7 : 0][3 : 0] D_4;
} PE_weight_t;

endpackage

import diff_core_pkg::*;