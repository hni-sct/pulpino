#!/bin/bash
# \
exec vsim -64 -do "$0"

set TB            tb_spi_reg_test
set TB_TEST $::env(TB_TEST)
set VSIM_FLAGS    "-GTEST=\"$TB_TEST\""
set MEMLOAD       "PRELOAD"
set SDF $::env(PL_SDF)

source ./tcl_files/config/vsim_pl.tcl
