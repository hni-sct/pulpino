// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`include "config.sv"
`include "tb_jtag_pkg.sv"

`define REF_CLK_PERIOD   (2*15.25us)  // 32.786 kHz --> FLL reset value --> 50 MHz
`define CLK_PERIOD       40.00ns      // 66.66666 MHz

`define EXIT_SUCCESS  0
`define EXIT_FAIL     1
`define EXIT_ERROR   -1

module tb_wrap_ps;
  timeunit      1ns;
  timeprecision 1ps;

  // +MEMLOAD= valid values are "SPI", "STANDALONE" "PRELOAD", "" (no load of L2)
  parameter  SPI            = "SINGLE";    // valid values are "SINGLE", "QUAD"
  parameter  BAUDRATE       = 781250;    // 1562500
  parameter  CLK_USE_FLL    = 0;  // 0 or 1
  parameter  TEST           = ""; //valid values are "" (NONE), "DEBUG"
  parameter  USE_ZERO_RISCY = 1;
  parameter  RISCY_RV32F    = 0;
  parameter  ZERO_RV32M     = 0;
  parameter  ZERO_RV32E     = 1;

  int           exit_status = `EXIT_ERROR; // modelsim exit code, will be overwritten when successful

  string        memload;
  string        sdf;
  logic         s_clk   = 1'b0;


  logic         s_rst_n = 1'b0;
  logic         s_rst_n_e = 1'b1;
  wire          s_rst_n_wire = (s_rst_n_e == 1) ? s_rst_n : 1'bz;

  logic         fetch_enable = 1'b0;
  logic         fetch_enable_e = 1'b1;
  wire          fetch_enable_wire = (fetch_enable_e == 1) ? fetch_enable : 1'bz;

  logic [1:0]   padmode_spi_master;

  logic         spi_sck   = 1'b0;
  logic         spi_sck_en   = 1'b1;
  wire          spi_sck_wire = (spi_sck_en == 1) ? spi_sck : 1'bz;

  logic         spi_csn   = 1'b1;
  logic         spi_csn_en   = 1'b1;
  wire          spi_csn_wire = (spi_csn_en == 1) ? spi_csn : 1'bz;

  logic [1:0]   spi_mode;

  logic         spi_sdo0;
  logic         spi_sdo0_en   = 1'b1;
  wire          spi_sdo0_wire = (spi_sdo0_en == 1) ? spi_sdo0 : 1'bz;

  logic         spi_sdo1;
  logic         spi_sdo2;
  logic         spi_sdo3;

  logic         spi_sdi0;
  logic         spi_sdi0_en   = 1'b0;
  wire          spi_sdi0_wire = (spi_sdi0_en == 1) ? spi_sdi0 : 1'bz;

  logic         spi_sdi1;
  logic         spi_sdi2;
  logic         spi_sdi3;

  wire          uart_tx_wire;
  wire          uart_rx_wire;

//  logic         uart_rx;
//  logic         uart_rx_en   = 1'b0;
//  wire          uart_rx_wire = (uart_rx_en == 1) ? uart_rx : 1'bz;

  logic         s_uart_dtr;
  logic         s_uart_dtr_en   = 1'b0;
  wire          s_uart_dtr_wire = (s_uart_dtr_en == 1) ? s_uart_dtr : 1'bz;

  logic         s_uart_rts;
  logic         s_uart_rts_en   = 1'b0;
  wire          s_uart_rts_wire = (s_uart_rts_en == 1) ? s_uart_rts : 1'bz;

  logic         s_uart_cts = 1'b0;
  logic         s_uart_cts_en   = 1'b1;
  wire          s_uart_cts_wire = (s_uart_cts_en == 1) ? s_uart_cts : 1'bz;

  logic         s_uart_dsr = 1'b0;
  logic         s_uart_dsr_en   = 1'b1;
  wire          s_uart_dsr_wire = (s_uart_dsr_en == 1) ? s_uart_dsr : 1'bz;

  logic         scl_pad_i;
  logic         scl_pad_o;
  logic         scl_padoen_o;

  logic         sda_pad_i;
  logic         sda_pad_o;
  logic         sda_padoen_o;

  tri1          scl_io;
  tri1          sda_io;

  wire  [10:0]  gpio_bi;
  logic [10:0]  gpio_en = '0;
  logic [10:0]  gpio_in = '0;
  logic [10:0]  gpio_out;

  assign gpio_bi[9] = (gpio_en[9] == 1) ? gpio_in[9] : 1'bz; 
  assign gpio_bi[8] = (gpio_en[8] == 1) ? gpio_in[8] : 1'bz; 
  assign gpio_bi[7] = (gpio_en[7] == 1) ? gpio_in[7] : 1'bz; 
  assign gpio_bi[6] = (gpio_en[6] == 1) ? gpio_in[6] : 1'bz; 
  assign gpio_bi[5] = (gpio_en[5] == 1) ? gpio_in[5] : 1'bz; 
  assign gpio_bi[4] = (gpio_en[4] == 1) ? gpio_in[4] : 1'bz; 
  assign gpio_bi[3] = (gpio_en[3] == 1) ? gpio_in[3] : 1'bz; 
  assign gpio_bi[2] = (gpio_en[2] == 1) ? gpio_in[2] : 1'bz; 
  assign gpio_bi[1] = (gpio_en[1] == 1) ? gpio_in[1] : 1'bz; 
  assign gpio_bi[0] = (gpio_en[0] == 1) ? gpio_in[0] : 1'bz; 

  logic [31:0]  recv_data;

  jtag_i jtag_if();

  logic jtag_tck_en = 1'b1;
  wire  jtag_tck_wire = (jtag_tck_en == 1) ? jtag_if.tck : 1'bz;
  logic jtag_trstn_en = 1'b1;
  wire  jtag_trstn_wire = (jtag_trstn_en == 1) ? jtag_if.trstn : 1'bz;
  logic jtag_tms_en = 1'b1;
  wire  jtag_tms_wire = (jtag_tms_en == 1) ? jtag_if.tms : 1'bz;
  logic jtag_tdi_en = 1'b1;
  wire  jtag_tdi_wire = (jtag_tdi_en == 1) ? jtag_if.tdi : 1'bz;
  logic jtag_tdo_en = 1'b0;
  wire  jtag_tdo_wire = (jtag_tdo_en == 1) ? jtag_if.tdo : 1'bz;


  adv_dbg_if_t adv_dbg_if = new(jtag_if);

  // use 8N1
  uart_bus
  #(
    .BAUD_RATE(BAUDRATE),
    .PARITY_EN(0)
  )
  uart
  (
    .rx         ( uart_rx_wire ),
    .tx         ( uart_tx_wire ),
    .rx_en      ( 1'b1    )
  );

  spi_slave
  spi_master();

  logic spi_master_clk_en = 1'b0;
  wire  spi_master_clk_wire = (spi_master_clk_en == 1) ? spi_master.clk : 1'bz;
  logic spi_master_csn_en = 1'b0;
  wire  spi_master_csn_wire = (spi_master_csn_en == 1) ? spi_master.csn : 1'bz;
  logic spi_master_sdo_en = 1'b0;
  wire  spi_master_sdo_wire = (spi_master_sdo_en == 1) ? spi_master.sdo[0] : 1'bz;
  logic spi_master_sdi_en = 1'b1;
  wire  spi_master_sdi_wire = (spi_master_sdi_en == 1) ? spi_master.sdi[0] : 1'bz;



  i2c_buf i2c_buf_i
  (
    .scl_io       ( scl_io       ),
    .sda_io       ( sda_io       ),
    .scl_pad_i    ( scl_pad_i    ),
    .scl_pad_o    ( scl_pad_o    ),
    .scl_padoen_o ( scl_padoen_o ),
    .sda_pad_i    ( sda_pad_i    ),
    .sda_pad_o    ( sda_pad_o    ),
    .sda_padoen_o ( sda_padoen_o )
  );

  i2c_eeprom_model
  #(
    .ADDRESS ( 7'b1010_000 )
  )
  i2c_eeprom_model_i
  (
    .scl_io ( scl_io  ),
    .sda_io ( sda_io  ),
    .rst_ni ( s_rst_n )
  );
  
  tsmc65_wrap
  top_i
  (
    .clk               ( s_clk        ),
    .rst_n             ( s_rst_n_wire ),

    .fetch_enable_i    ( fetch_enable_wire ),

    .spi_clk_i         ( spi_sck_wire      ),
    .spi_cs_i          ( spi_csn_wire      ),
    .spi_sdo0_o        ( spi_sdi0_wire     ),
    .spi_sdi0_i        ( spi_sdo0_wire     ),

    .spi_master_clk_o  ( spi_master_clk_wire     ),
    .spi_master_csn0_o ( spi_master_csn_wire     ),
    .spi_master_sdo0_o ( spi_master_sdo_wire  ),
    .spi_master_sdi0_i ( spi_master_sdi_wire  ),

    .uart_tx           ( uart_rx_wire      ),
    .uart_rx           ( uart_tx_wire      ),
    .uart_rts          ( s_uart_rts_wire   ),
    .uart_dtr          ( s_uart_dtr_wire   ),
    .uart_cts          ( s_uart_cts_wire   ),
    .uart_dsr          ( s_uart_dsr_wire   ),

    .gpio              ( gpio_bi      ),

    .tck_i             ( jtag_tck_wire    ),
    .trstn_i           ( jtag_trstn_wire  ),
    .tms_i             ( jtag_tms_wire    ),
    .tdi_i             ( jtag_tdi_wire    ),
    .tdo_o             ( jtag_tdo_wire    )
  );

  generate
    if (CLK_USE_FLL) begin
      initial
      begin
        #(`REF_CLK_PERIOD/2);
        s_clk = 1'b1;
        forever s_clk = #(`REF_CLK_PERIOD/2) ~s_clk;
      end
    end else begin
      initial
      begin
        #(`CLK_PERIOD/2);
        s_clk = 1'b1;
        forever s_clk = #(`CLK_PERIOD/2) ~s_clk;
      end
    end
  endgenerate

  logic use_qspi;
  always @(*) begin
     if (gpio_en[9] == 0) begin
         gpio_out[9] = (gpio_bi[9] === 'z) ? 0 : gpio_bi[9]; 
     end
     if (gpio_en[8] == 0) begin
         gpio_out[8] = (gpio_bi[8] === 'z) ? 0 : gpio_bi[8]; 
     end
     if (gpio_en[7] == 0) begin
         gpio_out[7] = (gpio_bi[7] === 'z) ? 0 : gpio_bi[7]; 
     end
     if (gpio_en[6] == 0) begin
         gpio_out[6] = (gpio_bi[6] === 'z) ? 0 : gpio_bi[6]; 
     end
     if (gpio_en[5] == 0) begin
         gpio_out[5] = (gpio_bi[5] === 'z) ? 0 : gpio_bi[5]; 
     end
     if (gpio_en[4] == 0) begin
         gpio_out[4] = (gpio_bi[4] === 'z) ? 0 : gpio_bi[4]; 
     end
     if (gpio_en[3] == 0) begin
         gpio_out[3] = (gpio_bi[3] === 'z) ? 0 : gpio_bi[3]; 
     end
     if (gpio_en[2] == 0) begin
         gpio_out[2] = (gpio_bi[2] === 'z) ? 0 : gpio_bi[2]; 
     end
     if (gpio_en[1] == 0) begin
         gpio_out[1] = (gpio_bi[1] === 'z) ? 0 : gpio_bi[1]; 
     end
     if (gpio_en[0] == 0) begin
         gpio_out[0] = (gpio_bi[0] === 'z) ? 0 : gpio_bi[0]; 
     end

     jtag_if.tdo = jtag_tdo_wire;
     spi_sdi0 = spi_sdi0_wire;
  end

  initial
  begin
    int i;

    if(!$value$plusargs("SDF=%s", sdf))
      sdf = "";

    $display("SDF=%s", sdf);
    if (sdf != "") 
        $sdf_annotate(sdf, top_i);

    if(!$value$plusargs("MEMLOAD=%s", memload))
      memload = "PRELOAD";

    $display("Using MEMLOAD method: %s", memload);

    $display("Using %s core", USE_ZERO_RISCY ? "zero-riscy" : "ri5cy");

    use_qspi = SPI == "QUAD" ? 1'b1 : 1'b0;

    s_rst_n      = 1'b0;
    fetch_enable = 1'b0;

    #500ns;

    s_rst_n = 1'b1;

    #500ns;
    if (use_qspi)
      spi_enable_qpi();


    if (memload != "STANDALONE")
    begin
      /* Configure JTAG and set boot address */
      adv_dbg_if.jtag_reset();
      adv_dbg_if.jtag_softreset();
      adv_dbg_if.init();
      adv_dbg_if.axi4_write32(32'h1A10_7008, 1, 32'h0000_0000);
    end

    if (memload == "PRELOAD")
    begin
      // preload memories
      mem_preload();
    end
    else if (memload == "SPI")
    begin
      spi_load(use_qspi);
      spi_check(use_qspi);
    end

    #200ns;
    fetch_enable = 1'b1;

    if (TEST == "ARDUINO_UART") begin
      if (~gpio_out[0])
        wait(gpio_out[0]);
      uart.send_char(8'h65);
    end else if (TEST == "ARDUINO_GPIO") begin
      // Here  test for GPIO Starts
      if (~gpio_out[0])
        wait(gpio_out[0]);

      gpio_en[4]=1'b1;
      gpio_in[4]=1'b1;
      #50ns
      gpio_en[4]=1'b0;

      if (~gpio_out[1])
        wait(gpio_out[1]);
      if (~gpio_out[2])
        wait(gpio_out[2]);
      if (~gpio_out[3])
        wait(gpio_out[3]);

      gpio_en[7]=1'b1;
      gpio_in[7]=1'b1;
      #50ns
      gpio_en[7]=1'b0;

    end
    
    // end of computation
    if (~gpio_out[8])
      wait(gpio_out[8]);

    spi_check_return_codes(exit_status);

    $fflush();
    $stop();
  end

  // TODO: this is a hack, do it properly!
  `include "tb_spi_pkg.sv"
  `include "tb_mem_ps_pkg.sv"
  `include "spi_debug_test.svh"
  `include "mem_dpi.svh"

endmodule
