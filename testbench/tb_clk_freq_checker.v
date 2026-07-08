//`timescale 100ns/1ps
`timescale 10ps/10ps

module tb_clk_freq_checker # 
(
  parameter real EXP_CLKFREQ = 100, //expected Output Clock Frequency
  parameter      MODE = "Rx_and_Tx",
  parameter      NUM_LANES = 1
)
(
  input wire       tx_clk_out_o_0,
  input wire       tx_clk_out_o_1,
  input wire       tx_clk_out_o_2,
  input wire       tx_clk_out_o_3,
  input wire       tx_clk_out_o_4,
  input wire       tx_clk_out_o_5,
  input wire       tx_clk_out_o_6,
  input wire       tx_clk_out_o_7,
  input wire       rx_clk_out_o_0,
  input wire       rx_clk_out_o_1,
  input wire       rx_clk_out_o_2,
  input wire       rx_clk_out_o_3,
  input wire       rx_clk_out_o_4,
  input wire       rx_clk_out_o_5,
  input wire       rx_clk_out_o_6,
  input wire       rx_clk_out_o_7,
  input wire       fcheck, 
  output reg       check_done,            //Check is done
  output reg       tb_error  
);

//--------------------------------------------------------------------------
//--- Local Parameters/Defines ---
//--------------------------------------------------------------------------

localparam FREQ_LTLRNCE = (EXP_CLKFREQ) - (0.1*EXP_CLKFREQ);
localparam FREQ_HTLRNCE = (EXP_CLKFREQ) + (0.1*EXP_CLKFREQ);
// -----------------------------------------------------------------------------
// Register Declarations
// -----------------------------------------------------------------------------

reg  [8:0]  tx_exp_clk_freq_0;
reg  [8:0]  tx_exp_clk_freq_1;
reg  [8:0]  tx_exp_clk_freq_2;
reg  [8:0]  tx_exp_clk_freq_3;
reg  [8:0]  tx_exp_clk_freq_4;
reg  [8:0]  tx_exp_clk_freq_5;
reg  [8:0]  tx_exp_clk_freq_6;
reg  [8:0]  tx_exp_clk_freq_7;

reg  [8:0]  tx_actual_clk_freq_tol_0;
reg  [8:0]  tx_actual_clk_freq_tol_1;
reg  [8:0]  tx_actual_clk_freq_tol_2;
reg  [8:0]  tx_actual_clk_freq_tol_3;
reg  [8:0]  tx_actual_clk_freq_tol_4;
reg  [8:0]  tx_actual_clk_freq_tol_5;
reg  [8:0]  tx_actual_clk_freq_tol_6;
reg  [8:0]  tx_actual_clk_freq_tol_7;

reg  [8:0]  rx_exp_clk_freq_0;
reg  [8:0]  rx_exp_clk_freq_1;
reg  [8:0]  rx_exp_clk_freq_2;
reg  [8:0]  rx_exp_clk_freq_3;
reg  [8:0]  rx_exp_clk_freq_4;
reg  [8:0]  rx_exp_clk_freq_5;
reg  [8:0]  rx_exp_clk_freq_6;
reg  [8:0]  rx_exp_clk_freq_7;

reg  [8:0]  rx_actual_clk_freq_tol_0;
reg  [8:0]  rx_actual_clk_freq_tol_1;
reg  [8:0]  rx_actual_clk_freq_tol_2;
reg  [8:0]  rx_actual_clk_freq_tol_3;
reg  [8:0]  rx_actual_clk_freq_tol_4;
reg  [8:0]  rx_actual_clk_freq_tol_5;
reg  [8:0]  rx_actual_clk_freq_tol_6;
reg  [8:0]  rx_actual_clk_freq_tol_7;

reg  [9:0]  error_count;

// -----------------------------------------------------------------------------
// Wire Declarations
// -----------------------------------------------------------------------------

wire current_error_tx_rx_0;
wire current_error_tx_rx_1;
wire current_error_tx_rx_2;
wire current_error_tx_rx_3;
wire current_error_tx_rx_4;
wire current_error_tx_rx_5;
wire current_error_tx_rx_6;
wire current_error_tx_rx_7;

wire current_error_tx_0;
wire current_error_tx_1;
wire current_error_tx_2;
wire current_error_tx_3;
wire current_error_tx_4;
wire current_error_tx_5;
wire current_error_tx_6;
wire current_error_tx_7;

wire current_error_rx_0;
wire current_error_rx_1;
wire current_error_rx_2;
wire current_error_rx_3;
wire current_error_rx_4;
wire current_error_rx_5;
wire current_error_rx_6;
wire current_error_rx_7;

// -----------------------------------------------------------------------------
// Time/Real Declarations
// -----------------------------------------------------------------------------

time tx_time_prev_0;
time tx_time_prev_1;
time tx_time_prev_2;
time tx_time_prev_3;
time tx_time_prev_4;
time tx_time_prev_5;
time tx_time_prev_6;
time tx_time_prev_7;

time tx_time_nxt_0;
time tx_time_nxt_1;
time tx_time_nxt_2;
time tx_time_nxt_3;
time tx_time_nxt_4;
time tx_time_nxt_5;
time tx_time_nxt_6;
time tx_time_nxt_7;

time tx_actual_clk_period_0;
time tx_actual_clk_period_1;
time tx_actual_clk_period_2;
time tx_actual_clk_period_3;
time tx_actual_clk_period_4;
time tx_actual_clk_period_5;
time tx_actual_clk_period_6;
time tx_actual_clk_period_7;

time rx_time_prev_0;
time rx_time_prev_1;
time rx_time_prev_2;
time rx_time_prev_3;
time rx_time_prev_4;
time rx_time_prev_5;
time rx_time_prev_6;
time rx_time_prev_7;

time rx_time_nxt_0;
time rx_time_nxt_1;
time rx_time_nxt_2;
time rx_time_nxt_3;
time rx_time_nxt_4;
time rx_time_nxt_5;
time rx_time_nxt_6;
time rx_time_nxt_7;

time rx_actual_clk_period_0;
time rx_actual_clk_period_1;
time rx_actual_clk_period_2;
time rx_actual_clk_period_3;
time rx_actual_clk_period_4;
time rx_actual_clk_period_5;
time rx_actual_clk_period_6;
time rx_actual_clk_period_7;

real tx_actual_clk_freq_0;
real tx_actual_clk_freq_1;
real tx_actual_clk_freq_2;
real tx_actual_clk_freq_3;
real tx_actual_clk_freq_4;
real tx_actual_clk_freq_5;
real tx_actual_clk_freq_6;
real tx_actual_clk_freq_7;

real rx_actual_clk_freq_0;
real rx_actual_clk_freq_1;
real rx_actual_clk_freq_2;
real rx_actual_clk_freq_3;
real rx_actual_clk_freq_4;
real rx_actual_clk_freq_5;
real rx_actual_clk_freq_6;
real rx_actual_clk_freq_7;

//--------------------------------------------------------------------------
// Assign Statements
//--------------------------------------------------------------------------
assign current_error_tx_rx_0       = ((tx_actual_clk_freq_tol_0 && rx_actual_clk_freq_tol_0) === 9'b0) ? 1'b1 : 
                                   (((tx_exp_clk_freq_0 === tx_actual_clk_freq_tol_0) && (rx_exp_clk_freq_0 === rx_actual_clk_freq_tol_0)) ? 1'b0 : 1'b1);
assign current_error_tx_0          = (tx_actual_clk_freq_tol_0 === 9'b0) ? 1'b1 : 
                                   ((tx_exp_clk_freq_0 === tx_actual_clk_freq_tol_0) ? 1'b0 : 1'b1);
assign current_error_rx_0          = (rx_actual_clk_freq_tol_0 === 9'b0) ? 1'b1 : 
                                   ((rx_exp_clk_freq_0 === rx_actual_clk_freq_tol_0) ? 1'b0 : 1'b1);

assign current_error_tx_rx_1       = ((tx_actual_clk_freq_tol_1 && rx_actual_clk_freq_tol_1) === 9'b0) ? 1'b1 : 
                                   (((tx_exp_clk_freq_1 === tx_actual_clk_freq_tol_1) && (rx_exp_clk_freq_1 === rx_actual_clk_freq_tol_1)) ? 1'b0 : 1'b1);
assign current_error_tx_1          = (tx_actual_clk_freq_tol_1 === 9'b0) ? 1'b1 : 
                                   ((tx_exp_clk_freq_1 === tx_actual_clk_freq_tol_1) ? 1'b0 : 1'b1);
assign current_error_rx_1          = (rx_actual_clk_freq_tol_1 === 9'b0) ? 1'b1 : 
                                   ((rx_exp_clk_freq_1 === rx_actual_clk_freq_tol_1) ? 1'b0 : 1'b1);

assign current_error_tx_rx_2       = ((tx_actual_clk_freq_tol_2 && rx_actual_clk_freq_tol_2) === 9'b0) ? 1'b1 : 
                                   (((tx_exp_clk_freq_2 === tx_actual_clk_freq_tol_2) && (rx_exp_clk_freq_2 === rx_actual_clk_freq_tol_2)) ? 1'b0 : 1'b1);
assign current_error_tx_2          = (tx_actual_clk_freq_tol_2 === 9'b0) ? 1'b1 : 
                                   ((tx_exp_clk_freq_2 === tx_actual_clk_freq_tol_2) ? 1'b0 : 1'b1);
assign current_error_rx_2          = (rx_actual_clk_freq_tol_2 === 9'b0) ? 1'b1 : 
                                   ((rx_exp_clk_freq_2 === rx_actual_clk_freq_tol_2) ? 1'b0 : 1'b1);

assign current_error_tx_rx_3       = ((tx_actual_clk_freq_tol_3 && rx_actual_clk_freq_tol_3) === 9'b0) ? 1'b1 : 
                                   (((tx_exp_clk_freq_3 === tx_actual_clk_freq_tol_3) && (rx_exp_clk_freq_3 === rx_actual_clk_freq_tol_3)) ? 1'b0 : 1'b1);
assign current_error_tx_3          = (tx_actual_clk_freq_tol_3 === 9'b0) ? 1'b1 : 
                                   ((tx_exp_clk_freq_3 === tx_actual_clk_freq_tol_3) ? 1'b0 : 1'b1);
assign current_error_rx_3          = (rx_actual_clk_freq_tol_3 === 9'b0) ? 1'b1 : 
                                   ((rx_exp_clk_freq_3 === rx_actual_clk_freq_tol_3) ? 1'b0 : 1'b1);

assign current_error_tx_rx_4       = ((tx_actual_clk_freq_tol_4 && rx_actual_clk_freq_tol_4) === 9'b0) ? 1'b1 : 
                                   (((tx_exp_clk_freq_4 === tx_actual_clk_freq_tol_4) && (rx_exp_clk_freq_4 === rx_actual_clk_freq_tol_4)) ? 1'b0 : 1'b1);
assign current_error_tx_4          = (tx_actual_clk_freq_tol_4 === 9'b0) ? 1'b1 : 
                                   ((tx_exp_clk_freq_4 === tx_actual_clk_freq_tol_4) ? 1'b0 : 1'b1);
assign current_error_rx_4          = (rx_actual_clk_freq_tol_4 === 9'b0) ? 1'b1 : 
                                   ((rx_exp_clk_freq_4 === rx_actual_clk_freq_tol_4) ? 1'b0 : 1'b1);

assign current_error_tx_rx_5       = ((tx_actual_clk_freq_tol_5 && rx_actual_clk_freq_tol_5) === 9'b0) ? 1'b1 : 
                                   (((tx_exp_clk_freq_5 === tx_actual_clk_freq_tol_5) && (rx_exp_clk_freq_5 === rx_actual_clk_freq_tol_5)) ? 1'b0 : 1'b1);
assign current_error_tx_5          = (tx_actual_clk_freq_tol_5 === 9'b0) ? 1'b1 : 
                                   ((tx_exp_clk_freq_5 === tx_actual_clk_freq_tol_5) ? 1'b0 : 1'b1);
assign current_error_rx_5          = (rx_actual_clk_freq_tol_5 === 9'b0) ? 1'b1 : 
                                   ((rx_exp_clk_freq_5 === rx_actual_clk_freq_tol_5) ? 1'b0 : 1'b1);

assign current_error_tx_rx_6       = ((tx_actual_clk_freq_tol_6 && rx_actual_clk_freq_tol_6) === 9'b0) ? 1'b1 : 
                                   (((tx_exp_clk_freq_6 === tx_actual_clk_freq_tol_6) && (rx_exp_clk_freq_6 === rx_actual_clk_freq_tol_6)) ? 1'b0 : 1'b1);
assign current_error_tx_6          = (tx_actual_clk_freq_tol_6 === 9'b0) ? 1'b1 : 
                                   ((tx_exp_clk_freq_6 === tx_actual_clk_freq_tol_6) ? 1'b0 : 1'b1);
assign current_error_rx_6          = (rx_actual_clk_freq_tol_6 === 9'b0) ? 1'b1 : 
                                   ((rx_exp_clk_freq_6 === rx_actual_clk_freq_tol_6) ? 1'b0 : 1'b1);

assign current_error_tx_rx_7       = ((tx_actual_clk_freq_tol_7 && rx_actual_clk_freq_tol_7) === 9'b0) ? 1'b1 : 
                                   (((tx_exp_clk_freq_7 === tx_actual_clk_freq_tol_7) && (rx_exp_clk_freq_7 === rx_actual_clk_freq_tol_7)) ? 1'b0 : 1'b1);
assign current_error_tx_7          = (tx_actual_clk_freq_tol_7 === 9'b0) ? 1'b1 : 
                                   ((tx_exp_clk_freq_7 === tx_actual_clk_freq_tol_7) ? 1'b0 : 1'b1);
assign current_error_rx_7          = (rx_actual_clk_freq_tol_7 === 9'b0) ? 1'b1 : 
                                   ((rx_exp_clk_freq_7 === rx_actual_clk_freq_tol_7) ? 1'b0 : 1'b1);


//--------------------------------------------------------------------------
// Initial statement; Reset sequence
//--------------------------------------------------------------------------
initial begin
  error_count               = 1'b0;

  tx_actual_clk_freq_tol_0  = 9'b0;
  tx_actual_clk_freq_tol_1  = 9'b0;
  tx_actual_clk_freq_tol_2  = 9'b0;
  tx_actual_clk_freq_tol_3  = 9'b0;
  tx_actual_clk_freq_tol_4  = 9'b0;
  tx_actual_clk_freq_tol_5  = 9'b0;
  tx_actual_clk_freq_tol_6  = 9'b0;
  tx_actual_clk_freq_tol_7  = 9'b0;
  
  tx_exp_clk_freq_0         = 9'b0;
  tx_exp_clk_freq_1         = 9'b0;
  tx_exp_clk_freq_2         = 9'b0;
  tx_exp_clk_freq_3         = 9'b0;
  tx_exp_clk_freq_4         = 9'b0;
  tx_exp_clk_freq_5         = 9'b0;
  tx_exp_clk_freq_6         = 9'b0;
  tx_exp_clk_freq_7         = 9'b0;
  
  rx_actual_clk_freq_tol_0  = 9'b0;
  rx_actual_clk_freq_tol_1  = 9'b0;
  rx_actual_clk_freq_tol_2  = 9'b0;
  rx_actual_clk_freq_tol_3  = 9'b0;
  rx_actual_clk_freq_tol_4  = 9'b0;
  rx_actual_clk_freq_tol_5  = 9'b0;
  rx_actual_clk_freq_tol_6  = 9'b0;
  rx_actual_clk_freq_tol_7  = 9'b0;

  rx_exp_clk_freq_0         = 9'b0;
  rx_exp_clk_freq_1         = 9'b0;
  rx_exp_clk_freq_2         = 9'b0;
  rx_exp_clk_freq_3         = 9'b0;
  rx_exp_clk_freq_4         = 9'b0;
  rx_exp_clk_freq_5         = 9'b0;
  rx_exp_clk_freq_6         = 9'b0;
  rx_exp_clk_freq_7         = 9'b0;
  
  @(&fcheck)
  $display("+-----------------------------------------------");
  $display(" Start of Clock Frequency Checking.             ");
  $display("+-----------------------------------------------");
  
  if (MODE == "Tx_only") begin
    $display("Expected Lane 0 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_0); 
    tb_error = current_error_tx_0;
  end
  else if (MODE == "Rx_only") begin
    $display("Expected Lane 0 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_0); 
    tb_error = current_error_rx_0;
  end
  else begin
    $display("Expected Lane 0 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_0); 
    $display("Expected Lane 0 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_0); 
    tb_error = current_error_tx_rx_0;
  end

  if (NUM_LANES > 1) begin
    if (MODE == "Tx_only") begin
      $display("Expected Lane 1 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_1); 
      tb_error = current_error_tx_1;
    end
    else if (MODE == "Rx_only") begin
      $display("Expected Lane 1 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_1); 
      tb_error = current_error_rx_1;
    end
    else begin
      $display("Expected Lane 1 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_1); 
      $display("Expected Lane 1 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_1); 
      tb_error = current_error_tx_rx_1;
    end 
  end

  if (NUM_LANES > 2) begin
    if (MODE == "Tx_only") begin
      $display("Expected Lane 2 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_2); 
      tb_error = current_error_tx_2;
    end
    else if (MODE == "Rx_only") begin
      $display("Expected Lane 2 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_2); 
      tb_error = current_error_rx_2;
    end
    else begin
      $display("Expected Lane 2 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_2); 
      $display("Expected Lane 2 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_2); 
      tb_error = current_error_tx_rx_2;
    end

    if (MODE == "Tx_only") begin
      $display("Expected Lane 3 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_3); 
      tb_error = current_error_tx_3;
    end
    else if (MODE == "Rx_only") begin
      $display("Expected Lane 3 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_3); 
      tb_error = current_error_rx_3;
    end
    else begin
      $display("Expected Lane 3 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_3); 
      $display("Expected Lane 3 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_3); 
      tb_error = current_error_tx_rx_3;
    end
  end

  if (NUM_LANES > 4) begin
    if (MODE == "Tx_only") begin
      $display("Expected Lane 4 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_4); 
      tb_error = current_error_tx_4;
    end
    else if (MODE == "Rx_only") begin
      $display("Expected Lane 4 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_4); 
      tb_error = current_error_rx_4;
    end
    else begin
      $display("Expected Lane 4 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_4); 
      $display("Expected Lane 4 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_4); 
      tb_error = current_error_tx_rx_4;
    end

    if (MODE == "Tx_only") begin
      $display("Expected Lane 5 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_5); 
      tb_error = current_error_tx_5;
    end
    else if (MODE == "Rx_only") begin
      $display("Expected Lane 5 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_5); 
      tb_error = current_error_rx_5;
    end
    else begin
      $display("Expected Lane 5 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_5); 
      $display("Expected Lane 5 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_5); 
      tb_error = current_error_tx_rx_5;
    end
  end

  if (NUM_LANES > 6) begin
    if (MODE == "Tx_only") begin
      $display("Expected Lane 6 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_6); 
      tb_error = current_error_tx_6;
    end
    else if (MODE == "Rx_only") begin
      $display("Expected Lane 6 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_6); 
      tb_error = current_error_rx_6;
    end
    else begin
      $display("Expected Lane 6 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_6); 
      $display("Expected Lane 6 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_6); 
      tb_error = current_error_tx_rx_6;
    end

    if (MODE == "Tx_only") begin
      $display("Expected Lane 7 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_7); 
      tb_error = current_error_tx_7;
    end
    else if (MODE == "Rx_only") begin
      $display("Expected Lane 7 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_7); 
      tb_error = current_error_rx_7;
    end
    else begin
      $display("Expected Lane 7 TX Out Clk Frequency(MHz) : %1.4f, Actual TX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, tx_actual_clk_freq_7); 
      $display("Expected Lane 7 RX Out Clk Frequency(MHz) : %1.4f, Actual RX Out Clk Frequency(MHz): %1.4f", EXP_CLKFREQ, rx_actual_clk_freq_7); 
      tb_error = current_error_tx_rx_7;
    end
  end
              
  #100
  if (tb_error == 0) begin
    $display("       **************** CLOCK MATCHED ****************            ");
  end
  else begin
    $display("     **************** !!! CLOCK MISMATCHED !!! ****************     ");
  end
  
  //  #(2400000) sel_450n_i   = 1; //can be used for dynamic clock rate change
  //  
  //  $display("+-----------------------------------------------------------------");
  //  $display("Switching User Clock Test to <360MHz/CLK Divider>                 ");
  //  $display("+-----------------------------------------------------------------");
  //  $monitor("Expected Frequency(MHz) : %1.1f, Actual Frequency(MHz): %1.1f", exp_clk_freq, actual_clk_freq); 
    
  //  #(2500000) sel_450n_i  = 0; 
  //
  //  $display("+-----------------------------------------------------------------");
  //  $display("Switching User Clock Test to <450MHz/CLK Divider>                 ");
  //  $display( "+-----------------------------------------------------------------");
  //  $monitor("Expected Frequency(MHz) : %1.1f, Actual Frequency(MHz): %1.1f", exp_clk_freq, actual_clk_freq);

  #100 check_done = 1;
  // $finish;
end

// --------------------------------
// ----- tx_clk_out_o_0 Checker -----
// --------------------------------
always @(posedge tx_clk_out_o_0) begin     
  tx_time_prev_0    <= $time;
  tx_time_nxt_0     <= tx_time_prev_0;
  tx_exp_clk_freq_0 <= EXP_CLKFREQ;
end

// --------------------------------
// ----- rx_clk_out_o_0 Checker -----
// --------------------------------
always @(posedge rx_clk_out_o_0) begin  
  rx_time_prev_0    <= $time; 
  rx_time_nxt_0     <= rx_time_prev_0;  
  rx_exp_clk_freq_0 <= EXP_CLKFREQ;
end

// ----------------------------------------------------
// ---Calculating Lane 0 TX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (tx_clk_out_o_0) begin
    tx_actual_clk_period_0   = (tx_time_prev_0 - tx_time_nxt_0);
    tx_actual_clk_freq_0     = 100000.00/tx_actual_clk_period_0; 
    tx_actual_clk_freq_tol_0 = (tx_actual_clk_freq_0 >= FREQ_LTLRNCE) && (tx_actual_clk_freq_0 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// ----------------------------------------------------
// ---Calculating Lane 0 RX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (rx_clk_out_o_0) begin
    rx_actual_clk_period_0   = (rx_time_prev_0 - rx_time_nxt_0);
    rx_actual_clk_freq_0     = 100000.00/rx_actual_clk_period_0;
    rx_actual_clk_freq_tol_0 = (rx_actual_clk_freq_0 >= FREQ_LTLRNCE) && (rx_actual_clk_freq_0 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// --------------------------------
// ----- tx_clk_out_o_1 Checker -----
// --------------------------------
always @(posedge tx_clk_out_o_1) begin     
  tx_time_prev_1    <= $time;
  tx_time_nxt_1     <= tx_time_prev_1;
  tx_exp_clk_freq_1 <= EXP_CLKFREQ;
end

// --------------------------------
// ----- rx_clk_out_o_1 Checker -----
// --------------------------------
always @(posedge rx_clk_out_o_1) begin  
  rx_time_prev_1    <= $time; 
  rx_time_nxt_1     <= rx_time_prev_1;  
  rx_exp_clk_freq_1 <= EXP_CLKFREQ;
end

// ----------------------------------------------------
// ---Calculating Lane 1 TX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (tx_clk_out_o_1) begin
    tx_actual_clk_period_1   = (tx_time_prev_1 - tx_time_nxt_1);
    tx_actual_clk_freq_1     = 100000.00/tx_actual_clk_period_1; 
    tx_actual_clk_freq_tol_1 = (tx_actual_clk_freq_1 >= FREQ_LTLRNCE) && (tx_actual_clk_freq_1 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// ----------------------------------------------------
// ---Calculating Lane 1 RX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (rx_clk_out_o_1) begin
    rx_actual_clk_period_1   = (rx_time_prev_1 - rx_time_nxt_1);
    rx_actual_clk_freq_1     = 100000.00/rx_actual_clk_period_1;
    rx_actual_clk_freq_tol_1 = (rx_actual_clk_freq_1 >= FREQ_LTLRNCE) && (rx_actual_clk_freq_1 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// --------------------------------
// ----- tx_clk_out_o_2 Checker -----
// --------------------------------
always @(posedge tx_clk_out_o_2) begin     
  tx_time_prev_2    <= $time;
  tx_time_nxt_2     <= tx_time_prev_2;
  tx_exp_clk_freq_2 <= EXP_CLKFREQ;
end

// --------------------------------
// ----- rx_clk_out_o_2 Checker -----
// --------------------------------
always @(posedge rx_clk_out_o_2) begin  
  rx_time_prev_2    <= $time; 
  rx_time_nxt_2     <= rx_time_prev_2;  
  rx_exp_clk_freq_2 <= EXP_CLKFREQ;
end

// ----------------------------------------------------
// ---Calculating Lane 2 TX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (tx_clk_out_o_2) begin
    tx_actual_clk_period_2   = (tx_time_prev_2 - tx_time_nxt_2);
    tx_actual_clk_freq_2     = 100000.00/tx_actual_clk_period_2; 
    tx_actual_clk_freq_tol_2 = (tx_actual_clk_freq_2 >= FREQ_LTLRNCE) && (tx_actual_clk_freq_2 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// ----------------------------------------------------
// ---Calculating Lane 2 RX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (rx_clk_out_o_2) begin
    rx_actual_clk_period_2   = (rx_time_prev_2 - rx_time_nxt_2);
    rx_actual_clk_freq_2     = 100000.00/rx_actual_clk_period_2;
    rx_actual_clk_freq_tol_2 = (rx_actual_clk_freq_2 >= FREQ_LTLRNCE) && (rx_actual_clk_freq_2 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// --------------------------------
// ----- tx_clk_out_o_3 Checker -----
// --------------------------------
always @(posedge tx_clk_out_o_3) begin     
  tx_time_prev_3    <= $time;
  tx_time_nxt_3     <= tx_time_prev_3;
  tx_exp_clk_freq_3 <= EXP_CLKFREQ;
end

// --------------------------------
// ----- rx_clk_out_o_3 Checker -----
// --------------------------------
always @(posedge rx_clk_out_o_3) begin  
  rx_time_prev_3    <= $time; 
  rx_time_nxt_3     <= rx_time_prev_3;  
  rx_exp_clk_freq_3 <= EXP_CLKFREQ;
end

// ----------------------------------------------------
// ---Calculating Lane 3 TX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (tx_clk_out_o_3) begin
    tx_actual_clk_period_3   = (tx_time_prev_3 - tx_time_nxt_3);
    tx_actual_clk_freq_3     = 100000.00/tx_actual_clk_period_3; 
    tx_actual_clk_freq_tol_3 = (tx_actual_clk_freq_3 >= FREQ_LTLRNCE) && (tx_actual_clk_freq_3 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// ----------------------------------------------------
// ---Calculating Lane 3 RX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (rx_clk_out_o_3) begin
    rx_actual_clk_period_3   = (rx_time_prev_3 - rx_time_nxt_3);
    rx_actual_clk_freq_3     = 100000.00/rx_actual_clk_period_3;
    rx_actual_clk_freq_tol_3 = (rx_actual_clk_freq_3 >= FREQ_LTLRNCE) && (rx_actual_clk_freq_3 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// --------------------------------
// ----- tx_clk_out_o_4 Checker -----
// --------------------------------
always @(posedge tx_clk_out_o_4) begin     
  tx_time_prev_4    <= $time;
  tx_time_nxt_4     <= tx_time_prev_4;
  tx_exp_clk_freq_4 <= EXP_CLKFREQ;
end

// --------------------------------
// ----- rx_clk_out_o_4 Checker -----
// --------------------------------
always @(posedge rx_clk_out_o_4) begin  
  rx_time_prev_4    <= $time; 
  rx_time_nxt_4     <= rx_time_prev_4;  
  rx_exp_clk_freq_4 <= EXP_CLKFREQ;
end

// ----------------------------------------------------
// ---Calculating Lane 4 TX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (tx_clk_out_o_4) begin
    tx_actual_clk_period_4   = (tx_time_prev_4 - tx_time_nxt_4);
    tx_actual_clk_freq_4     = 100000.00/tx_actual_clk_period_4; 
    tx_actual_clk_freq_tol_4 = (tx_actual_clk_freq_4 >= FREQ_LTLRNCE) && (tx_actual_clk_freq_4 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// ----------------------------------------------------
// ---Calculating Lane 4 RX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (rx_clk_out_o_4) begin
    rx_actual_clk_period_4   = (rx_time_prev_4 - rx_time_nxt_4);
    rx_actual_clk_freq_4     = 100000.00/rx_actual_clk_period_4;
    rx_actual_clk_freq_tol_4 = (rx_actual_clk_freq_4 >= FREQ_LTLRNCE) && (rx_actual_clk_freq_4 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// --------------------------------
// ----- tx_clk_out_o_5 Checker -----
// --------------------------------
always @(posedge tx_clk_out_o_5) begin     
  tx_time_prev_5    <= $time;
  tx_time_nxt_5     <= tx_time_prev_5;
  tx_exp_clk_freq_5 <= EXP_CLKFREQ;
end

// --------------------------------
// ----- rx_clk_out_o_5 Checker -----
// --------------------------------
always @(posedge rx_clk_out_o_5) begin  
  rx_time_prev_5    <= $time; 
  rx_time_nxt_5     <= rx_time_prev_5;  
  rx_exp_clk_freq_5 <= EXP_CLKFREQ;
end

// ----------------------------------------------------
// ---Calculating Lane 5 TX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (tx_clk_out_o_5) begin
    tx_actual_clk_period_5   = (tx_time_prev_5 - tx_time_nxt_5);
    tx_actual_clk_freq_5     = 100000.00/tx_actual_clk_period_5; 
    tx_actual_clk_freq_tol_5 = (tx_actual_clk_freq_5 >= FREQ_LTLRNCE) && (tx_actual_clk_freq_5 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// ----------------------------------------------------
// ---Calculating Lane 5 RX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (rx_clk_out_o_5) begin
    rx_actual_clk_period_5   = (rx_time_prev_5 - rx_time_nxt_5);
    rx_actual_clk_freq_5     = 100000.00/rx_actual_clk_period_5;
    rx_actual_clk_freq_tol_5 = (rx_actual_clk_freq_5 >= FREQ_LTLRNCE) && (rx_actual_clk_freq_5 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// --------------------------------
// ----- tx_clk_out_o_6 Checker -----
// --------------------------------
always @(posedge tx_clk_out_o_6) begin     
  tx_time_prev_6    <= $time;
  tx_time_nxt_6     <= tx_time_prev_6;
  tx_exp_clk_freq_6 <= EXP_CLKFREQ;
end

// --------------------------------
// ----- rx_clk_out_o_6 Checker -----
// --------------------------------
always @(posedge rx_clk_out_o_6) begin  
  rx_time_prev_6    <= $time; 
  rx_time_nxt_6     <= rx_time_prev_6;  
  rx_exp_clk_freq_6 <= EXP_CLKFREQ;
end

// ----------------------------------------------------
// ---Calculating Lane 6 TX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (tx_clk_out_o_6) begin
    tx_actual_clk_period_6   = (tx_time_prev_6 - tx_time_nxt_6);
    tx_actual_clk_freq_6     = 100000.00/tx_actual_clk_period_6; 
    tx_actual_clk_freq_tol_6 = (tx_actual_clk_freq_6 >= FREQ_LTLRNCE) && (tx_actual_clk_freq_6 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// ----------------------------------------------------
// ---Calculating Lane 6 RX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (rx_clk_out_o_6) begin
    rx_actual_clk_period_6   = (rx_time_prev_6 - rx_time_nxt_6);
    rx_actual_clk_freq_6     = 100000.00/rx_actual_clk_period_6;
    rx_actual_clk_freq_tol_6 = (rx_actual_clk_freq_6 >= FREQ_LTLRNCE) && (rx_actual_clk_freq_6 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// --------------------------------
// ----- tx_clk_out_o_7 Checker -----
// --------------------------------
always @(posedge tx_clk_out_o_7) begin     
  tx_time_prev_7    <= $time;
  tx_time_nxt_7     <= tx_time_prev_7;
  tx_exp_clk_freq_7 <= EXP_CLKFREQ;
end

// --------------------------------
// ----- rx_clk_out_o_7 Checker -----
// --------------------------------
always @(posedge rx_clk_out_o_7) begin  
  rx_time_prev_7    <= $time; 
  rx_time_nxt_7     <= rx_time_prev_7;  
  rx_exp_clk_freq_7 <= EXP_CLKFREQ;
end

// ----------------------------------------------------
// ---Calculating Lane 7 TX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (tx_clk_out_o_7) begin
    tx_actual_clk_period_7   = (tx_time_prev_7 - tx_time_nxt_7);
    tx_actual_clk_freq_7     = 100000.00/tx_actual_clk_period_7; 
    tx_actual_clk_freq_tol_7 = (tx_actual_clk_freq_7 >= FREQ_LTLRNCE) && (tx_actual_clk_freq_7 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// ----------------------------------------------------
// ---Calculating Lane 7 RX Actual Frequency and Tolerance ---
// ----------------------------------------------------
always @* begin
  if (rx_clk_out_o_7) begin
    rx_actual_clk_period_7   = (rx_time_prev_7 - rx_time_nxt_7);
    rx_actual_clk_freq_7     = 100000.00/rx_actual_clk_period_7;
    rx_actual_clk_freq_tol_7 = (rx_actual_clk_freq_7 >= FREQ_LTLRNCE) && (rx_actual_clk_freq_7 <= FREQ_HTLRNCE) ? EXP_CLKFREQ : 0;
  end
end

// -----------------------------
// ------ Error Counter  ------
// -----------------------------
always @ * begin
 if (tb_error) begin
   error_count = error_count + 1;
 end
 else begin
   error_count = error_count;
 end
end

endmodule
