// =============================================================================
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// -----------------------------------------------------------------------------
//   Copyright (c) 2023 by Lattice Semiconductor Corporation
//   ALL RIGHTS RESERVED
// --------------------------------------------------------------------
//
//   Permission:
//
//      Lattice SG Pte. Ltd. grants permission to use this code
//      pursuant to the terms of the Lattice Reference Design License Agreement.
//
//
//   Disclaimer:
//
//      This VHDL or Verilog source code is intended as a design reference
//      which illustrates how these types of functions can be implemented.
//      It is the user's responsibility to verify their design for
//      consistency and functionality through the use of formal
//      verification methods.  Lattice provides no warranty
//      regarding the use or functionality of this code.
//
// -----------------------------------------------------------------------------
//
//                  Lattice SG Pte. Ltd.
//                  101 Thomson Road, United Square #07-02
//                  Singapore 307591
//
//
//                  TEL: 1-800-Lattice (USA and Canada)
//                       +65-6631-2000 (Singapore)
//                       +1-503-268-8001 (other locations)
//
//                  web: http://www.latticesemi.com/
//                  email: techsupport@latticesemi.com
//
// -----------------------------------------------------------------------------
//
// =============================================================================
//                         FILE DETAILS
// Project               :
// File                  : tb_top.v
// Title                 : Testbench for MPCS.
// Dependencies          : 1.
//                       : 2.
// Description           :
// =============================================================================
//                        REVISION HISTORY
// Version               : 1.0
// Author(s)             :
// Mod. Date             : 
// Changes Made          : Initial version of testbench for MPCS.
//                       : 
// =============================================================================
`timescale 1ns/1ps

`include "tb_lmmi_mst.v"
`include "tb_clkgen.v"
`include "tb_clk_freq_checker.v"

module tb_top();

`include "dut_params.v"

//--------------------------------------------------------------------------
//--- Local Parameters/Defines ---
//--------------------------------------------------------------------------
localparam CLKPERIOD   = 6.4; //156.25MHz
localparam REFCLKFREQ  = 1000/REFCLK; 
localparam DATA_MSB    = (NUM_LANES == 1) ? 7  :
                         (NUM_LANES == 2) ? 15 :
                         (NUM_LANES == 4) ? 31 :
                         (NUM_LANES == 6) ? 47 : 63;
localparam ITER_LSB    = (MODESEL == 2 || (MODESEL == 0 && PCS_BYPASS == 1)) ? 0   : 256; 
localparam ITER_MSB    = (MODESEL == 2 || (MODESEL == 0 && PCS_BYPASS == 1)) ? 256 : 491;
localparam DWIDTH      = (MODESEL == 0                                     ) ? 40  : 
                         (MODESEL == 2)                 ? 32  : 64;
                                                              
localparam PCS_DWIDTH  = (MODESEL == 2)                 ? 32  : 80; 
localparam BUS_IDL_L0  = 3'd0,
           BUS_STA_L0  = 3'd1,
           BUS_IDL_L1  = 3'd0,
           BUS_STA_L1  = 3'd1,
           BUS_IDL_L2  = 3'd0,
           BUS_STA_L2  = 3'd1,
           BUS_IDL_L3  = 3'd0,
           BUS_STA_L3  = 3'd1,
           BUS_IDL_L4  = 3'd0,
           BUS_STA_L4  = 3'd1,
           BUS_IDL_L5  = 3'd0,
           BUS_STA_L5  = 3'd1,
           BUS_IDL_L6  = 3'd0,
           BUS_STA_L6  = 3'd1,
           BUS_IDL_L7  = 3'd0,
           BUS_STA_L7  = 3'd1;

localparam EXP_CLKFREQ = CLK_OUT;
localparam MULTIRATE   = (PROTOCOL == "SLVS_EC")   ? 1 : 
                         (PROTOCOL == "COAXPRESS") ? 1 : 
                         (PROTOCOL == "EDP")       ? 1 : 
                         (PROTOCOL == "DP")        ? 1 :
                         (PROTOCOL == "G8B10B")    ? 1 : 
                         (PCS_BYPASS == 1)         ? 1 : 0;
// -----------------------------------------------------------------------------
// Integer/Register Declarations
// -----------------------------------------------------------------------------              
integer i, j;
integer error_count;

reg [25:0]   reg_list[0:490];
reg [8*23:1] reg_names[0:490];
reg          reset;                // aligned with usr_clk
reg          reset_n;              // aligned with usr_clk
reg          fcheck;

reg [PCS_DWIDTH-1:0] pcsdata;

reg                 bus_data_mode_l0;
reg     [2:0]       bus_sm_l0;
reg     [31:0]      bus_data_l0;
reg     [3:0]       bus_control_l0;
reg     [8:0]       bus_cnt_l0;

reg                 bus_data_mode_l1;
reg     [2:0]       bus_sm_l1;
reg     [31:0]      bus_data_l1;
reg     [3:0]       bus_control_l1;
reg     [8:0]       bus_cnt_l1;

reg                 bus_data_mode_l2;
reg     [2:0]       bus_sm_l2;
reg     [31:0]      bus_data_l2;
reg     [3:0]       bus_control_l2;
reg     [8:0]       bus_cnt_l2;

reg                 bus_data_mode_l3;
reg     [2:0]       bus_sm_l3;
reg     [31:0]      bus_data_l3;
reg     [3:0]       bus_control_l3;
reg     [8:0]       bus_cnt_l3;

reg                 bus_data_mode_l4;
reg     [2:0]       bus_sm_l4;
reg     [31:0]      bus_data_l4;
reg     [3:0]       bus_control_l4;
reg     [8:0]       bus_cnt_l4;

reg                 bus_data_mode_l5;
reg     [2:0]       bus_sm_l5;
reg     [31:0]      bus_data_l5;
reg     [3:0]       bus_control_l5;
reg     [8:0]       bus_cnt_l5;

reg                 bus_data_mode_l6;
reg     [2:0]       bus_sm_l6;
reg     [31:0]      bus_data_l6;
reg     [3:0]       bus_control_l6;
reg     [8:0]       bus_cnt_l6;

reg                 bus_data_mode_l7;
reg     [2:0]       bus_sm_l7;
reg     [31:0]      bus_data_l7;
reg     [3:0]       bus_control_l7;
reg     [8:0]       bus_cnt_l7;

// -----------------------------------------------------------------------------
// Wire Declarations
// -----------------------------------------------------------------------------    
                       
wire        mpcs_clk;             // MPCS usr_clk
wire        ref_clk;              // Serial reference clk

wire        fcheck_tb_error;
wire        fcheck_done;

wire [7:0]  epcs_ready_w;
wire [7:0]  epcs_phyrdy_w;

wire [7:0]  mpcs_ready_w;
wire [7:0]  mpcs_phyrdy_w;
wire [3:0]  pipe_phy_status_w;

wire [63:0] lmmi_rdata_o_w;
wire [7:0]  lmmi_rdata_valid_o_w;
wire [7:0]  lmmi_ready_o_w;

//64b66b
wire        tx_fifo_wr;
wire        tx_frcpkt ;
wire [7:0]  tx_control;

//8b10b
wire [3:0]  tx_frcdata;
wire [3:0]  tx_dispval;
wire [3:0]  tx_frcdisp;
            
wire        use_refmux_i     ; 
wire        diffioclksel_i   ; 
wire  [1:0] clksel_i         ; 
wire        sd_ext_0_refclk_i;
wire        sd_ext_1_refclk_i;
wire        pll_0_refclk_i   ;
wire        pll_1_refclk_i   ;    
wire        sd_pll_refclk_i  ;

//LMMI Interface
wire        lmmi_clk_i_0;
wire        lmmi_clk_i_7;
wire        lmmi_clk_i_6;
wire        lmmi_clk_i_5;
wire        lmmi_clk_i_4;
wire        lmmi_clk_i_3;
wire        lmmi_clk_i_2;
wire        lmmi_clk_i_1;
  
wire        lmmi_resetn_i_0;              
wire        lmmi_resetn_i_7;
wire        lmmi_resetn_i_6;
wire        lmmi_resetn_i_5;
wire        lmmi_resetn_i_4;
wire        lmmi_resetn_i_3;
wire        lmmi_resetn_i_2;
wire        lmmi_resetn_i_1;
        
wire        lmmi_request_i_0;
wire        lmmi_request_i_7;
wire        lmmi_request_i_6;
wire        lmmi_request_i_5;
wire        lmmi_request_i_4;
wire        lmmi_request_i_3;
wire        lmmi_request_i_2;
wire        lmmi_request_i_1;
  
wire        lmmi_wr_rdn_i_0;
wire        lmmi_wr_rdn_i_7;
wire        lmmi_wr_rdn_i_6;
wire        lmmi_wr_rdn_i_5;
wire        lmmi_wr_rdn_i_4;
wire        lmmi_wr_rdn_i_3;
wire        lmmi_wr_rdn_i_2;
wire        lmmi_wr_rdn_i_1;
            
wire [8:0]  lmmi_offset_i_0;
wire [8:0]  lmmi_offset_i_7;
wire [8:0]  lmmi_offset_i_6;
wire [8:0]  lmmi_offset_i_5;
wire [8:0]  lmmi_offset_i_4;
wire [8:0]  lmmi_offset_i_3;
wire [8:0]  lmmi_offset_i_2;
wire [8:0]  lmmi_offset_i_1;

wire [7:0]  lmmi_wdata_i_0;     
wire [7:0]  lmmi_wdata_i_7;
wire [7:0]  lmmi_wdata_i_6;
wire [7:0]  lmmi_wdata_i_5;
wire [7:0]  lmmi_wdata_i_4;
wire [7:0]  lmmi_wdata_i_3;
wire [7:0]  lmmi_wdata_i_2;
wire [7:0]  lmmi_wdata_i_1;
                    
wire        lmmi_rdata_valid_o_7;
wire        lmmi_rdata_valid_o_6;
wire        lmmi_rdata_valid_o_5;
wire        lmmi_rdata_valid_o_4;
wire        lmmi_rdata_valid_o_3;
wire        lmmi_rdata_valid_o_2;
wire        lmmi_rdata_valid_o_1;
wire        lmmi_rdata_valid_o_0;
            
wire        lmmi_ready_o_7;
wire        lmmi_ready_o_6;
wire        lmmi_ready_o_5;
wire        lmmi_ready_o_4;
wire        lmmi_ready_o_3;
wire        lmmi_ready_o_2;
wire        lmmi_ready_o_1;
wire        lmmi_ready_o_0;

wire [7:0]  lmmi_rdata_o_7;
wire [7:0]  lmmi_rdata_o_6;
wire [7:0]  lmmi_rdata_o_5;
wire [7:0]  lmmi_rdata_o_4;
wire [7:0]  lmmi_rdata_o_3;
wire [7:0]  lmmi_rdata_o_2;
wire [7:0]  lmmi_rdata_o_1;
wire [7:0]  lmmi_rdata_o_0;


// Serial I/Os and Pads

wire        sdq_refclkp_q0_i;       //pad, refclk+, Q0
wire        sdq_refclkn_q0_i;       //pad, refclk-, Q0
wire        sdq_refclkp_q1_i;       //pad, refclk+, Q1
wire        sdq_refclkn_q1_i;       //pad, refclk-, Q1
                                                         
wire        sd7txp_o;               // pad, TX+
wire        sd6txp_o;               // pad, TX+
wire        sd5txp_o;               // pad, TX+
wire        sd4txp_o;               // pad, TX+
wire        sd3txp_o;               // pad, TX+
wire        sd2txp_o;               // pad, TX+
wire        sd1txp_o;               // pad, TX+
wire        sd0txp_o;               // pad, TX+

wire        sd7txn_o;               // pad, Tx-
wire        sd6txn_o;               // pad, Tx-
wire        sd5txn_o;               // pad, Tx-
wire        sd4txn_o;               // pad, Tx-
wire        sd3txn_o;               // pad, Tx-
wire        sd2txn_o;               // pad, Tx-
wire        sd1txn_o;               // pad, Tx-
wire        sd0txn_o;               // pad, Tx-
                     
wire        sd7rxp_i;               // serial pad, RX+
wire        sd6rxp_i;               // serial pad, RX+
wire        sd5rxp_i;               // serial pad, RX+
wire        sd4rxp_i;               // serial pad, RX+
wire        sd3rxp_i;               // serial pad, RX+
wire        sd2rxp_i;               // serial pad, RX+
wire        sd1rxp_i;               // serial pad, RX+
wire        sd0rxp_i;               // serial pad, RX+
                                    
wire        sd7rxn_i;               // serial pad, RX-
wire        sd6rxn_i;               // serial pad, RX-
wire        sd5rxn_i;               // serial pad, RX-
wire        sd4rxn_i;               // serial pad, RX-
wire        sd3rxn_i;               // serial pad, RX-
wire        sd2rxn_i;               // serial pad, RX-
wire        sd1rxn_i;               // serial pad, RX-
wire        sd0rxn_i;               // serial pad, RX-

wire        sd7_rext_i;              // pad, external resistance
wire        sd6_rext_i;              // pad, external resistance
wire        sd5_rext_i;              // pad, external resistance
wire        sd4_rext_i;              // pad, external resistance
wire        sd3_rext_i;              // pad, external resistance
wire        sd2_rext_i;              // pad, external resistance
wire        sd1_rext_i;              // pad, external resistance
wire        sd0_rext_i;              // pad, external resistance
   
wire        sd7_refret_i;            // pad
wire        sd6_refret_i;            // pad
wire        sd5_refret_i;            // pad
wire        sd4_refret_i;            // pad
wire        sd3_refret_i;            // pad
wire        sd2_refret_i;            // pad
wire        sd1_refret_i;            // pad
wire        sd0_refret_i;            // pad
    

//MPCS Interface

wire        mpcs_rx_usr_clk_i_7;
wire        mpcs_rx_usr_clk_i_6;
wire        mpcs_rx_usr_clk_i_5;
wire        mpcs_rx_usr_clk_i_4;
wire        mpcs_rx_usr_clk_i_3;
wire        mpcs_rx_usr_clk_i_2;
wire        mpcs_rx_usr_clk_i_1;
wire        mpcs_rx_usr_clk_i_0;
       
wire        mpcs_tx_usr_clk_i_7;
wire        mpcs_tx_usr_clk_i_6;
wire        mpcs_tx_usr_clk_i_5;
wire        mpcs_tx_usr_clk_i_4;
wire        mpcs_tx_usr_clk_i_3;
wire        mpcs_tx_usr_clk_i_2;
wire        mpcs_tx_usr_clk_i_1;
wire        mpcs_tx_usr_clk_i_0;

wire        usr_clk_i;
            
wire        mpcs_tx_pcs_rstn_i_7;
wire        mpcs_tx_pcs_rstn_i_6;
wire        mpcs_tx_pcs_rstn_i_5;
wire        mpcs_tx_pcs_rstn_i_4;
wire        mpcs_tx_pcs_rstn_i_3;
wire        mpcs_tx_pcs_rstn_i_2;
wire        mpcs_tx_pcs_rstn_i_1;
wire        mpcs_tx_pcs_rstn_i_0;
                
wire        mpcs_rx_pcs_rstn_i_7;
wire        mpcs_rx_pcs_rstn_i_6;
wire        mpcs_rx_pcs_rstn_i_5;
wire        mpcs_rx_pcs_rstn_i_4;
wire        mpcs_rx_pcs_rstn_i_3;
wire        mpcs_rx_pcs_rstn_i_2;
wire        mpcs_rx_pcs_rstn_i_1;
wire        mpcs_rx_pcs_rstn_i_0;

wire        mpcs_cc_clk_i_7;
wire        mpcs_cc_clk_i_6;
wire        mpcs_cc_clk_i_5;
wire        mpcs_cc_clk_i_4;
wire        mpcs_cc_clk_i_3;
wire        mpcs_cc_clk_i_2;
wire        mpcs_cc_clk_i_1;
wire        mpcs_cc_clk_i_0;

wire        mpcs_rx_out_clk_o_7;
wire        mpcs_rx_out_clk_o_6;
wire        mpcs_rx_out_clk_o_5;
wire        mpcs_rx_out_clk_o_4;
wire        mpcs_rx_out_clk_o_3;
wire        mpcs_rx_out_clk_o_2;
wire        mpcs_rx_out_clk_o_1;
wire        mpcs_rx_out_clk_o_0;
            
wire        mpcs_tx_out_clk_o_7;
wire        mpcs_tx_out_clk_o_6;
wire        mpcs_tx_out_clk_o_5;
wire        mpcs_tx_out_clk_o_4;
wire        mpcs_tx_out_clk_o_3;
wire        mpcs_tx_out_clk_o_2;
wire        mpcs_tx_out_clk_o_1;
wire        mpcs_tx_out_clk_o_0;
                 
wire        mpcs_perstn_i_7;
wire        mpcs_perstn_i_6;
wire        mpcs_perstn_i_5;
wire        mpcs_perstn_i_4;
wire        mpcs_perstn_i_3;
wire        mpcs_perstn_i_2;
wire        mpcs_perstn_i_1;
wire        mpcs_perstn_i_0;
         
wire        mpcs_clkreq_in_n_i_7;
wire        mpcs_clkreq_in_n_i_6;
wire        mpcs_clkreq_in_n_i_5;
wire        mpcs_clkreq_in_n_i_4;
wire        mpcs_clkreq_in_n_i_3;
wire        mpcs_clkreq_in_n_i_2;
wire        mpcs_clkreq_in_n_i_1;
wire        mpcs_clkreq_in_n_i_0;
              
wire        mpcs_clkreq_out_n_o_7;
wire        mpcs_clkreq_out_n_o_6;
wire        mpcs_clkreq_out_n_o_5;
wire        mpcs_clkreq_out_n_o_4;
wire        mpcs_clkreq_out_n_o_3;
wire        mpcs_clkreq_out_n_o_2;
wire        mpcs_clkreq_out_n_o_1;
wire        mpcs_clkreq_out_n_o_0;
        
wire        mpcs_clkreq_n_oe_o_7;
wire        mpcs_clkreq_n_oe_o_6;
wire        mpcs_clkreq_n_oe_o_5;
wire        mpcs_clkreq_n_oe_o_4;
wire        mpcs_clkreq_n_oe_o_3;
wire        mpcs_clkreq_n_oe_o_2;
wire        mpcs_clkreq_n_oe_o_1;
wire        mpcs_clkreq_n_oe_o_0;
         
wire [79:0] mpcs_rx_ch_dout_o_7;
wire [79:0] mpcs_rx_ch_dout_o_6;
wire [79:0] mpcs_rx_ch_dout_o_5;
wire [79:0] mpcs_rx_ch_dout_o_4;
wire [79:0] mpcs_rx_ch_dout_o_3;
wire [79:0] mpcs_rx_ch_dout_o_2;
wire [79:0] mpcs_rx_ch_dout_o_1;
wire [79:0] mpcs_rx_ch_dout_o_0;
    
wire [79:0] mpcs_tx_ch_din_i_7;
wire [79:0] mpcs_tx_ch_din_i_6;
wire [79:0] mpcs_tx_ch_din_i_5;
wire [79:0] mpcs_tx_ch_din_i_4;
wire [79:0] mpcs_tx_ch_din_i_3;
wire [79:0] mpcs_tx_ch_din_i_2;
wire [79:0] mpcs_tx_ch_din_i_1;
wire [79:0] mpcs_tx_ch_din_i_0; 

wire [79:0] mpcs_tx_ch_din_i_7_next;
wire [79:0] mpcs_tx_ch_din_i_6_next;
wire [79:0] mpcs_tx_ch_din_i_5_next;
wire [79:0] mpcs_tx_ch_din_i_4_next;
wire [79:0] mpcs_tx_ch_din_i_3_next;
wire [79:0] mpcs_tx_ch_din_i_2_next;
wire [79:0] mpcs_tx_ch_din_i_1_next;
wire [79:0] mpcs_tx_ch_din_i_0_next;
   
wire [3:0]  mpcs_tx_fifo_st_o_7;
wire [3:0]  mpcs_tx_fifo_st_o_6;
wire [3:0]  mpcs_tx_fifo_st_o_5;
wire [3:0]  mpcs_tx_fifo_st_o_4;
wire [3:0]  mpcs_tx_fifo_st_o_3;
wire [3:0]  mpcs_tx_fifo_st_o_2;
wire [3:0]  mpcs_tx_fifo_st_o_1;
wire [3:0]  mpcs_tx_fifo_st_o_0;

wire [3:0]  mpcs_rx_fifo_st_o_7;
wire [3:0]  mpcs_rx_fifo_st_o_6;
wire [3:0]  mpcs_rx_fifo_st_o_5;
wire [3:0]  mpcs_rx_fifo_st_o_4;
wire [3:0]  mpcs_rx_fifo_st_o_3;
wire [3:0]  mpcs_rx_fifo_st_o_2;
wire [3:0]  mpcs_rx_fifo_st_o_1;
wire [3:0]  mpcs_rx_fifo_st_o_0;
    
wire        mpcs_rx_hi_ber_o_7;
wire        mpcs_rx_hi_ber_o_6;
wire        mpcs_rx_hi_ber_o_5;
wire        mpcs_rx_hi_ber_o_4;
wire        mpcs_rx_hi_ber_o_3;
wire        mpcs_rx_hi_ber_o_2;
wire        mpcs_rx_hi_ber_o_1;
wire        mpcs_rx_hi_ber_o_0;

wire        mpcs_rx_blk_lock_o_7;
wire        mpcs_rx_blk_lock_o_6;
wire        mpcs_rx_blk_lock_o_5;
wire        mpcs_rx_blk_lock_o_4;
wire        mpcs_rx_blk_lock_o_3;
wire        mpcs_rx_blk_lock_o_2;
wire        mpcs_rx_blk_lock_o_1;
wire        mpcs_rx_blk_lock_o_0;
       
wire        mpcs_ebuf_empty_o_7;
wire        mpcs_ebuf_empty_o_6;
wire        mpcs_ebuf_empty_o_5;
wire        mpcs_ebuf_empty_o_4;
wire        mpcs_ebuf_empty_o_3;
wire        mpcs_ebuf_empty_o_2;
wire        mpcs_ebuf_empty_o_1;
wire        mpcs_ebuf_empty_o_0;
        
wire        mpcs_ebuf_full_o_7;
wire        mpcs_ebuf_full_o_6;
wire        mpcs_ebuf_full_o_5;
wire        mpcs_ebuf_full_o_4;
wire        mpcs_ebuf_full_o_3;
wire        mpcs_ebuf_full_o_2;
wire        mpcs_ebuf_full_o_1;
wire        mpcs_ebuf_full_o_0;
    
wire        mpcs_anxmit_i_7;
wire        mpcs_anxmit_i_6;
wire        mpcs_anxmit_i_5;
wire        mpcs_anxmit_i_4;
wire        mpcs_anxmit_i_3;
wire        mpcs_anxmit_i_2;
wire        mpcs_anxmit_i_1;
wire        mpcs_anxmit_i_0; 
        
wire        mpcs_walign_en_i_7;
wire        mpcs_walign_en_i_6;
wire        mpcs_walign_en_i_5;
wire        mpcs_walign_en_i_4;
wire        mpcs_walign_en_i_3;
wire        mpcs_walign_en_i_2;
wire        mpcs_walign_en_i_1;
wire        mpcs_walign_en_i_0;
    
wire        mpcs_get_lsync_o_7;
wire        mpcs_get_lsync_o_6;
wire        mpcs_get_lsync_o_5;
wire        mpcs_get_lsync_o_4;
wire        mpcs_get_lsync_o_3;
wire        mpcs_get_lsync_o_2;
wire        mpcs_get_lsync_o_1;
wire        mpcs_get_lsync_o_0;
   
wire        mpcs_rx_get_lalign_o_7;
wire        mpcs_rx_get_lalign_o_6;
wire        mpcs_rx_get_lalign_o_5;
wire        mpcs_rx_get_lalign_o_4;
wire        mpcs_rx_get_lalign_o_3;
wire        mpcs_rx_get_lalign_o_2;
wire        mpcs_rx_get_lalign_o_1;
wire        mpcs_rx_get_lalign_o_0;

wire        mpcs_rx_deskew_en_i_7;
wire        mpcs_rx_deskew_en_i_6;
wire        mpcs_rx_deskew_en_i_5;
wire        mpcs_rx_deskew_en_i_4;
wire        mpcs_rx_deskew_en_i_3;
wire        mpcs_rx_deskew_en_i_2;
wire        mpcs_rx_deskew_en_i_1;
wire        mpcs_rx_deskew_en_i_0;
       
wire        mpcs_clkin_i_7; //PMA Clock
wire        mpcs_clkin_i_6; //PMA Clock
wire        mpcs_clkin_i_5; //PMA Clock
wire        mpcs_clkin_i_4; //PMA Clock
wire        mpcs_clkin_i_3; //PMA Clock
wire        mpcs_clkin_i_2; //PMA Clock
wire        mpcs_clkin_i_1; //PMA Clock
wire        mpcs_clkin_i_0; //PMA Clock

wire [1:0]  mpcs_pwrdn_i_7;
wire [1:0]  mpcs_pwrdn_i_6;
wire [1:0]  mpcs_pwrdn_i_5;
wire [1:0]  mpcs_pwrdn_i_4;
wire [1:0]  mpcs_pwrdn_i_3;
wire [1:0]  mpcs_pwrdn_i_2;
wire [1:0]  mpcs_pwrdn_i_1;
wire [1:0]  mpcs_pwrdn_i_0;

wire        mpcs_txhiz_i_7;
wire        mpcs_txhiz_i_6;
wire        mpcs_txhiz_i_5;
wire        mpcs_txhiz_i_4;
wire        mpcs_txhiz_i_3;
wire        mpcs_txhiz_i_2;
wire        mpcs_txhiz_i_1;
wire        mpcs_txhiz_i_0;
  
wire        mpcs_rxidle_o_7;
wire        mpcs_rxidle_o_6;
wire        mpcs_rxidle_o_5;
wire        mpcs_rxidle_o_4;
wire        mpcs_rxidle_o_3;
wire        mpcs_rxidle_o_2;
wire        mpcs_rxidle_o_1;
wire        mpcs_rxidle_o_0;

wire        mpcs_rxerr_i_7;
wire        mpcs_rxerr_i_6;
wire        mpcs_rxerr_i_5;
wire        mpcs_rxerr_i_4;
wire        mpcs_rxerr_i_3;
wire        mpcs_rxerr_i_2;
wire        mpcs_rxerr_i_1;
wire        mpcs_rxerr_i_0;
  
wire        mpcs_fomreq_i_7;
wire        mpcs_fomreq_i_6;
wire        mpcs_fomreq_i_5;
wire        mpcs_fomreq_i_4;
wire        mpcs_fomreq_i_3;
wire        mpcs_fomreq_i_2;
wire        mpcs_fomreq_i_1;
wire        mpcs_fomreq_i_0;
   
wire        mpcs_fomack_o_7;
wire        mpcs_fomack_o_6;
wire        mpcs_fomack_o_5;
wire        mpcs_fomack_o_4;
wire        mpcs_fomack_o_3;
wire        mpcs_fomack_o_2;
wire        mpcs_fomack_o_1;
wire        mpcs_fomack_o_0;

wire [7:0]  mpcs_fomrslt_o_7;
wire [7:0]  mpcs_fomrslt_o_6;
wire [7:0]  mpcs_fomrslt_o_5;
wire [7:0]  mpcs_fomrslt_o_4;
wire [7:0]  mpcs_fomrslt_o_3;
wire [7:0]  mpcs_fomrslt_o_2;
wire [7:0]  mpcs_fomrslt_o_1;
wire [7:0]  mpcs_fomrslt_o_0;

wire [1:0]  mpcs_rate_i_7;
wire [1:0]  mpcs_rate_i_6;
wire [1:0]  mpcs_rate_i_5;
wire [1:0]  mpcs_rate_i_4;
wire [1:0]  mpcs_rate_i_3;
wire [1:0]  mpcs_rate_i_2;
wire [1:0]  mpcs_rate_i_1;
wire [1:0]  mpcs_rate_i_0;

wire [1:0]  mpcs_speed_o_7;
wire [1:0]  mpcs_speed_o_6;
wire [1:0]  mpcs_speed_o_5;
wire [1:0]  mpcs_speed_o_4;
wire [1:0]  mpcs_speed_o_3;
wire [1:0]  mpcs_speed_o_2;
wire [1:0]  mpcs_speed_o_1;
wire [1:0]  mpcs_speed_o_0;

wire        mpcs_txval_i_7;
wire        mpcs_txval_i_6;
wire        mpcs_txval_i_5;
wire        mpcs_txval_i_4;
wire        mpcs_txval_i_3;
wire        mpcs_txval_i_2;
wire        mpcs_txval_i_1;
wire        mpcs_txval_i_0;
         
wire        mpcs_rxoob_i_7;
wire        mpcs_rxoob_i_6;
wire        mpcs_rxoob_i_5;
wire        mpcs_rxoob_i_4;
wire        mpcs_rxoob_i_3;
wire        mpcs_rxoob_i_2;
wire        mpcs_rxoob_i_1;
wire        mpcs_rxoob_i_0;
  
wire        mpcs_txdeemp_i_7;
wire        mpcs_txdeemp_i_6;
wire        mpcs_txdeemp_i_5;
wire        mpcs_txdeemp_i_4;
wire        mpcs_txdeemp_i_3;
wire        mpcs_txdeemp_i_2;
wire        mpcs_txdeemp_i_1;
wire        mpcs_txdeemp_i_0;
   
wire [1:0]  mpcs_pwrst_o_7;
wire [1:0]  mpcs_pwrst_o_6;
wire [1:0]  mpcs_pwrst_o_5;
wire [1:0]  mpcs_pwrst_o_4;
wire [1:0]  mpcs_pwrst_o_3;
wire [1:0]  mpcs_pwrst_o_2;
wire [1:0]  mpcs_pwrst_o_1;
wire [1:0]  mpcs_pwrst_o_0;

wire        mpcs_skipbit_i_7;
wire        mpcs_skipbit_i_6;
wire        mpcs_skipbit_i_5;
wire        mpcs_skipbit_i_4;
wire        mpcs_skipbit_i_3;
wire        mpcs_skipbit_i_2;
wire        mpcs_skipbit_i_1;
wire        mpcs_skipbit_i_0;

wire        mpcs_ready_o_7;
wire        mpcs_ready_o_6;
wire        mpcs_ready_o_5;
wire        mpcs_ready_o_4;
wire        mpcs_ready_o_3;
wire        mpcs_ready_o_2;
wire        mpcs_ready_o_1;
wire        mpcs_ready_o_0; //Ready - Calibration Done
    
wire        mpcs_phyrdy_o_7;
wire        mpcs_phyrdy_o_6;
wire        mpcs_phyrdy_o_5;
wire        mpcs_phyrdy_o_4;
wire        mpcs_phyrdy_o_3;
wire        mpcs_phyrdy_o_2;
wire        mpcs_phyrdy_o_1;
wire        mpcs_phyrdy_o_0; //PHY Ready - ready to transmit

wire        mpcs_rxval_o_7;
wire        mpcs_rxval_o_6;
wire        mpcs_rxval_o_5;
wire        mpcs_rxval_o_4;
wire        mpcs_rxval_o_3;
wire        mpcs_rxval_o_2;
wire        mpcs_rxval_o_1;
wire        mpcs_rxval_o_0;
    
//EPCS Interface

wire        epcs_rx_usr_clk_i_7;
wire        epcs_rx_usr_clk_i_6;
wire        epcs_rx_usr_clk_i_5;
wire        epcs_rx_usr_clk_i_4;
wire        epcs_rx_usr_clk_i_3;
wire        epcs_rx_usr_clk_i_2;
wire        epcs_rx_usr_clk_i_1;
wire        epcs_rx_usr_clk_i_0;
             
wire        epcs_tx_usr_clk_i_7;
wire        epcs_tx_usr_clk_i_6;
wire        epcs_tx_usr_clk_i_5;
wire        epcs_tx_usr_clk_i_4;
wire        epcs_tx_usr_clk_i_3;
wire        epcs_tx_usr_clk_i_2;
wire        epcs_tx_usr_clk_i_1;
wire        epcs_tx_usr_clk_i_0;
             
wire        epcs_tx_pcs_rstn_i_7;
wire        epcs_tx_pcs_rstn_i_6;
wire        epcs_tx_pcs_rstn_i_5;
wire        epcs_tx_pcs_rstn_i_4;
wire        epcs_tx_pcs_rstn_i_3;
wire        epcs_tx_pcs_rstn_i_2;
wire        epcs_tx_pcs_rstn_i_1;
wire        epcs_tx_pcs_rstn_i_0;
                 
wire        epcs_rx_pcs_rstn_i_7;
wire        epcs_rx_pcs_rstn_i_6;
wire        epcs_rx_pcs_rstn_i_5;
wire        epcs_rx_pcs_rstn_i_4;
wire        epcs_rx_pcs_rstn_i_3;
wire        epcs_rx_pcs_rstn_i_2;
wire        epcs_rx_pcs_rstn_i_1;
wire        epcs_rx_pcs_rstn_i_0;
                              
wire        epcs_rstn_i_7;
wire        epcs_rstn_i_6;
wire        epcs_rstn_i_5;
wire        epcs_rstn_i_4;
wire        epcs_rstn_i_3;
wire        epcs_rstn_i_2;
wire        epcs_rstn_i_1;
wire        epcs_rstn_i_0;

wire        epcs_rxclk_o_7;
wire        epcs_rxclk_o_6;
wire        epcs_rxclk_o_5;
wire        epcs_rxclk_o_4;
wire        epcs_rxclk_o_3;
wire        epcs_rxclk_o_2;
wire        epcs_rxclk_o_1;
wire        epcs_rxclk_o_0;
             
wire        epcs_txclk_o_7;
wire        epcs_txclk_o_6;
wire        epcs_txclk_o_5;
wire        epcs_txclk_o_4;
wire        epcs_txclk_o_3;
wire        epcs_txclk_o_2;
wire        epcs_txclk_o_1;
wire        epcs_txclk_o_0;

wire [79:0] epcs_txdata_i_7; 
wire [79:0] epcs_txdata_i_6; 
wire [79:0] epcs_txdata_i_5; 
wire [79:0] epcs_txdata_i_4; 
wire [79:0] epcs_txdata_i_3; 
wire [79:0] epcs_txdata_i_2; 
wire [79:0] epcs_txdata_i_1; 
wire [79:0] epcs_txdata_i_0; 
    
wire [39:0] epcs_rxdata_o_7;
wire [39:0] epcs_rxdata_o_6;
wire [39:0] epcs_rxdata_o_5;
wire [39:0] epcs_rxdata_o_4;
wire [39:0] epcs_rxdata_o_3;
wire [39:0] epcs_rxdata_o_2;
wire [39:0] epcs_rxdata_o_1;
wire [39:0] epcs_rxdata_o_0;


wire [3:0]  epcs_tx_fifo_st_o_7;
wire [3:0]  epcs_tx_fifo_st_o_6;
wire [3:0]  epcs_tx_fifo_st_o_5;
wire [3:0]  epcs_tx_fifo_st_o_4;
wire [3:0]  epcs_tx_fifo_st_o_3;
wire [3:0]  epcs_tx_fifo_st_o_2;
wire [3:0]  epcs_tx_fifo_st_o_1;
wire [3:0]  epcs_tx_fifo_st_o_0;

wire [3:0]  epcs_rx_fifo_st_o_7;
wire [3:0]  epcs_rx_fifo_st_o_6;
wire [3:0]  epcs_rx_fifo_st_o_5;
wire [3:0]  epcs_rx_fifo_st_o_4;
wire [3:0]  epcs_rx_fifo_st_o_3;
wire [3:0]  epcs_rx_fifo_st_o_2;
wire [3:0]  epcs_rx_fifo_st_o_1;
wire [3:0]  epcs_rx_fifo_st_o_0;
                 
wire        epcs_clkin_i_7;
wire        epcs_clkin_i_6;
wire        epcs_clkin_i_5;
wire        epcs_clkin_i_4;
wire        epcs_clkin_i_3;
wire        epcs_clkin_i_2;
wire        epcs_clkin_i_1;
wire        epcs_clkin_i_0;
             
wire [1:0]  epcs_pwrdn_i_7;
wire [1:0]  epcs_pwrdn_i_6;
wire [1:0]  epcs_pwrdn_i_5;
wire [1:0]  epcs_pwrdn_i_4;
wire [1:0]  epcs_pwrdn_i_3;
wire [1:0]  epcs_pwrdn_i_2;
wire [1:0]  epcs_pwrdn_i_1;
wire [1:0]  epcs_pwrdn_i_0;
             
wire        epcs_txhiz_i_7;
wire        epcs_txhiz_i_6;
wire        epcs_txhiz_i_5;
wire        epcs_txhiz_i_4;
wire        epcs_txhiz_i_3;
wire        epcs_txhiz_i_2;
wire        epcs_txhiz_i_1;
wire        epcs_txhiz_i_0;
             
wire        epcs_rxidle_o_7;
wire        epcs_rxidle_o_6;
wire        epcs_rxidle_o_5;
wire        epcs_rxidle_o_4;
wire        epcs_rxidle_o_3;
wire        epcs_rxidle_o_2;
wire        epcs_rxidle_o_1;
wire        epcs_rxidle_o_0;
                 
wire        epcs_rxerr_i_7;
wire        epcs_rxerr_i_6;
wire        epcs_rxerr_i_5;
wire        epcs_rxerr_i_4;
wire        epcs_rxerr_i_3;
wire        epcs_rxerr_i_2;
wire        epcs_rxerr_i_1;
wire        epcs_rxerr_i_0;
             
wire        epcs_fomreq_i_7;
wire        epcs_fomreq_i_6;
wire        epcs_fomreq_i_5;
wire        epcs_fomreq_i_4;
wire        epcs_fomreq_i_3;
wire        epcs_fomreq_i_2;
wire        epcs_fomreq_i_1;
wire        epcs_fomreq_i_0;
             
wire        epcs_fomack_o_7;
wire        epcs_fomack_o_6;
wire        epcs_fomack_o_5;
wire        epcs_fomack_o_4;
wire        epcs_fomack_o_3;
wire        epcs_fomack_o_2;
wire        epcs_fomack_o_1;
wire        epcs_fomack_o_0;
                 
wire [7:0]  epcs_fomrslt_o_7;
wire [7:0]  epcs_fomrslt_o_6;
wire [7:0]  epcs_fomrslt_o_5;
wire [7:0]  epcs_fomrslt_o_4;
wire [7:0]  epcs_fomrslt_o_3;
wire [7:0]  epcs_fomrslt_o_2;
wire [7:0]  epcs_fomrslt_o_1;
wire [7:0]  epcs_fomrslt_o_0;
                 
wire [1:0]  epcs_rate_i_7;
wire [1:0]  epcs_rate_i_6;
wire [1:0]  epcs_rate_i_5;
wire [1:0]  epcs_rate_i_4;
wire [1:0]  epcs_rate_i_3;
wire [1:0]  epcs_rate_i_2;
wire [1:0]  epcs_rate_i_1;
wire [1:0]  epcs_rate_i_0;
             
wire [1:0]  epcs_speed_o_7;
wire [1:0]  epcs_speed_o_6;
wire [1:0]  epcs_speed_o_5;
wire [1:0]  epcs_speed_o_4;
wire [1:0]  epcs_speed_o_3;
wire [1:0]  epcs_speed_o_2;
wire [1:0]  epcs_speed_o_1;
wire [1:0]  epcs_speed_o_0;
                 
wire        epcs_txval_i_7;
wire        epcs_txval_i_6;
wire        epcs_txval_i_5;
wire        epcs_txval_i_4;
wire        epcs_txval_i_3;
wire        epcs_txval_i_2;
wire        epcs_txval_i_1;
wire        epcs_txval_i_0;
                                               
wire        epcs_rxoob_i_7;
wire        epcs_rxoob_i_6;
wire        epcs_rxoob_i_5;
wire        epcs_rxoob_i_4;
wire        epcs_rxoob_i_3;
wire        epcs_rxoob_i_2;
wire        epcs_rxoob_i_1;
wire        epcs_rxoob_i_0;
             
wire        epcs_txdeemp_i_7;
wire        epcs_txdeemp_i_6;
wire        epcs_txdeemp_i_5;
wire        epcs_txdeemp_i_4;
wire        epcs_txdeemp_i_3;
wire        epcs_txdeemp_i_2;
wire        epcs_txdeemp_i_1;
wire        epcs_txdeemp_i_0;
             
wire [1:0]  epcs_pwrst_o_7;
wire [1:0]  epcs_pwrst_o_6;
wire [1:0]  epcs_pwrst_o_5;
wire [1:0]  epcs_pwrst_o_4;
wire [1:0]  epcs_pwrst_o_3;
wire [1:0]  epcs_pwrst_o_2;
wire [1:0]  epcs_pwrst_o_1;
wire [1:0]  epcs_pwrst_o_0;
                 
wire        epcs_skipbit_i_7;
wire        epcs_skipbit_i_6;
wire        epcs_skipbit_i_5;
wire        epcs_skipbit_i_4;
wire        epcs_skipbit_i_3;
wire        epcs_skipbit_i_2;
wire        epcs_skipbit_i_1;
wire        epcs_skipbit_i_0;

wire        epcs_ready_o_7;
wire        epcs_ready_o_6;
wire        epcs_ready_o_5;
wire        epcs_ready_o_4;
wire        epcs_ready_o_3;
wire        epcs_ready_o_2;
wire        epcs_ready_o_1;
wire        epcs_ready_o_0;

wire        epcs_phyrdy_o_7;
wire        epcs_phyrdy_o_6;
wire        epcs_phyrdy_o_5;
wire        epcs_phyrdy_o_4;
wire        epcs_phyrdy_o_3;
wire        epcs_phyrdy_o_2;
wire        epcs_phyrdy_o_1;
wire        epcs_phyrdy_o_0;
   
wire        epcs_rxval_o_7;
wire        epcs_rxval_o_6;
wire        epcs_rxval_o_5;
wire        epcs_rxval_o_4;
wire        epcs_rxval_o_3;
wire        epcs_rxval_o_2;
wire        epcs_rxval_o_1;
wire        epcs_rxval_o_0;

//PIPE Interface

wire        pipe_aux_clk_i_3;
wire        pipe_aux_clk_i_2;
wire        pipe_aux_clk_i_1;
wire        pipe_aux_clk_i_0;
             
wire        pipe_rstn_i_3;
wire        pipe_rstn_i_2;
wire        pipe_rstn_i_1;
wire        pipe_rstn_i_0;
             
wire        pipe_pclkout_o_3; 
wire        pipe_pclkout_o_2; 
wire        pipe_pclkout_o_1; 
wire        pipe_pclkout_o_0; 
    
wire        pipe_pclkin_i_3;
wire        pipe_pclkin_i_2;
wire        pipe_pclkin_i_1;
wire        pipe_pclkin_i_0;
             
wire [1:0]  pipe_rate_i_3;  
wire [1:0]  pipe_rate_i_2;  
wire [1:0]  pipe_rate_i_1;    
wire [1:0]  pipe_rate_i_0;    
             
wire [1:0]  pipe_powerdown_i_3; 
wire [1:0]  pipe_powerdown_i_2; 
wire [1:0]  pipe_powerdown_i_1; 
wire [1:0]  pipe_powerdown_i_0; 

wire [1:0]  pipe_width_2g5_o_3; 
wire [1:0]  pipe_width_2g5_o_2; 
wire [1:0]  pipe_width_2g5_o_1; 
wire [1:0]  pipe_width_2g5_o_0; 
             
wire [1:0]  pipe_width_5g0_o_3; 
wire [1:0]  pipe_width_5g0_o_2; 
wire [1:0]  pipe_width_5g0_o_1; 
wire [1:0]  pipe_width_5g0_o_0; 
            
wire [1:0]  pipe_width_8g0_o_3; 
wire [1:0]  pipe_width_8g0_o_2; 
wire [1:0]  pipe_width_8g0_o_1; 
wire [1:0]  pipe_width_8g0_o_0; 
                    
wire        pipe_txdetectrx_i_3; 
wire        pipe_txdetectrx_i_2; 
wire        pipe_txdetectrx_i_1;  
wire        pipe_txdetectrx_i_0;  
             
wire [7:0]  pipe_rxeq_fom_o_3;
wire [7:0]  pipe_rxeq_fom_o_2;
wire [7:0]  pipe_rxeq_fom_o_1;
wire [7:0]  pipe_rxeq_fom_o_0;

wire [5:0]  pipe_rx_eq_eval_feedback_dir_o_3;
wire [5:0]  pipe_rx_eq_eval_feedback_dir_o_2;
wire [5:0]  pipe_rx_eq_eval_feedback_dir_o_1;
wire [5:0]  pipe_rx_eq_eval_feedback_dir_o_0;
    
wire [17:0] pipe_txdeemp_i_3; 
wire [17:0] pipe_txdeemp_i_2; 
wire [17:0] pipe_txdeemp_i_1; 
wire [17:0] pipe_txdeemp_i_0; 

wire [2:0]  pipe_txmargin_i_3; 
wire [2:0]  pipe_txmargin_i_2; 
wire [2:0]  pipe_txmargin_i_1;  
wire [2:0]  pipe_txmargin_i_0;  
             
wire        pipe_tx_swing_i_3; 
wire        pipe_tx_swing_i_2; 
wire        pipe_tx_swing_i_1; 
wire        pipe_tx_swing_i_0; 
              
wire        pipe_tx_data_enable_o_3; 
wire        pipe_tx_data_enable_o_2; 
wire        pipe_tx_data_enable_o_1; 
wire        pipe_tx_data_enable_o_0; 

wire [31:0] pipe_txdata_i_3;
wire [31:0] pipe_txdata_i_2;
wire [31:0] pipe_txdata_i_1;
wire [31:0] pipe_txdata_i_0;
    
wire [3:0]  pipe_txdatak_i_3; 
wire [3:0]  pipe_txdatak_i_2; 
wire [3:0]  pipe_txdatak_i_1; 
wire [3:0]  pipe_txdatak_i_0; 
             
wire        pipe_txdatavalid_i_3; 
wire        pipe_txdatavalid_i_2; 
wire        pipe_txdatavalid_i_1; 
wire        pipe_txdatavalid_i_0; 
             
wire        pipe_tx_start_block_i_3; 
wire        pipe_tx_start_block_i_2; 
wire        pipe_tx_start_block_i_1; 
wire        pipe_tx_start_block_i_0; 

wire [1:0]  pipe_txsyncheader_i_3; 
wire [1:0]  pipe_txsyncheader_i_2; 
wire [1:0]  pipe_txsyncheader_i_1; 
wire [1:0]  pipe_txsyncheader_i_0; 
             
wire        pipe_tx_elec_idle_i_3; 
wire        pipe_tx_elec_idle_i_2; 
wire        pipe_tx_elec_idle_i_1; 
wire        pipe_tx_elec_idle_i_0; 
             
wire        pipe_txcompl_i_3; 
wire        pipe_txcompl_i_2; 
wire        pipe_txcompl_i_1; 
wire        pipe_txcompl_i_0; 

wire [31:0] pipe_rx_data_o_3; 
wire [31:0] pipe_rx_data_o_2; 
wire [31:0] pipe_rx_data_o_1; 
wire [31:0] pipe_rx_data_o_0; 
            
wire        pipe_rx_data_en_o_3; 
wire        pipe_rx_data_en_o_2; 
wire        pipe_rx_data_en_o_1; 
wire        pipe_rx_data_en_o_0; 
            
wire [3:0]  pipe_rxdatak_o_3; 
wire [3:0]  pipe_rxdatak_o_2; 
wire [3:0]  pipe_rxdatak_o_1; 
wire [3:0]  pipe_rxdatak_o_0; 
                
wire        pipe_rxdatavalid_o_3; 
wire        pipe_rxdatavalid_o_2; 
wire        pipe_rxdatavalid_o_1; 
wire        pipe_rxdatavalid_o_0; 
            
wire        pipe_rx_start_block_o_3; 
wire        pipe_rx_start_block_o_2; 
wire        pipe_rx_start_block_o_1; 
wire        pipe_rx_start_block_o_0; 
             
wire [1:0]  pipe_rxsyncheader_o_3; 
wire [1:0]  pipe_rxsyncheader_o_2; 
wire [1:0]  pipe_rxsyncheader_o_1; 
wire [1:0]  pipe_rxsyncheader_o_0; 
            
wire        pipe_rx_elec_idle_o_3; 
wire        pipe_rx_elec_idle_o_2; 
wire        pipe_rx_elec_idle_o_1; 
wire        pipe_rx_elec_idle_o_0; 
                                     
wire        pipe_rx_polarity_i_3;
wire        pipe_rx_polarity_i_2;
wire        pipe_rx_polarity_i_1;
wire        pipe_rx_polarity_i_0;

wire [2:0]  pipe_rxstatus_o_3; 
wire [2:0]  pipe_rxstatus_o_2; 
wire [2:0]  pipe_rxstatus_o_1; 
wire [2:0]  pipe_rxstatus_o_0; 
                 
wire        pipe_blockalignctrl_i_3; 
wire        pipe_blockalignctrl_i_2; 
wire        pipe_blockalignctrl_i_1;  
wire        pipe_blockalignctrl_i_0;  
             
wire [5:0]  pipe_local_fs_o_3; 
wire [5:0]  pipe_local_fs_o_2; 
wire [5:0]  pipe_local_fs_o_1; 
wire [5:0]  pipe_local_fs_o_0; 
              
wire [5:0]  pipe_local_lf_o_3; 
wire [5:0]  pipe_local_lf_o_2; 
wire [5:0]  pipe_local_lf_o_1; 
wire [5:0]  pipe_local_lf_o_0; 
    
wire        pipe_local_get_preset_coef_i_3; 
wire        pipe_local_get_preset_coef_i_2; 
wire        pipe_local_get_preset_coef_i_1; 
wire        pipe_local_get_preset_coef_i_0; 
             
wire [3:0]  pipe_local_get_preset_index_i_3; 
wire [3:0]  pipe_local_get_preset_index_i_2; 
wire [3:0]  pipe_local_get_preset_index_i_1; 
wire [3:0]  pipe_local_get_preset_index_i_0; 
    
wire        pipe_local_get_tx_coef_valid_o_3; 
wire        pipe_local_get_tx_coef_valid_o_2; 
wire        pipe_local_get_tx_coef_valid_o_1; 
wire        pipe_local_get_tx_coef_valid_o_0; 
             
wire [17:0] pipe_local_get_tx_preset_coef_o_3; 
wire [17:0] pipe_local_get_tx_preset_coef_o_2; 
wire [17:0] pipe_local_get_tx_preset_coef_o_1; 
wire [17:0] pipe_local_get_tx_preset_coef_o_0; 

wire        pipe_rxeqeval_i_3; 
wire        pipe_rxeqeval_i_2; 
wire        pipe_rxeqeval_i_1;  
wire        pipe_rxeqeval_i_0;  
             
wire        pipe_invalidrequest_i_3; 
wire        pipe_invalidrequest_i_2; 
wire        pipe_invalidrequest_i_1; 
wire        pipe_invalidrequest_i_0; 
             
wire        pipe_rxpresethint_en_i_3;
wire        pipe_rxpresethint_en_i_2;
wire        pipe_rxpresethint_en_i_1;
wire        pipe_rxpresethint_en_i_0;

wire [2:0]  pipe_rxpresethint_i_3; 
wire [2:0]  pipe_rxpresethint_i_2; 
wire [2:0]  pipe_rxpresethint_i_1; 
wire [2:0]  pipe_rxpresethint_i_0; 

wire [5:0]  pipe_remote_lf_i_3;
wire [5:0]  pipe_remote_lf_i_2;
wire [5:0]  pipe_remote_lf_i_1;
wire [5:0]  pipe_remote_lf_i_0;

wire [5:0]  pipe_remote_fs_i_3;
wire [5:0]  pipe_remote_fs_i_2;
wire [5:0]  pipe_remote_fs_i_1;
wire [5:0]  pipe_remote_fs_i_0;

wire [17:0] pipe_remote_eq_rx_deemph_i_3;
wire [17:0] pipe_remote_eq_rx_deemph_i_2;
wire [17:0] pipe_remote_eq_rx_deemph_i_1;
wire [17:0] pipe_remote_eq_rx_deemph_i_0;

wire [3:0]  pipe_remote_eq_rx_preset_i_3;
wire [3:0]  pipe_remote_eq_rx_preset_i_2;
wire [3:0]  pipe_remote_eq_rx_preset_i_1;
wire [3:0]  pipe_remote_eq_rx_preset_i_0;

wire        pipe_tx_clkreq_n_i_3;
wire        pipe_tx_clkreq_n_i_2;
wire        pipe_tx_clkreq_n_i_1;
wire        pipe_tx_clkreq_n_i_0;
    
wire        pipe_rx_pclkreq_n_o_3;
wire        pipe_rx_pclkreq_n_o_2;
wire        pipe_rx_pclkreq_n_o_1;
wire        pipe_rx_pclkreq_n_o_0;
    
wire        pipe_l1pmss_en_i_3;
wire        pipe_l1pmss_en_i_2;
wire        pipe_l1pmss_en_i_1;
wire        pipe_l1pmss_en_i_0;

wire        pipe_rxelecidle_disable_i_3; 
wire        pipe_rxelecidle_disable_i_2; 
wire        pipe_rxelecidle_disable_i_1; 
wire        pipe_rxelecidle_disable_i_0; 
             
wire        pipe_txcommonmode_disable_i_3; 
wire        pipe_txcommonmode_disable_i_2; 
wire        pipe_txcommonmode_disable_i_1;  
wire        pipe_txcommonmode_disable_i_0;  
        
wire        pipe_phy_status_o_3; 
wire        pipe_phy_status_o_2; 
wire        pipe_phy_status_o_1; 
wire        pipe_phy_status_o_0; 

wire        pipe_rxval_o_3; 
wire        pipe_rxval_o_2; 
wire        pipe_rxval_o_1; 
wire        pipe_rxval_o_0; 
 
//JTAG Ports
 
wire        acjtag_mode_i;  
            
wire        acjtag_enable_i_7;
wire        acjtag_enable_i_6;
wire        acjtag_enable_i_5;
wire        acjtag_enable_i_4;
wire        acjtag_enable_i_3;
wire        acjtag_enable_i_2;
wire        acjtag_enable_i_1;
wire        acjtag_enable_i_0;
            
wire        acjtag_acmode_i_7;
wire        acjtag_acmode_i_6;
wire        acjtag_acmode_i_5;
wire        acjtag_acmode_i_4;
wire        acjtag_acmode_i_3;
wire        acjtag_acmode_i_2;
wire        acjtag_acmode_i_1;
wire        acjtag_acmode_i_0;
            
wire        acjtag_drive1_i_7;
wire        acjtag_drive1_i_6;
wire        acjtag_drive1_i_5;
wire        acjtag_drive1_i_4;
wire        acjtag_drive1_i_3;
wire        acjtag_drive1_i_2;
wire        acjtag_drive1_i_1;
wire        acjtag_drive1_i_0;
            
wire        acjtag_highz_i_7; 
wire        acjtag_highz_i_6; 
wire        acjtag_highz_i_5; 
wire        acjtag_highz_i_4; 
wire        acjtag_highz_i_3; 
wire        acjtag_highz_i_2; 
wire        acjtag_highz_i_1; 
wire        acjtag_highz_i_0; 
            
wire        acjtagpout_o_7;   
wire        acjtagpout_o_6;   
wire        acjtagpout_o_5;   
wire        acjtagpout_o_4;   
wire        acjtagpout_o_3;   
wire        acjtagpout_o_2;   
wire        acjtagpout_o_1;   
wire        acjtagpout_o_0;   
            
wire        acjtagnout_o_7;   
wire        acjtagnout_o_6;   
wire        acjtagnout_o_5;   
wire        acjtagnout_o_4;   
wire        acjtagnout_o_3;   
wire        acjtagnout_o_2;   
wire        acjtagnout_o_1;   
wire        acjtagnout_o_0; 

//Lane Alignment ports

wire [7:0] tx_lalign_out_up_o      ;
wire       tx_lalign_clk_out_o     ;
wire       rx_lalign_clk_out_o     ;
wire [7:0] tx_lalign_out_down_o    ;

//Quad Alignment ports

wire       tx_lalign_clk_in_i ;
wire       rx_lalign_clk_in_i ;
wire [7:0] tx_lalign_in_up_i  ;
wire [7:0] tx_lalign_in_down_i;

//--------------------------------------------------------------------------
// Assign Statements
//--------------------------------------------------------------------------

//Reference Clocks
//For multi-quad configurations, it is not recommended to use 2 separate refclk for Q0 and Q1.
//                               It is recommended to use refclk from PCSREFMUX instead by enabling use_refmux_i 
//                               and set the desired diffioclksel_i/clksel_i, see options below.

assign  use_refmux_i      = (NUM_LANES > 4) ? 1'b1  : 1'b0;  //1'b1  -- enable PCSREFMUX

assign  diffioclksel_i    = 1'b0;                            //1'b0  -- use sd_ext_0_refclk_i
                                                             //1'b1  -- use sd_ext_1_refclk_i
assign  clksel_i          = (NUM_LANES > 4) ? 2'b11 : 2'b00; //2'b00 -- use pll_0_refclk_i
                                                             //2'b01 -- use pll_1_refclk_i
                                                             //2'b10 -- use output from DIFFCLKIO_CORE
                                                             //2'b11 -- sd_pll_refclk_i 
                                  
assign  sd_ext_0_refclk_i = 1'b0;    //Other refclks
assign  sd_ext_1_refclk_i = 1'b0;    //Other refclks
assign  pll_0_refclk_i    = 1'b0;    //Other refclks - Left PLL (not recommended to use, see IPUG Section 2.5.4)
assign  pll_1_refclk_i    = 1'b0;    //Other refclks - Right PLL (not recommended to use, see IPUG Section 2.5.4)  
assign  sd_pll_refclk_i   = ref_clk; //Other refclks

assign  sdq_refclkp_q0_i = ref_clk;      //pad, refclk+, Q0
assign  sdq_refclkn_q0_i = ~ref_clk;     //pad, refclk-, Q0
assign  sdq_refclkp_q1_i = ref_clk;      //pad, refclk+, Q1
assign  sdq_refclkn_q1_i = ~ref_clk;     //pad, refclk-, Q1

//64b66b
assign  tx_fifo_wr = 1'b1; //see UG for the values
assign  tx_frcpkt  = 1'b0; //see UG for the values
assign  tx_control = 8'b0; //see UG for the values

//8b10b
assign  tx_frcdata = 4'b1111; //see UG for the values
assign  tx_dispval = 4'b1111; //see UG for the values
assign  tx_frcdisp = 4'b1111; //see UG for the values

assign  acjtag_mode_i = 1'b0;  
        
assign  acjtag_enable_i_7 = 1'b0;
assign  acjtag_enable_i_6 = 1'b0;
assign  acjtag_enable_i_5 = 1'b0;
assign  acjtag_enable_i_4 = 1'b0;
assign  acjtag_enable_i_3 = 1'b0;
assign  acjtag_enable_i_2 = 1'b0;
assign  acjtag_enable_i_1 = 1'b0;
assign  acjtag_enable_i_0 = 1'b0;
        
assign  acjtag_acmode_i_7 = 1'b0;
assign  acjtag_acmode_i_6 = 1'b0;
assign  acjtag_acmode_i_5 = 1'b0;
assign  acjtag_acmode_i_4 = 1'b0;
assign  acjtag_acmode_i_3 = 1'b0;
assign  acjtag_acmode_i_2 = 1'b0;
assign  acjtag_acmode_i_1 = 1'b0;
assign  acjtag_acmode_i_0 = 1'b0;
        
assign  acjtag_drive1_i_7 = 1'b0;
assign  acjtag_drive1_i_6 = 1'b0;
assign  acjtag_drive1_i_5 = 1'b0;
assign  acjtag_drive1_i_4 = 1'b0;
assign  acjtag_drive1_i_3 = 1'b0;
assign  acjtag_drive1_i_2 = 1'b0;
assign  acjtag_drive1_i_1 = 1'b0;
assign  acjtag_drive1_i_0 = 1'b0;

assign  acjtag_highz_i_7 = 1'b0; 
assign  acjtag_highz_i_6 = 1'b0; 
assign  acjtag_highz_i_5 = 1'b0; 
assign  acjtag_highz_i_4 = 1'b0; 
assign  acjtag_highz_i_3 = 1'b0; 
assign  acjtag_highz_i_2 = 1'b0; 
assign  acjtag_highz_i_1 = 1'b0; 
assign  acjtag_highz_i_0 = 1'b0; 

assign  tx_lalign_clk_in_i  = tx_lalign_clk_out_o ;
assign  rx_lalign_clk_in_i  = rx_lalign_clk_out_o ;
assign  tx_lalign_in_up_i   = tx_lalign_out_up_o ;
assign  tx_lalign_in_down_i = tx_lalign_out_down_o ;
        
assign  ready_o = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES == 1 ) ?  (mpcs_ready_w[0]  ):
                  ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES == 2 ) ? &(mpcs_ready_w[1:0]):
                  ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES == 4 ) ? &(mpcs_ready_w[3:0]):
                  ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES == 6 ) ? &(mpcs_ready_w[5:0]):
                  ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES == 8 ) ? &(mpcs_ready_w[7:0]):
                  ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES == 1 ) ?  (epcs_ready_w[0]  ):
                  ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES == 2 ) ? &(epcs_ready_w[1:0]):
                  ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES == 4 ) ? &(epcs_ready_w[3:0]):
                  ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES == 6 ) ? &(epcs_ready_w[5:0]):
                  ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES == 8 ) ? &(epcs_ready_w[7:0]):
                  1'b1;  

assign  phyrdy_o = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES == 1 ) ?  (mpcs_phyrdy_w[0]  ):
                   ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES == 2 ) ? &(mpcs_phyrdy_w[1:0]):
                   ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES == 4 ) ? &(mpcs_phyrdy_w[3:0]):
                   ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES == 6 ) ? &(mpcs_phyrdy_w[5:0]):
                   ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES == 8 ) ? &(mpcs_phyrdy_w[7:0]):
                   ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES == 1 ) ?  (epcs_phyrdy_w[0]  ):
                   ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES == 2 ) ? &(epcs_phyrdy_w[1:0]):
                   ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES == 4 ) ? &(epcs_phyrdy_w[3:0]):
                   ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES == 6 ) ? &(epcs_phyrdy_w[5:0]):
                   ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES == 8 ) ? &(epcs_phyrdy_w[7:0]):
                   |(pipe_phy_status_w); 
                   
assign  lmmi_clk_i_7 = lmmi_clk_i_0;
assign  lmmi_clk_i_6 = lmmi_clk_i_0;
assign  lmmi_clk_i_5 = lmmi_clk_i_0;
assign  lmmi_clk_i_4 = lmmi_clk_i_0;
assign  lmmi_clk_i_3 = lmmi_clk_i_0;
assign  lmmi_clk_i_2 = lmmi_clk_i_0;
assign  lmmi_clk_i_1 = lmmi_clk_i_0;

assign  lmmi_resetn_i_7 = lmmi_resetn_i_0;
assign  lmmi_resetn_i_6 = lmmi_resetn_i_0;
assign  lmmi_resetn_i_5 = lmmi_resetn_i_0;
assign  lmmi_resetn_i_4 = lmmi_resetn_i_0;
assign  lmmi_resetn_i_3 = lmmi_resetn_i_0;
assign  lmmi_resetn_i_2 = lmmi_resetn_i_0;
assign  lmmi_resetn_i_1 = lmmi_resetn_i_0;

assign  lmmi_request_i_7 = lmmi_request_i_0;
assign  lmmi_request_i_6 = lmmi_request_i_0;
assign  lmmi_request_i_5 = lmmi_request_i_0;
assign  lmmi_request_i_4 = lmmi_request_i_0;
assign  lmmi_request_i_3 = lmmi_request_i_0;
assign  lmmi_request_i_2 = lmmi_request_i_0;
assign  lmmi_request_i_1 = lmmi_request_i_0;

assign  lmmi_wr_rdn_i_7 = lmmi_wr_rdn_i_0;
assign  lmmi_wr_rdn_i_6 = lmmi_wr_rdn_i_0;
assign  lmmi_wr_rdn_i_5 = lmmi_wr_rdn_i_0;
assign  lmmi_wr_rdn_i_4 = lmmi_wr_rdn_i_0;
assign  lmmi_wr_rdn_i_3 = lmmi_wr_rdn_i_0;
assign  lmmi_wr_rdn_i_2 = lmmi_wr_rdn_i_0;
assign  lmmi_wr_rdn_i_1 = lmmi_wr_rdn_i_0;

assign  lmmi_offset_i_7 = lmmi_offset_i_0;
assign  lmmi_offset_i_6 = lmmi_offset_i_0;
assign  lmmi_offset_i_5 = lmmi_offset_i_0;
assign  lmmi_offset_i_4 = lmmi_offset_i_0;
assign  lmmi_offset_i_3 = lmmi_offset_i_0;
assign  lmmi_offset_i_2 = lmmi_offset_i_0;
assign  lmmi_offset_i_1 = lmmi_offset_i_0;

assign  lmmi_wdata_i_7 = lmmi_wdata_i_0;
assign  lmmi_wdata_i_6 = lmmi_wdata_i_0;
assign  lmmi_wdata_i_5 = lmmi_wdata_i_0;
assign  lmmi_wdata_i_4 = lmmi_wdata_i_0;
assign  lmmi_wdata_i_3 = lmmi_wdata_i_0;
assign  lmmi_wdata_i_2 = lmmi_wdata_i_0;
assign  lmmi_wdata_i_1 = lmmi_wdata_i_0;

assign  sd7rxp_i = sd7txp_o;    // pad, RX+, ext serial loopback
assign  sd6rxp_i = sd6txp_o;    // pad, RX+, ext serial loopback
assign  sd5rxp_i = sd5txp_o;    // pad, RX+, ext serial loopback
assign  sd4rxp_i = sd4txp_o;    // pad, RX+, ext serial loopback
assign  sd3rxp_i = sd3txp_o;    // pad, RX+, ext serial loopback
assign  sd2rxp_i = sd2txp_o;    // pad, RX+, ext serial loopback
assign  sd1rxp_i = sd1txp_o;    // pad, RX+, ext serial loopback
assign  sd0rxp_i = sd0txp_o;    // pad, RX+, ext serial loopback

assign  sd7rxn_i = sd7txn_o;    // pad, RX-, ext serial loopback
assign  sd6rxn_i = sd6txn_o;    // pad, RX-, ext serial loopback
assign  sd5rxn_i = sd5txn_o;    // pad, RX-, ext serial loopback
assign  sd4rxn_i = sd4txn_o;    // pad, RX-, ext serial loopback
assign  sd3rxn_i = sd3txn_o;    // pad, RX-, ext serial loopback
assign  sd2rxn_i = sd2txn_o;    // pad, RX-, ext serial loopback
assign  sd1rxn_i = sd1txn_o;    // pad, RX-, ext serial loopback
assign  sd0rxn_i = sd0txn_o;    // pad, RX-, ext serial loopback

assign  sd7_rext_i = 1'b0;      // pad, external resistance
assign  sd6_rext_i = 1'b0;      // pad, external resistance
assign  sd5_rext_i = 1'b0;      // pad, external resistance
assign  sd4_rext_i = 1'b0;      // pad, external resistance
assign  sd3_rext_i = 1'b0;      // pad, external resistance
assign  sd2_rext_i = 1'b0;      // pad, external resistance
assign  sd1_rext_i = 1'b0;      // pad, external resistance
assign  sd0_rext_i = 1'b0;      // pad, external resistance

assign  sd7_refret_i = 1'b0;    // pad
assign  sd6_refret_i = 1'b0;    // pad
assign  sd5_refret_i = 1'b0;    // pad
assign  sd4_refret_i = 1'b0;    // pad
assign  sd3_refret_i = 1'b0;    // pad
assign  sd2_refret_i = 1'b0;    // pad
assign  sd1_refret_i = 1'b0;    // pad
assign  sd0_refret_i = 1'b0;    // pad

//MPCS Interface
assign  mpcs_rx_usr_clk_i_7 = mpcs_rx_out_clk_o_7;
assign  mpcs_rx_usr_clk_i_6 = mpcs_rx_out_clk_o_6;
assign  mpcs_rx_usr_clk_i_5 = mpcs_rx_out_clk_o_5;
assign  mpcs_rx_usr_clk_i_4 = mpcs_rx_out_clk_o_4;
assign  mpcs_rx_usr_clk_i_3 = mpcs_rx_out_clk_o_3;
assign  mpcs_rx_usr_clk_i_2 = mpcs_rx_out_clk_o_2;
assign  mpcs_rx_usr_clk_i_1 = mpcs_rx_out_clk_o_1;
assign  mpcs_rx_usr_clk_i_0 = mpcs_rx_out_clk_o_0;

assign  mpcs_tx_usr_clk_i_7 = mpcs_tx_out_clk_o_7;
assign  mpcs_tx_usr_clk_i_6 = mpcs_tx_out_clk_o_6;
assign  mpcs_tx_usr_clk_i_5 = mpcs_tx_out_clk_o_5;
assign  mpcs_tx_usr_clk_i_4 = mpcs_tx_out_clk_o_4;
assign  mpcs_tx_usr_clk_i_3 = mpcs_tx_out_clk_o_3;
assign  mpcs_tx_usr_clk_i_2 = mpcs_tx_out_clk_o_2;
assign  mpcs_tx_usr_clk_i_1 = mpcs_tx_out_clk_o_1;
assign  mpcs_tx_usr_clk_i_0 = mpcs_tx_out_clk_o_0;


assign  usr_clk_i = (PCS_BYPASS == 1) ? epcs_txclk_o_0 : mpcs_tx_out_clk_o_0;

assign  mpcs_tx_pcs_rstn_i_7 = reset_n;
assign  mpcs_tx_pcs_rstn_i_6 = reset_n;
assign  mpcs_tx_pcs_rstn_i_5 = reset_n;
assign  mpcs_tx_pcs_rstn_i_4 = reset_n;
assign  mpcs_tx_pcs_rstn_i_3 = reset_n;
assign  mpcs_tx_pcs_rstn_i_2 = reset_n;
assign  mpcs_tx_pcs_rstn_i_1 = reset_n;
assign  mpcs_tx_pcs_rstn_i_0 = reset_n;

assign  mpcs_rx_pcs_rstn_i_7 = reset_n && phyrdy_o; //wait for phy ready signal
assign  mpcs_rx_pcs_rstn_i_6 = reset_n && phyrdy_o; //wait for phy ready signal
assign  mpcs_rx_pcs_rstn_i_5 = reset_n && phyrdy_o; //wait for phy ready signal
assign  mpcs_rx_pcs_rstn_i_4 = reset_n && phyrdy_o; //wait for phy ready signal
assign  mpcs_rx_pcs_rstn_i_3 = reset_n && phyrdy_o; //wait for phy ready signal
assign  mpcs_rx_pcs_rstn_i_2 = reset_n && phyrdy_o; //wait for phy ready signal
assign  mpcs_rx_pcs_rstn_i_1 = reset_n && phyrdy_o; //wait for phy ready signal
assign  mpcs_rx_pcs_rstn_i_0 = reset_n && phyrdy_o; //wait for phy ready signal

assign  mpcs_cc_clk_i_7 = mpcs_clk;
assign  mpcs_cc_clk_i_6 = mpcs_clk;
assign  mpcs_cc_clk_i_5 = mpcs_clk;
assign  mpcs_cc_clk_i_4 = mpcs_clk;
assign  mpcs_cc_clk_i_3 = mpcs_clk;
assign  mpcs_cc_clk_i_2 = mpcs_clk;
assign  mpcs_cc_clk_i_1 = mpcs_clk;
assign  mpcs_cc_clk_i_0 = mpcs_clk;

assign  mpcs_perstn_i_7 = reset_n;
assign  mpcs_perstn_i_6 = reset_n;
assign  mpcs_perstn_i_5 = reset_n;
assign  mpcs_perstn_i_4 = reset_n;
assign  mpcs_perstn_i_3 = reset_n;
assign  mpcs_perstn_i_2 = reset_n;
assign  mpcs_perstn_i_1 = reset_n;
assign  mpcs_perstn_i_0 = reset_n;
        
assign  mpcs_clkreq_in_n_i_7 = 1'b1;
assign  mpcs_clkreq_in_n_i_6 = 1'b1;
assign  mpcs_clkreq_in_n_i_5 = 1'b1;
assign  mpcs_clkreq_in_n_i_4 = 1'b1;
assign  mpcs_clkreq_in_n_i_3 = 1'b1;
assign  mpcs_clkreq_in_n_i_2 = 1'b1;
assign  mpcs_clkreq_in_n_i_1 = 1'b1;
assign  mpcs_clkreq_in_n_i_0 = 1'b1;

assign  mpcs_anxmit_i_7 = 1'b1; //Auto-neg
assign  mpcs_anxmit_i_6 = 1'b1; //Auto-neg
assign  mpcs_anxmit_i_5 = 1'b1; //Auto-neg
assign  mpcs_anxmit_i_4 = 1'b1; //Auto-neg
assign  mpcs_anxmit_i_3 = 1'b1; //Auto-neg
assign  mpcs_anxmit_i_2 = 1'b1; //Auto-neg
assign  mpcs_anxmit_i_1 = 1'b1; //Auto-neg
assign  mpcs_anxmit_i_0 = 1'b1; //Auto-neg

assign  mpcs_walign_en_i_7 = 1'b1;  // Enable Word Alignment
assign  mpcs_walign_en_i_6 = 1'b1;  // Enable Word Alignment
assign  mpcs_walign_en_i_5 = 1'b1;  // Enable Word Alignment
assign  mpcs_walign_en_i_4 = 1'b1;  // Enable Word Alignment
assign  mpcs_walign_en_i_3 = 1'b1;  // Enable Word Alignment
assign  mpcs_walign_en_i_2 = 1'b1;  // Enable Word Alignment
assign  mpcs_walign_en_i_1 = 1'b1;  // Enable Word Alignment
assign  mpcs_walign_en_i_0 = 1'b1;  // Enable Word Alignment

assign  mpcs_rx_deskew_en_i_7 = 1'b1;
assign  mpcs_rx_deskew_en_i_6 = 1'b1;
assign  mpcs_rx_deskew_en_i_5 = 1'b1;
assign  mpcs_rx_deskew_en_i_4 = 1'b1;
assign  mpcs_rx_deskew_en_i_3 = 1'b1;
assign  mpcs_rx_deskew_en_i_2 = 1'b1;
assign  mpcs_rx_deskew_en_i_1 = 1'b1;
assign  mpcs_rx_deskew_en_i_0 = 1'b1;  

assign  mpcs_clkin_i_7 = mpcs_clk; //PMA Clock
assign  mpcs_clkin_i_6 = mpcs_clk; //PMA Clock
assign  mpcs_clkin_i_5 = mpcs_clk; //PMA Clock
assign  mpcs_clkin_i_4 = mpcs_clk; //PMA Clock
assign  mpcs_clkin_i_3 = mpcs_clk; //PMA Clock
assign  mpcs_clkin_i_2 = mpcs_clk; //PMA Clock
assign  mpcs_clkin_i_1 = mpcs_clk; //PMA Clock
assign  mpcs_clkin_i_0 = mpcs_clk; //PMA Clock

assign  mpcs_pwrdn_i_7 = 2'b00; // Initial PMA state
assign  mpcs_pwrdn_i_6 = 2'b00; // Initial PMA state
assign  mpcs_pwrdn_i_5 = 2'b00; // Initial PMA state
assign  mpcs_pwrdn_i_4 = 2'b00; // Initial PMA state
assign  mpcs_pwrdn_i_3 = 2'b00; // Initial PMA state
assign  mpcs_pwrdn_i_2 = 2'b00; // Initial PMA state
assign  mpcs_pwrdn_i_1 = 2'b00; // Initial PMA state
assign  mpcs_pwrdn_i_0 = 2'b00; // Initial PMA state
    
assign  mpcs_txhiz_i_7 = 1'b0;
assign  mpcs_txhiz_i_6 = 1'b0;
assign  mpcs_txhiz_i_5 = 1'b0;
assign  mpcs_txhiz_i_4 = 1'b0;
assign  mpcs_txhiz_i_3 = 1'b0;
assign  mpcs_txhiz_i_2 = 1'b0;
assign  mpcs_txhiz_i_1 = 1'b0;
assign  mpcs_txhiz_i_0 = 1'b0;  

assign  mpcs_rxerr_i_7 = 1'b0;
assign  mpcs_rxerr_i_6 = 1'b0;
assign  mpcs_rxerr_i_5 = 1'b0;
assign  mpcs_rxerr_i_4 = 1'b0;
assign  mpcs_rxerr_i_3 = 1'b0;
assign  mpcs_rxerr_i_2 = 1'b0;
assign  mpcs_rxerr_i_1 = 1'b0;
assign  mpcs_rxerr_i_0 = 1'b0;  
    
assign  mpcs_fomreq_i_7 = 1'b0;
assign  mpcs_fomreq_i_6 = 1'b0;
assign  mpcs_fomreq_i_5 = 1'b0;
assign  mpcs_fomreq_i_4 = 1'b0;
assign  mpcs_fomreq_i_3 = 1'b0;
assign  mpcs_fomreq_i_2 = 1'b0;
assign  mpcs_fomreq_i_1 = 1'b0;
assign  mpcs_fomreq_i_0 = 1'b0;  

assign  mpcs_rate_i_7 = 2'b00;
assign  mpcs_rate_i_6 = 2'b00;
assign  mpcs_rate_i_5 = 2'b00;
assign  mpcs_rate_i_4 = 2'b00;
assign  mpcs_rate_i_3 = 2'b00;
assign  mpcs_rate_i_2 = 2'b00;
assign  mpcs_rate_i_1 = 2'b00;
assign  mpcs_rate_i_0 = 2'b00; //For multi-rate protocol only -- Jo_to_enhance
                                //2'b00 - rate0 
                                //2'b01 - rate1 
                                //2'b10 - rate2        

assign  mpcs_txval_i_7 = 1'b1;
assign  mpcs_txval_i_6 = 1'b1;
assign  mpcs_txval_i_5 = 1'b1;
assign  mpcs_txval_i_4 = 1'b1;
assign  mpcs_txval_i_3 = 1'b1;
assign  mpcs_txval_i_2 = 1'b1;
assign  mpcs_txval_i_1 = 1'b1;
assign  mpcs_txval_i_0 = 1'b1;
        
assign  mpcs_rxoob_i_7 = 1'b0;
assign  mpcs_rxoob_i_6 = 1'b0;
assign  mpcs_rxoob_i_5 = 1'b0;
assign  mpcs_rxoob_i_4 = 1'b0;
assign  mpcs_rxoob_i_3 = 1'b0;
assign  mpcs_rxoob_i_2 = 1'b0;
assign  mpcs_rxoob_i_1 = 1'b0;
assign  mpcs_rxoob_i_0 = 1'b0; 
  
assign  mpcs_txdeemp_i_7 = 1'b0;
assign  mpcs_txdeemp_i_6 = 1'b0;
assign  mpcs_txdeemp_i_5 = 1'b0;
assign  mpcs_txdeemp_i_4 = 1'b0;
assign  mpcs_txdeemp_i_3 = 1'b0;
assign  mpcs_txdeemp_i_2 = 1'b0;
assign  mpcs_txdeemp_i_1 = 1'b0;    
assign  mpcs_txdeemp_i_0 = 1'b0;        

assign  mpcs_skipbit_i_7 = 1'b0; // For Manual Word Alignment
assign  mpcs_skipbit_i_6 = 1'b0; // For Manual Word Alignment
assign  mpcs_skipbit_i_5 = 1'b0; // For Manual Word Alignment
assign  mpcs_skipbit_i_4 = 1'b0; // For Manual Word Alignment
assign  mpcs_skipbit_i_3 = 1'b0; // For Manual Word Alignment
assign  mpcs_skipbit_i_2 = 1'b0; // For Manual Word Alignment
assign  mpcs_skipbit_i_1 = 1'b0; // For Manual Word Alignment       
assign  mpcs_skipbit_i_0 = 1'b0; // For Manual Word Alignment           

assign  mpcs_ready_w[7] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  6) ? mpcs_ready_o_7 : 1'b0;
assign  mpcs_ready_w[6] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  6) ? mpcs_ready_o_6 : 1'b0;
assign  mpcs_ready_w[5] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  4) ? mpcs_ready_o_5 : 1'b0;
assign  mpcs_ready_w[4] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  4) ? mpcs_ready_o_4 : 1'b0;
assign  mpcs_ready_w[3] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  2) ? mpcs_ready_o_3 : 1'b0;
assign  mpcs_ready_w[2] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  2) ? mpcs_ready_o_2 : 1'b0;
assign  mpcs_ready_w[1] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  1) ? mpcs_ready_o_1 : 1'b0;
assign  mpcs_ready_w[0] = ((MODESEL <= 1 && PCS_BYPASS == 0)                  ) ? mpcs_ready_o_0 : 1'b0;

assign  mpcs_phyrdy_w[7] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  6) ? mpcs_phyrdy_o_7 : 1'b0;
assign  mpcs_phyrdy_w[6] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  6) ? mpcs_phyrdy_o_6 : 1'b0;
assign  mpcs_phyrdy_w[5] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  4) ? mpcs_phyrdy_o_5 : 1'b0;
assign  mpcs_phyrdy_w[4] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  4) ? mpcs_phyrdy_o_4 : 1'b0;
assign  mpcs_phyrdy_w[3] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  2) ? mpcs_phyrdy_o_3 : 1'b0;
assign  mpcs_phyrdy_w[2] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  2) ? mpcs_phyrdy_o_2 : 1'b0;
assign  mpcs_phyrdy_w[1] = ((MODESEL <= 1 && PCS_BYPASS == 0) && NUM_LANES >  1) ? mpcs_phyrdy_o_1 : 1'b0;
assign  mpcs_phyrdy_w[0] = ((MODESEL <= 1 && PCS_BYPASS == 0)                  ) ? mpcs_phyrdy_o_0 : 1'b0;

//EPCS Interface - PCS Bypass

assign  epcs_rx_usr_clk_i_7 = epcs_rxclk_o_7;
assign  epcs_rx_usr_clk_i_6 = epcs_rxclk_o_6;
assign  epcs_rx_usr_clk_i_5 = epcs_rxclk_o_5;
assign  epcs_rx_usr_clk_i_4 = epcs_rxclk_o_4;
assign  epcs_rx_usr_clk_i_3 = epcs_rxclk_o_3;
assign  epcs_rx_usr_clk_i_2 = epcs_rxclk_o_2;
assign  epcs_rx_usr_clk_i_1 = epcs_rxclk_o_1;
assign  epcs_rx_usr_clk_i_0 = epcs_rxclk_o_0;

assign  epcs_tx_usr_clk_i_7 = epcs_txclk_o_7;
assign  epcs_tx_usr_clk_i_6 = epcs_txclk_o_6;
assign  epcs_tx_usr_clk_i_5 = epcs_txclk_o_5;
assign  epcs_tx_usr_clk_i_4 = epcs_txclk_o_4;
assign  epcs_tx_usr_clk_i_3 = epcs_txclk_o_3;
assign  epcs_tx_usr_clk_i_2 = epcs_txclk_o_2;
assign  epcs_tx_usr_clk_i_1 = epcs_txclk_o_1;
assign  epcs_tx_usr_clk_i_0 = epcs_txclk_o_0;

assign  epcs_tx_pcs_rstn_i_7 = reset_n;
assign  epcs_tx_pcs_rstn_i_6 = reset_n;
assign  epcs_tx_pcs_rstn_i_5 = reset_n;
assign  epcs_tx_pcs_rstn_i_4 = reset_n;
assign  epcs_tx_pcs_rstn_i_3 = reset_n;
assign  epcs_tx_pcs_rstn_i_2 = reset_n;
assign  epcs_tx_pcs_rstn_i_1 = reset_n;
assign  epcs_tx_pcs_rstn_i_0 = reset_n;
        
assign  epcs_rx_pcs_rstn_i_7 = reset_n && phyrdy_o; //wait for phyrdy
assign  epcs_rx_pcs_rstn_i_6 = reset_n && phyrdy_o; //wait for phyrdy
assign  epcs_rx_pcs_rstn_i_5 = reset_n && phyrdy_o; //wait for phyrdy
assign  epcs_rx_pcs_rstn_i_4 = reset_n && phyrdy_o; //wait for phyrdy
assign  epcs_rx_pcs_rstn_i_3 = reset_n && phyrdy_o; //wait for phyrdy
assign  epcs_rx_pcs_rstn_i_2 = reset_n && phyrdy_o; //wait for phyrdy
assign  epcs_rx_pcs_rstn_i_1 = reset_n && phyrdy_o; //wait for phyrdy
assign  epcs_rx_pcs_rstn_i_0 = reset_n && phyrdy_o; //wait for phyrdy

assign  epcs_rstn_i_7 = reset_n;
assign  epcs_rstn_i_6 = reset_n;
assign  epcs_rstn_i_5 = reset_n;
assign  epcs_rstn_i_4 = reset_n;
assign  epcs_rstn_i_3 = reset_n;
assign  epcs_rstn_i_2 = reset_n;
assign  epcs_rstn_i_1 = reset_n;
assign  epcs_rstn_i_0 = reset_n;
    
assign  epcs_clkin_i_7 = mpcs_clk;
assign  epcs_clkin_i_6 = mpcs_clk;
assign  epcs_clkin_i_5 = mpcs_clk;
assign  epcs_clkin_i_4 = mpcs_clk;
assign  epcs_clkin_i_3 = mpcs_clk;
assign  epcs_clkin_i_2 = mpcs_clk;
assign  epcs_clkin_i_1 = mpcs_clk;
assign  epcs_clkin_i_0 = mpcs_clk;

assign  epcs_pwrdn_i_7 = 2'b00; // Initial PMA state
assign  epcs_pwrdn_i_6 = 2'b00; // Initial PMA state
assign  epcs_pwrdn_i_5 = 2'b00; // Initial PMA state
assign  epcs_pwrdn_i_4 = 2'b00; // Initial PMA state
assign  epcs_pwrdn_i_3 = 2'b00; // Initial PMA state
assign  epcs_pwrdn_i_2 = 2'b00; // Initial PMA state
assign  epcs_pwrdn_i_1 = 2'b00; // Initial PMA state
assign  epcs_pwrdn_i_0 = 2'b00; // Initial PMA state

assign  epcs_txhiz_i_7 = 1'b0;
assign  epcs_txhiz_i_6 = 1'b0;
assign  epcs_txhiz_i_5 = 1'b0;
assign  epcs_txhiz_i_4 = 1'b0;
assign  epcs_txhiz_i_3 = 1'b0;
assign  epcs_txhiz_i_2 = 1'b0;
assign  epcs_txhiz_i_1 = 1'b0;
assign  epcs_txhiz_i_0 = 1'b0;

assign  epcs_rxerr_i_7 = 1'b0;
assign  epcs_rxerr_i_6 = 1'b0;
assign  epcs_rxerr_i_5 = 1'b0;
assign  epcs_rxerr_i_4 = 1'b0;
assign  epcs_rxerr_i_3 = 1'b0;
assign  epcs_rxerr_i_2 = 1'b0;
assign  epcs_rxerr_i_1 = 1'b0;
assign  epcs_rxerr_i_0 = 1'b0;

assign  epcs_fomreq_i_7 = 1'b0;
assign  epcs_fomreq_i_6 = 1'b0;
assign  epcs_fomreq_i_5 = 1'b0;
assign  epcs_fomreq_i_4 = 1'b0;
assign  epcs_fomreq_i_3 = 1'b0;
assign  epcs_fomreq_i_2 = 1'b0;
assign  epcs_fomreq_i_1 = 1'b0;
assign  epcs_fomreq_i_0 = 1'b0;

assign  epcs_rate_i_7 = 2'b00;
assign  epcs_rate_i_6 = 2'b00;
assign  epcs_rate_i_5 = 2'b00;
assign  epcs_rate_i_4 = 2'b00;
assign  epcs_rate_i_3 = 2'b00;
assign  epcs_rate_i_2 = 2'b00;
assign  epcs_rate_i_1 = 2'b00;
assign  epcs_rate_i_0 = 2'b00; //For multi-rate protocol only
                                   //2'b00 - rate0 
                                   //2'b01 - rate1 
                                   //2'b10 - rate2                             

assign  epcs_txval_i_7 = 1'b1;
assign  epcs_txval_i_6 = 1'b1;
assign  epcs_txval_i_5 = 1'b1;
assign  epcs_txval_i_4 = 1'b1;
assign  epcs_txval_i_3 = 1'b1;
assign  epcs_txval_i_2 = 1'b1;
assign  epcs_txval_i_1 = 1'b1;
assign  epcs_txval_i_0 = 1'b1;
    
assign  epcs_rxoob_i_7 = 1'b0;
assign  epcs_rxoob_i_6 = 1'b0;
assign  epcs_rxoob_i_5 = 1'b0;
assign  epcs_rxoob_i_4 = 1'b0;
assign  epcs_rxoob_i_3 = 1'b0;
assign  epcs_rxoob_i_2 = 1'b0;
assign  epcs_rxoob_i_1 = 1'b0;
assign  epcs_rxoob_i_0 = 1'b0;
    
assign  epcs_txdeemp_i_7 = 1'b0;
assign  epcs_txdeemp_i_6 = 1'b0;
assign  epcs_txdeemp_i_5 = 1'b0;
assign  epcs_txdeemp_i_4 = 1'b0;
assign  epcs_txdeemp_i_3 = 1'b0;
assign  epcs_txdeemp_i_2 = 1'b0;
assign  epcs_txdeemp_i_1 = 1'b0;
assign  epcs_txdeemp_i_0 = 1'b0;

assign  epcs_skipbit_i_7 = 1'b0; // For Manual Word Alignment
assign  epcs_skipbit_i_6 = 1'b0; // For Manual Word Alignment
assign  epcs_skipbit_i_5 = 1'b0; // For Manual Word Alignment
assign  epcs_skipbit_i_4 = 1'b0; // For Manual Word Alignment
assign  epcs_skipbit_i_3 = 1'b0; // For Manual Word Alignment
assign  epcs_skipbit_i_2 = 1'b0; // For Manual Word Alignment
assign  epcs_skipbit_i_1 = 1'b0; // For Manual Word Alignment
assign  epcs_skipbit_i_0 = 1'b0; // For Manual Word Alignment

assign  epcs_ready_w[7] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  6) ? epcs_ready_o_7 : 1'b0;
assign  epcs_ready_w[6] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  6) ? epcs_ready_o_6 : 1'b0;
assign  epcs_ready_w[5] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  4) ? epcs_ready_o_5 : 1'b0;
assign  epcs_ready_w[4] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  4) ? epcs_ready_o_4 : 1'b0;
assign  epcs_ready_w[3] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  2) ? epcs_ready_o_3 : 1'b0;
assign  epcs_ready_w[2] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  2) ? epcs_ready_o_2 : 1'b0;
assign  epcs_ready_w[1] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  1) ? epcs_ready_o_1 : 1'b0;
assign  epcs_ready_w[0] = ((MODESEL == 0 && PCS_BYPASS == 1)                  ) ? epcs_ready_o_0 : 1'b0;

assign  epcs_phyrdy_w[7] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  6) ? epcs_phyrdy_o_7 : 1'b0;
assign  epcs_phyrdy_w[6] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  6) ? epcs_phyrdy_o_6 : 1'b0;
assign  epcs_phyrdy_w[5] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  4) ? epcs_phyrdy_o_5 : 1'b0;
assign  epcs_phyrdy_w[4] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  4) ? epcs_phyrdy_o_4 : 1'b0;
assign  epcs_phyrdy_w[3] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  2) ? epcs_phyrdy_o_3 : 1'b0;
assign  epcs_phyrdy_w[2] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  2) ? epcs_phyrdy_o_2 : 1'b0;
assign  epcs_phyrdy_w[1] = ((MODESEL == 0 && PCS_BYPASS == 1) && NUM_LANES >  1) ? epcs_phyrdy_o_1 : 1'b0;
assign  epcs_phyrdy_w[0] = ((MODESEL == 0 && PCS_BYPASS == 1)                  ) ? epcs_phyrdy_o_0 : 1'b0;

//PIPE Interface

assign  pipe_aux_clk_i_3 = mpcs_clk;
assign  pipe_aux_clk_i_2 = mpcs_clk;
assign  pipe_aux_clk_i_1 = mpcs_clk;
assign  pipe_aux_clk_i_0 = mpcs_clk;

assign  pipe_rstn_i_3 = reset_n && phyrdy_o; //wait for phyrdy
assign  pipe_rstn_i_2 = reset_n && phyrdy_o; //wait for phyrdy
assign  pipe_rstn_i_1 = reset_n && phyrdy_o; //wait for phyrdy
assign  pipe_rstn_i_0 = reset_n && phyrdy_o; //wait for phyrdy   

assign  pipe_pclkin_i_3 = mpcs_clk;
assign  pipe_pclkin_i_2 = mpcs_clk;
assign  pipe_pclkin_i_1 = mpcs_clk;
assign  pipe_pclkin_i_0 = mpcs_clk;

assign  pipe_rate_i_3 = 2'b00;  
assign  pipe_rate_i_2 = 2'b00;  
assign  pipe_rate_i_1 = 2'b00;  
assign  pipe_rate_i_0 = 2'b00; //For multi-rate protocol only
                               //2'b00 - rate0 
                               //2'b01 - rate1 
                               //2'b10 - rate2   
    
assign  pipe_powerdown_i_3 = 2'b00;  
assign  pipe_powerdown_i_2 = 2'b00;  
assign  pipe_powerdown_i_1 = 2'b00;   
assign  pipe_powerdown_i_0 = 2'b00;  

assign  pipe_txdetectrx_i_3 = 1'b1;     //TxdetectRx/Loopback     
assign  pipe_txdetectrx_i_2 = 1'b1;     //TxdetectRx/Loopback     
assign  pipe_txdetectrx_i_1 = 1'b1;     //TxdetectRx/Loopback     
assign  pipe_txdetectrx_i_0 = 1'b1;     //TxdetectRx/Loopback 

assign  pipe_txdeemp_i_3 = 18'b1111;    //Transmit De-emphasis  
assign  pipe_txdeemp_i_2 = 18'b1111;    //Transmit De-emphasis  
assign  pipe_txdeemp_i_1 = 18'b1111;    //Transmit De-emphasis 
assign  pipe_txdeemp_i_0 = 18'b1111;    //Transmit De-emphasis  

assign  pipe_txmargin_i_3 = 3'b111;     //Transmit Margin  
assign  pipe_txmargin_i_2 = 3'b111;     //Transmit Margin  
assign  pipe_txmargin_i_1 = 3'b111;     //Transmit Margin   
assign  pipe_txmargin_i_0 = 3'b111;     //Transmit Margin 

assign  pipe_tx_swing_i_3 = 1'b1;       //Transmit Swing
assign  pipe_tx_swing_i_2 = 1'b1;       //Transmit Swing
assign  pipe_tx_swing_i_1 = 1'b1;       //Transmit Swing    
assign  pipe_tx_swing_i_0 = 1'b1;       //Transmit Swing

assign  pipe_txdatak_i_3 = 4'b1111;     //Transmit Control Character    
assign  pipe_txdatak_i_2 = 4'b1111;     //Transmit Control Character    
assign  pipe_txdatak_i_1 = 4'b1111;     //Transmit Control Character    
assign  pipe_txdatak_i_0 = 4'b1111;     //Transmit Control Character    
             
assign  pipe_txdatavalid_i_3 = 1'b1;    //Transmit Data Valid
assign  pipe_txdatavalid_i_2 = 1'b1;    //Transmit Data Valid
assign  pipe_txdatavalid_i_1 = 1'b1;    //Transmit Data Valid
assign  pipe_txdatavalid_i_0 = 1'b1;    //Transmit Data Valid
                                        
assign  pipe_tx_start_block_i_3 = 1'b0; //Transmit data starting byte
assign  pipe_tx_start_block_i_2 = 1'b0; //Transmit data starting byte
assign  pipe_tx_start_block_i_1 = 1'b0; //Transmit data starting byte
assign  pipe_tx_start_block_i_0 = 1'b0; //Transmit data starting byte

assign  pipe_txsyncheader_i_3 = 2'b0;   //Transmit Sync Header
assign  pipe_txsyncheader_i_2 = 2'b0;   //Transmit Sync Header
assign  pipe_txsyncheader_i_1 = 2'b0;   //Transmit Sync Header
assign  pipe_txsyncheader_i_0 = 2'b0;   //Transmit Sync Header

assign  pipe_tx_elec_idle_i_3 = 1'b0;   //Transmit Electrical Idle
assign  pipe_tx_elec_idle_i_2 = 1'b0;   //Transmit Electrical Idle
assign  pipe_tx_elec_idle_i_1 = 1'b0;   //Transmit Electrical Idle
assign  pipe_tx_elec_idle_i_0 = 1'b0;   //Transmit Electrical Idle

assign  pipe_txcompl_i_3 = 1'b0;        //Transmit Compliance
assign  pipe_txcompl_i_2 = 1'b0;        //Transmit Compliance
assign  pipe_txcompl_i_1 = 1'b0;        //Transmit Compliance
assign  pipe_txcompl_i_0 = 1'b0;        //Transmit Compliance

assign  pipe_rx_polarity_i_3 = 1'b0;    //Receive Polarity
assign  pipe_rx_polarity_i_2 = 1'b0;    //Receive Polarity
assign  pipe_rx_polarity_i_1 = 1'b0;    //Receive Polarity
assign  pipe_rx_polarity_i_0 = 1'b0;    //Receive Polarity

assign  pipe_blockalignctrl_i_3 = 1'b1; //Block Align Control
assign  pipe_blockalignctrl_i_2 = 1'b1; //Block Align Control
assign  pipe_blockalignctrl_i_1 = 1'b1; //Block Align Control 
assign  pipe_blockalignctrl_i_0 = 1'b1; //Block Align Control

assign  pipe_local_get_preset_coef_i_3 = 1'b0;        
assign  pipe_local_get_preset_coef_i_2 = 1'b0;        
assign  pipe_local_get_preset_coef_i_1 = 1'b0;        
assign  pipe_local_get_preset_coef_i_0 = 1'b0;        
                  
assign  pipe_local_get_preset_index_i_3 = 4'b0; 
assign  pipe_local_get_preset_index_i_2 = 4'b0; 
assign  pipe_local_get_preset_index_i_1 = 4'b0; 
assign  pipe_local_get_preset_index_i_0 = 4'b0; 

assign  pipe_rxeqeval_i_3 = 1'b1;        //Rx Equalization Evaluation Request
assign  pipe_rxeqeval_i_2 = 1'b1;        //Rx Equalization Evaluation Request
assign  pipe_rxeqeval_i_1 = 1'b1;        //Rx Equalization Evaluation Request 
assign  pipe_rxeqeval_i_0 = 1'b1;        //Rx Equalization Evaluation Request
          
assign  pipe_invalidrequest_i_3 = 1'b0;  //Rx Equalization Invalid Request
assign  pipe_invalidrequest_i_2 = 1'b0;  //Rx Equalization Invalid Request
assign  pipe_invalidrequest_i_1 = 1'b0;  //Rx Equalization Invalid Request
assign  pipe_invalidrequest_i_0 = 1'b0;  //Rx Equalization Invalid Request
              
assign  pipe_rxpresethint_en_i_3 = 1'b0;
assign  pipe_rxpresethint_en_i_2 = 1'b0;
assign  pipe_rxpresethint_en_i_1 = 1'b0;
assign  pipe_rxpresethint_en_i_0 = 1'b0;

assign  pipe_rxpresethint_i_3 = 3'b0;    //Rx Equalization Preset Hint
assign  pipe_rxpresethint_i_2 = 3'b0;    //Rx Equalization Preset Hint
assign  pipe_rxpresethint_i_1 = 3'b0;    //Rx Equalization Preset Hint
assign  pipe_rxpresethint_i_0 = 3'b0;    //Rx Equalization Preset Hint

assign  pipe_remote_lf_i_3 = 6'b0; 
assign  pipe_remote_lf_i_2 = 6'b0; 
assign  pipe_remote_lf_i_1 = 6'b0; 
assign  pipe_remote_lf_i_0 = 6'b0; 

assign  pipe_remote_fs_i_3 = 6'b0;
assign  pipe_remote_fs_i_2 = 6'b0;
assign  pipe_remote_fs_i_1 = 6'b0;
assign  pipe_remote_fs_i_0 = 6'b0;

assign  pipe_remote_eq_rx_deemph_i_3 = 18'b0;
assign  pipe_remote_eq_rx_deemph_i_2 = 18'b0;
assign  pipe_remote_eq_rx_deemph_i_1 = 18'b0;
assign  pipe_remote_eq_rx_deemph_i_0 = 18'b0;

assign  pipe_remote_eq_rx_preset_i_3 = 4'b0;
assign  pipe_remote_eq_rx_preset_i_2 = 4'b0;
assign  pipe_remote_eq_rx_preset_i_1 = 4'b0;
assign  pipe_remote_eq_rx_preset_i_0 = 4'b0;

assign  pipe_tx_clkreq_n_i_3 = 1'b1;
assign  pipe_tx_clkreq_n_i_2 = 1'b1;
assign  pipe_tx_clkreq_n_i_1 = 1'b1;
assign  pipe_tx_clkreq_n_i_0 = 1'b1;

assign  pipe_l1pmss_en_i_3 = 1'b0;
assign  pipe_l1pmss_en_i_2 = 1'b0;
assign  pipe_l1pmss_en_i_1 = 1'b0;
assign  pipe_l1pmss_en_i_0 = 1'b0;

assign  pipe_rxelecidle_disable_i_3 = 1'b0; 
assign  pipe_rxelecidle_disable_i_2 = 1'b0; 
assign  pipe_rxelecidle_disable_i_1 = 1'b0; 
assign  pipe_rxelecidle_disable_i_0 = 1'b0; 
         
assign  pipe_txcommonmode_disable_i_3 = 1'b0;  
assign  pipe_txcommonmode_disable_i_2 = 1'b0;  
assign  pipe_txcommonmode_disable_i_1 = 1'b0;  
assign  pipe_txcommonmode_disable_i_0 = 1'b0;  
 
assign pipe_phy_status_w[3] = (MODESEL == 2 && NUM_LANES >  2) ? pipe_phy_status_o_3 : 1'b0;
assign pipe_phy_status_w[2] = (MODESEL == 2 && NUM_LANES >  2) ? pipe_phy_status_o_2 : 1'b0;
assign pipe_phy_status_w[1] = (MODESEL == 2 && NUM_LANES >  1) ? pipe_phy_status_o_1 : 1'b0;
assign pipe_phy_status_w[0] = (MODESEL == 2 && NUM_LANES == 1) ? pipe_phy_status_o_0 : 1'b0;       

assign mpcs_tx_ch_din_i_0 = {1'b0, bus_control_l0[3], bus_data_l0[31:24], 1'b0, bus_control_l0[2], bus_data_l0[23:16], 1'b0, bus_control_l0[1], bus_data_l0[15:8], 1'b0, bus_control_l0[0], bus_data_l0[7:0]};
assign mpcs_tx_ch_din_i_1 = {1'b0, bus_control_l1[3], bus_data_l1[31:24], 1'b0, bus_control_l1[2], bus_data_l1[23:16], 1'b0, bus_control_l1[1], bus_data_l1[15:8], 1'b0, bus_control_l1[0], bus_data_l1[7:0]};
assign mpcs_tx_ch_din_i_2 = {1'b0, bus_control_l2[3], bus_data_l2[31:24], 1'b0, bus_control_l2[2], bus_data_l2[23:16], 1'b0, bus_control_l2[1], bus_data_l2[15:8], 1'b0, bus_control_l2[0], bus_data_l2[7:0]};
assign mpcs_tx_ch_din_i_3 = {1'b0, bus_control_l3[3], bus_data_l3[31:24], 1'b0, bus_control_l3[2], bus_data_l3[23:16], 1'b0, bus_control_l3[1], bus_data_l3[15:8], 1'b0, bus_control_l3[0], bus_data_l3[7:0]};
assign mpcs_tx_ch_din_i_4 = {1'b0, bus_control_l4[3], bus_data_l4[31:24], 1'b0, bus_control_l4[2], bus_data_l4[23:16], 1'b0, bus_control_l4[1], bus_data_l4[15:8], 1'b0, bus_control_l4[0], bus_data_l4[7:0]};
assign mpcs_tx_ch_din_i_5 = {1'b0, bus_control_l5[3], bus_data_l5[31:24], 1'b0, bus_control_l5[2], bus_data_l5[23:16], 1'b0, bus_control_l5[1], bus_data_l5[15:8], 1'b0, bus_control_l5[0], bus_data_l5[7:0]};
assign mpcs_tx_ch_din_i_6 = {1'b0, bus_control_l6[3], bus_data_l6[31:24], 1'b0, bus_control_l6[2], bus_data_l6[23:16], 1'b0, bus_control_l6[1], bus_data_l6[15:8], 1'b0, bus_control_l6[0], bus_data_l6[7:0]};
assign mpcs_tx_ch_din_i_7 = {1'b0, bus_control_l7[3], bus_data_l7[31:24], 1'b0, bus_control_l7[2], bus_data_l7[23:16], 1'b0, bus_control_l7[1], bus_data_l7[15:8], 1'b0, bus_control_l7[0], bus_data_l7[7:0]};  
              
//--------------------------------------------------------------------------
// Initial statement; Reset sequence
//--------------------------------------------------------------------------
initial begin
  reset                   = 1;
  reset_n                 = 0;
  #(20*CLKPERIOD) reset   = 0;
  #(20*CLKPERIOD) reset_n = 1;

  $display("************************************************");
  $display("Start of Simulation                             ");
  $display("+-----------------------------------------------");
  
  error_count = 0;
  
  repeat(40) @(posedge lmmi_clk_i_0); // wait for some time
  
  register_check();  
      if (error_count == 0) begin
       $display("\n[%010t] [TEST]: ALL PCS Registers MATCHED. \n", $time);
       end
      else begin
       $display("\n[%010t] [TEST]: PCS Register MISMATCHED - No of Errors = %0d.\n", $time, error_count);
       end  
       
  $display("+-----------------------------------------------");
  $display("Waiting for calibration to complete             ");
  $display("+-----------------------------------------------");
  
  $display("\n[%010t] [TEST]: Waiting for ready_o assertion. \n", $time);
  #6500000 ready_check(ready_o);
  //@(&ready_o)
  $display("\n[%010t] [TEST]: ready_o asserted! \n", $time);
 
  $display("\n[%010t] [TEST]: Waiting for phyrdy_o assertion. \n", $time);
  #5000    phyrdy_check(phyrdy_o);
  //@(&phyrdy_o)
  $display("\n[%010t] [TEST]: phyrdy_o asserted! \n", $time);
  
  $display("+-----------------------------------------------");
  $display("Waiting for stable MPCS output clock...    \n   ");   
  #10000;
  
  fcheck = 1;
  
  @(&fcheck_done)
  if (fcheck_tb_error == 0) begin
     $display("MPCS Clock Out is STABLE!  \n                         ");
  end 
  else begin
     $display("MPCS Clock Out did NOT meet the Frequency requirement!");
  end
  #2000;
  fcheck = 0;
//  #20000 pmastat_check(); //check serial outputs
  $display("+-----------------------------------------------");
  $display("PHY calibration to completed.                   ");
  $display("+-----------------------------------------------");

//Insert data log for normal tx/rx

  #50000 
  if (error_count+fcheck_tb_error == 0) begin
    $display("\n[%010t] SIMULATION PASSED \n", $time);
  end
  else begin
    $display("\n[%010t] SIMULATION FAILED - No of Errors = %0d.\n", $time, error_count+fcheck_tb_error);
  end
  $display("+-----------------------------------------------");
  $display("End of Simulation                               ");
  $display("************************************************");
  
  #5000 $finish;
end


tb_clk_freq_checker #(
          .EXP_CLKFREQ        (EXP_CLKFREQ),
          .MODE               (MODE),
          .NUM_LANES          (NUM_LANES)
          )
        u_clk_freq_checker  
          (
        //Inputs
          .tx_clk_out_o_0      (PCS_BYPASS ? epcs_txclk_o_0 : mpcs_tx_out_clk_o_0),   
          .tx_clk_out_o_1      (PCS_BYPASS ? epcs_txclk_o_1 : mpcs_tx_out_clk_o_1),   
          .tx_clk_out_o_2      (PCS_BYPASS ? epcs_txclk_o_2 : mpcs_tx_out_clk_o_2),   
          .tx_clk_out_o_3      (PCS_BYPASS ? epcs_txclk_o_3 : mpcs_tx_out_clk_o_3),   
          .tx_clk_out_o_4      (PCS_BYPASS ? epcs_txclk_o_4 : mpcs_tx_out_clk_o_4),   
          .tx_clk_out_o_5      (PCS_BYPASS ? epcs_txclk_o_5 : mpcs_tx_out_clk_o_5),   
          .tx_clk_out_o_6      (PCS_BYPASS ? epcs_txclk_o_6 : mpcs_tx_out_clk_o_6),   
          .tx_clk_out_o_7      (PCS_BYPASS ? epcs_txclk_o_7 : mpcs_tx_out_clk_o_7),   
          .rx_clk_out_o_0      (PCS_BYPASS ? epcs_rxclk_o_0 : mpcs_rx_out_clk_o_0),   
          .rx_clk_out_o_1      (PCS_BYPASS ? epcs_rxclk_o_1 : mpcs_rx_out_clk_o_1),   
          .rx_clk_out_o_2      (PCS_BYPASS ? epcs_rxclk_o_2 : mpcs_rx_out_clk_o_2),   
          .rx_clk_out_o_3      (PCS_BYPASS ? epcs_rxclk_o_3 : mpcs_rx_out_clk_o_3),   
          .rx_clk_out_o_4      (PCS_BYPASS ? epcs_rxclk_o_4 : mpcs_rx_out_clk_o_4),   
          .rx_clk_out_o_5      (PCS_BYPASS ? epcs_rxclk_o_5 : mpcs_rx_out_clk_o_5),   
          .rx_clk_out_o_6      (PCS_BYPASS ? epcs_rxclk_o_6 : mpcs_rx_out_clk_o_6),   
          .rx_clk_out_o_7      (PCS_BYPASS ? epcs_rxclk_o_7 : mpcs_rx_out_clk_o_7),   
          .fcheck              (fcheck   ),             //Wait for fcheck to assert before start of Frequency Checking
        //Outputs
          .check_done          (fcheck_done     ),
          .tb_error            (fcheck_tb_error )
        );

tb_clkgen #
(
 // Parameters
 .NUMCLKS               (1),
 .REFCLKFREQ            (REFCLKFREQ),                         //RefClk in ns
 .FABCLKFREQ            ((MODESEL == 1) ? 6.4 : REFCLKFREQ))  //Fabric Clk in ns
u_tb_clkgen
(
 // Outputs
 .refck_o               (ref_clk),   //Serial Reference clock
 .mpcsck_o              (mpcs_clk),  //Fabric clock
 .genclk_o              ()
 /*AUTOINST*/);


// Transmit Data Generation in Lane 0
always @ (posedge mpcs_tx_usr_clk_i_0) begin
    if (~mpcs_tx_pcs_rstn_i_0) begin
        bus_data_l0 <= 32'd0;
        bus_control_l0 <= 4'd0;
        bus_sm_l0 <= BUS_IDL_L0;
        bus_data_mode_l0 <= 1'b0;
        bus_cnt_l0 <= 9'd0;
    end
    else begin
        case (bus_sm_l0)
            BUS_IDL_L0: 
            begin
                bus_data_l0 <= 32'd0;
                bus_control_l0 <= 4'd0;
                bus_sm_l0 <= BUS_STA_L0;
            end
            BUS_STA_L0: 
            begin
                if (~mpcs_get_lsync_o_0)
                    begin
                    bus_data_l0 <= {8'hAA, 8'hAA, 8'hAA, 8'hBC};
                    bus_control_l0 <= 4'b0001;
                    end 
                else
                    begin
                    bus_data_l0 <= mpcs_tx_ch_din_i_0_next;
                    bus_control_l0 <= 4'b0000;
                    end
            end
            default: begin
                bus_sm_l0 <= BUS_IDL_L0;
            end
        endcase
    end
end

// Transmit Data Generation in Lane 1
always @ (posedge mpcs_tx_usr_clk_i_1) begin
    if (~mpcs_tx_pcs_rstn_i_1) begin
        bus_data_l1 <= 32'd0;
        bus_control_l1 <= 4'd0;
        bus_sm_l1 <= BUS_IDL_L1;
        bus_data_mode_l1 <= 1'b0;
        bus_cnt_l1 <= 9'd0;
    end
    else begin
        case (bus_sm_l1)
            BUS_IDL_L1: 
            begin
                bus_data_l1 <= 32'd0;
                bus_control_l1 <= 4'd0;
                bus_sm_l1 <= BUS_STA_L1;
            end
            BUS_STA_L1: 
            begin
                if (~mpcs_get_lsync_o_1)
                    begin
                    bus_data_l1 <= {8'hAA, 8'hAA, 8'hAA, 8'hBC};
                    bus_control_l1 <= 4'b0001;
                    end 
                else
                    begin
                    bus_data_l1 <= mpcs_tx_ch_din_i_1_next;
                    bus_control_l1 <= 4'b0000;
                    end
            end
            default: begin
                bus_sm_l1 <= BUS_IDL_L1;
            end
        endcase
    end
end

// Transmit Data Generation in Lane 2
always @ (posedge mpcs_tx_usr_clk_i_2) begin
    if (~mpcs_tx_pcs_rstn_i_2) begin
        bus_data_l2 <= 32'd0;
        bus_control_l2 <= 4'd0;
        bus_sm_l2 <= BUS_IDL_L2;
        bus_data_mode_l2 <= 1'b0;
        bus_cnt_l2 <= 9'd0;
    end
    else begin
        case (bus_sm_l2)
            BUS_IDL_L2: 
            begin
                bus_data_l2 <= 32'd0;
                bus_control_l2 <= 4'd0;
                bus_sm_l2 <= BUS_STA_L2;
            end
            BUS_STA_L2: 
            begin
                if (~mpcs_get_lsync_o_2)
                    begin
                    bus_data_l2 <= {8'hAA, 8'hAA, 8'hAA, 8'hBC};
                    bus_control_l2 <= 4'b0001;
                    end 
                else
                    begin
                    bus_data_l2 <= mpcs_tx_ch_din_i_2_next;
                    bus_control_l2 <= 4'b0000;
                    end
            end
            default: begin
                bus_sm_l2 <= BUS_IDL_L2;
            end
        endcase
    end
end

// Transmit Data Generation in Lane 3
always @ (posedge mpcs_tx_usr_clk_i_3) begin
    if (~mpcs_tx_pcs_rstn_i_3) begin
        bus_data_l3 <= 32'd0;
        bus_control_l3 <= 4'd0;
        bus_sm_l3 <= BUS_IDL_L3;
        bus_data_mode_l3 <= 1'b0;
        bus_cnt_l3 <= 9'd0;
    end
    else begin
        case (bus_sm_l3)
            BUS_IDL_L3: 
            begin
                bus_data_l3 <= 32'd0;
                bus_control_l3 <= 4'd0;
                bus_sm_l3 <= BUS_STA_L3;
            end
            BUS_STA_L3: 
            begin
                if (~mpcs_get_lsync_o_3)
                    begin
                    bus_data_l3 <= {8'hAA, 8'hAA, 8'hAA, 8'hBC};
                    bus_control_l3 <= 4'b0001;
                    end 
                else
                    begin
                    bus_data_l3 <= mpcs_tx_ch_din_i_3_next;
                    bus_control_l3 <= 4'b0000;
                    end
            end
            default: begin
                bus_sm_l3 <= BUS_IDL_L3;
            end
        endcase
    end
end

// Transmit Data Generation in Lane 4
always @ (posedge mpcs_tx_usr_clk_i_4) begin
    if (~mpcs_tx_pcs_rstn_i_4) begin
        bus_data_l4 <= 32'd0;
        bus_control_l4 <= 4'd0;
        bus_sm_l4 <= BUS_IDL_L4;
        bus_data_mode_l4 <= 1'b0;
        bus_cnt_l4 <= 9'd0;
    end
    else begin
        case (bus_sm_l4)
            BUS_IDL_L4: 
            begin
                bus_data_l4 <= 32'd0;
                bus_control_l4 <= 4'd0;
                bus_sm_l4 <= BUS_STA_L4;
            end
            BUS_STA_L4: 
            begin
                if (~mpcs_get_lsync_o_4)
                    begin
                    bus_data_l4 <= {8'hAA, 8'hAA, 8'hAA, 8'hBC};
                    bus_control_l4 <= 4'b0001;
                    end 
                else
                    begin
                    bus_data_l4 <= mpcs_tx_ch_din_i_4_next;
                    bus_control_l4 <= 4'b0000;
                    end
            end
            default: begin
                bus_sm_l4 <= BUS_IDL_L4;
            end
        endcase
    end
end

// Transmit Data Generation in Lane 5
always @ (posedge mpcs_tx_usr_clk_i_5) begin
    if (~mpcs_tx_pcs_rstn_i_5) begin
        bus_data_l5 <= 32'd0;
        bus_control_l5 <= 4'd0;
        bus_sm_l5 <= BUS_IDL_L5;
        bus_data_mode_l5 <= 1'b0;
        bus_cnt_l5 <= 9'd0;
    end
    else begin
        case (bus_sm_l5)
            BUS_IDL_L5: 
            begin
                bus_data_l5 <= 32'd0;
                bus_control_l5 <= 4'd0;
                bus_sm_l5 <= BUS_STA_L5;
            end
            BUS_STA_L5: 
            begin
                if (~mpcs_get_lsync_o_5)
                    begin
                    bus_data_l5 <= {8'hAA, 8'hAA, 8'hAA, 8'hBC};
                    bus_control_l5 <= 4'b0001;
                    end 
                else
                    begin
                    bus_data_l5 <= mpcs_tx_ch_din_i_5_next;
                    bus_control_l5 <= 4'b0000;
                    end
            end
            default: begin
                bus_sm_l5 <= BUS_IDL_L5;
            end
        endcase
    end
end

// Transmit Data Generation in Lane 6
always @ (posedge mpcs_tx_usr_clk_i_6) begin
    if (~mpcs_tx_pcs_rstn_i_6) begin
        bus_data_l6 <= 32'd0;
        bus_control_l6 <= 4'd0;
        bus_sm_l6 <= BUS_IDL_L6;
        bus_data_mode_l6 <= 1'b0;
        bus_cnt_l6 <= 9'd0;
    end
    else begin
        case (bus_sm_l6)
            BUS_IDL_L6: 
            begin
                bus_data_l6 <= 32'd0;
                bus_control_l6 <= 4'd0;
                bus_sm_l6 <= BUS_STA_L6;
            end
            BUS_STA_L6: 
            begin
                if (~mpcs_get_lsync_o_6)
                    begin
                    bus_data_l6 <= {8'hAA, 8'hAA, 8'hAA, 8'hBC};
                    bus_control_l6 <= 4'b0001;
                    end 
                else
                    begin
                    bus_data_l6 <= mpcs_tx_ch_din_i_6_next;
                    bus_control_l6 <= 4'b0000;
                    end
            end
            default: begin
                bus_sm_l6 <= BUS_IDL_L6;
            end
        endcase
    end
end

// Transmit Data Generation in Lane 7
always @ (posedge mpcs_tx_usr_clk_i_7) begin
    if (~mpcs_tx_pcs_rstn_i_7) begin
        bus_data_l7 <= 32'd0;
        bus_control_l7 <= 4'd0;
        bus_sm_l7 <= BUS_IDL_L7;
        bus_data_mode_l7 <= 1'b0;
        bus_cnt_l7 <= 9'd0;
    end
    else begin
        case (bus_sm_l7)
            BUS_IDL_L7: 
            begin
                bus_data_l7 <= 32'd0;
                bus_control_l7 <= 4'd0;
                bus_sm_l7 <= BUS_STA_L7;
            end
            BUS_STA_L7: 
            begin
                if (~mpcs_get_lsync_o_7)
                    begin
                    bus_data_l7 <= {8'hAA, 8'hAA, 8'hAA, 8'hBC};
                    bus_control_l7 <= 4'b0001;
                    end 
                else
                    begin
                    bus_data_l7 <= mpcs_tx_ch_din_i_7_next;
                    bus_control_l7 <= 4'b0000;
                    end
            end
            default: begin
                bus_sm_l7 <= BUS_IDL_L7;
            end
        endcase
    end
end


//----------------------------------------------------------------------------
//--- Sample Mapping for Input Data Generation ---
//----------------------------------------------------------------------------
//--- User will need to provide the Data Checker for the selected Protocol ---
//----------------------------------------------------------------------------

always @ (posedge usr_clk_i or negedge reset_n) begin
 if (!reset_n) begin
  pcsdata <= {PCS_DWIDTH-1{1'b0}};
 end
 else begin
    if (MODESEL == 1) begin      //PMA+64b66b PCS
      pcsdata <= {tx_fifo_wr, 6'b0, tx_frcpkt, tx_control[7:0], 8'b0, $urandom_range({DWIDTH{1'b0}}, {DWIDTH{1'b1}})}; //inserted 8'b0 due to urandom_range limitation
    end
    else if (MODESEL == 0 && PCS_BYPASS == 0) begin //PMA+8b10b PCS
      pcsdata <= {28'b0, tx_frcdata[3:0], tx_dispval[3:0], tx_frcdisp[3:0], 8'b0, $urandom_range({DWIDTH{1'b0}}, {DWIDTH{1'b1}})}; //inserted 8'b0 due to urandom_range limitation
    end
     else if (MODESEL == 2) begin //PMA+PCIE-PCS
      pcsdata <= {$urandom_range({DWIDTH{1'b0}}, {DWIDTH{1'b1}})};
    end
    else begin                   //PMA only, MODESEL == 3  
      pcsdata <= {40'b0, 8'b0, $urandom_range({DWIDTH{1'b0}}, {DWIDTH{1'b1}})}; //inserted 8'b0 due to urandom_range limitation
    end
 end
end

generate
  if ((MODESEL == 0 || MODESEL == 1) && PCS_BYPASS == 0) begin //PMA+MPCS
     assign mpcs_tx_ch_din_i_7_next = pcsdata[PCS_DWIDTH-1:0];
     assign mpcs_tx_ch_din_i_6_next = pcsdata[PCS_DWIDTH-1:0];
     assign mpcs_tx_ch_din_i_5_next = pcsdata[PCS_DWIDTH-1:0];
     assign mpcs_tx_ch_din_i_4_next = pcsdata[PCS_DWIDTH-1:0];
     assign mpcs_tx_ch_din_i_3_next = pcsdata[PCS_DWIDTH-1:0];
     assign mpcs_tx_ch_din_i_2_next = pcsdata[PCS_DWIDTH-1:0];
     assign mpcs_tx_ch_din_i_1_next = pcsdata[PCS_DWIDTH-1:0];
     assign mpcs_tx_ch_din_i_0_next = pcsdata[PCS_DWIDTH-1:0];
  end 
  else if (MODESEL == 2) begin //PMA+PCIE-PCS 
     assign pipe_txdata_i_3 = pcsdata[PCS_DWIDTH-1:0];
     assign pipe_txdata_i_2 = pcsdata[PCS_DWIDTH-1:0];
     assign pipe_txdata_i_1 = pcsdata[PCS_DWIDTH-1:0];
     assign pipe_txdata_i_0 = pcsdata[PCS_DWIDTH-1:0];
  end
  else begin //PMA only, MODESEL == 3
     assign epcs_txdata_i_7 = pcsdata[PCS_DWIDTH-1:0];
     assign epcs_txdata_i_6 = pcsdata[PCS_DWIDTH-1:0];
     assign epcs_txdata_i_5 = pcsdata[PCS_DWIDTH-1:0];
     assign epcs_txdata_i_4 = pcsdata[PCS_DWIDTH-1:0];
     assign epcs_txdata_i_3 = pcsdata[PCS_DWIDTH-1:0];
     assign epcs_txdata_i_2 = pcsdata[PCS_DWIDTH-1:0];
     assign epcs_txdata_i_1 = pcsdata[PCS_DWIDTH-1:0];
     assign epcs_txdata_i_0 = pcsdata[PCS_DWIDTH-1:0];
  end
endgenerate  

//----------------------------------------------------------------------------
//--- END Input Data Generation ---
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------
//--- Tasks ---
//----------------------------------------------------------------------------
task register_check();
  reg [DATA_MSB:0]  wr_data;
  reg [DATA_MSB:0]  rd_data;
  begin
    $display("[%010t] [TEST]: READ Register default value check START!\n", $time);
    
    if (MODESEL == 0 && PCS_BYPASS == 0) begin //PCS-enabled/8B10B Path
          
        for (i=ITER_LSB; i < 491; i=i+1) begin
          if (reg_list[i][25:24] == 2'b11) begin
            u_tb_lmmi_mst.m_read(i[9:0], rd_data[DATA_MSB:0]);
            data_compare_reg(rd_data[DATA_MSB:0],{NUM_LANES{reg_list[i][7:0]}}, reg_names[i], i[9:0]);
          end
        end
                
        for (i=ITER_LSB; i < 491; i=i+1) begin
          if (reg_list[i][25:24] == 2'b01) begin
            u_tb_lmmi_mst.m_read(i[9:0], rd_data[DATA_MSB:0]);
            data_compare_reg(rd_data[DATA_MSB:0],{NUM_LANES{reg_list[i][7:0]}}, reg_names[i], i[9:0]);
          end
        end
            
    end 
    
    else if (MODESEL == 1) begin //PCS-enabled/64B66B Path
          
        for (i=ITER_LSB; i < 491; i=i+1) begin
          if (reg_list[i][25:24] == 2'b11) begin
            u_tb_lmmi_mst.m_read(i[9:0], rd_data[DATA_MSB:0]);
            data_compare_reg(rd_data[DATA_MSB:0],{NUM_LANES{reg_list[i][7:0]}}, reg_names[i], i[9:0]);
          end
        end
        
        for (i=384; i < 422; i=i+1) begin //180->1A5
        //  if (reg_list[i][25:24] == 2'b11) begin
            u_tb_lmmi_mst.m_read(i[9:0], rd_data[DATA_MSB:0]);
            data_compare_reg(rd_data[DATA_MSB:0],{NUM_LANES{reg_list[i][7:0]}}, reg_names[i], i[9:0]);
        //  end
        end
        
        for (i=448; i < 454; i=i+1) begin //1C0->1C5
        //  if (reg_list[i][25:24] == 2'b11) begin
            u_tb_lmmi_mst.m_read(i[9:0], rd_data[DATA_MSB:0]);
            data_compare_reg(rd_data[DATA_MSB:0],{NUM_LANES{reg_list[i][7:0]}}, reg_names[i], i[9:0]);
        //  end
        end
        
        for (i=ITER_LSB; i < 491; i=i+1) begin
          if (reg_list[i][25:24] == 2'b01) begin
            u_tb_lmmi_mst.m_read(i[9:0], rd_data[DATA_MSB:0]);
            data_compare_reg(rd_data[DATA_MSB:0],{NUM_LANES{reg_list[i][7:0]}}, reg_names[i], i[9:0]);
          end
        end
            
    end 
    
    else begin //(MODESEL == 3); PCS-bypassed
        for (i=ITER_LSB; i < ITER_MSB; i=i+1) begin 
           if (reg_list[i][25:24] != 2'b00) begin
             u_tb_lmmi_mst.m_read(i[9:0], rd_data[DATA_MSB:0]);
             data_compare_reg(rd_data[DATA_MSB:0],{NUM_LANES{reg_list[i][7:0]}}, reg_names[i], i[9:0]);
           end
        end
    end
    
    $display("\n[%010t] [TEST]: READ Register default value check DONE!\n", $time);
  end
endtask

 task data_compare_reg(
  input     [DATA_MSB:0]        act,
  input     [DATA_MSB:0]        exp,
  input reg [8*23:1]      reg_name,
  input     [9:0]         addr
);
  begin
    if (exp != act) begin
      error_count = error_count + 1;
      $error("[%010t] [reg_test]: Data compare error on %0s register (LMMI Addr=0x%03x). Actual (0x%02x) != Expected (0x%02x)!", $time, reg_name, addr, act, exp);
    end
    else begin
     $display("[%010t] [reg_test]: (LMMI Addr=0x%02x). Actual (0x%02x) == Expected (0x%02x)", $time, addr, act, exp);
    end
  end
endtask

function [7:0] get_exp_data(input [1:0] access,
                            input [7:0] wrbits, 
                            input [7:0] data,
                            input [7:0] def);
  begin
    if (access == 2'b10) // write-only
      get_exp_data = 8'h00;
    else if ((access == 2'b01) || (wrbits == 8'h00))
      get_exp_data = def;
    else
      get_exp_data = (wrbits & data) | (~wrbits & def);
  end
endfunction

task ready_check(input ready_o);
  begin
    if (ready_o) begin
          $display("\n[%010t] [TEST]: Calibration COMPLETED.\n", $time);
    end
    else begin
          error_count = error_count + 1;
          $error("[%010t] [TEST]: Calibration not completed. \n", $time);
    end
  end
endtask

task phyrdy_check(input phyrdy_o);
  begin
    if (phyrdy_o) begin
          $display("[%010t] [TEST]: PHY ready signal asserted and ready to transmit. \n", $time);
    end
    else begin
          error_count = error_count + 1;
          $error("[%010t] [TEST]: PHY ready signal is not asserting. \n", $time);
    end
  end
endtask

task pmastat_check();
  reg [DATA_MSB:0]  rd_data;
  begin
    $display("[%010t] [TEST]: Checking PMA Status for Valid RX data. \n", $time);
    for (i=454; i < 455; i=i+1) begin
      u_tb_lmmi_mst.m_read(i[9:0], rd_data[DATA_MSB:0]);
      data_compare_reg(rd_data[DATA_MSB:0],{NUM_LANES{reg_list[i][7:0]}}, reg_names[i], i[9:0]);
    end
    $display("\n[%010t] [TEST]: PMA Status Check DONE. \n", $time);
  end
endtask

//----------------------------------------------------------------------------
//--- END Tasks ---
//----------------------------------------------------------------------------
 
//--------------------------------------------------------------------------
//--- PCS Register Declarations ---
//--------------------------------------------------------------------------

//reg 003
localparam RX_IMPED_RATIO_REG = (RX_IMPED_RATIO == "0b10000000") ? 'd128 : 'd85;

//reg004
localparam TX_DIVMODE_0_REG    = (MODESEL == 3)    ? 0 : (TX_RX_DIVMODE_0-1);
localparam TXRX_F_A_REG        = (TX_RX_F_A > 1)   ? (TX_RX_F_A-1) : 0;

//reg005
localparam TXRX_M_A_REG        = (TX_RX_M_A == 2) ? 1 : 
                                 (TX_RX_M_A == 4) ? 2 : 
                                 (TX_RX_M_A == 8) ? 3 : 0;
localparam TXRX_N_A_REG        = (TX_RX_N_A-1);

//reg006
localparam RX_DIVMODE0_REG     = (TX_RX_DIVMODE_0 == 2) ? 2 :TX_RX_DIVMODE_0-1;

//reg009
localparam TX_IMPED_RATIO_REG = (TX_IMPED_RATIO == "0b10000000") ? 'd128 : 'd85;

//reg016
localparam TX_DIVMODE_1_REG    = (MODESEL == 2) ? 0 : (TX_RX_DIVMODE_1-1);
localparam TXRX_F_B_REG        = MULTIRATE ? ((TX_RX_F_B > 1)  ? (TX_RX_F_B-1) : 0) : 4;
localparam TXRX_M_B_REG        = MULTIRATE ? 
                                 ((TX_RX_M_B == 2) ? 1 : 
                                 (TX_RX_M_B == 4) ? 2 : 
                                 (TX_RX_M_B == 8) ? 3 : 0) : 1;
localparam TXRX_N_B_REG        = MULTIRATE ? (TX_RX_N_B-1) : 9;

//reg0b0
localparam TX_DIVMODE_2_REG    = (MODESEL == 2)   ? 0 : (TX_RX_DIVMODE_2-1);
localparam TXRX_F_C_REG        = MULTIRATE ? ((TX_RX_F_C > 1)  ? (TX_RX_F_C-1) : 0) : 4;
localparam TXRX_M_C_REG        = MULTIRATE ? 
                                 ((TX_RX_M_C == 2) ? 1 : 
                                 (TX_RX_M_C == 4) ? 2 : 
                                 (TX_RX_M_C == 8) ? 3 : 0) : 1;
localparam TXRX_N_C_REG        = MULTIRATE ? (TX_RX_N_C-1) : 9;

//reg0b2
localparam RX_DIVMODE2_REG     = (MODESEL != 3 && TX_RX_DIVMODE_2 == 4) ? "0b11" : 
                                 (MODESEL != 3 && TX_RX_DIVMODE_2 == 1) ? "0b00" : //bypass
                                 (MODESEL != 3 && TX_RX_DIVMODE_2 == 2) ? "0b10" : "0b00";                                  
//reg064
localparam LPBK_EN_REG   = (LOOPBACK_MODE == "Near_End_Serial_Loopback") ? 1'b1 : 1'b0 ; 

//reg074
localparam RX_POLINV_REG = (RX_POLINV == "NORMAL") ? 1'b0 : 1'b1 ;
localparam TX_POLINV_REG = (TX_POLINV == "NORMAL") ? 1'b0 : 1'b1 ;
localparam MESO_LPBK_REG = (LOOPBACK_MODE == "Far_End_Serial_Loopback") ? 1'b1 : 1'b0 ; 

//reg0D1 -- Preliminary Phase
localparam GEN3_ENA_PRE_REG = (GEN3_ENA_PREA0 == "DISABLED") ? 1'b0 : 1'b1 ;
localparam GEN12_ENA_PRE_REG = (GEN12_ENA_PREA0 == "DISABLED") ? 1'b0 : 1'b1 ;

//reg0D3 -- Post Phase
localparam GEN3_ENA_POST_A0_REG = (GEN3_ENA_POST_A0 == "DISABLED") ? 1'b0 : 1'b1 ;
localparam GEN12_ENA_POST_A0_REG = (GEN12_ENA_POST_A0 == "DISABLED") ? 1'b0 : 1'b1 ;

//reg0D5 -- Training Phase
localparam GEN3_ENA_POST_A1A2_REG = (GEN3_ENA_POST_A1A2 == "DISABLED") ? 1'b0 : 1'b1 ;
localparam GEN12_ENA_POST_A1A2_REG = (GEN12_ENA_POST_A1A2 == "DISABLED") ? 1'b0 : 1'b1 ;

//reg110                         
localparam TX_DBUS_20_REG     = (BUS_WIDTH == 10)            ? 1'b0 : 1'b1;
localparam ENC_8B10B_DIS_REG  = (ENC_8B10B_DIS == "ENABLED") ? 1'b0 : 1'b1;
localparam TX_PMFIFO_DIS_REG  = (TX_PMFIFO_DIS == "ENABLED") ? 1'b0 : 1'b1;
localparam TX_FIFO_DIS_REG    = (TX_FIFO_DIS == "ENABLED")   ? 1'b0 : 1'b1;
localparam GEAR_EN_REG        = (GEAR_EN == "DISABLED")      ? 1'b0 : 1'b1;

//reg111, reg 122 
localparam ENC_DEC_8B10B_INTERLEAVE = (PROTOCOL == "RXAUI") ? 1'b1 : 1'b0;

//reg120                         
localparam RFIFO_COM_ALIGN_REG = (RFIFO_COM_ALIGN == "DISABLED")? 1'b0 : 1'b1;
localparam RX_DBUS_20_REG      = (BUS_WIDTH == 10)              ? 1'b0 : 1'b1;
localparam DEC_8B10B_DIS_REG   = (DEC_8B10B_DIS == "ENABLED")   ? 1'b0 : 1'b1;
localparam RX_FIFO_DIS_REG     = (RX_FIFO_DIS == "ENABLED")     ? 1'b0 : 1'b1;

//reg130
localparam WA_DIS_REG          = (WA_DIS == "ENABLED")         ? 1'b0 : 1'b1;
localparam ALIGN_2BYTE_DIS_REG = (ALIGN_2BYTE_DIS == "ENABLED")? 1'b0 : 1'b1;
localparam SEC_WAPTN_DIS_REG   = (SEC_WAPTN_DIS == "ENABLED")  ? 1'b0 : 1'b1;
localparam WA_PTN_20B_REG      = (WA_PTN_20B == "10BIT_WIDTH") ? 1'b0 : 1'b1;
localparam SYNCDET_FSM_DIS_REG = (SYNCDET_FSM_DIS == "ENABLED")? 1'b0 : 1'b1;
localparam AUTO_WA_DIS_REG     = (AUTO_WA_DIS == "ENABLED")    ? 1'b0 : 1'b1;

//reg 13d
localparam SEC_SYNC_PTN_DIS_REG = (SEC_SYNC_PTN_DIS == "ENABLED") ? 1'b0 : 1'b1;
localparam SYNC_PTN_10B_REG     = (SYNC_PTN_10B == "8B_CODE")     ? 1'b0 : 1'b1;
localparam SYNC_PTN_ALIGN_REG   = (SYNC_PTN_ALIGN == "DISABLED")  ? 1'b0 : 1'b1;
localparam SYNC_PTN_LEN_REG     = (SYNC_PTN_LEN == "1")           ? 2'b00 : 
                                  (SYNC_PTN_LEN == "2")           ? 2'b01 : 2'b10;

//reg150
localparam SEC_LAPTN_EN_REG    = (SEC_LAPTN_EN == "DISABLED")  ? 1'b0  : 1'b1;
localparam LALIGN_EN_REG       = (LALIGN_EN == "DISABLED")     ? 1'b0  : 1'b1;
localparam LALIGN_10B_REG      = (LALIGN_10B == "8B_CODE")     ? 1'b0  : 1'b1;
localparam LALIGN_PTN_LEN_REG  = (LALIGN_PTN_LEN == "1_BYTE")  ? 2'b00 : 
                                 (LALIGN_PTN_LEN == "2_BYTE")  ? 2'b01 : 2'b10;

//reg151
localparam MAX_LSKEW_REG  = (MAX_LSKEW == "1_BYTE_SKEW")  ? 4'b0001 : 
                            (MAX_LSKEW == "2_BYTE_SKEW")  ? 4'b0010 :
                            (MAX_LSKEW == "3_BYTE_SKEW")  ? 4'b0011 :
                            (MAX_LSKEW == "4_BYTE_SKEW")  ? 4'b0100 :
                            (MAX_LSKEW == "5_BYTE_SKEW")  ? 4'b0101 :
                            (MAX_LSKEW == "6_BYTE_SKEW")  ? 4'b0110 :
                            (MAX_LSKEW == "7_BYTE_SKEW")  ? 4'b0111 :
                            (MAX_LSKEW == "8_BYTE_SKEW")  ? 4'b1000 :
                            (MAX_LSKEW == "9_BYTE_SKEW")  ? 4'b1001 :
                            (MAX_LSKEW == "10_BYTE_SKEW") ? 4'b1010 : 4'b0000;
//reg15c
localparam LALIGN_MASK_CODE_REG = (LALIGN_MASK_CODE == "0b0000") ? 4'b0000 :
                                  (LALIGN_MASK_CODE == "0b0001") ? 4'b0001 :
                                  (LALIGN_MASK_CODE == "0b0010") ? 4'b0010 :
                                  (LALIGN_MASK_CODE == "0b0011") ? 4'b0011 :
                                  (LALIGN_MASK_CODE == "0b0100") ? 4'b0100 :
                                  (LALIGN_MASK_CODE == "0b0101") ? 4'b0101 :
                                  (LALIGN_MASK_CODE == "0b0110") ? 4'b0110 :
                                  (LALIGN_MASK_CODE == "0b0111") ? 4'b0111 :
                                  (LALIGN_MASK_CODE == "0b1000") ? 4'b1000 :
                                  (LALIGN_MASK_CODE == "0b1001") ? 4'b1001 :
                                  (LALIGN_MASK_CODE == "0b1010") ? 4'b1010 :
                                  (LALIGN_MASK_CODE == "0b1011") ? 4'b1011 :
                                  (LALIGN_MASK_CODE == "0b1100") ? 4'b1100 :
                                  (LALIGN_MASK_CODE == "0b1101") ? 4'b1101 :
                                  (LALIGN_MASK_CODE == "0b1110") ? 4'b1110 : 4'b1111;
//reg160
localparam SEC_SKIP_EN_REG     = (SEC_SKIP_EN == "DISABLED") ? 1'b0  : 1'b1;
localparam SKIP_PTN_LEN_REG    = (SKIP_PTN_LEN == "1_BYTE")  ? 2'b00 : 
                                 (SKIP_PTN_LEN == "2_BYTE")  ? 2'b01 : 2'b10;
localparam CTC_FIFO_EN_REG     = (CTC_FIFO_EN == "DISABLED") ? 1'b0  : 1'b1;
localparam CLK_COMP_10B_REG    = (CLK_COMP_10B == "8B_CODE") ? 1'b0  : 1'b1;
localparam CLK_COMP_EN_REG     = (CLK_COMP_EN == "DISABLED") ? 1'b0  : 1'b1;

//reg16e
localparam SKP_MASK_CODE_REG  = (SKP_MASK_CODE == "0b0000") ? 4'b0000 :
                                (SKP_MASK_CODE == "0b0001") ? 4'b0001 :
                                (SKP_MASK_CODE == "0b0010") ? 4'b0010 :
                                (SKP_MASK_CODE == "0b0011") ? 4'b0011 :
                                (SKP_MASK_CODE == "0b0100") ? 4'b0100 :
                                (SKP_MASK_CODE == "0b0101") ? 4'b0101 :
                                (SKP_MASK_CODE == "0b0110") ? 4'b0110 :
                                (SKP_MASK_CODE == "0b0111") ? 4'b0111 :
                                (SKP_MASK_CODE == "0b1000") ? 4'b1000 :
                                (SKP_MASK_CODE == "0b1001") ? 4'b1001 :
                                (SKP_MASK_CODE == "0b1010") ? 4'b1010 :
                                (SKP_MASK_CODE == "0b1011") ? 4'b1011 :
                                (SKP_MASK_CODE == "0b1100") ? 4'b1100 :
                                (SKP_MASK_CODE == "0b1101") ? 4'b1101 :
                                (SKP_MASK_CODE == "0b1110") ? 4'b1110 : 4'b1111;
//reg180
localparam END_64B66B_DIS_REG  = (END_64B66B_DIS == "ENABLED") ? 1'b0  : 1'b1;
localparam SRC_64B66B_DIS_REG  = (SRC_64B66B_DIS == "ENABLED") ? 1'b0  : 1'b1;

//reg183
localparam PCS_64B66B_NOFPLL_REG  = (PCS_64B66B_NOFPLL == "ENABLED") ? 1'b1  : 1'b0;
localparam BALIGN_64B66B_DIS_REG  = (BALIGN_64B66B_DIS == "ENABLED") ? 1'b0  : 1'b1;
localparam CTC_64B66B_DIS_REG     = (CTC_64B66B_DIS == "ENABLED")    ? 1'b0  : 1'b1;
localparam DEC_64B66B_DIS_REG     = (DEC_64B66B_DIS == "ENABLED")    ? 1'b0  : 1'b1;
localparam DESCR_64B66B_DIS_REG   = (DESCR_64B66B_DIS == "ENABLED")  ? 1'b0  : 1'b1;

//reg1e0
localparam NEAR_LP_EN_REG   = (LOOPBACK_MODE == "Near_End_Parallel_Loopback") ? 1'b1  : 1'b0;
localparam FAR_LP_EN_REG    = (LOOPBACK_MODE == "Far_End_Parallel_Loopback")  ? 1'b1  : 1'b0;

//----END


generate
if (MODESEL != 1) begin
  assign lmmi_rdata_o_w = {lmmi_rdata_o_7, lmmi_rdata_o_6, lmmi_rdata_o_5, lmmi_rdata_o_4, lmmi_rdata_o_3, lmmi_rdata_o_2, lmmi_rdata_o_1, lmmi_rdata_o_0};
  assign lmmi_rdata_valid_o_w = {lmmi_rdata_valid_o_7, lmmi_rdata_valid_o_6, lmmi_rdata_valid_o_5, lmmi_rdata_valid_o_4, lmmi_rdata_valid_o_3, lmmi_rdata_valid_o_2, lmmi_rdata_valid_o_1, lmmi_rdata_valid_o_0};
  assign lmmi_ready_o_w = {lmmi_ready_o_7, lmmi_ready_o_6, lmmi_ready_o_5, lmmi_ready_o_4, lmmi_ready_o_3, lmmi_ready_o_2, lmmi_ready_o_1, lmmi_ready_o_0};
end
endgenerate

//10GE Case
generate
if (MODESEL == 1 && NUM_LANES == 1) begin
  assign lmmi_rdata_o_w = lmmi_rdata_o_0;
  assign lmmi_rdata_valid_o_w = lmmi_rdata_valid_o_0;
  assign lmmi_ready_o_w =  lmmi_ready_o_0;
end
endgenerate

generate
if (MODESEL == 1 && (NUM_LANES == 2 || NUM_LANES == 4)) begin
  assign lmmi_rdata_o_w = {lmmi_rdata_o_7, lmmi_rdata_o_6, lmmi_rdata_o_3, lmmi_rdata_o_2};
  assign lmmi_rdata_valid_o_w = {lmmi_rdata_valid_o_7, lmmi_rdata_valid_o_6, lmmi_rdata_valid_o_3, lmmi_rdata_valid_o_2};
  assign lmmi_ready_o_w = {lmmi_ready_o_7, lmmi_ready_o_6, lmmi_ready_o_3, lmmi_ready_o_2};
end
endgenerate
            
//--------------------------------------------------------------------------
//--- Module Instantiation ---
//--------------------------------------------------------------------------
`include "dut_inst.v"

GSR GSR_INST (.GSR_N(reset_n), .CLK(mpcs_clk));

tb_lmmi_mst #
(
 // Parameters
 .MODESEL                               (MODESEL),
 .PCS_BYPASS                            (PCS_BYPASS))
u_tb_lmmi_mst
(/*AUTOINST*/
 // Inputs
 .lmmi_rdata                            (lmmi_rdata_o_w),               // Templated
 .lmmi_rdata_valid                      (lmmi_rdata_valid_o_w),         // Templated
 .lmmi_ready                            (lmmi_ready_o_w),               // Templated
 .lmmi_error                            (1'b0),                         // Templated
 // Outputs
 .lmmi_clk                              (lmmi_clk_i_0),                 // Templated
 .lmmi_resetn                           (lmmi_resetn_i_0),              // Templated
 .lmmi_offset                           (lmmi_offset_i_0),              // Templated
 .lmmi_request                          (lmmi_request_i_0),             // Templated
 .lmmi_wdata                            (lmmi_wdata_i_0),               // Templated
 .lmmi_wr_rdn                           (lmmi_wr_rdn_i_0));             // Templated
 
//--------------------------------------------------------------------------
//--- Register Checker ---
//--------------------------------------------------------------------------

//               register_name                = HEX_ADDR //Decimal_EQ
// ------------------ PCIE-PCS+PMA registers -------------------//
localparam [8:0] PCS_REG_00                   = 9'h000;  //00
localparam [8:0] PCS_REG_01                   = 9'h001;  //01
localparam [8:0] PCS_REG_02                   = 9'h002;  //02
localparam [8:0] PCS_REG_03                   = 9'h003;  //03
localparam [8:0] PCS_REG_04                   = 9'h004;  //04 
localparam [8:0] PCS_REG_05                   = 9'h005;  //05 
localparam [8:0] PCS_REG_06                   = 9'h006;  //06 
localparam [8:0] PCS_REG_07                   = 9'h007;  //07 
localparam [8:0] PCS_REG_08                   = 9'h008;  //08
localparam [8:0] PCS_REG_09                   = 9'h009;  //09
localparam [8:0] PCS_REG_10                   = 9'h00a;  //10
localparam [8:0] PCS_REG_11                   = 9'h00b;  //11
localparam [8:0] PCS_REG_12                   = 9'h00c;  //12
localparam [8:0] PCS_REG_13                   = 9'h00d;  //13
localparam [8:0] PCS_REG_14                   = 9'h00e;  //14
localparam [8:0] PCS_REG_15                   = 9'h00f;  //15
localparam [8:0] PCS_REG_16                   = 9'h010;  //16
localparam [8:0] PCS_REG_17                   = 9'h011;  //17
localparam [8:0] PCS_REG_18                   = 9'h012;  //18
localparam [8:0] PCS_REG_19                   = 9'h013;  //19
localparam [8:0] PCS_REG_20                   = 9'h014;  //20
localparam [8:0] PCS_REG_21                   = 9'h015;  //21
localparam [8:0] PCS_REG_22                   = 9'h016;  //22
localparam [8:0] PCS_REG_23                   = 9'h017;  //23
localparam [8:0] PCS_REG_24                   = 9'h018;  //24
localparam [8:0] PCS_REG_25                   = 9'h019;  //25
localparam [8:0] PCS_REG_26                   = 9'h01a;  //26
localparam [8:0] PCS_REG_27                   = 9'h01b;  //27
localparam [8:0] PCS_REG_28                   = 9'h01c;  //28
localparam [8:0] PCS_REG_29                   = 9'h01d;  //29
localparam [8:0] PCS_REG_30                   = 9'h01e;  //30
localparam [8:0] PCS_REG_31                   = 9'h01f;  //31
localparam [8:0] PCS_REG_32                   = 9'h020;  //32
localparam [8:0] PCS_REG_33                   = 9'h021;  //33
localparam [8:0] PCS_REG_34                   = 9'h022;  //34
localparam [8:0] PCS_REG_35                   = 9'h023;  //35
localparam [8:0] PCS_REG_36                   = 9'h024;  //36
localparam [8:0] PCS_REG_37                   = 9'h025;  //37
localparam [8:0] PCS_REG_38                   = 9'h026;  //38
localparam [8:0] PCS_REG_39                   = 9'h027;  //39
localparam [8:0] PCS_REG_40                   = 9'h028;  //40
localparam [8:0] PCS_REG_41                   = 9'h029;  //41
localparam [8:0] PCS_REG_42                   = 9'h02a;  //42
localparam [8:0] PCS_REG_43                   = 9'h02b;  //43
localparam [8:0] PCS_REG_44                   = 9'h02c;  //44
localparam [8:0] PCS_REG_45                   = 9'h02d;  //45
localparam [8:0] PCS_REG_46                   = 9'h02e;  //46
localparam [8:0] PCS_REG_47                   = 9'h02f;  //47
localparam [8:0] PCS_REG_48                   = 9'h030;  //48
localparam [8:0] PCS_REG_49                   = 9'h031;  //49
localparam [8:0] PCS_REG_50                   = 9'h032;  //50
localparam [8:0] PCS_REG_51                   = 9'h033;  //51
localparam [8:0] PCS_REG_52                   = 9'h034;  //52
localparam [8:0] PCS_REG_53                   = 9'h035;  //53
localparam [8:0] PCS_REG_54                   = 9'h036;  //54
localparam [8:0] PCS_REG_55                   = 9'h037;  //55
localparam [8:0] PCS_REG_56                   = 9'h038;  //56
localparam [8:0] PCS_REG_57                   = 9'h039;  //57
localparam [8:0] PCS_REG_58                   = 9'h03a;  //58
localparam [8:0] PCS_REG_59                   = 9'h03b;  //59
localparam [8:0] PCS_REG_60                   = 9'h03c;  //60
localparam [8:0] PCS_REG_61                   = 9'h03d;  //61
localparam [8:0] PCS_REG_62                   = 9'h03e;  //62
localparam [8:0] PCS_REG_63                   = 9'h03f;  //63
localparam [8:0] PCS_REG_64                   = 9'h040;  //64
localparam [8:0] PCS_REG_65                   = 9'h041;  //65
localparam [8:0] PCS_REG_66                   = 9'h042;  //66
localparam [8:0] PCS_REG_67                   = 9'h043;  //67
localparam [8:0] PCS_REG_68                   = 9'h044;  //68
localparam [8:0] PCS_REG_69                   = 9'h045;  //69
localparam [8:0] PCS_REG_70                   = 9'h046;  //70
localparam [8:0] PCS_REG_71                   = 9'h047;  //71
localparam [8:0] PCS_REG_72                   = 9'h048;  //72
localparam [8:0] PCS_REG_73                   = 9'h049;  //73
localparam [8:0] PCS_REG_74                   = 9'h04a;  //74
localparam [8:0] PCS_REG_75                   = 9'h04b;  //75
localparam [8:0] PCS_REG_76                   = 9'h04c;  //76
localparam [8:0] PCS_REG_77                   = 9'h04d;  //77
localparam [8:0] PCS_REG_78                   = 9'h04e;  //78
localparam [8:0] PCS_REG_79                   = 9'h04f;  //79
localparam [8:0] PCS_REG_80                   = 9'h050;  //80
localparam [8:0] PCS_REG_81                   = 9'h051;  //81 
localparam [8:0] PCS_REG_82                   = 9'h052;  //82 
localparam [8:0] PCS_REG_83                   = 9'h053;  //83 
localparam [8:0] PCS_REG_84                   = 9'h054;  //84 
localparam [8:0] PCS_REG_85                   = 9'h055;  //85 
localparam [8:0] PCS_REG_86                   = 9'h056;  //86 
localparam [8:0] PCS_REG_87                   = 9'h057;  //87 
localparam [8:0] PCS_REG_88                   = 9'h058;  //88 
localparam [8:0] PCS_REG_89                   = 9'h059;  //89 
localparam [8:0] PCS_REG_90                   = 9'h05a;  //90 
localparam [8:0] PCS_REG_91                   = 9'h05b;  //91 
localparam [8:0] PCS_REG_92                   = 9'h05c;  //92 
localparam [8:0] PCS_REG_93                   = 9'h05d;  //93 
localparam [8:0] PCS_REG_94                   = 9'h05e;  //94 
localparam [8:0] PCS_REG_95                   = 9'h05f;  //95 
localparam [8:0] PCS_REG_96                   = 9'h060;  //96 
localparam [8:0] PCS_REG_97                   = 9'h061;  //97 
localparam [8:0] PCS_REG_98                   = 9'h062;  //98 
localparam [8:0] PCS_REG_99                   = 9'h063;  //99 
localparam [8:0] PCS_REG_100                  = 9'h064;  //100
localparam [8:0] PCS_REG_101                  = 9'h065;  //101
localparam [8:0] PCS_REG_102                  = 9'h066;  //102
localparam [8:0] PCS_REG_103                  = 9'h067;  //103
localparam [8:0] PCS_REG_104                  = 9'h068;  //104
localparam [8:0] PCS_REG_105                  = 9'h069;  //105
localparam [8:0] PCS_REG_106                  = 9'h06a;  //106
localparam [8:0] PCS_REG_107                  = 9'h06b;  //107
localparam [8:0] PCS_REG_108                  = 9'h06c;  //108
localparam [8:0] PCS_REG_109                  = 9'h06d;  //109
localparam [8:0] PCS_REG_110                  = 9'h06e;  //110
localparam [8:0] PCS_REG_111                  = 9'h06f;  //111
localparam [8:0] PCS_REG_112                  = 9'h070;  //112
localparam [8:0] PCS_REG_113                  = 9'h071;  //113
localparam [8:0] PCS_REG_114                  = 9'h072;  //114
localparam [8:0] PCS_REG_115                  = 9'h073;  //115
localparam [8:0] PCS_REG_116                  = 9'h074;  //116 -TX_POLINV, RX_POLINV
localparam [8:0] PCS_REG_117                  = 9'h075;  //117
localparam [8:0] PCS_REG_118                  = 9'h076;  //118
localparam [8:0] PCS_REG_119                  = 9'h077;  //119
localparam [8:0] PCS_REG_120                  = 9'h078;  //120
localparam [8:0] PCS_REG_121                  = 9'h079;  //121
localparam [8:0] PCS_REG_122                  = 9'h07a;  //122
localparam [8:0] PCS_REG_123                  = 9'h07b;  //123
localparam [8:0] PCS_REG_124                  = 9'h07c;  //124
localparam [8:0] PCS_REG_125                  = 9'h07d;  //125
localparam [8:0] PCS_REG_126                  = 9'h07e;  //126
localparam [8:0] PCS_REG_127                  = 9'h07f;  //127
localparam [8:0] PCS_REG_128                  = 9'h080;  //128
localparam [8:0] PCS_REG_129                  = 9'h081;  //129
localparam [8:0] PCS_REG_130                  = 9'h082;  //130
localparam [8:0] PCS_REG_131                  = 9'h083;  //131
localparam [8:0] PCS_REG_132                  = 9'h084;  //132
localparam [8:0] PCS_REG_133                  = 9'h085;  //133
localparam [8:0] PCS_REG_134                  = 9'h086;  //134
localparam [8:0] PCS_REG_135                  = 9'h087;  //135
localparam [8:0] PCS_REG_136                  = 9'h088;  //136
localparam [8:0] PCS_REG_137                  = 9'h089;  //137
localparam [8:0] PCS_REG_138                  = 9'h08a;  //138
localparam [8:0] PCS_REG_139                  = 9'h08b;  //139
localparam [8:0] PCS_REG_140                  = 9'h08c;  //140
localparam [8:0] PCS_REG_141                  = 9'h08d;  //141
localparam [8:0] PCS_REG_142                  = 9'h08e;  //142
localparam [8:0] PCS_REG_143                  = 9'h08f;  //143
localparam [8:0] PCS_REG_144                  = 9'h090;  //144
localparam [8:0] PCS_REG_145                  = 9'h091;  //145
localparam [8:0] PCS_REG_146                  = 9'h092;  //146
localparam [8:0] PCS_REG_147                  = 9'h093;  //147
localparam [8:0] PCS_REG_148                  = 9'h094;  //148
localparam [8:0] PCS_REG_149                  = 9'h095;  //149
localparam [8:0] PCS_REG_150                  = 9'h096;  //150
localparam [8:0] PCS_REG_151                  = 9'h097;  //151
localparam [8:0] PCS_REG_152                  = 9'h098;  //152
localparam [8:0] PCS_REG_153                  = 9'h099;  //153
localparam [8:0] PCS_REG_154                  = 9'h09a;  //154
localparam [8:0] PCS_REG_155                  = 9'h09b;  //155
localparam [8:0] PCS_REG_156                  = 9'h09c;  //156
localparam [8:0] PCS_REG_157                  = 9'h09d;  //157
localparam [8:0] PCS_REG_158                  = 9'h09e;  //158
localparam [8:0] PCS_REG_159                  = 9'h09f;  //159
localparam [8:0] PCS_REG_160                  = 9'h0a0;  //160
localparam [8:0] PCS_REG_161                  = 9'h0a1;  //161
localparam [8:0] PCS_REG_162                  = 9'h0a2;  //162
localparam [8:0] PCS_REG_163                  = 9'h0a3;  //163
localparam [8:0] PCS_REG_164                  = 9'h0a4;  //164
localparam [8:0] PCS_REG_165                  = 9'h0a5;  //165
localparam [8:0] PCS_REG_166                  = 9'h0a6;  //166
localparam [8:0] PCS_REG_167                  = 9'h0a7;  //167
localparam [8:0] PCS_REG_168                  = 9'h0a8;  //168
localparam [8:0] PCS_REG_169                  = 9'h0a9;  //169
localparam [8:0] PCS_REG_170                  = 9'h0aa;  //170
localparam [8:0] PCS_REG_171                  = 9'h0ab;  //171
localparam [8:0] PCS_REG_172                  = 9'h0ac;  //172
localparam [8:0] PCS_REG_173                  = 9'h0ad;  //173
localparam [8:0] PCS_REG_174                  = 9'h0ae;  //174
localparam [8:0] PCS_REG_175                  = 9'h0af;  //175
localparam [8:0] PCS_REG_176                  = 9'h0b0;  //176
localparam [8:0] PCS_REG_177                  = 9'h0b1;  //177
localparam [8:0] PCS_REG_178                  = 9'h0b2;  //178
localparam [8:0] PCS_REG_179                  = 9'h0b3;  //179
localparam [8:0] PCS_REG_180                  = 9'h0b4;  //180
localparam [8:0] PCS_REG_181                  = 9'h0b5;  //181
localparam [8:0] PCS_REG_182                  = 9'h0b6;  //182
localparam [8:0] PCS_REG_183                  = 9'h0b7;  //183
localparam [8:0] PCS_REG_184                  = 9'h0b8;  //184
localparam [8:0] PCS_REG_185                  = 9'h0b9;  //185
localparam [8:0] PCS_REG_186                  = 9'h0ba;  //186
localparam [8:0] PCS_REG_187                  = 9'h0bb;  //187
localparam [8:0] PCS_REG_188                  = 9'h0bc;  //188
localparam [8:0] PCS_REG_189                  = 9'h0bd;  //189
localparam [8:0] PCS_REG_190                  = 9'h0be;  //190
localparam [8:0] PCS_REG_191                  = 9'h0bf;  //191
localparam [8:0] PCS_REG_192                  = 9'h0c0;  //192
localparam [8:0] PCS_REG_193                  = 9'h0c1;  //193
localparam [8:0] PCS_REG_194                  = 9'h0c2;  //194
localparam [8:0] PCS_REG_195                  = 9'h0c3;  //195
localparam [8:0] PCS_REG_196                  = 9'h0c4;  //196
localparam [8:0] PCS_REG_197                  = 9'h0c5;  //197
localparam [8:0] PCS_REG_198                  = 9'h0c6;  //198
localparam [8:0] PCS_REG_199                  = 9'h0c7;  //199
localparam [8:0] PCS_REG_200                  = 9'h0c8;  //200
localparam [8:0] PCS_REG_201                  = 9'h0c9;  //201
localparam [8:0] PCS_REG_202                  = 9'h0ca;  //202
localparam [8:0] PCS_REG_203                  = 9'h0cb;  //203
localparam [8:0] PCS_REG_204                  = 9'h0cc;  //204
localparam [8:0] PCS_REG_205                  = 9'h0cd;  //205
localparam [8:0] PCS_REG_206                  = 9'h0ce;  //206
localparam [8:0] PCS_REG_207                  = 9'h0cf;  //207
localparam [8:0] PCS_REG_208                  = 9'h0d0;  //208
localparam [8:0] PCS_REG_209                  = 9'h0d1;  //209
localparam [8:0] PCS_REG_210                  = 9'h0d2;  //210
localparam [8:0] PCS_REG_211                  = 9'h0d3;  //211
localparam [8:0] PCS_REG_212                  = 9'h0d4;  //212
localparam [8:0] PCS_REG_213                  = 9'h0d5;  //213
localparam [8:0] PCS_REG_214                  = 9'h0d6;  //214
localparam [8:0] PCS_REG_215                  = 9'h0d7;  //215
localparam [8:0] PCS_REG_216                  = 9'h0d8;  //216
localparam [8:0] PCS_REG_217                  = 9'h0d9;  //217
localparam [8:0] PCS_REG_218                  = 9'h0da;  //218
localparam [8:0] PCS_REG_219                  = 9'h0db;  //219
localparam [8:0] PCS_REG_220                  = 9'h0dc;  //220
localparam [8:0] PCS_REG_221                  = 9'h0dd;  //221
localparam [8:0] PCS_REG_222                  = 9'h0de;  //222
localparam [8:0] PCS_REG_223                  = 9'h0df;  //223
localparam [8:0] PCS_REG_224                  = 9'h0e0;  //224
localparam [8:0] PCS_REG_225                  = 9'h0e1;  //225
localparam [8:0] PCS_REG_226                  = 9'h0e2;  //226
localparam [8:0] PCS_REG_227                  = 9'h0e3;  //227
localparam [8:0] PCS_REG_228                  = 9'h0e4;  //228
localparam [8:0] PCS_REG_229                  = 9'h0e5;  //229
localparam [8:0] PCS_REG_230                  = 9'h0e6;  //230
localparam [8:0] PCS_REG_231                  = 9'h0e7;  //231
localparam [8:0] PCS_REG_232                  = 9'h0e8;  //232
localparam [8:0] PCS_REG_233                  = 9'h0e9;  //233
localparam [8:0] PCS_REG_234                  = 9'h0ea;  //234
localparam [8:0] PCS_REG_235                  = 9'h0eb;  //235
localparam [8:0] PCS_REG_236                  = 9'h0ec;  //236
localparam [8:0] PCS_REG_237                  = 9'h0ed;  //237
localparam [8:0] PCS_REG_238                  = 9'h0ee;  //238
localparam [8:0] PCS_REG_239                  = 9'h0ef;  //239
localparam [8:0] PCS_REG_240                  = 9'h0f0;  //240
localparam [8:0] PCS_REG_241                  = 9'h0f1;  //241
localparam [8:0] PCS_REG_242                  = 9'h0f2;  //242
localparam [8:0] PCS_REG_243                  = 9'h0f3;  //243
localparam [8:0] PCS_REG_244                  = 9'h0f4;  //244
localparam [8:0] PCS_REG_245                  = 9'h0f5;  //245
localparam [8:0] PCS_REG_246                  = 9'h0f6;  //246
localparam [8:0] PCS_REG_247                  = 9'h0f7;  //247
localparam [8:0] PCS_REG_248                  = 9'h0f8;  //248
localparam [8:0] PCS_REG_249                  = 9'h0f9;  //249
localparam [8:0] PCS_REG_250                  = 9'h0fa;  //250
localparam [8:0] PCS_REG_251                  = 9'h0fb;  //251
localparam [8:0] PCS_REG_252                  = 9'h0fc;  //252
localparam [8:0] PCS_REG_253                  = 9'h0fd;  //253
localparam [8:0] PCS_REG_254                  = 9'h0fe;  //254
localparam [8:0] PCS_REG_255                  = 9'h0ff;  //255
                                                     
// -------------------- MPCS registers -------------------------//
localparam [8:0] DATA_PATH_SEL_ADDR           = 9'h100;  //256
localparam [8:0] TX_PATH_CTRL_ADDR            = 9'h110;  //272
localparam [8:0] ENC_8B10B_CTRL_ADDR          = 9'h111;  //273
localparam [8:0] RX_PATH_CTRL_ADDR            = 9'h120;  //288
localparam [8:0] RX_PATH_STATUS_ADDR          = 9'h121;  //289
localparam [8:0] DEC_8B10B_CTRL_ADDR          = 9'h122;  //290
localparam [8:0] WA_CTRL_ADDR                 = 9'h130;  //304
localparam [8:0] PRI_WA_PTN_BYTE0_ADDR        = 9'h131;  //305
localparam [8:0] PRI_WA_PTN_BYTE1_ADDR        = 9'h132;  //306
localparam [8:0] PRI_WA_PTN_MSB_ADDR          = 9'h133;  //307
localparam [8:0] SEC_WA_PTN_BYTE0_ADDR        = 9'h134;  //308
localparam [8:0] SEC_WA_PTN_BYTE1_ADDR        = 9'h135;  //309
localparam [8:0] SEC_WA_PTN_MSB_ADDR          = 9'h136;  //310
localparam [8:0] WA_PTN_MASK_BYTE0_ADDR       = 9'h137;  //311
localparam [8:0] WA_PTN_MASK_BYTE1_ADDR       = 9'h138;  //312
localparam [8:0] WA_PTN_MASK_MSB_ADDR         = 9'h139;  //313
localparam [8:0] SYNC_FSM_CFG0_ADDR           = 9'h13a;  //314
localparam [8:0] SYNC_FSM_CFG1_ADDR           = 9'h13b;  //315
localparam [8:0] SYNC_FSM_CFG2_ADDR           = 9'h13c;  //316
localparam [8:0] SYNC_FSM_CFG3_ADDR           = 9'h13d;  //317
localparam [8:0] WA_SLIP_BIT_ADDR             = 9'h13e;  //318
localparam [8:0] PRI_SYNC_DET_PTN_BYTE0_ADDR  = 9'h13f;  //319
localparam [8:0] PRI_SYNC_DET_PTN_BYTE1_ADDR  = 9'h140;  //320
localparam [8:0] PRI_SYNC_DET_PTN_BYTE2_ADDR  = 9'h141;  //321
localparam [8:0] PRI_SYNC_DET_PTN_BYTE3_ADDR  = 9'h142;  //322
localparam [8:0] PRI_SYNC_DET_PTN_MSB_ADDR    = 9'h143;  //323
localparam [8:0] SEC_SYNC_DET_PTN_BYTE0_ADDR  = 9'h144;  //324
localparam [8:0] SEC_SYNC_DET_PTN_BYTE1_ADDR  = 9'h145;  //325
localparam [8:0] SEC_SYNC_DET_PTN_BYTE2_ADDR  = 9'h146;  //326
localparam [8:0] SEC_SYNC_DET_PTN_BYTE3_ADDR  = 9'h147;  //327
localparam [8:0] SEC_SYNC_DET_PTN_MSB_ADDR    = 9'h148;  //328
localparam [8:0] SYNC_DET_PTN_MASK_BYTE0_ADDR = 9'h149;  //329
localparam [8:0] SYNC_DET_PTN_MASK_BYTE1_ADDR = 9'h14a;  //330
localparam [8:0] SYNC_DET_PTN_MASK_BYTE2_ADDR = 9'h14b;  //331
localparam [8:0] SYNC_DET_PTN_MASK_BYTE3_ADDR = 9'h14c;  //332
localparam [8:0] SYNC_DET_PTN_MASK_MSB_ADDR   = 9'h14d;  //333
localparam [8:0] LA_CTRL_ADDR                 = 9'h150;  //336
localparam [8:0] MAX_LANE_SKEW_ADDR           = 9'h151;  //337
localparam [8:0] PRI_LA_PTN_BYTE0_ADDR        = 9'h152;  //338
localparam [8:0] PRI_LA_PTN_BYTE1_ADDR        = 9'h153;  //339
localparam [8:0] PRI_LA_PTN_BYTE2_ADDR        = 9'h154;  //340
localparam [8:0] PRI_LA_PTN_BYTE3_ADDR        = 9'h155;  //341
localparam [8:0] PRI_LA_PTN_MSB_ADDR          = 9'h156;  //342
localparam [8:0] SEC_LA_PTN_BYTE0_ADDR        = 9'h157;  //343
localparam [8:0] SEC_LA_PTN_BYTE1_ADDR        = 9'h158;  //344
localparam [8:0] SEC_LA_PTN_BYTE2_ADDR        = 9'h159;  //345
localparam [8:0] SEC_LA_PTN_BYTE3_ADDR        = 9'h15a;  //346
localparam [8:0] SEC_LA_PTN_MSB_ADDR          = 9'h15b;  //347
localparam [8:0] LA_PTN_MASK_ADDR             = 9'h15c;  //348
localparam [8:0] CLK_FREQ_COMP_CTRL_ADDR      = 9'h160;  //352
localparam [8:0] SKP_INS_DEL_CTRL_ADDR        = 9'h161;  //353
localparam [8:0] ELAS_HIGH_WATER_ADDR         = 9'h162;  //354
localparam [8:0] ELAS_LOW_WATER_ADDR          = 9'h163;  //355
localparam [8:0] PRI_SKP_PTN_BYTE0_ADDR       = 9'h164;  //356
localparam [8:0] PRI_SKP_PTN_BYTE1_ADDR       = 9'h165;  //357
localparam [8:0] PRI_SKP_PTN_BYTE2_ADDR       = 9'h166;  //358
localparam [8:0] PRI_SKP_PTN_BYTE3_ADDR       = 9'h167;  //359
localparam [8:0] PRI_SKP_PTN_MSB_ADDR         = 9'h168;  //360
localparam [8:0] SEC_SKP_PTN_BYTE0_ADDR       = 9'h169;  //361
localparam [8:0] SEC_SKP_PTN_BYTE1_ADDR       = 9'h16a;  //362
localparam [8:0] SEC_SKP_PTN_BYTE2_ADDR       = 9'h16b;  //363
localparam [8:0] SEC_SKP_PTN_BYTE3_ADDR       = 9'h16c;  //364
localparam [8:0] SEC_SKP_PTN_MSB_ADDR         = 9'h16d;  //365
localparam [8:0] SKP_PTN_MASK_ADDR            = 9'h16e;  //366
localparam [8:0] TX_PATH_CTRL_64B66B_ADDR     = 9'h180;  //384
localparam [8:0] TX_FIFO_AF_64B66B_ADDR       = 9'h181;  //385
localparam [8:0] TX_FIFO_AE_64B66B_ADDR       = 9'h182;  //386
localparam [8:0] RX_PATH_CTRL_64B66B_ADDR     = 9'h183;  //387
localparam [8:0] CTC_HIGH_WATER_64B66B_ADDR   = 9'h184;  //388
localparam [8:0] CTC_LOW_WATER_64B66B_ADDR    = 9'h185;  //389
localparam [8:0] BA_SHIFT_64B66B_ADDR         = 9'h186;  //390
localparam [8:0] BER_CNT_10GR_ADDR            = 9'h190;  //400
localparam [8:0] BLK_ERR_CNT_10GR_ADDR        = 9'h191;  //401
localparam [8:0] TP_SEEDA_BYTE0_10GR_ADDR     = 9'h192;  //402
localparam [8:0] TP_SEEDA_BYTE1_10GR_ADDR     = 9'h193;  //403
localparam [8:0] TP_SEEDA_BYTE2_10GR_ADDR     = 9'h194;  //404
localparam [8:0] TP_SEEDA_BYTE3_10GR_ADDR     = 9'h195;  //405
localparam [8:0] TP_SEEDA_BYTE4_10GR_ADDR     = 9'h196;  //406
localparam [8:0] TP_SEEDA_BYTE5_10GR_ADDR     = 9'h197;  //407
localparam [8:0] TP_SEEDA_BYTE6_10GR_ADDR     = 9'h198;  //408
localparam [8:0] TP_SEEDA_BYTE7_10GR_ADDR     = 9'h199;  //409
localparam [8:0] TP_SEEDB_BYTE0_10GR_ADDR     = 9'h19a;  //410
localparam [8:0] TP_SEEDB_BYTE1_10GR_ADDR     = 9'h19b;  //411
localparam [8:0] TP_SEEDB_BYTE2_10GR_ADDR     = 9'h19c;  //412
localparam [8:0] TP_SEEDB_BYTE3_10GR_ADDR     = 9'h19d;  //413
localparam [8:0] TP_SEEDB_BYTE4_10GR_ADDR     = 9'h19e;  //414
localparam [8:0] TP_SEEDB_BYTE5_10GR_ADDR     = 9'h19f;  //415
localparam [8:0] TP_SEEDB_BYTE6_10GR_ADDR     = 9'h1a0;  //416
localparam [8:0] TP_SEEDB_BYTE7_10GR_ADDR     = 9'h1a1;  //417
localparam [8:0] TP_CTRL0_10GR_ADDR           = 9'h1a2;  //418
localparam [8:0] TP_CTRL1_10GR_ADDR           = 9'h1a3;  //419
localparam [8:0] TP_ERR_CNT_BTYE0_10GR_ADDR   = 9'h1a4;  //420
localparam [8:0] TP_ERR_CNT_BTYE1_10GR_ADDR   = 9'h1a5;  //421
localparam [8:0] PMA_STATUS                   = 9'h1c6;  //454
localparam [8:0] PMA_CONTROL                  = 9'h1c7;  //455
localparam [8:0] LOOP_BACK_CTRL_ADDR          = 9'h1e0;  //480
localparam [8:0] BIST_CTRL0_ADDR              = 9'h1e1;  //481
localparam [8:0] BIST_CTRL1_ADDR              = 9'h1e2;  //482
localparam [8:0] UDBC1_BYTE0_ADDR             = 9'h1e3;  //483
localparam [8:0] UDBC1_BYTE1_ADDR             = 9'h1e4;  //484
localparam [8:0] UDBC1_MSB_ADDR               = 9'h1e5;  //485
localparam [8:0] UDBC2_BYTE0_ADDR             = 9'h1e6;  //486
localparam [8:0] UDBC2_BYTE1_ADDR             = 9'h1e7;  //487
localparam [8:0] UDBC2_MSB_ADDR               = 9'h1e8;  //488
localparam [8:0] BIST_STATUS0_ADDR            = 9'h1e9;  //489
localparam [8:0] BIST_STATUS1_ADDR            = 9'h1ea;  //490

   initial begin // initialize register list 
     // reg_type = 2'b00 - do not check
     // reg_type = 2'b01 - read only
     // reg_type = 2'b10 - write only
     // reg_type = 2'b11 - R/W
     
                  // { reg_type, exp_value, writable_bits, reset value}
   // ------------------ PCIE-PCS+PMA registers -------------------//           
  reg_list[0]   = {2'b11, 8'h00, 8'h00, 8'h80}; //reg000
  reg_list[1]   = {2'b11, 8'h00, 8'h00, 8'h20}; //reg001
  reg_list[2]   = {2'b11, 8'h00, 8'h00, 8'hf8}; //reg002
  reg_list[3]   = {2'b11, 8'h00, 8'h00, {RX_IMPED_RATIO_REG[7:0]}};                        //reg003
  reg_list[4]   = {2'b11, 8'h00, 8'h00, {2'b0, TX_DIVMODE_0_REG[1:0], TXRX_F_A_REG[3:0]}}; //reg004
  reg_list[5]   = {2'b11, 8'h00, 8'h00, {1'b0, TXRX_M_A_REG[1:0], TXRX_N_A_REG[4:0]}};     //reg005
  reg_list[6]   = {2'b11, 8'h00, 8'h00, {2'b0, RX_DIVMODE0_REG[1:0], TXRX_F_A_REG[3:0]}};  //reg006
  reg_list[7]   = {2'b11, 8'h00, 8'h00, {1'b0, TXRX_M_A_REG[1:0], TXRX_N_A_REG[4:0]}};     //reg007
  reg_list[8]   = {2'b11, 8'h00, 8'h00, {CNT250NS_MAX_DEC[7:0]}};                          //reg008
  reg_list[9]   = {2'b11, 8'h00, 8'h00, {TX_IMPED_RATIO_REG[7:0]}};                        //reg009
  reg_list[10]  = {2'b11, 8'h00, 8'h00, {TX_PST_RATIO_DEC[7:0]}};                          //reg00a
  reg_list[11]  = {2'b11, 8'h00, 8'h00, {TX_PRE_RATIO_DEC[7:0]}};                          //reg00b
  reg_list[12]  = {2'b11, 8'h00, 8'h00, 8'h84}; //reg00c
  reg_list[13]  = {2'b11, 8'h00, 8'h00, 8'h38}; //reg00d
  reg_list[14]  = {2'b11, 8'h00, 8'h00, 8'hc0}; //reg00e
  reg_list[15]  = {2'b11, 8'h00, 8'h00, 8'h70}; //reg00f
  reg_list[16]  = {2'b11, 8'h00, 8'h00, {2'b0, TX_DIVMODE_1_REG[1:0], TXRX_F_B_REG[3:0]}};  //reg010
  reg_list[17]  = {2'b11, 8'h00, 8'h00, {1'b0, TXRX_M_B_REG[1:0], TXRX_N_B_REG[4:0]}};     //reg011
  reg_list[18]  = {2'b11, 8'h00, 8'h00, {2'b0, TX_DIVMODE_1_REG[1:0], TXRX_F_B_REG[3:0]}};  //reg012
  reg_list[19]  = {2'b11, 8'h00, 8'h00, {1'b0, TXRX_M_B_REG[1:0], TXRX_N_B_REG[4:0]}};     //reg013
  reg_list[20]  = {2'b11, 8'h00, 8'h00, 8'h20}; //reg014
  reg_list[21]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg015
  reg_list[22]  = {2'b11, 8'h00, 8'h00, 8'h15}; //reg016
  reg_list[23]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg017
  reg_list[24]  = {2'b11, 8'h00, 8'h00, {TX_AMP_RATIO_MARGIN0_FULL_DEC[7:0]}};             //reg018
  reg_list[25]  = {2'b11, 8'h00, 8'h00, 8'h78}; //reg019
  reg_list[26]  = {2'b11, 8'h00, 8'h00, 8'h68}; //reg01a
  reg_list[27]  = {2'b11, 8'h00, 8'h00, 8'h60}; //reg01b
  reg_list[28]  = {2'b11, 8'h00, 8'h00, 8'h58}; //reg01c
  reg_list[29]  = {2'b11, 8'h00, 8'h00, 8'h50}; //reg01d
  reg_list[30]  = {2'b11, 8'h00, 8'h00, 8'h48}; //reg01e
  reg_list[31]  = {2'b11, 8'h00, 8'h00, 8'h40}; //reg01f
  reg_list[32]  = {2'b11, 8'h00, 8'h00, 8'h09}; //reg020
  reg_list[33]  = {2'b11, 8'h00, 8'h00, 8'h14}; //reg021
  reg_list[34]  = {2'b11, 8'h00, 8'h00, 8'h04}; //reg022
  reg_list[35]  = {2'b11, 8'h00, 8'h00, 8'h03}; //reg023
  reg_list[36]  = {2'b11, 8'h00, 8'h00, 8'h20}; //reg024
  reg_list[37]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg025
  reg_list[38]  = {2'b11, 8'h00, 8'h00, 8'h15}; //reg026
  reg_list[39]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg027
  reg_list[40]  = {2'b11, 8'h00, 8'h00, 8'h50}; //reg028
  reg_list[41]  = {2'b11, 8'h00, 8'h00, 8'h58}; //reg029
  reg_list[42]  = {2'b11, 8'h00, 8'h00, 8'h48}; //reg02a
  reg_list[43]  = {2'b11, 8'h00, 8'h00, 8'h40}; //reg02b
  reg_list[44]  = {2'b11, 8'h00, 8'h00, 8'h38}; //reg02c
  reg_list[45]  = {2'b11, 8'h00, 8'h00, 8'h30}; //reg02d
  reg_list[46]  = {2'b11, 8'h00, 8'h00, 8'h28}; //reg02e
  reg_list[47]  = {2'b11, 8'h00, 8'h00, 8'h20}; //reg02f
  reg_list[48]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg030
  reg_list[49]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg031
  reg_list[50]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg032
  reg_list[51]  = {2'b01, 8'h00, 8'h00, 8'h4a}; //reg033
  reg_list[52]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg034
  reg_list[53]  = {2'b11, 8'h00, 8'h00, 8'h1f}; //reg035
  reg_list[54]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg036
  reg_list[55]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg037
  reg_list[56]  = {2'b01, 8'h00, 8'h00, 8'he0}; //reg038
  reg_list[57]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg039
  reg_list[58]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg03a
  reg_list[59]  = {2'b01, 8'h00, 8'h00, 8'h20}; //reg03b
  reg_list[60]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg03c
  reg_list[61]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg03d
  reg_list[62]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg03e
  reg_list[63]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg03f
  reg_list[64]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg040
  reg_list[65]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg041
  reg_list[66]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg042
  reg_list[67]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg043
  reg_list[68]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg044
  reg_list[69]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg045
  reg_list[70]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg046
  reg_list[71]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg047
  reg_list[72]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg048
  reg_list[73]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg049
  reg_list[74]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg04a
  reg_list[75]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg04b
  reg_list[76]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg04c
  reg_list[77]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg04d
  reg_list[78]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg04e
  reg_list[79]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg04f
  reg_list[80]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg050
  reg_list[81]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg051
  reg_list[82]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg052
  reg_list[83]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg053
  reg_list[84]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg054
  reg_list[85]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg055
  reg_list[86]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg056
  reg_list[87]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg057
  reg_list[88]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg058
  reg_list[89]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg059
  reg_list[90]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg05a
  reg_list[91]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg05b
  reg_list[92]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg05c
  reg_list[93]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg05d
  reg_list[94]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg05e
  reg_list[95]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg05f
  reg_list[96]  = {2'b01, 8'h00, 8'h00, 8'h00}; //reg060
  reg_list[97]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg061
  reg_list[98]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg062
  reg_list[99]  = {2'b11, 8'h00, 8'h00, 8'h00}; //reg063
  reg_list[100] = {2'b11, 8'h00, 8'h00, {6'b0, LPBK_EN_REG[0], 1'b0}}; //reg064
  reg_list[101] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg065
  reg_list[102] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg066
  reg_list[103] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg067
  reg_list[104] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg068
  reg_list[105] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg069
  reg_list[106] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg06a
  reg_list[107] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg06b
  reg_list[108] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg06c
  reg_list[109] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg06d
  reg_list[110] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg06e
  reg_list[111] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg06f
  reg_list[112] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg070
  reg_list[113] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg071
  reg_list[114] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg072
  reg_list[115] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg073
  reg_list[116] = {2'b11, 8'h00, 8'h00, {1'b0, RX_POLINV_REG[0], TX_POLINV_REG[0], 2'b0, MESO_LPBK_REG[0], 2'b0}}; //reg074
  reg_list[117] = {2'b11, 8'h00, 8'h00, 5'h0, ATXICP_RATE0_DEC[2:0]};                                              //reg075
  reg_list[118] = {2'b11, 8'h00, 8'h00, 1'h0, ARXCDRICP_RATE0_DEC[2:0], 1'h0, ARXICP_RATE0_DEC[2:0]};              //reg076
  reg_list[119] = {2'b11, 8'h00, 8'h00, 5'h0, ATXICP_RATE1_DEC[2:0]};                                              //reg077
  reg_list[120] = {2'b11, 8'h00, 8'h00, 1'h0, ARXCDRICP_RATE1_DEC[2:0], 1'h0, ARXICP_RATE1_DEC[2:0]};              //reg078
  reg_list[121] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg079
  reg_list[122] = {2'b11, 8'h00, 8'h00, 5'h10, ATXICP_RATE2_DEC[2:0]};                                              //reg07a
  reg_list[123] = {2'b11, 8'h00, 8'h00, 1'h0, ARXCDRICP_RATE2_DEC[2:0], 1'h0, ARXICP_RATE2_DEC[2:0]};              //reg07b
  reg_list[124] = {2'b11, 8'h00, 8'h00, 8'h06}; //reg07c
  reg_list[125] = {2'b11, 8'h00, 8'h00, ARXRSVCTL_DEC[7:0]};                                                       //reg07d
  reg_list[126] = {2'b01, 8'h00, 8'h00, 8'h30}; //reg07e
  reg_list[127] = {2'b01, 8'h00, 8'h00, 8'h1d}; //reg07f    
  reg_list[128] = {2'b10, 8'h00, 8'h00, 8'h10}; //reg080
  reg_list[129] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg081
  reg_list[130] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg082
  reg_list[131] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg083
  reg_list[132] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg084
  reg_list[133] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg085
  reg_list[134] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg086
  reg_list[135] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg087
  reg_list[136] = {2'b11, 8'h00, 8'h00, 8'h40}; //reg088
  reg_list[137] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg089
  reg_list[138] = {2'b11, 8'h00, 8'h00, 8'h01}; //reg08a
  reg_list[139] = {2'b11, 8'h00, 8'h00, 8'h81}; //reg08b
  reg_list[140] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg08c
  reg_list[141] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg08d
  reg_list[142] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg08e
  reg_list[143] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg08f
  reg_list[144] = {2'b11, 8'h00, 8'h00, 8'h53}; //reg090
  reg_list[145] = {2'b11, 8'h00, 8'h00, 8'h13}; //reg091
  reg_list[146] = {2'b11, 8'h00, 8'h00, 8'h74}; //reg092
  reg_list[147] = {2'b11, 8'h00, 8'h00, 8'h04}; //reg093
  reg_list[148] = {2'b11, 8'h00, 8'h00, 8'h0e}; //reg094
  reg_list[149] = {2'b11, 8'h00, 8'h00, 8'h1e}; //reg095
  reg_list[150] = {2'b11, 8'h00, 8'h00, 8'h30}; //reg096
  reg_list[151] = {2'b11, 8'h00, 8'h00, 8'h0f}; //reg097
  reg_list[152] = {2'b11, 8'h00, 8'h00, 8'h14}; //reg098
  reg_list[153] = {2'b11, 8'h00, 8'h00, 8'h18}; //reg099
  reg_list[154] = {2'b11, 8'h00, 8'h00, 8'h0c}; //reg09a
  reg_list[155] = {2'b11, 8'h00, 8'h00, 8'h0e}; //reg09b
  reg_list[156] = {2'b11, 8'h00, 8'h00, 8'h16}; //reg09c
  reg_list[157] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg09d
  reg_list[158] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg09e
  reg_list[159] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg09f
  reg_list[160] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0a0
  reg_list[161] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0a1
  reg_list[162] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0a2
  reg_list[163] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0a3
  reg_list[164] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0a4
  reg_list[165] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0a5
  reg_list[166] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0a6
  reg_list[167] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0a7
  reg_list[168] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0a8
  reg_list[169] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0a9
  reg_list[170] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0aa
  reg_list[171] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0ab
  reg_list[172] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0ac
  reg_list[173] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0ad
  reg_list[174] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0ae
  reg_list[175] = {2'b01, 8'h00, 8'h00, 8'h28}; //reg0af
  reg_list[176] = {2'b11, 8'h00, 8'h00, {2'b0, TX_DIVMODE_2_REG[1:0], TXRX_F_C_REG[3:0]}}; //reg0b0
  reg_list[177] = {2'b11, 8'h00, 8'h00, {1'b0, TXRX_M_C_REG[1:0], TXRX_N_C_REG[4:0]}};     //reg0b1
  reg_list[178] = {2'b11, 8'h00, 8'h00, {2'b0, RX_DIVMODE2_REG[1:0], TXRX_F_C_REG[3:0]}};  //reg0b2
  reg_list[179] = {2'b11, 8'h00, 8'h00, {1'b0, TXRX_M_C_REG[1:0], TXRX_N_C_REG[4:0]}};     //reg0b3
  reg_list[180] = {2'b11, 8'h00, 8'h00, 8'h0a}; //reg0b4
  reg_list[181] = {2'b11, 8'h00, 8'h00, 8'h66}; //reg0b5
  reg_list[182] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0b6
  reg_list[183] = {2'b11, 8'h00, 8'h00, 8'h04}; //reg0b7
  reg_list[184] = {2'b11, 8'h00, 8'h00, 8'h80}; //reg0b8
  reg_list[185] = {2'b11, 8'h00, 8'h00, 8'h50}; //reg0b9
  reg_list[186] = {2'b11, 8'h00, 8'h00, 8'h60}; //reg0ba
  reg_list[187] = {2'b11, 8'h00, 8'h00, 8'h40}; //reg0bb
  reg_list[188] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0bc
  reg_list[189] = {2'b11, 8'h00, 8'h00, 8'h03}; //reg0bd
  reg_list[190] = {2'b11, 8'h00, 8'h00, 8'h04}; //reg0be
  reg_list[191] = {2'b11, 8'h00, 8'h00, 8'h63}; //reg0bf
  reg_list[192] = {2'b11, 8'h00, 8'h00, 8'h44}; //reg0c0 
  reg_list[193] = {2'b11, 8'h00, 8'h00, 8'h05}; //reg0c1 
  reg_list[194] = {2'b11, 8'h00, 8'h00, 8'ha0}; //reg0c2 
  reg_list[195] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0c3 
  reg_list[196] = {2'b11, 8'h00, 8'h00, 8'h50}; //reg0c4 
  reg_list[197] = {2'b11, 8'h00, 8'h00, 8'h40}; //reg0c5 
  reg_list[198] = {2'b11, 8'h00, 8'h00, 8'hb4}; //reg0c6
  reg_list[199] = {2'b11, 8'h00, 8'h00, 8'h42}; //reg0c7
  reg_list[200] = {2'b11, 8'h00, 8'h00, 8'h7f}; //reg0c8
  reg_list[201] = {2'b11, 8'h00, 8'h00, 8'h5d}; //reg0c9
  reg_list[202] = {2'b11, 8'h00, 8'h00, 8'h5f}; //reg0ca
  reg_list[203] = {2'b11, 8'h00, 8'h00, 8'h47}; //reg0cb
  reg_list[204] = {2'b11, 8'h00, 8'h00, 8'h3f}; //reg0cc
  reg_list[205] = {2'b11, 8'h00, 8'h00, 8'h1d}; //reg0cd
  reg_list[206] = {2'b11, 8'h00, 8'h00, 8'h1f}; //reg0ce
  reg_list[207] = {2'b11, 8'h00, 8'h00, 8'h07}; //reg0cf
  reg_list[208] = {2'b11, 8'h00, 8'h00, 8'h2d}; //reg0d0
  reg_list[209] = {2'b11, 8'h00, 8'h00, {GEN3_ENA_PRE_REG[0], GEN12_ENA_PRE_REG[0],6'h25}}; //reg0d1
  reg_list[210] = {2'b11, 8'h00, 8'h00, 8'h09}; //reg0d2
  reg_list[211] = {2'b11, 8'h00, 8'h00, {GEN3_ENA_POST_A0_REG[0], GEN12_ENA_POST_A0_REG[0],6'h21}}; //reg0d3
  reg_list[212] = {2'b11, 8'h00, 8'h00, 8'h2d}; //reg0d4
  reg_list[213] = {2'b11, 8'h00, 8'h00, {GEN3_ENA_POST_A1A2_REG[0], GEN12_ENA_POST_A1A2_REG[0],6'h25}}; //reg0d5
  reg_list[214] = {2'b11, 8'h00, 8'h00, 8'h44}; //reg0d6
  reg_list[215] = {2'b11, 8'h00, 8'h00, 8'h44}; //reg0d7
  reg_list[216] = {2'b11, 8'h00, 8'h00, 8'hed}; //reg0d8
  reg_list[217] = {2'b11, 8'h00, 8'h00, {1'b0, RXEQ_ALGO_DEC[3:0], 1'b0, RXEQ_ENABLE_DEC[3:0]}}; //reg0d9 -- RXEQ_ALGO, RXEQ_ENABLE
  reg_list[218] = {2'b11, 8'h00, 8'h00, 8'h04}; //reg0da
  reg_list[219] = {2'b11, 8'h00, 8'h00, 8'hff}; //reg0db
  reg_list[220] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0dc
  reg_list[221] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0dd
  reg_list[222] = {2'b11, 8'h00, 8'h00, 8'h14}; //reg0de
  reg_list[223] = {2'b11, 8'h00, 8'h00, 8'h20}; //reg0df
  reg_list[224] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0e0
  reg_list[225] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0e1
  reg_list[226] = {2'b00, 8'h00, 8'h00, 8'h11}; //reg0e2 -- FSM
  reg_list[227] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0e3
  reg_list[228] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0e4
  reg_list[229] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0e5
  reg_list[230] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0e6
  reg_list[231] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0e7
  reg_list[232] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0e8
  reg_list[233] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0e9
  reg_list[234] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0ea
  reg_list[235] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0eb
  reg_list[236] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0ec
  reg_list[237] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0ed
  reg_list[238] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0ee
  reg_list[239] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0ef
  reg_list[240] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0f0
  reg_list[241] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0f1
  reg_list[242] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0f2
  reg_list[243] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0f3
  reg_list[244] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0f4
  reg_list[245] = {2'b01, 8'h00, 8'h00, 8'h01}; //reg0f5
  reg_list[246] = {2'b11, 8'h00, 8'h00, 8'h10}; //reg0f6
  reg_list[247] = {2'b01, 8'h00, 8'h00, 8'h00}; //reg0f7
  reg_list[248] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0f8
  reg_list[249] = {2'b11, 8'h00, 8'h00, 8'hff}; //reg0f9
  reg_list[250] = {2'b11, 8'h00, 8'h00, 8'h00}; //reg0fa
  reg_list[251] = {2'b11, 8'h00, 8'h00, 8'h02}; //reg0fb
  reg_list[252] = {2'b11, 8'h00, 8'h00, 8'h40}; //reg0fc
  reg_list[253] = {2'b11, 8'h00, 8'h00, 8'hf0}; //reg0fd
  reg_list[254] = {2'b11, 8'h00, 8'h00, 8'h18}; //reg0fe
  reg_list[255] = {2'b11, 8'h00, 8'h00, 8'h15}; //reg0ff
  
  // -------------------- MPCS registers -------------------------//
     reg_list[256] = {2'b11, 8'h00, {1'b0, MODESEL[1:0], RX_OVRD[0], 1'b0, MODESEL[1:0], TX_OVRD[0]}};                                                                               // reg00
     
     reg_list[257] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[258] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[259] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[260] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[261] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[262] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[263] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[264] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[265] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[266] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[267] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[268] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[269] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[270] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[271] = {2'b00, 8'h00, 8'h00};  // do not check
     
     reg_list[272] = {2'b11, 8'h00, 8'h00, {TX_PMFIFO_DIS_REG, 1'b0, TX_DBUS_20_REG[0], ENC_8B10B_DIS_REG[0], TX_FIFO_DIS_REG[0], GEAR_EN_REG[0], 2'b0}};                           // reg10
     reg_list[273] = {2'b11, 8'h01, 8'h00, {7'b0, ENC_DEC_8B10B_INTERLEAVE[0]}};                                                                                                     // reg11 
     
     reg_list[274] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[275] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[276] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[277] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[278] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[279] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[280] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[281] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[282] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[283] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[284] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[285] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[286] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[287] = {2'b00, 8'h00, 8'h00};  // do not check
     
     reg_list[288] = {2'b11, 8'hA4, 8'h00, {RFIFO_COM_ALIGN_REG[0], 1'b0, RX_DBUS_20_REG[0], DEC_8B10B_DIS_REG[0], RX_FIFO_DIS_REG[0], GEAR_EN_REG[0], 2'b0}};                       // reg20 
     reg_list[289] = {2'b00, 8'h00, 8'h00, 8'h00};  //do not check                                                                                                                        // reg21
     reg_list[290] = {2'b11, 8'h01, 8'h00, {7'b0, ENC_DEC_8B10B_INTERLEAVE[0]}};                                                                                                     // reg22 
     
     reg_list[291] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[292] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[293] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[294] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[295] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[296] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[297] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[298] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[299] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[300] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[301] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[302] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[303] = {2'b00, 8'h00, 8'h00};  // do not check
     
     reg_list[304] = {2'b11, 8'h04, 8'h00, {2'b0, WA_DIS_REG[0], ALIGN_2BYTE_DIS_REG[0], SEC_WAPTN_DIS_REG[0], WA_PTN_20B_REG[0], SYNCDET_FSM_DIS_REG[0], AUTO_WA_DIS_REG[0]}};      // reg30
     reg_list[305] = {2'b11, 8'h7C, 8'h00, PRI_WA_PTN_DEC[7:0]};                                                                                                                     // reg31 
     reg_list[306] = {2'b11, 8'h7C, 8'h00, PRI_WA_PTN_DEC[17:10]};                                                                                                                   // reg32 
     reg_list[307] = {2'b11, 8'h05, 8'h00, {4'b0, PRI_WA_PTN_DEC[19:18], PRI_WA_PTN_DEC[9:8]}};                                                                                      // reg33 
     reg_list[308] = {2'b11, 8'h00, 8'h00, SEC_WA_PTN_DEC[7:0]};                                                                                                                     // reg34 
     reg_list[309] = {2'b11, 8'h83, 8'h00, SEC_WA_PTN_DEC[17:10]};                                                                                                                   // reg35 
     reg_list[310] = {2'b11, 8'h00, 8'h00, {4'b0, SEC_WA_PTN_DEC[19:18], SEC_WA_PTN_DEC[9:8]}};                                                                                      // reg36 
     reg_list[311] = {2'b11, 8'h00, 8'h00, WA_MASK_CODE_DEC[7:0]};                                                                                                                   // reg37
     reg_list[312] = {2'b11, 8'h00, 8'h00, WA_MASK_CODE_DEC[17:10]};                                                                                                                 // reg38
     reg_list[313] = {2'b11, 8'h00, 8'h00, {4'b0, WA_MASK_CODE_DEC[19:18], WA_MASK_CODE_DEC[9:8]}};                                                                                  // reg39
     reg_list[314] = {2'b11, 8'h00, 8'h00, VAL_SYNC[7:0]};                                                                                                                           // reg3a
     reg_list[315] = {2'b11, 8'h00, 8'h00, {2'b0, BAD_CODE[5:0]}};                                                                                                                   // reg3b
     reg_list[316] = {2'b11, 8'h00, 8'h00, GOOD_CODE[7:0]};                                                                                                                          // reg3c
     reg_list[317] = {2'b11, 8'h00, 8'h00, {3'b0, SEC_SYNC_PTN_DIS_REG[0], SYNC_PTN_10B_REG[0], SYNC_PTN_ALIGN_REG[0], SYNC_PTN_LEN_REG[1:0]}};                                      // reg3d
     reg_list[318] = {2'b01, 8'h00, 8'h00, 8'h00};                                                                                                                         // reg3e
     reg_list[319] = {2'b11, 8'h00, 8'h00, PRE_SDPTN_B0_DEC[7:0]};                                                                                                                   // reg3f 
     reg_list[320] = {2'b11, 8'h00, 8'h00, PRE_SDPTN_B1_DEC[7:0]};                                                                                                                   // reg40
     reg_list[321] = {2'b11, 8'h00, 8'h00, PRE_SDPTN_B2_DEC[7:0]};                                                                                                                   // reg41
     reg_list[322] = {2'b11, 8'h00, 8'h00, PRE_SDPTN_B3_DEC[7:0]};                                                                                                                   // reg42
     reg_list[323] = {2'b11, 8'h00, 8'h00, {PRE_SDPTN_B3_DEC[9:8], PRE_SDPTN_B2_DEC[9:8], PRE_SDPTN_B1_DEC[9:8], PRE_SDPTN_B0_DEC[9:8]}};                                            // reg43 
     reg_list[324] = {2'b11, 8'h00, 8'h00, SEC_SDPTN_B0_DEC[7:0]};                                                                                                                   // reg44 
     reg_list[325] = {2'b11, 8'h00, 8'h00, SEC_SDPTN_B1_DEC[7:0]};                                                                                                                   // reg45
     reg_list[326] = {2'b11, 8'h00, 8'h00, SEC_SDPTN_B2_DEC[7:0]};                                                                                                                   // reg46
     reg_list[327] = {2'b11, 8'h00, 8'h00, SEC_SDPTN_B3_DEC[7:0]};                                                                                                                   // reg47
     reg_list[328] = {2'b11, 8'h00, 8'h00, {SEC_SDPTN_B3_DEC[9:8], SEC_SDPTN_B2_DEC[9:8], SEC_SDPTN_B1_DEC[9:8], SEC_SDPTN_B0_DEC[9:8]}};                                            // reg48 
     reg_list[329] = {2'b11, 8'h00, 8'h00, SDPTN_MASK_B0_DEC[7:0]};                                                                                                                   // reg49
     reg_list[330] = {2'b11, 8'h00, 8'h00, SDPTN_MASK_B1_DEC[7:0]};                                                                                                                   // reg4a
     reg_list[331] = {2'b11, 8'h00, 8'h00, SDPTN_MASK_B2_DEC[7:0]};                                                                                                                   // reg4b
     reg_list[332] = {2'b11, 8'h00, 8'h00, SDPTN_MASK_B3_DEC[7:0]};                                                                                                                   // reg4c
     reg_list[333] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                         // reg4d - a
     
     reg_list[334] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[335] = {2'b00, 8'h00, 8'h00};  // do not check
     
     reg_list[336] = {2'b11, 8'h00, 8'h00, {3'b0, SEC_LAPTN_EN_REG[0], LALIGN_PTN_LEN_REG[1:0], LALIGN_10B_REG[0], LALIGN_EN_REG[0]}};                                               // reg50
     reg_list[337] = {2'b11, 8'h00, 8'h00, {4'b0, MAX_LSKEW_REG[3:0]}};                                                                                                              // reg51
     reg_list[338] = {2'b11, 8'h00, 8'h00, PRI_LAPTN_B0_DEC[7:0]};                                                                                                                   // reg52
     reg_list[339] = {2'b11, 8'h00, 8'h00, PRI_LAPTN_B1_DEC[7:0]};                                                                                                                   // reg53
     reg_list[340] = {2'b11, 8'h00, 8'h00, PRI_LAPTN_B2_DEC[7:0]};                                                                                                                   // reg54
     reg_list[341] = {2'b11, 8'h00, 8'h00, PRI_LAPTN_B3_DEC[7:0]};                                                                                                                   // reg55
     reg_list[342] = {2'b11, 8'h00, 8'h00, {PRI_LAPTN_B3_DEC[9:8], PRI_LAPTN_B2_DEC[9:8], PRI_LAPTN_B1_DEC[9:8], PRI_LAPTN_B0_DEC[9:8]}};                                            // reg56
     reg_list[343] = {2'b11, 8'h00, 8'h00, SEC_LAPTN_B0_DEC[7:0]};                                                                                                                   // reg57
     reg_list[344] = {2'b11, 8'h00, 8'h00, SEC_LAPTN_B1_DEC[7:0]};                                                                                                                   // reg58
     reg_list[345] = {2'b11, 8'h00, 8'h00, SEC_LAPTN_B2_DEC[7:0]};                                                                                                                   // reg59
     reg_list[346] = {2'b11, 8'h00, 8'h00, SEC_LAPTN_B3_DEC[7:0]};                                                                                                                   // reg5a
     reg_list[347] = {2'b11, 8'h00, 8'h00, 8'h01};                                                                                                                          // reg5b 
     reg_list[348] = {2'b11, 8'h00, 8'h00, {4'b0, LALIGN_MASK_CODE_REG[3:0]}};                                                                                                        // reg5c
     
     reg_list[349] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[350] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[351] = {2'b00, 8'h00, 8'h00};  // do not check
     
     reg_list[352] = {2'b11, 8'h00, 8'h00, {2'b0, SEC_SKIP_EN_REG[0], SKIP_PTN_LEN_REG[1:0], CLK_COMP_10B_REG[0], CTC_FIFO_EN_REG[0], CLK_COMP_EN_REG[0]}};                                                              // reg60
     reg_list[353] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                          // reg61
     reg_list[354] = {2'b11, 8'h00, 8'h00, HIGH_WATER_LINE_DEC[5:0]};                                                                                                                     // reg62 
     reg_list[355] = {2'b11, 8'h00, 8'h00, LOW_WATER_LINE_DEC[5:0]};                                                                                                                     // reg63 
     reg_list[356] = {2'b11, 8'h00, 8'h00, PRI_SKIP_B0_DEC[7:0]};                                                                                                                     // reg64 
     reg_list[357] = {2'b11, 8'h00, 8'h00, PRI_SKIP_B1_DEC[7:0]};                                                                                                                     // reg65 
     reg_list[358] = {2'b11, 8'h00, 8'h00, PRI_SKIP_B2_DEC[7:0]};                                                                                                                     // reg66
     reg_list[359] = {2'b11, 8'h00, 8'h00, PRI_SKIP_B3_DEC[7:0]};                                                                                                                     // reg67
     reg_list[360] = {2'b11, 8'h00, 8'h00, {PRI_SKIP_B3_DEC[9:8], PRI_SKIP_B2_DEC[9:8], PRI_SKIP_B1_DEC[9:8], PRI_SKIP_B0_DEC[9:8]}};                                                 // reg68 
     reg_list[361] = {2'b11, 8'h00, 8'h00, 8'h7C};                                                                                                                           // reg69 
     reg_list[362] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                           // reg6a
     reg_list[363] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                           // reg6b
     reg_list[364] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                           // reg6c
     reg_list[365] = {2'b11, 8'h00, 8'h00, 8'h01};                                                                                                                           // reg6d 
     reg_list[366] = {2'b11, 8'h00, 8'h00, {4'b0, SKP_MASK_CODE_REG[3:0]}};                                                                                                  // reg6e
     
     reg_list[367] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[368] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[369] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[370] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[371] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[372] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[373] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[374] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[375] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[376] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[377] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[378] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[379] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[380] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[381] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[382] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[383] = {2'b00, 8'h00, 8'h00};  // do not check
     
     reg_list[384] = {2'b11, 8'h00, {6'b0, END_64B66B_DIS_REG[0], SRC_64B66B_DIS_REG[0]}};                                                                                   // reg80
     reg_list[385] = {2'b11, 8'h00, {4'b0, FIFO_AF[3:0]}};                                                                                                                   // reg81
     reg_list[386] = {2'b11, 8'h00, {4'b0, FIFO_AE[3:0]}};                                                                                                                   // reg82
     reg_list[387] = {2'b11, 8'h00, {3'b0, PCS_64B66B_NOFPLL_REG[0], BALIGN_64B66B_DIS_REG[0], CTC_64B66B_DIS_REG[0], DEC_64B66B_DIS_REG[0], DESCR_64B66B_DIS_REG[0]}};      // reg83
     reg_list[388] = {2'b11, 8'h00, 8'h0C};                                                                                                                                  // reg84
     reg_list[389] = {2'b11, 8'h00, 8'h04};                                                                                                                                  // reg85
     
     reg_list[390] = {2'b01, 8'h00, 8'h00};  // reg86
     reg_list[391] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[392] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[393] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[394] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[395] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[396] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[397] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[398] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[399] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[400] = {2'b01, 8'h00, 8'h00};  // reg90
     reg_list[401] = {2'b01, 8'h00, 8'h00};  // reg91
     reg_list[402] = {2'b11, 8'h00, 8'h00};  // reg92
     reg_list[403] = {2'b11, 8'h00, 8'h00};  // reg93
     reg_list[404] = {2'b11, 8'h00, 8'h00};  // reg94
     reg_list[405] = {2'b11, 8'h00, 8'h00};  // reg95
     reg_list[406] = {2'b11, 8'h00, 8'h00};  // reg96
     reg_list[407] = {2'b11, 8'h00, 8'h00};  // reg97
     reg_list[408] = {2'b11, 8'h00, 8'h00};  // reg98
     reg_list[409] = {2'b11, 8'h00, 8'h00};  // reg99
     reg_list[410] = {2'b11, 8'h00, 8'h00};  // reg9A
     reg_list[411] = {2'b11, 8'h00, 8'h00};  // reg9B
     reg_list[412] = {2'b11, 8'h00, 8'h00};  // reg9C
     reg_list[413] = {2'b11, 8'h00, 8'h00};  // reg9D
     reg_list[414] = {2'b11, 8'h00, 8'h00};  // reg9E
     reg_list[415] = {2'b11, 8'h00, 8'h00};  // reg9F
     reg_list[416] = {2'b11, 8'h00, 8'h00};  // regA0
     reg_list[417] = {2'b11, 8'h00, 8'h00};  // regA1
     reg_list[418] = {2'b11, 8'h00, 8'h00};  // regA2
     reg_list[419] = {2'b11, 8'h00, 8'h00};  // regA3
     reg_list[420] = {2'b01, 8'h00, 8'h00};  // regA4
     reg_list[421] = {2'b01, 8'h00, 8'h00};  // regA5
     reg_list[422] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[423] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[424] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[425] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[426] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[427] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[428] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[429] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[430] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[431] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[432] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[433] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[434] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[435] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[436] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[437] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[438] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[439] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[440] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[441] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[442] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[443] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[444] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[445] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[446] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[447] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[448] = {2'b01, 8'h00, 8'h00};  // regc0
     reg_list[449] = {2'b01, 8'h00, 8'h00};  // regc1
     reg_list[450] = {2'b01, 8'h00, 8'h00};  // regc2
     reg_list[451] = {2'b01, 8'h00, 8'h00};  // regc3
     reg_list[452] = {2'b11, 8'h00, 8'h00};  // regc4
     reg_list[453] = {2'b11, 8'h00, 8'h01};  // regc5
     reg_list[454] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[455] = {2'b00, 8'h00, 8'h00};  // do not check           
     reg_list[456] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[457] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[458] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[459] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[460] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[461] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[462] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[463] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[464] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[465] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[466] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[467] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[468] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[469] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[470] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[471] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[472] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[473] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[474] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[475] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[476] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[477] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[478] = {2'b00, 8'h00, 8'h00};  // do not check
     reg_list[479] = {2'b00, 8'h00, 8'h00};  // do not check
     
     reg_list[480] = {2'b11, 8'h00, 8'h00, {6'b0, FAR_LP_EN_REG[0], NEAR_LP_EN_REG[0]}};                                                                                             // rege0
     reg_list[481] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                           // rege1
     reg_list[482] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                           // rege2
     reg_list[483] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                           // rege3
     reg_list[484] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                           // rege4
     reg_list[485] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                           // rege5
     reg_list[486] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                           // rege6
     reg_list[487] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                           // rege7
     reg_list[488] = {2'b11, 8'h00, 8'h00, 8'h00};                                                                                                                           // rege8
     reg_list[489] = {2'b01, 8'h00, 8'h00, 8'h00};                                                                                                                           // rege9
     reg_list[490] = {2'b01, 8'h00, 8'h00, 8'h00};                                                                                                                           // regea

  //------------------------REGISTER NAMES------------------------//
  // ------------------ PCIE-PCS+PMA registers -------------------//   
     reg_names[0]   = "reg000" ;
     reg_names[1]   = "reg001" ;
     reg_names[2]   = "reg002" ;
     reg_names[3]   = "reg003" ;
     reg_names[4]   = "reg004" ;
     reg_names[5]   = "reg005" ;
     reg_names[6]   = "reg006" ;
     reg_names[7]   = "reg007" ;
     reg_names[8]   = "reg008" ;
     reg_names[9]   = "reg009" ;
     reg_names[10]  = "reg00a" ;
     reg_names[11]  = "reg00b" ;
     reg_names[12]  = "reg00c" ;
     reg_names[13]  = "reg00d" ;
     reg_names[14]  = "reg00e" ;
     reg_names[15]  = "reg00f" ;
     reg_names[16]  = "reg010" ;
     reg_names[17]  = "reg011" ;
     reg_names[18]  = "reg012" ;
     reg_names[19]  = "reg013" ;
     reg_names[20]  = "reg014" ;
     reg_names[21]  = "reg015" ;
     reg_names[22]  = "reg016" ;
     reg_names[23]  = "reg017" ;
     reg_names[24]  = "reg018" ;
     reg_names[25]  = "reg019" ;
     reg_names[26]  = "reg01a" ;
     reg_names[27]  = "reg01b" ;
     reg_names[28]  = "reg01c" ;
     reg_names[29]  = "reg01d" ;
     reg_names[30]  = "reg01e" ;
     reg_names[31]  = "reg01f" ;
     reg_names[32]  = "reg020" ;
     reg_names[33]  = "reg021" ;
     reg_names[34]  = "reg022" ;
     reg_names[35]  = "reg023" ;
     reg_names[36]  = "reg024" ;
     reg_names[37]  = "reg025" ;
     reg_names[38]  = "reg026" ;
     reg_names[39]  = "reg027" ;
     reg_names[40]  = "reg028" ;
     reg_names[41]  = "reg029" ;
     reg_names[42]  = "reg02a" ;
     reg_names[43]  = "reg02b" ;
     reg_names[44]  = "reg02c" ;
     reg_names[45]  = "reg02d" ;
     reg_names[46]  = "reg02e" ;
     reg_names[47]  = "reg02f" ;
     reg_names[48]  = "reg030" ;
     reg_names[49]  = "reg031" ;
     reg_names[50]  = "reg032" ;
     reg_names[51]  = "reg033" ;
     reg_names[52]  = "reg034" ;
     reg_names[53]  = "reg035" ;
     reg_names[54]  = "reg036" ;
     reg_names[55]  = "reg037" ;
     reg_names[56]  = "reg038" ;
     reg_names[57]  = "reg039" ;
     reg_names[58]  = "reg03a" ;
     reg_names[59]  = "reg03b" ;
     reg_names[60]  = "reg03c" ;
     reg_names[61]  = "reg03d" ;
     reg_names[62]  = "reg03e" ;
     reg_names[63]  = "reg03f" ;
     reg_names[64]  = "reg040" ;
     reg_names[65]  = "reg041" ;
     reg_names[66]  = "reg042" ;
     reg_names[67]  = "reg043" ;
     reg_names[68]  = "reg044" ;
     reg_names[69]  = "reg045" ;
     reg_names[70]  = "reg046" ;
     reg_names[71]  = "reg047" ;
     reg_names[72]  = "reg048" ;
     reg_names[73]  = "reg049" ;
     reg_names[74]  = "reg04a" ;
     reg_names[75]  = "reg04b" ;
     reg_names[76]  = "reg04c" ;
     reg_names[77]  = "reg04d" ;
     reg_names[78]  = "reg04e" ;
     reg_names[79]  = "reg04f" ;
     reg_names[80]  = "reg050" ;
     reg_names[81]  = "reg051" ;
     reg_names[82]  = "reg052" ;
     reg_names[83]  = "reg053" ;
     reg_names[84]  = "reg054" ;
     reg_names[85]  = "reg055" ;
     reg_names[86]  = "reg056" ;
     reg_names[87]  = "reg057" ;
     reg_names[88]  = "reg058" ;
     reg_names[89]  = "reg059" ;
     reg_names[90]  = "reg05a" ;
     reg_names[91]  = "reg05b" ;
     reg_names[92]  = "reg05c" ;
     reg_names[93]  = "reg05d" ;
     reg_names[94]  = "reg05e" ;
     reg_names[95]  = "reg05f" ;
     reg_names[96]  = "reg060" ;
     reg_names[97]  = "reg061" ;
     reg_names[98]  = "reg062" ;
     reg_names[99]  = "reg063" ;
     reg_names[100] = "reg064" ;
     reg_names[101] = "reg065" ;
     reg_names[102] = "reg066" ;
     reg_names[103] = "reg067" ;
     reg_names[104] = "reg068" ;
     reg_names[105] = "reg069" ;
     reg_names[106] = "reg06a" ;
     reg_names[107] = "reg06b" ;
     reg_names[108] = "reg06c" ;
     reg_names[109] = "reg06d" ;
     reg_names[110] = "reg06e" ;
     reg_names[111] = "reg06f" ;
     reg_names[112] = "reg070" ;
     reg_names[113] = "reg071" ;
     reg_names[114] = "reg072" ;
     reg_names[115] = "reg073" ;
     reg_names[116] = "reg074" ;
     reg_names[117] = "reg075" ;
     reg_names[118] = "reg076" ;
     reg_names[119] = "reg077" ;
     reg_names[120] = "reg078" ;
     reg_names[121] = "reg079" ;
     reg_names[122] = "reg07a" ;
     reg_names[123] = "reg07b" ;
     reg_names[124] = "reg07c" ;
     reg_names[125] = "reg07d" ;
     reg_names[126] = "reg07e" ;
     reg_names[127] = "reg07f" ;
     reg_names[128] = "reg080" ;
     reg_names[129] = "reg081" ;
     reg_names[130] = "reg082" ;
     reg_names[131] = "reg083" ;
     reg_names[132] = "reg084" ;
     reg_names[133] = "reg085" ;
     reg_names[134] = "reg086" ;
     reg_names[135] = "reg087" ;
     reg_names[136] = "reg088" ;
     reg_names[137] = "reg089" ;
     reg_names[138] = "reg08a" ;
     reg_names[139] = "reg08b" ;
     reg_names[140] = "reg08c" ;
     reg_names[141] = "reg08d" ;
     reg_names[142] = "reg08e" ;
     reg_names[143] = "reg08f" ;
     reg_names[144] = "reg090" ;
     reg_names[145] = "reg091" ;
     reg_names[146] = "reg092" ;
     reg_names[147] = "reg093" ;
     reg_names[148] = "reg094" ;
     reg_names[149] = "reg095" ;
     reg_names[150] = "reg096" ;
     reg_names[151] = "reg097" ;
     reg_names[152] = "reg098" ;
     reg_names[153] = "reg099" ;
     reg_names[154] = "reg09a" ;
     reg_names[155] = "reg09b" ;
     reg_names[156] = "reg09c" ;
     reg_names[157] = "reg09d" ;
     reg_names[158] = "reg09e" ;
     reg_names[159] = "reg09f" ;
     reg_names[160] = "reg0a0" ;
     reg_names[161] = "reg0a1" ;
     reg_names[162] = "reg0a2" ;
     reg_names[163] = "reg0a3" ;
     reg_names[164] = "reg0a4" ;
     reg_names[165] = "reg0a5" ;
     reg_names[166] = "reg0a6" ;
     reg_names[167] = "reg0a7" ;
     reg_names[168] = "reg0a8" ;
     reg_names[169] = "reg0a9" ;
     reg_names[170] = "reg0aa" ;
     reg_names[171] = "reg0ab" ;
     reg_names[172] = "reg0ac" ;
     reg_names[173] = "reg0ad" ;
     reg_names[174] = "reg0ae" ;
     reg_names[175] = "reg0af" ;
     reg_names[176] = "reg0b0" ;
     reg_names[177] = "reg0b1" ;
     reg_names[178] = "reg0b2" ;
     reg_names[179] = "reg0b3" ;
     reg_names[180] = "reg0b4" ;
     reg_names[181] = "reg0b5" ;
     reg_names[182] = "reg0b6" ;
     reg_names[183] = "reg0b7" ;
     reg_names[184] = "reg0b8" ;
     reg_names[185] = "reg0b9" ;
     reg_names[186] = "reg0ba" ;
     reg_names[187] = "reg0bb" ;
     reg_names[188] = "reg0bc" ;
     reg_names[189] = "reg0bd" ;
     reg_names[190] = "reg0be" ;
     reg_names[191] = "reg0bf" ;
     reg_names[192] = "reg0c0" ;
     reg_names[193] = "reg0c1" ;
     reg_names[194] = "reg0c2" ;
     reg_names[195] = "reg0c3" ;
     reg_names[196] = "reg0c4" ;
     reg_names[197] = "reg0c5" ;
     reg_names[198] = "reg0c6" ;
     reg_names[199] = "reg0c7" ;
     reg_names[200] = "reg0c8" ;
     reg_names[201] = "reg0c9" ;
     reg_names[202] = "reg0ca" ;
     reg_names[203] = "reg0cb" ;
     reg_names[204] = "reg0cc" ;
     reg_names[205] = "reg0cd" ;
     reg_names[206] = "reg0ce" ;
     reg_names[207] = "reg0cf" ;
     reg_names[208] = "reg0d0" ;
     reg_names[209] = "reg0d1" ;
     reg_names[210] = "reg0d2" ;
     reg_names[211] = "reg0d3" ;
     reg_names[212] = "reg0d4" ;
     reg_names[213] = "reg0d5" ;
     reg_names[214] = "reg0d6" ;
     reg_names[215] = "reg0d7" ;
     reg_names[216] = "reg0d8" ;
     reg_names[217] = "reg0d9" ;
     reg_names[218] = "reg0da" ;
     reg_names[219] = "reg0db" ;
     reg_names[220] = "reg0dc" ;
     reg_names[221] = "reg0dd" ;
     reg_names[222] = "reg0de" ;
     reg_names[223] = "reg0df" ;
     reg_names[224] = "reg0e0" ;
     reg_names[225] = "reg0e1" ;
     reg_names[226] = "reg0e2" ;
     reg_names[227] = "reg0e3" ;
     reg_names[228] = "reg0e4" ;
     reg_names[229] = "reg0e5" ;
     reg_names[230] = "reg0e6" ;
     reg_names[231] = "reg0e7" ;
     reg_names[232] = "reg0e8" ;
     reg_names[233] = "reg0e9" ;
     reg_names[234] = "reg0ea" ;
     reg_names[235] = "reg0eb" ;
     reg_names[236] = "reg0ec" ;
     reg_names[237] = "reg0ed" ;
     reg_names[238] = "reg0ee" ;
     reg_names[239] = "reg0ef" ;
     reg_names[240] = "reg0f0" ;
     reg_names[241] = "reg0f1" ;
     reg_names[242] = "reg0f2" ;
     reg_names[243] = "reg0f3" ;
     reg_names[244] = "reg0f4" ;
     reg_names[245] = "reg0f5" ;
     reg_names[246] = "reg0f6" ;
     reg_names[247] = "reg0f7" ;
     reg_names[248] = "reg0f8" ;
     reg_names[249] = "reg0f9" ;
     reg_names[250] = "reg0fa" ;
     reg_names[251] = "reg0fb" ;
     reg_names[252] = "reg0fc" ;
     reg_names[253] = "reg0fd" ;
     reg_names[254] = "reg0fe" ;
     reg_names[255] = "reg0ff" ;
  
     // -------------------- MPCS registers -------------------------//
     reg_names[256] = "reg100";
     reg_names[272] = "reg110";
     reg_names[273] = "reg111";
     reg_names[288] = "reg120";
     reg_names[289] = "reg121";
     reg_names[290] = "reg122"; 
     reg_names[304] = "reg130";
     reg_names[305] = "reg131";
     reg_names[306] = "reg132";
     reg_names[307] = "reg133";
     reg_names[308] = "reg134";
     reg_names[309] = "reg135";
     reg_names[310] = "reg136";
     reg_names[311] = "reg137";
     reg_names[312] = "reg138";
     reg_names[313] = "reg139";
     reg_names[314] = "reg13a";
     reg_names[315] = "reg13b";
     reg_names[316] = "reg13c";
     reg_names[317] = "reg13d";
     reg_names[318] = "reg13e";
     reg_names[319] = "reg13f";
     reg_names[320] = "reg140";
     reg_names[321] = "reg141";
     reg_names[322] = "reg142";
     reg_names[323] = "reg143";
     reg_names[324] = "reg144";
     reg_names[325] = "reg145";
     reg_names[326] = "reg146";
     reg_names[327] = "reg147";
     reg_names[328] = "reg148";
     reg_names[329] = "reg149";
     reg_names[330] = "reg14a";
     reg_names[331] = "reg14b";
     reg_names[332] = "reg14c";
     reg_names[333] = "reg14d";
     reg_names[336] = "reg150";
     reg_names[337] = "reg151";
     reg_names[338] = "reg152";
     reg_names[339] = "reg153";
     reg_names[340] = "reg154";
     reg_names[341] = "reg155";
     reg_names[342] = "reg156";
     reg_names[343] = "reg157";
     reg_names[344] = "reg158";
     reg_names[345] = "reg159";
     reg_names[346] = "reg15a";
     reg_names[347] = "reg15b";
     reg_names[348] = "reg15c";
     reg_names[352] = "reg160";
     reg_names[353] = "reg161";
     reg_names[354] = "reg162";
     reg_names[355] = "reg163";
     reg_names[356] = "reg164";
     reg_names[357] = "reg165";
     reg_names[358] = "reg166";
     reg_names[359] = "reg167";
     reg_names[360] = "reg168";
     reg_names[361] = "reg169";
     reg_names[362] = "reg16a";
     reg_names[363] = "reg16b";
     reg_names[364] = "reg16c";
     reg_names[365] = "reg16d";
     reg_names[366] = "reg16e";
     reg_names[384] = "reg180";
     reg_names[385] = "reg181";
     reg_names[386] = "reg182";
     reg_names[387] = "reg183";
     reg_names[388] = "reg184";
     reg_names[389] = "reg185";
     reg_names[390] = "reg186";
     reg_names[400] = "reg190";
     reg_names[401] = "reg191";
     reg_names[402] = "reg192";
     reg_names[403] = "reg193";
     reg_names[404] = "reg194";
     reg_names[405] = "reg195";
     reg_names[406] = "reg196";
     reg_names[407] = "reg197";
     reg_names[408] = "reg198";
     reg_names[409] = "reg199";
     reg_names[410] = "reg19a";
     reg_names[411] = "reg19b";
     reg_names[412] = "reg19c";
     reg_names[413] = "reg19d";
     reg_names[414] = "reg19e";
     reg_names[415] = "reg19f";
     reg_names[416] = "reg1a0";
     reg_names[417] = "reg1a1";
     reg_names[418] = "reg1a2";
     reg_names[419] = "reg1a3";
     reg_names[420] = "reg1a4";
     reg_names[421] = "reg1a5";  
     reg_names[453] = "reg1c5";
     reg_names[454] = "reg1c6";
     reg_names[455] = "reg1c7";
     reg_names[480] = "reg1e0";
     reg_names[481] = "reg1e1";
     reg_names[482] = "reg1e2";
     reg_names[483] = "reg1e3";
     reg_names[484] = "reg1e4";
     reg_names[485] = "reg1e5";
     reg_names[486] = "reg1e6";
     reg_names[487] = "reg1e7";
     reg_names[488] = "reg1e8";
     reg_names[489] = "reg1e9";
     reg_names[490] = "reg1ea";   
   end
       
endmodule
