#!/bin/tcsh
source ${PULP_PATH}/vsim/vcompile/colors.csh

##############################################################################
# Settings
##############################################################################

set IP=sram_tsmc65
set IP_NAME="sram_tsmc65"


##############################################################################
# Check settings
##############################################################################

# check if environment variables are defined
if (! $?MSIM_LIBS_PATH ) then
  echo "${Red} MSIM_LIBS_PATH is not defined ${NC}"
  exit 1
endif

if (! $?RTL_PATH ) then
  echo "${Red} RTL_PATH is not defined ${NC}"
  exit 1
endif


set LIB_NAME="${IP}_lib"
set LIB_PATH="${MSIM_LIBS_PATH}/${LIB_NAME}"

##############################################################################
# Preparing library
##############################################################################

echo "${Green}--> Compiling ${IP_NAME}... ${NC}"

rm -rf $LIB_PATH

vlib $LIB_PATH
vmap $LIB_NAME $LIB_PATH

echo "${Green}Compiling component: ${Brown} ${IP_NAME} ${NC}"
echo "${Red}"

##############################################################################
# Compiling RTL
##############################################################################


# files depending on RISCV vs. OR1K
vlog -quiet -sv -work ${LIB_PATH} /homes1/lift/kbastian/work/designs/pulpino-flow/ips/SRAM/VERILOG/ts1n65lpll8192x32m16_220a_ss1p08vm40c.v  || goto error

echo "${Cyan}--> ${IP_NAME} compilation complete! ${NC}"
exit 0

##############################################################################
# Error handler
##############################################################################

error:
echo "${NC}"
exit 1
