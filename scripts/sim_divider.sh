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
~/intelFPGA_lite/20.1/modelsim_ase/bin/vlog ./rtl/tb_divider.sv ./rtl/divider.sv
if [ $QUIET -eq 1 ]
then
	CMD="~/intelFPGA_lite/20.1/modelsim_ase/bin/vsim -suppress 8630 -do \"vsim work.tb_divider -t ps; add wave *; run -all; quit\" -quiet -c"
else
	CMD="~/intelFPGA_lite/20.1/modelsim_ase/bin/vsim -do \"vsim work.tb_divider -t ps; add wave *; add wave tb_divider/div0/*; run -all\""
fi
eval $CMD
