`timescale 1ns / 1ps

package ctl;

/*
typedef enum {
    DL_DB = 0,
    DL_ADL,
    DL_ADH,
    O_ADH_0,
    O_ADH_1_7,
    ADH_ABH,
    ADL_ABL,
    PCL_PCL,
    ADL_PCL,
    I_PC,
    PCL_DB,
    PCL_ADL,
    PCH_PCH,
    ADH_PCH,
    PCH_DB,
    PCH_ADH,
    SB_ADH,
    SB_DB,
    O_ADL0,
    O_ADL1,
    O_ADL2,
    S_ADL,
    SB_S,
    S_S,
    S_SB,
    DBB_ADD,
    DB_ADD,
    ADL_ADD,
    I_ADDC,
    DAA,
    DSA,
    SUMS,
    ANDS,
    EORS,
    ORS,
    SRS,
    ADD_ADL,
    ADD_SB_0_6,
    ADD_SB_7,
    O_ADD,
    SB_ADD,
    SB_AC,
    AC_DB,
    AC_SB,
    SB_X,
    X_SB,
    SB_Y,
    Y_SB,
    P_DB,
    DB0_C,
    IR5_C,
    ACR_C,
    DBI_Z,
    DBZ_Z,
    DB2_I,
    IR5_I,
    DB3_D,
    IR5_D,
    DB6_V,
    AVR_V,
    I_V,
    DB7_N,

    NumCtlSignals
} ControlSignals;
*/

typedef enum {
    O_ADH_0,
    O_ADH_1_7,
    ADH_ABH,
    ADL_ABL,
    ADL_PCL,
    I_PC,
    ADH_PCH,
    O_ADL_0,
    O_ADL_1,
    O_ADL_2,
    SB_AC,
    SB_X,
    SB_Y,
    SB_S,

    // ALU flags
    DAA,
    I_ADDC,

    NumCtlSignals
} ControlSignals;

typedef enum logic[2:0] {
    DB_INVALID = 'X,

    AC_DB = 0,
    P_DB,
    SB_DB,
    PCH_DB,
    PCL_DB,
    DL_DB
} DBSrc;

typedef enum logic[2:0] {
    SB_INVALID = 'X,

    O_SB = 0,
    AC_SB,
    Y_SB,
    X_SB,
    ADD_SB,
    S_SB,
    DL_SB
} SBSrc;

typedef enum logic[1:0] {
    ADH_INVALID = 'X,

    SB_ADH = 0,
    PCH_ADH,
    GEN_ADH,
    DL_ADH
} ADHSrc;

typedef enum logic[2:0] {
    ADL_INVALID = 'X,

    ADD_ADL = 0,
    S_ADL,
    GEN_ADL,
    PCL_ADL,
    DL_ADL
} ADLSrc;

typedef enum logic[2:0] {
    ALU_INVALID = 'X,

    SUMS = 0,
    ANDS,
    EORS,
    ORS,
    SRS,
    SLS
} ALUOp;

endpackage
