module flashing_lights (
    input  F_125Mhz_P,
    input  F_125Mhz_N,

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
    output reg LED4,
    output Debug_LED1,
    output Debug_LED2
);

assign F_SFP1_TX_DISABLE = 1'b0;

// Current board behavior shows these LEDs are active-high.
// Internally, switch_value uses the intuitive meaning: switch on = 1.
localparam LED_ON = 1'b1;
localparam LED_OFF = 1'b0;

wire tx_clk;
wire rx_clk;
wire fabric_clk;

wire [79:0] mpcs_tx_word;
wire [79:0] mpcs_rx_word;

wire mpcs_lsync;
wire mpcs_phyrdy;
wire mpcs_ready;
wire mpcs_rx_val;
wire mpcs_resetn;
wire mpcs_tx_enable;

assign fabric_clk = F_125Mhz_P;

(* syn_preserve = 1 *) reg [15:0] reset_count = 16'd0;
(* syn_preserve = 1 *) reg [25:0] fabric_clk_count = 26'd0;
(* syn_preserve = 1 *) reg [25:0] fabric_clk_n_count = 26'd0;

always @(posedge fabric_clk) begin
    fabric_clk_count <= fabric_clk_count + 1'b1;

    if (!mpcs_resetn) begin
        reset_count <= reset_count + 1'b1;
    end
end

assign mpcs_resetn = &reset_count;
assign mpcs_tx_enable = mpcs_resetn && mpcs_phyrdy;

(* syn_preserve = 1 *) reg [25:0] tx_clk_count = 26'd0;

always @(posedge F_125Mhz_N) begin
    fabric_clk_n_count <= fabric_clk_n_count + 1'b1;
end

always @(posedge tx_clk) begin
    tx_clk_count <= tx_clk_count + 1'b1;
end

assign Debug_LED1 = fabric_clk_count[25];
assign Debug_LED2 = fabric_clk_n_count[25];

// 64B/66B mapping: bit 79 writes the Tx FIFO, bit 72 leaves the encoder enabled,
// bits 71:64 mark all payload bytes as data, and bits 63:0 carry the payload.
assign mpcs_tx_word = {1'b1, 6'b0, 1'b0, 8'h00, 62'd0, Switch1, Switch2};
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

    .lmmi_clk_i_0(fabric_clk),
    .lmmi_resetn_i_0(mpcs_resetn),
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
    .mpcs_tx_pcs_rstn_i_0(mpcs_tx_enable),
    .mpcs_rx_pcs_rstn_i_0(mpcs_resetn && mpcs_phyrdy),
    .mpcs_rx_out_clk_o_0(rx_clk),
    .mpcs_tx_out_clk_o_0(tx_clk),
    .mpcs_perstn_i_0(mpcs_resetn),

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
    .mpcs_clkin_i_0(fabric_clk),
    .mpcs_pwrdn_i_0(2'b00),
    .mpcs_txhiz_i_0(1'b0),
    .mpcs_rxidle_o_0(),
    .mpcs_rxerr_i_0(1'b0),
    .mpcs_fomreq_i_0(1'b0),
    .mpcs_fomack_o_0(),
    .mpcs_fomrslt_o_0(),
    .mpcs_speed_o_0(),
    .mpcs_txval_i_0(mpcs_tx_enable),
    .mpcs_phyrdy_o_0(mpcs_phyrdy),
    .mpcs_ready_o_0(mpcs_ready),
    .mpcs_rxoob_i_0(1'b0),
    .mpcs_txdeemp_i_0(1'b0),
    .mpcs_pwrst_o_0(),
    .mpcs_skipbit_i_0(1'b0),
    .mpcs_rxval_o_0(mpcs_rx_val)
);

endmodule
