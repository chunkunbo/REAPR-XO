# -*- coding: utf-8 -*-
"""
@author: VinhDang
modified by Chunkun
"""

import sys
import math

common_repo_path = sys.argv[1]
report_count = int(sys.argv[2])
ddr_banks    = int(sys.argv[3])
io_test      = int(sys.argv[4])

if ((report_count%512)!=0):
    #if report_count is not evenly divided by 512, find the exponent of next higher power of 2 and calculate the next power of 2 
    #factorb = (int(math.pow(2, math.ceil(math.log(report_count%512, 2)))))/8
    tmpnum = int(math.pow(2, math.ceil(math.log(report_count%512, 2))))
    if (tmpnum < 8):
        factorb = 8/8
    else:
        factorb = tmpnum/8
    numb    = 1
else:
    #set to 0, otherwise
    factorb = 0
    numb    = 0

if ((report_count/512)!=0):
    #if report_count >= 512
    factora = 512/8
    numa    = report_count/512
else:
    #if report_count < 512
    factora = 0
    numa    = 0

output_file=open('./rtl_prj/Makefile','w')

code_string="""# io_global Application
COMMON_REPO:="""+common_repo_path+'\n\n'

if (io_test == 0):
    code_string=code_string+"""include $(COMMON_REPO)/utility/boards.mk
include $(COMMON_REPO)/libs/xcl/xcl.mk
include $(COMMON_REPO)/libs/opencl/opencl.mk

# io_global Host Application
io_global_SRCS=../io_global_bandwidth_real.cpp $(xcl_SRCS)
io_global_HDRS=$(xcl_HDRS)
io_global_CXXFLAGS=-DUSE_NDDR $(xcl_CXXFLAGS) $(opencl_CXXFLAGS)
io_global_LDFLAGS=$(opencl_LDFLAGS)

EXES=io_global

bandwidth_KERNEL := bandwidth

"""
else:
    code_string=code_string+"""include $(COMMON_REPO)/utility/boards.mk
include $(COMMON_REPO)/libs/xcl/xcl.mk
include $(COMMON_REPO)/libs/opencl/opencl.mk

# io_global Host Application
io_global_SRCS=../io_global_bandwidth.cpp $(xcl_SRCS)
io_global_HDRS=$(xcl_HDRS)
io_global_CXXFLAGS=-DUSE_NDDR $(xcl_CXXFLAGS) $(opencl_CXXFLAGS)
io_global_LDFLAGS=$(opencl_LDFLAGS)

EXES=io_global

bandwidth_KERNEL := bandwidth


"""

code_string=code_string+"""
include $(COMMON_REPO)/utility/rules.mk
"""

output_file.write(code_string)
output_file.close()
