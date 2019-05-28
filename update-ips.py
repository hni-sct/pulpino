#!/usr/bin/env python3
# Francesco Conti <f.conti@unibo.it>
#
# Copyright (C) 2016-2018 ETH Zurich, University of Bologna.
# All rights reserved.

from ipstools_cfg import *

try:
    os.mkdir("ips")
except OSError:
    pass
# creates an IPApproX database
ipdb = ipstools.IPDatabase(
    skip_scripts=True,
    build_deps_tree=True,
    resolve_deps_conflicts=True,
    rtl_dir='rtl',
    ips_dir='ips',
    vsim_dir='vsim',
    default_server=DEFAULT_SERVER
)
# updates the IPs from the git repo
ipdb.update_ips()

# launch generate-ips.py
ipdb.save_database()
execute("./generate-scripts.py")

