#!/bin/bash
# \
exec vsim -64 -do "$0"

set TB            tb_wrap_ps
set TB_TEST $::env(TB_TEST)
set VSIM_FLAGS    "-GTEST=\"$TB_TEST\""
set MEMLOAD       "PRELOAD"
#set SDF "" 
set SDF "/homes1/lift/kbastian/work/designs/pulpino-flow/syn/tsmc65_wrap.sdf" 

source ./tcl_files/config/vsim_ps.tcl
