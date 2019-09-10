# REAPR-XO
As we use original REAPR (https://github.com/ted-xie/REAPR), we found that generate Xilinx Object files first and then compile using these files help to reduce the overall compilation time.
In this reporsitory, we provide a new workflow for this purpose. Similar to use REAPR, we provide a entry file (run.sh) under REAPR-XO/pcie_integration/rtl_prj/.
Users need to modify certain fields in order to run REAPR-XO.

## Requirments
The requiments for running REAPR-XO is the same to original REAPR on AWS F1 instance (https://github.com/chunkunbo/REARP-on-Amazon-F1).
1. Download original REAPR from https://github.com/ted-xie/REAPR
2. Download AWS FPGA tool kit from https://github.com/aws/aws-fpga
3. Prerequisites for REARR: 
* python3.6+
* virtualenv
* pip

## Major changes in REAPR-XO
1. A new Makefile generator is provided. In the new workflow, we separate the process of generating xlcbin file and the host executatble. So the new Makefile only need to generate the executable.
2. A new entry file is provided (run.sh). The first few steps are the same with original REAPR. But for the last few step, we first generate the .xo file, and then the xclbin file, and at last the host executable.
Users need to modify certain fields in this file. One example is provided.
Line 9: modify this to your SDAccel path.
Line 14: modify this to your ANML file path.
Line 15: Name your generated vhdl file.
Line 16: Name you module.
Line 30-33: modify this to your own device configuration. In this example, we use AWS-F1 as our device. We also provide a couple othe examples.
Line 35: modify the number of reports of your application.

## Run REAPR-XO
To run REAPR-XO, first set up the envrironment variables.
source source_me.sh
Then modify the entry file as suggested in the above section and simply run the command.
./run.sh
This will generate the host executable and the xclbin file. Users can run their applications on the FPGA device.
If users want to run AWS-F1, extra steps are needed.
Please refer to (https://github.com/chunkunbo/REARP-on-Amazon-F1) for details.
