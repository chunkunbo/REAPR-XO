#!/bin/bash
#Common paths
#Ted Xie's Python tool
#modified by Chunkun for using Xilinx Object files
ANML2HDL_PATH=$REAPR_HOME/a2h
#
#https://github.com/Xilinx/SDAccel_Examples.git
#SDACCEL_REPO_PATH=/net/af5/vqd8a/Xilinx-SDAccel/SDAccel_Examples
SDACCEL_REPO_PATH=/net/af5/cb2yy/aws-fpga/SDAccel/examples/xilinx
PROJ_PATH=$(dirname $PWD)
TOOL_PATH=$PROJ_PATH/python_tools

#Application-specific and FPGA board settings
ANML=Examples/1.anml
OUTFILE=er1.vhd
ENTITY=er1

TARGET=logic

#DDR_BANKS=2
#DEVICE_NAME="xcku060-ffva1156-2-e"
#DEVICE_FIRMWARE="xilinx:adm-pcie-ku3:2ddr-xpr:4.0"
#CLK_FREQ_MHZ=250

#DDR_BANKS=4
#DEVICE_NAME="xcku115-flvb2104-2-e"
#DEVICE_FIRMWARE="xilinx:xil-accel-rd-ku115:4ddr-xpr:4.0"
#CLK_FREQ_MHZ=300

DDR_BANKS=4
DEVICE_NAME="xcvu9p-flgb2104-2-i"
DEVICE_FIRMWARE="xilinx:aws-vu9p-f1:4ddr-xpr-2pr:4.0"
CLK_FREQ_MHZ=250

REPORT_SIZE=1

#IO_TEST: Set to 1 if running I/O kernel only, otherwise set to 0 for automata module hooking
IO_TEST=0

#
set -e

#Generate automata processing RTL module
if [ $IO_TEST = 0 ]; then
    echo "1.Generate automata processing RTL module"
    cd $ANML2HDL_PATH
    python a2h.py -a $ANML -o $OUTFILE -e $ENTITY -t $TARGET
    cp OutputFiles/$OUTFILE $PROJ_PATH/vv_prj/hdl
    cp Resources/ste_sim.vhd $PROJ_PATH/vv_prj/hdl
fi

#Generate host application and I/O C kernel
cd $PROJ_PATH
echo "2.Generate host code (C)"
python $TOOL_PATH/host_gen.py $REPORT_SIZE $DDR_BANKS $IO_TEST

echo "3.Generate copy kernel header (C)"
python $TOOL_PATH/copy_kernel_h_gen.py $REPORT_SIZE

echo "4.Generate copy kernel (C)"
python $TOOL_PATH/copy_kernel_c_gen.py $REPORT_SIZE

#Generate AXI I/O template kernel (RTL)
echo "5.Generate I/O template script"
python $TOOL_PATH/iotemplatescript_gen.py $DEVICE_NAME $CLK_FREQ_MHZ

cd $PROJ_PATH/vhls_prj
echo "6.Generate I/O template kernel (RTL)"
vivado_hls -f test_io/solution1/iotemplate_script.tcl

if [ $IO_TEST = 0 ]; then
    #Hook automata module to the IO kernel
    echo "7.Hook automata module to the IO kernel"
    python $TOOL_PATH/automatahook.py $REPORT_SIZE test_io/solution1/impl/verilog/bandwidth.v $ENTITY > bandwidth.v
    #Update the IO kernel in the vivado project 
    mv test_io/solution1/impl/verilog/bandwidth.v test_io/solution1/impl/verilog/bandwidth.v_ORIG 
    cp bandwidth.v test_io/solution1/impl/verilog/
    cp test_io/solution1/impl/verilog/*.v $PROJ_PATH/vv_prj/hdl
else
    cp test_io/solution1/impl/verilog/*.v $PROJ_PATH/vv_prj/hdl
fi

#Generate kernel description XML file
cd $PROJ_PATH
echo "8.Generate kernel.xml"
python $TOOL_PATH/kernel_xml_gen.py $REPORT_SIZE

#Generate IP generation script
echo "9.Generate package_kernel.tcl"
python $TOOL_PATH/package_kernel_tcl_gen.py $REPORT_SIZE $IO_TEST

#Generate XO files
echo "10.Generate XO files"

cd $PROJ_PATH/rtl_prj

vivado -mode batch -source ../vv_prj/gen_xo.tcl -tclargs xclbin/bandwidth.hw.xilinx_aws-vu9p-f1_4ddr-xpr-2pr_4_0.xo bandwidth hw xilinx_aws-vu9p-f1_4ddr-xpr-2pr_4_0

echo "11.Generate XCLBIN files"

if [ $REPORT_SIZE  -ge 0 -a $REPORT_SIZE -le 512 ]; then
    xocc -l --xp "param:compiler.preserveHlsOutput=1" --xp "param:compiler.generateExtraRunData=true" -s --kernel_frequency 250 --xp vivado_param:project.runs.noReportGeneration=0 --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM0.core.OCL_REGION_0.M00_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM1.core.OCL_REGION_0.M01_AXI   -o xclbin/bandwidth.hw.xilinx_aws-vu9p-f1_4ddr-xpr-2pr_4_0.xclbin -t hw --platform xilinx:aws-vu9p-f1:4ddr-xpr-2pr:4.0 xclbin/bandwidth.hw.xilinx_aws-vu9p-f1_4ddr-xpr-2pr_4_0.xo
fi
if [ $REPORT_SIZE  -gt 512 -a $REPORT_SIZE -le 1024 ]; then
    xocc -l --xp "param:compiler.preserveHlsOutput=1" --xp "param:compiler.generateExtraRunData=true" -s --kernel_frequency 250 --xp vivado_param:project.runs.noReportGeneration=0 --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM0.core.OCL_REGION_0.M00_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM1.core.OCL_REGION_0.M01_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM2.core.OCL_REGION_0.M02_AXI   -o xclbin/bandwidth.hw.xilinx_aws-vu9p-f1_4ddr-xpr-2pr_4_0.xclbin -t hw --platform xilinx:aws-vu9p-f1:4ddr-xpr-2pr:4.0 xclbin/bandwidth.hw.xilinx_aws-vu9p-f1_4ddr-xpr-2pr_4_0.xo
fi
if [ $REPORT_SIZE  -gt 1024 -a $REPORT_SIZE -le 1536 ]; then
    xocc -l --xp "param:compiler.preserveHlsOutput=1" --xp "param:compiler.generateExtraRunData=true" -s --kernel_frequency 250 --xp vivado_param:project.runs.noReportGeneration=0 --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM0.core.OCL_REGION_0.M00_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM1.core.OCL_REGION_0.M01_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM2.core.OCL_REGION_0.M02_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM3.core.OCL_REGION_0.M03_AXI   -o xclbin/bandwidth.hw.xilinx_aws-vu9p-f1_4ddr-xpr-2pr_4_0.xclbin -t hw --platform xilinx:aws-vu9p-f1:4ddr-xpr-2pr:4.0 xclbin/bandwidth.hw.xilinx_aws-vu9p-f1_4ddr-xpr-2pr_4_0.xo
fi
if [ $REPORT_SIZE  -gt 1536 -a $REPORT_SIZE -le 2048 ]; then
    xocc -l --xp "param:compiler.preserveHlsOutput=1" --xp "param:compiler.generateExtraRunData=true" -s --kernel_frequency 250 --xp vivado_param:project.runs.noReportGeneration=0 --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM0.core.OCL_REGION_0.M00_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM1.core.OCL_REGION_0.M01_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM2.core.OCL_REGION_0.M02_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM3.core.OCL_REGION_0.M03_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM4.core.OCL_REGION_0.M00_AXI   -o xclbin/bandwidth.hw.xilinx_aws-vu9p-f1_4ddr-xpr-2pr_4_0.xclbin -t hw --platform xilinx:aws-vu9p-f1:4ddr-xpr-2pr:4.0 xclbin/bandwidth.hw.xilinx_aws-vu9p-f1_4ddr-xpr-2pr_4_0.xo
fi
if [ $REPORT_SIZE  -gt 2048 -a $REPORT_SIZE -le 2600 ]; then
    xocc -l --xp "param:compiler.preserveHlsOutput=1" --xp "param:compiler.generateExtraRunData=true" -s --kernel_frequency 250 --xp vivado_param:project.runs.noReportGeneration=0 --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM0.core.OCL_REGION_0.M00_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM1.core.OCL_REGION_0.M01_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM2.core.OCL_REGION_0.M02_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM3.core.OCL_REGION_0.M03_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM4.core.OCL_REGION_0.M00_AXI --xp misc:map_connect=add.kernel.bandwidth_1.M_AXI_GMEM5.core.OCL_REGION_0.M01_AXI   -o xclbin/bandwidth.hw.xilinx_aws-vu9p-f1_4ddr-xpr-2pr_4_0.xclbin -t hw --platform xilinx:aws-vu9p-f1:4ddr-xpr-2pr:4.0 xclbin/bandwidth.hw.xilinx_aws-vu9p-f1_4ddr-xpr-2pr_4_0.xo
fi

cd $PROJ_PATH
#Generate Makefile
echo "12.Generate Makefile"
python $TOOL_PATH/makefile_gen.py $SDACCEL_REPO_PATH $REPORT_SIZE $DDR_BANKS $IO_TEST

#Compile the project using SDAccel (including generating IP and XO files from the RTL kernel)
echo "13.Compile"
cd $PROJ_PATH/rtl_prj
nohup make all TARGETS=hw DEVICES=$DEVICE_FIRMWARE
