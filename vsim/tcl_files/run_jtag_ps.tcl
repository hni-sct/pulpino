#!/bin/bash
# \
exec vsim -64 -do "$0"

set TB            tb_wrap_jtag
set TB_TEST $::env(TB_TEST)
set VSIM_FLAGS    "-GTEST=\"$TB_TEST\""
set MEMLOAD       "STANDALONE"
set SDF $::env(PS_SDF)

source ./tcl_files/config/vsim_ps.tcl