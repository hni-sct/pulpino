#!/bin/tcsh
source ${PULP_PATH}/vsim/vcompile/colors.csh

##############################################################################
# Settings
##############################################################################

set IP=tsmc65
set IP_NAME="tsmc65"


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
vlog -quiet -sv -work ${LIB_PATH} /opt/sct/pdk/tsmc/65n/IO2.5V/iolib/LINEAR/tpdn65lpnv2od3_200a_FE/TSMCHOME/digital/Front_End/verilog/tpdn65lpnv2od3_140b/tpdn65lpnv2od3.v  || goto error
vlog -quiet -sv -work ${LIB_PATH} /opt/sct/pdk/tsmc/65n/stclib/12-track/tcbn65lpbwp12t-set/tcbn65lpbwp12t_200b_FE/TSMCHOME/digital/Front_End/verilog/tcbn65lpbwp12t_200a/tcbn65lpbwp12t.v  || goto error

echo "${Cyan}--> ${IP_NAME} compilation complete! ${NC}"
exit 0

##############################################################################
# Error handler
##############################################################################

error:
echo "${NC}"
exit 1
