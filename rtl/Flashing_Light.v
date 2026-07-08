module flashing_lights (
    input  sdq_refclkp_q0_i,
    input  sdq_refclkn_q0_i,

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

// The Versa DIP switches and LEDs are active-low at the board level.
// Internally, switch_value uses the intuitive meaning: switch on = 1.
wire ref_clk = sdq_refclkp_q0_i;

reg [7:0] reset_shift = 8'h00;
wire resetn = &reset_shift;

always @(posedge ref_clk) begin
    reset_shift <= {reset_shift[6:0], 1'b1};
end

wire tx_clk;
wire rx_clk;

wire mpcs_ready;
wire mpcs_phyrdy;
wire mpcs_lsync;
wire mpcs_rxval;

wire [79:0] mpcs_tx_word;
wire [79:0] mpcs_rx_word;

reg switch1_meta;
reg switch1_sync;
reg switch2_meta;
reg switch2_sync;

wire [1:0] switch_value = {~switch1_sync, ~switch2_sync};

always @(posedge tx_clk or negedge resetn) begin
    if (!resetn) begin
        switch1_meta <= 1'b1;
        switch1_sync <= 1'b1;
        switch2_meta <= 1'b1;
        switch2_sync <= 1'b1;
    end else begin
        switch1_meta <= Switch1;
        switch1_sync <= switch1_meta;
        switch2_meta <= Switch2;
        switch2_sync <= switch2_meta;
    end
end

reg [31:0] tx_payload;
reg [3:0] tx_control;

wire [39:0] tx_pcs_word = {
    1'b0, tx_control[3], tx_payload[31:24],
    1'b0, tx_control[2], tx_payload[23:16],
    1'b0, tx_control[1], tx_payload[15:8],
    1'b0, tx_control[0], tx_payload[7:0]
};

assign mpcs_tx_word = {40'd0, tx_pcs_word};

always @(posedge tx_clk or negedge resetn) begin
    if (!resetn) begin
        tx_payload <= 32'h00000000;
        tx_control <= 4'b0000;
    end else if (!mpcs_lsync) begin
        // Send a K28.5-style comma/control byte while the receiver is looking
        // for word alignment. This mirrors the generated Lattice testbench.
        tx_payload <= 32'hAAAAAABC;
        tx_control <= 4'b0001;
    end else begin
        tx_payload <= {30'd0, switch_value};
        tx_control <= 4'b0000;
    end
end

wire rx_byte0_is_control = mpcs_rx_word[8];
wire [7:0] rx_byte0 = mpcs_rx_word[7:0];
wire rx_data_valid = mpcs_ready && mpcs_phyrdy && mpcs_lsync &&
                     mpcs_rxval && !rx_byte0_is_control;

reg [1:0] rx_data;
reg have_rx_data;

always @(posedge rx_clk or negedge resetn) begin
    if (!resetn) begin
        rx_data <= 2'b00;
        have_rx_data <= 1'b0;
    end else if (rx_data_valid) begin
        rx_data <= rx_byte0[1:0];
        have_rx_data <= 1'b1;
    end
end

always @* begin
    LED1 = 1'b1;
    LED2 = 1'b1;
    LED3 = 1'b1;
    LED4 = 1'b1;

    if (have_rx_data) begin
        case (rx_data)
            2'b00: LED1 = 1'b0;
            2'b01: LED2 = 1'b0;
            2'b10: LED3 = 1'b0;
            2'b11: LED4 = 1'b0;
            default: begin
                LED1 = 1'b1;
                LED2 = 1'b1;
                LED3 = 1'b1;
                LED4 = 1'b1;
            end
        endcase
    end
end

MPCS_ex u_mpcs (
    .use_refmux_i(1'b0),
    .diffioclksel_i(1'b0),
    .clksel_i(2'b00),

    .sdq_refclkp_q0_i(sdq_refclkp_q0_i),
    .sdq_refclkn_q0_i(sdq_refclkn_q0_i),
    .sdq_refclkp_q1_i(1'b0),
    .sdq_refclkn_q1_i(1'b0),
    .sd_ext_0_refclk_i(1'b0),
    .sd_ext_1_refclk_i(1'b0),
    .pll_0_refclk_i(1'b0),
    .pll_1_refclk_i(1'b0),
    .sd_pll_refclk_i(ref_clk),

    .acjtag_mode_i(1'b0),
    .acjtag_enable_i_0(1'b0),
    .acjtag_acmode_i_0(1'b0),
    .acjtag_drive1_i_0(1'b0),
    .acjtag_highz_i_0(1'b0),
    .acjtagpout_o_0(),
    .acjtagnout_o_0(),

    .lmmi_clk_i_0(ref_clk),
    .lmmi_resetn_i_0(resetn),
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
    .mpcs_tx_pcs_rstn_i_0(resetn),
    .mpcs_rx_pcs_rstn_i_0(resetn && mpcs_phyrdy),
    .mpcs_rx_out_clk_o_0(rx_clk),
    .mpcs_tx_out_clk_o_0(tx_clk),
    .mpcs_perstn_i_0(resetn),

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
    .mpcs_clkin_i_0(ref_clk),
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
    .mpcs_rxval_o_0(mpcs_rxval)
);

endmodule
