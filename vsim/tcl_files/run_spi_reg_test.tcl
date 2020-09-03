#!/bin/bash
# \
exec vsim -64 -do "$0"

set TB_TEST $::env(TB_TEST)
set VSIM_FLAGS    "-GTEST=\"$TB_TEST\""

set TB            tb_spi_reg_test
set MEMLOAD       "STANDALONE"

source ./tcl_files/config/vsim.tcl
