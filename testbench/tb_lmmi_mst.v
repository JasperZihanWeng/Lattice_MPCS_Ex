`ifndef __RTL_MODULE__TB_LMMI_MST__
`define __RTL_MODULE__TB_LMMI_MST__

`timescale 1ns/1ps
//==========================================================================
// Module : tb_lmmi_mst
//==========================================================================
module tb_lmmi_mst

#( //--begin_param--
//----------------------------
// Parameters
//----------------------------
parameter                     MODESEL     = 0,
parameter                     PCS_BYPASS  = 0

) //--end_param--

( //--begin_ports--
//----------------------------
// Inputs
//----------------------------
input       [63:0]            lmmi_rdata,
input       [7:0]             lmmi_rdata_valid,
input       [7:0]             lmmi_ready,
input                         lmmi_error,

//----------------------------
// Outputs
//----------------------------
output reg                    lmmi_clk,
output reg                    lmmi_resetn,
output reg  [8:0]             lmmi_offset,
output reg                    lmmi_request,
output reg  [7:0]             lmmi_wdata,
output reg                    lmmi_wr_rdn

); //--end_ports--



//--------------------------------------------------------------------------
//--- Local Parameters/Defines ---
//--------------------------------------------------------------------------
localparam    CLKPERIOD = 5; 
localparam    OFFSET_MSB = (MODESEL == 2 || (MODESEL == 0 && PCS_BYPASS == 1)) ? 1'b0 : 1'b1; 
        //1'b1 - MPCS registers
        //1'b0 - PCIE-PCS+PMA registers
//--------------------------------------------------------------------------
//--- Combinational Wire/Reg ---
//--------------------------------------------------------------------------

//--------------------------------------------------------------------------
//--- Registers ---
//--------------------------------------------------------------------------
reg  [15:0] addr;
reg  [7:0]  data;    //write - 1 lane
reg  [63:0]  rddata; //read -- all lanes

initial begin
  lmmi_clk     = 0;
  lmmi_offset  = 16'h0;
  lmmi_request = 0;
  lmmi_wdata   = 0;
  lmmi_wr_rdn  = 0;
  lmmi_resetn  = 1; 

  #(25*CLKPERIOD) lmmi_resetn  = 0;    
  #(2*CLKPERIOD) lmmi_resetn  = 1;   

end

always #(CLKPERIOD/2) lmmi_clk = ~lmmi_clk;

task m_write
(
  input  [7:0]  addr,
  input  [7:0] data
);
  reg           done;
  begin
    //@(posedge lmmi_clk);
      lmmi_request <= 1'b1;
      lmmi_wr_rdn <= 1'b1;    
      lmmi_wdata <= data;  
      lmmi_offset <= {OFFSET_MSB, addr};

    done = 0;
    while(!done) begin
      @(posedge lmmi_clk);
        done = lmmi_ready;
    end
    lmmi_request <= 1'b0;
    lmmi_wr_rdn <= 1'b0;
  end
endtask // m_write

task m_read
(
  input  [7:0]  addr,
  output [63:0] data
);
  reg           done;
  reg           valid;
  begin
    //@(posedge lmmi_clk);
      lmmi_request <= 1'b1;  
      lmmi_wr_rdn <= 1'b0;
      lmmi_offset <= {OFFSET_MSB, addr}; 

    fork
      begin // request
        done = 0;
        while(!done) begin
          @(posedge lmmi_clk);
            done = lmmi_ready;
        end
        lmmi_request <= 1'b0; 
      end

      begin // data
        valid = 0;
        while(!valid | !done) begin
          @(posedge lmmi_clk);
            valid = lmmi_rdata_valid;
        end
        data = lmmi_rdata;
      end
    join
  end
endtask // m_read

//--------------------------------------------------------------------------
//--- Module Instantiation ---
//--------------------------------------------------------------------------

endmodule //--tb_lmmi_mst--
`endif // __RTL_MODULE__TB_LMMI_MST__
