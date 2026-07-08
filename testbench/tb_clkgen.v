`ifndef __RTL_MODULE__TB_CLKGEN__
`define __RTL_MODULE__TB_CLKGEN__
`timescale 1ns / 1ps
//==========================================================================
// Module : tb_clkgen
//==========================================================================
module tb_clkgen #

( //--begin_param--
//----------------------------
// Parameters
//----------------------------
parameter                     NUMCLKS     = 1,
parameter                     REFCLKFREQ  = 32'd10,
parameter                     FABCLKFREQ  = 32'd10,
parameter [(NUMCLKS*32)-1:0]  CLKFREQ     = {NUMCLKS{32'd8}},
parameter [(NUMCLKS*32)-1:0]  CLKOUTDELAY = {NUMCLKS{32'd0}},
parameter                     DUMMY_PARAM = 0

) //--end_param--

( //--begin_ports--
//----------------------------
// Inputs
//----------------------------

//----------------------------
// Outputs
//----------------------------
output reg                    refck_o,
output reg                    mpcsck_o,
output wire [NUMCLKS-1:0]     genclk_o

); //--end_ports--



//--------------------------------------------------------------------------
//--- Local Parameters/Defines ---
//--------------------------------------------------------------------------

//--------------------------------------------------------------------------
//--- Combinational Wire/Reg ---
//--------------------------------------------------------------------------
reg         [NUMCLKS-1:0]     clk;
reg         [31:0]            clkfreq[NUMCLKS-1:0];

//--------------------------------------------------------------------------
//--- Registers ---
//--------------------------------------------------------------------------

assign genclk_o = clk;
initial begin
  refck_o  = 0;
  mpcsck_o  = 0;
  clk      = {NUMCLKS{1'b0}};
end

always refck_o  = #(REFCLKFREQ/2) ~refck_o;
always mpcsck_o = #(FABCLKFREQ/2) ~mpcsck_o;

genvar idx;
generate
  for(idx=0; idx<NUMCLKS; idx=idx+1) begin
    always begin
      clkfreq[idx] = CLKFREQ[32*idx +:32];
      clk[idx] = #(CLKFREQ[32*idx +:32]/2) ~clk[idx];
    end
  end
endgenerate

//--------------------------------------------------------------------------
//--- Module Instantiation ---
//--------------------------------------------------------------------------



endmodule //--tb_clkgen--
`endif // __RTL_MODULE__TB_CLKGEN__
