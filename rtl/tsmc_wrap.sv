// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module tsmc65_wrap
  (
    // Clock and Reset
    input logic               clk /*verilator clocker*/,
    inout logic               rst_n,

//    input  logic              clk_sel_i,
//    input  logic              clk_standalone_i,
//    input  logic              testmode_i,
//    input  logic              fetch_enable_i,
//    input  logic              scan_enable_i,

    //SPI Slave
    inout  logic              spi_clk_i /*verilator clocker*/,
    inout  logic              spi_cs_i /*verilator clocker*/,
//    output logic [1:0]        spi_mode_o,
    inout logic               spi_sdo0_o,
//    output logic              spi_sdo1_o,
//    output logic              spi_sdo2_o,
//    output logic              spi_sdo3_o,
    inout  logic              spi_sdi0_i,
//    input  logic              spi_sdi1_i,
//    input  logic              spi_sdi2_i,
//    input  logic              spi_sdi3_i,

    //SPI Master
    inout  logic              spi_master_clk_o,
    inout  logic              spi_master_csn0_o,
//    output logic              spi_master_csn1_o,
//    output logic              spi_master_csn2_o,
//    output logic              spi_master_csn3_o,
//    output logic [1:0]        spi_master_mode_o,
    inout  logic              spi_master_sdo0_o,
//    output logic              spi_master_sdo1_o,
//    output logic              spi_master_sdo2_o,
//    output logic              spi_master_sdo3_o,
    inout  logic              spi_master_sdi0_i,
//    input  logic              spi_master_sdi1_i,
//    input  logic              spi_master_sdi2_i,
//    input  logic              spi_master_sdi3_i,

// i2c
//    input  logic              scl_pad_i,
//    output logic              scl_pad_o,
//    output logic              scl_padoen_o,
//    input  logic              sda_pad_i,
//    output logic              sda_pad_o,
//    output logic              sda_padoen_o,

    inout  logic              uart_tx,
    inout  logic              uart_rx,
    inout  logic              uart_rts,
    inout  logic              uart_dtr,
    inout  logic              uart_cts,
    inout  logic              uart_dsr,

    inout logic          [8:0] gpio,
//    input  logic       [31:0] gpio_in,
//    output logic       [31:0] gpio_out,
//    output logic       [31:0] gpio_dir,
//    output logic [31:0] [5:0] gpio_padcfg,

    // JTAG signals
    inout  logic              tck_i,
    inout  logic              trstn_i,
    inout  logic              tms_i,
    inout  logic              tdi_i,
    inout  logic              tdo_o

    // PULPino specific pad config
//    output logic [31:0] [5:0] pad_cfg_o,
//    output logic       [31:0] pad_mux_o
  );

// Internal wires
    logic net_clk;
    logic net_rst_n;
    logic net_clk_sel_i;
    logic net_clk_standalone_i;
    logic net_testmode_i;
    logic net_fetch_enable_i;
    logic net_scan_enable_i;
    logic net_spi_clk_i;
    logic net_spi_cs_i;
    logic [1:0] net_spi_mode_o;
    logic net_spi_sdo0_o;
    logic net_spi_sdo1_o;
    logic net_spi_sdo2_o;
    logic net_spi_sdo3_o;
    logic net_spi_sdi0_i;
    logic net_spi_sdi1_i;
    logic net_spi_sdi2_i;
    logic net_spi_sdi3_i;
    logic net_spi_master_clk_o;
    logic net_spi_master_csn0_o;
    logic net_spi_master_csn1_o;
    logic net_spi_master_csn2_o;
    logic net_spi_master_csn3_o;
    logic [1:0] net_spi_master_mode_o;
    logic net_spi_master_sdo0_o;
    logic net_spi_master_sdo1_o;
    logic net_spi_master_sdo2_o;
    logic net_spi_master_sdo3_o;
    logic net_spi_master_sdi0_i;
    logic net_spi_master_sdi1_i;
    logic net_spi_master_sdi2_i;
    logic net_spi_master_sdi3_i;
    logic net_scl_pad_i;
    logic net_scl_pad_o;
    logic net_scl_padoen_o;
    logic net_sda_pad_i;
    logic net_sda_pad_o;
    logic net_sda_padoen_o;
    logic net_uart_tx;
    logic net_uart_rx;
    logic net_uart_rts;
    logic net_uart_dtr;
    logic net_uart_cts;
    logic net_uart_dsr;
    logic [31:0] net_gpio_in;
    logic [31:0] net_gpio_out;
    logic [31:0] net_gpio_dir;
    logic [31:0][5:0] net_gpio_padcfg;
    logic net_tck_i;
    logic net_trstn_i;
    logic net_tms_i;
    logic net_tdi_i;
    logic net_tdo_o;
    logic [31:0][5:0] net_pad_cfg_o;
    logic [31:0] net_pad_mux_o;


  pulpino_top 
  #(
    .USE_ZERO_RISCY(1),
    .RISCY_RV32F(0),
    .ZERO_RV32M(1),
    .ZERO_RV32E(0)
   ) top_inst (
    .clk(net_clk),
    .rst_n(net_rst_n),
    .clk_sel_i(net_clk_sel_i),
    .clk_standalone_i(net_clk_standalone_i),
    .testmode_i(net_testmode_i),
    .fetch_enable_i(net_fetch_enable_i),
    .scan_enable_i(net_scan_enable_i),
    .spi_clk_i(net_spi_clk_i),
    .spi_cs_i(net_spi_cs_i),
    .spi_mode_o(net_spi_mode_o),
    .spi_sdo0_o(net_spi_sdo0_o),
    .spi_sdo1_o(net_spi_sdo1_o),
    .spi_sdo2_o(net_spi_sdo2_o),
    .spi_sdo3_o(net_spi_sdo3_o),
    .spi_sdi0_i(net_spi_sdi0_i),
    .spi_sdi1_i(net_spi_sdi1_i),
    .spi_sdi2_i(net_spi_sdi2_i),
    .spi_sdi3_i(net_spi_sdi3_i),
    .spi_master_clk_o(net_spi_master_clk_o),
    .spi_master_csn0_o(net_spi_master_csn0_o),
    .spi_master_csn1_o(net_spi_master_csn1_o),
    .spi_master_csn2_o(net_spi_master_csn2_o),
    .spi_master_csn3_o(net_spi_master_csn3_o),
    .spi_master_mode_o(net_spi_master_mode_o),
    .spi_master_sdo0_o(net_spi_master_sdo0_o),
    .spi_master_sdo1_o(net_spi_master_sdo1_o),
    .spi_master_sdo2_o(net_spi_master_sdo2_o),
    .spi_master_sdo3_o(net_spi_master_sdo3_o),
    .spi_master_sdi0_i(net_spi_master_sdi0_i),
    .spi_master_sdi1_i(net_spi_master_sdi1_i),
    .spi_master_sdi2_i(net_spi_master_sdi2_i),
    .spi_master_sdi3_i(net_spi_master_sdi3_i),
    .scl_pad_i(net_scl_pad_i),
    .scl_pad_o(net_scl_pad_o),
    .scl_padoen_o(net_scl_padoen_o),
    .sda_pad_i(net_sda_pad_i),
    .sda_pad_o(net_sda_pad_o),
    .sda_padoen_o(net_sda_padoen_o),
    .uart_tx(net_uart_tx),
    .uart_rx(net_uart_rx),
    .uart_rts(net_uart_rts),
    .uart_dtr(net_uart_dtr),
    .uart_cts(net_uart_cts),
    .uart_dsr(net_uart_dsr),
    .gpio_in(net_gpio_in),
    .gpio_out(net_gpio_out),
    .gpio_dir(net_gpio_dir),
    .gpio_padcfg(net_gpio_padcfg),
    .tck_i(net_tck_i),
    .trstn_i(net_trstn_i),
    .tms_i(net_tms_i),
    .tdi_i(net_tdi_i),
    .tdo_o(net_tdo_o),
    .pad_cfg_o(net_pad_cfg_o),
    .pad_mux_o(net_pad_mux_o)
  );

  PXOE1CDG pad_clk_0 (
    .XE(1'b1),
    .XI(clk),
    .XO(),
    .XC(net_clk)
  );

  PDDW0204CDG pad_rst_n_0 (
    .I(),
    .DS(1'b0),
    .OEN(1'b1),
    .PAD(rst_n),
    .C(net_rst_n),
    .PE(1'b0),
    .IE(1'b1)
  );

  PDDW0204CDG pad_spi_clk_i_0 (
    .I(),
    .DS(1'b0),
    .OEN(1'b1),
    .PAD(spi_clk_i),
    .C(net_spi_clk_i),
    .PE(1'b0),
    .IE(1'b1)
  );

  PDDW0204CDG pad_spi_cs_i_0 (
    .I(),
    .DS(1'b0),
    .OEN(1'b1),
    .PAD(spi_cs_i),
    .C(net_spi_cs_i),
    .PE(1'b0),
    .IE(1'b1)
  );

  PDDW0204CDG pad_spi_sdo0_o_0 (
    .I(net_spi_sdo0_o),
    .DS(1'b0),
    .OEN(1'b0),
    .PAD(spi_sdo0_o),
    .C(),
    .PE(1'b0),
    .IE(1'b0)
  );

  PDDW0204CDG pad_spi_sdi0_i_0 (
    .I(),
    .DS(1'b0),
    .OEN(1'b1),
    .PAD(spi_sdi0_i),
    .C(net_spi_sdi0_i),
    .PE(1'b0),
    .IE(1'b1)
  );

  PDDW0204CDG pad_spi_master_clk_o_0 (
    .I(net_spi_master_clk_o),
    .DS(1'b0),
    .OEN(1'b0),
    .PAD(spi_master_clk_o),
    .C(),
    .PE(1'b0),
    .IE(1'b0)
  );

  PDDW0204CDG pad_spi_master_csn0_o_0 (
    .I(net_spi_master_csn0_o),
    .DS(1'b0),
    .OEN(1'b0),
    .PAD(spi_master_csn0_o),
    .C(),
    .PE(1'b0),
    .IE(1'b0)
  );

  PDDW0204CDG pad_spi_master_sdo0_o_0 (
    .I(net_spi_master_sdo0_o),
    .DS(1'b0),
    .OEN(1'b0),
    .PAD(spi_master_sdo0_o),
    .C(),
    .PE(1'b0),
    .IE(1'b0)
  );

  PDDW0204CDG pad_spi_master_sdi0_i_0 (
    .I(),
    .DS(1'b0),
    .OEN(1'b1),
    .PAD(spi_master_sdi0_i),
    .C(net_spi_master_sdi0_i),
    .PE(1'b0),
    .IE(1'b1)
  );

  // UART

  PDDW0204CDG pad_uart_tx_0 (
    .I(net_uart_tx),
    .DS(1'b0),
    .OEN(1'b0),
    .PAD(uart_tx),
    .C(),
    .PE(1'b0),
    .IE(1'b0)
  );

  PDDW0204CDG pad_uart_rx_0 (
    .I(),
    .DS(1'b0),
    .OEN(1'b1),
    .PAD(uart_rx),
    .C(net_uart_rx),
    .PE(1'b0),
    .IE(1'b1)
  );

  PDDW0204CDG pad_uart_rts_0 (
    .I(net_uart_rts),
    .DS(1'b0),
    .OEN(1'b0),
    .PAD(uart_rts),
    .C(),
    .PE(1'b0),
    .IE(1'b0)
  );

  PDDW0204CDG pad_uart_dtr_0 (
    .I(net_uart_dtr),
    .DS(1'b0),
    .OEN(1'b0),
    .PAD(uart_dtr),
    .C(),
    .PE(1'b0),
    .IE(1'b0)
  );

  PDDW0204CDG pad_uart_cts_0 (
    .I(),
    .DS(1'b0),
    .OEN(1'b1),
    .PAD(uart_cts),
    .C(net_uart_cts),
    .PE(1'b0),
    .IE(1'b1)
  );

  PDDW0204CDG pad_uart_dsr_0 (
    .I(),
    .DS(1'b0),
    .OEN(1'b1),
    .PAD(uart_dsr),
    .C(net_uart_dsr),
    .PE(1'b0),
    .IE(1'b1)
  );

  // JTAG
  PDDW0204CDG pad_tck_i_0 (
    .I(),
    .DS(1'b0),
    .OEN(1'b1),
    .PAD(tck_i),
    .C(net_tck_i),
    .PE(1'b0),
    .IE(1'b1)
  );

  PDDW0204CDG pad_trstn_i_0 (
    .I(),
    .DS(1'b0),
    .OEN(1'b1),
    .PAD(trstn_i),
    .C(net_trstn_i),
    .PE(1'b0),
    .IE(1'b1)
  );

  PDDW0204CDG pad_tms_i_0 (
    .I(),
    .DS(1'b0),
    .OEN(1'b1),
    .PAD(tms_i),
    .C(net_tms_i),
    .PE(1'b0),
    .IE(1'b1)
  );

  PDDW0204CDG pad_tdi_i_0 (
    .I(),
    .DS(1'b0),
    .OEN(1'b1),
    .PAD(tdi_i),
    .C(net_tdi_i),
    .PE(1'b0),
    .IE(1'b1)
  );

  PDDW0204CDG pad_tdo_o_0 (
    .I(net_tdo_o),
    .DS(1'b0),
    .OEN(1'b0),
    .PAD(tdo_o),
    .C(),
    .PE(1'b0),
    .IE(1'b0)
  );

  // GPIOs
  PDDW0204CDG pad_gpio_0(
    .I(net_gpio_in[0]),
    .DS(1'b0),
    .OEN(net_gpio_dir[0]),
    .PAD(gpio[0]),
    .C(net_gpio_out[0]),
    .PE(net_gpio_padcfg[0][0]),
    .IE(~net_gpio_dir[0])
  );

  PDDW0204CDG pad_gpio_1(
    .I(net_gpio_in[1]),
    .DS(1'b0),
    .OEN(net_gpio_dir[1]),
    .PAD(gpio[1]),
    .C(net_gpio_out[1]),
    .PE(net_gpio_padcfg[1][0]),
    .IE(~net_gpio_dir[1])
  );

  PDDW0204CDG pad_gpio_2(
    .I(net_gpio_in[2]),
    .DS(1'b0),
    .OEN(net_gpio_dir[2]),
    .PAD(gpio[2]),
    .C(net_gpio_out[2]),
    .PE(net_gpio_padcfg[2][0]),
    .IE(~net_gpio_dir[2])
  );

  PDDW0204CDG pad_gpio_3(
    .I(net_gpio_in[3]),
    .DS(1'b0),
    .OEN(net_gpio_dir[3]),
    .PAD(gpio[3]),
    .C(net_gpio_out[3]),
    .PE(net_gpio_padcfg[3][0]),
    .IE(~net_gpio_dir[3])
  );

  PDDW0204CDG pad_gpio_4(
    .I(net_gpio_in[4]),
    .DS(1'b0),
    .OEN(net_gpio_dir[4]),
    .PAD(gpio[4]),
    .C(net_gpio_out[4]),
    .PE(net_gpio_padcfg[4][0]),
    .IE(~net_gpio_dir[4])
  );

  PDDW0204CDG pad_gpio_5(
    .I(net_gpio_in[5]),
    .DS(1'b0),
    .OEN(net_gpio_dir[5]),
    .PAD(gpio[5]),
    .C(net_gpio_out[5]),
    .PE(net_gpio_padcfg[5][0]),
    .IE(~net_gpio_dir[5])
  );

  PDDW0204CDG pad_gpio_6(
    .I(net_gpio_in[6]),
    .DS(1'b0),
    .OEN(net_gpio_dir[6]),
    .PAD(gpio[6]),
    .C(net_gpio_out[6]),
    .PE(net_gpio_padcfg[6][0]),
    .IE(~net_gpio_dir[6])
  );

  PDDW0204CDG pad_gpio_7(
    .I(net_gpio_in[7]),
    .DS(1'b0),
    .OEN(net_gpio_dir[7]),
    .PAD(gpio[7]),
    .C(net_gpio_out[7]),
    .PE(net_gpio_padcfg[7][0]),
    .IE(~net_gpio_dir[7])
  );

  PDDW0204CDG pad_gpio_8(
    .I(net_gpio_in[8]),
    .DS(1'b0),
    .OEN(net_gpio_dir[8]),
    .PAD(gpio[8]),
    .C(net_gpio_out[8]),
    .PE(net_gpio_padcfg[8][0]),
    .IE(~net_gpio_dir[8])
  );

endmodule
