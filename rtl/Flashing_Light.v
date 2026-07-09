module flashing_lights (
    input  sdq_refclkp_q1_i,
    input  sdq_refclkn_q1_i,

    input  Switch1,
    input  Switch2,

    input  sd0rxp_i,
    input  sd0rxn_i,
    output sd0txp_o,
    output sd0txn_o,
    output F_SFP1_TX_DISABLE,

    output reg LED1,
    output reg LED2,
    output reg LED3,
    output reg LED4
);

assign F_SFP1_TX_DISABLE = 1'b0;

// Current board behavior shows these LEDs are active-high.
// Internally, switch_value uses the intuitive meaning: switch on = 1.
localparam LED_ON = 1'b1;
localparam LED_OFF = 1'b0;

wire tx_clk;
wire rx_clk;

wire [79:0] mpcs_tx_word;
wire [79:0] mpcs_rx_word;

wire mpcs_lsync;
wire mpcs_phyrdy;
wire mpcs_ready;
wire mpcs_rx_val;


assign mpcs_tx_word = {78'h0, Switch1, Switch2};
//rx_switch_value is the received signal for which light to turn on
reg [1:0] rx_switch_value = 2'b00;

always @(posedge rx_clk) begin
        rx_switch_value <= mpcs_rx_word[1:0];
end

always @* begin
    LED1 = mpcs_lsync;
    LED2 = mpcs_phyrdy;
    LED3 = mpcs_ready;
    LED4 = mpcs_rx_val;
end



MPCS_ex u_mpcs (
    .use_refmux_i(1'b0),
    .diffioclksel_i(1'b0),
    .clksel_i(2'b00),

    .sdq_refclkp_q0_i(1'b0),
    .sdq_refclkn_q0_i(1'b0),
    .sdq_refclkp_q1_i(sdq_refclkp_q1_i),
    .sdq_refclkn_q1_i(sdq_refclkn_q1_i),
    .sd_ext_0_refclk_i(1'b0),
    .sd_ext_1_refclk_i(1'b0),
    .pll_0_refclk_i(1'b0),
    .pll_1_refclk_i(1'b0),
    .sd_pll_refclk_i(1'b0),

    .acjtag_mode_i(1'b0),
    .acjtag_enable_i_0(1'b0),
    .acjtag_acmode_i_0(1'b0),
    .acjtag_drive1_i_0(1'b0),
    .acjtag_highz_i_0(1'b0),
    .acjtagpout_o_0(),
    .acjtagnout_o_0(),

    .lmmi_clk_i_0(tx_clk),
    .lmmi_resetn_i_0(1'b1),
    .lmmi_request_i_0(1'b0),
    .lmmi_wr_rdn_i_0(1'b0),
    .lmmi_offset_i_0(9'd0),
    .lmmi_wdata_i_0(8'd0),
    .lmmi_rdata_valid_o_0(),
    .lmmi_ready_o_0(),
    .lmmi_rdata_o_0(),

    .sd0rxp_i(sd0rxp_i),
    .sd0rxn_i(sd0rxn_i),
    .sd0txp_o(sd0txp_o),
    .sd0txn_o(sd0txn_o),
    .sd0_rext_i(1'b0),
    .sd0_refret_i(1'b0),

    .mpcs_rx_usr_clk_i_0(rx_clk),
    .mpcs_tx_usr_clk_i_0(tx_clk),
    .mpcs_tx_pcs_rstn_i_0(1'b1),
    .mpcs_rx_pcs_rstn_i_0(1'b1),
    .mpcs_rx_out_clk_o_0(rx_clk),
    .mpcs_tx_out_clk_o_0(tx_clk),
    .mpcs_perstn_i_0(1'b1),

    .mpcs_tx_ch_din_i_0(mpcs_tx_word),
    .mpcs_tx_fifo_st_o_0(),
    .mpcs_rx_ch_dout_o_0(mpcs_rx_word),
    .mpcs_rx_fifo_st_o_0(),
    .mpcs_ebuf_empty_o_0(),
    .mpcs_ebuf_full_o_0(),

    .mpcs_anxmit_i_0(1'b1),
    .mpcs_walign_en_i_0(1'b1),
    .mpcs_get_lsync_o_0(mpcs_lsync),
    .mpcs_rx_get_lalign_o_0(),
    .mpcs_rx_deskew_en_i_0(1'b1),
    .mpcs_clkin_i_0(tx_clk),
    .mpcs_pwrdn_i_0(2'b00),
    .mpcs_txhiz_i_0(1'b0),
    .mpcs_rxidle_o_0(),
    .mpcs_rxerr_i_0(1'b0),
    .mpcs_fomreq_i_0(1'b0),
    .mpcs_fomack_o_0(),
    .mpcs_fomrslt_o_0(),
    .mpcs_speed_o_0(),
    .mpcs_txval_i_0(1'b1),
    .mpcs_phyrdy_o_0(mpcs_phyrdy),
    .mpcs_ready_o_0(mpcs_ready),
    .mpcs_rxoob_i_0(1'b0),
    .mpcs_txdeemp_i_0(1'b0),
    .mpcs_pwrst_o_0(),
    .mpcs_skipbit_i_0(1'b0),
    .mpcs_rxval_o_0(mpcs_rx_val)
);

endmodule
