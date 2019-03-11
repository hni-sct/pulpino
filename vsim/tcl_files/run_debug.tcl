#!/bin/bash
# \
exec vsim -64 -do "$0"

set TB            tb_wrap
set VSIM_FLAGS    "-gTEST=\"DEBUG\""
set MEMLOAD       "PRELOAD"

source ./tcl_files/config/vsim.tcl
