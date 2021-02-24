#!/bin/bash
QUIET=0
CMD=""
while getopts "q" opt; do
	case ${opt} in
			q )
				QUIET=1
			  ;;
	esac
done
~/intelFPGA_lite/20.1/modelsim_ase/bin/vlog ./rtl/tb_adder.sv ./rtl/adder.sv
if [ $QUIET -eq 1 ]
then
	CMD="~/intelFPGA_lite/20.1/modelsim_ase/bin/vsim -do \"vsim work.tb_adder -t ps; add wave *; run -all; quit\" -quiet -c"
else
	CMD="~/intelFPGA_lite/20.1/modelsim_ase/bin/vsim -do \"vsim work.tb_adder -t ps; add wave *; add wave tb_adder/add0/*; run -all\""
fi
eval $CMD
