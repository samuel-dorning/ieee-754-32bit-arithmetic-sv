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
~/intelFPGA_lite/20.1/modelsim_ase/bin/vlog ./tb_adder.sv ./adder.sv
#~/intelFPGA_lite/20.1/modelsim_ase/bin/vlog ./tb_multiplier.sv
if [ $QUIET -eq 1 ]
then
	CMD="~/intelFPGA_lite/20.1/modelsim_ase/bin/vsim -do ./scripts/sim_adder_quiet.do -quiet -c"
else
	CMD="~/intelFPGA_lite/20.1/modelsim_ase/bin/vsim -do ./scripts/sim_adder.do"
fi
eval $CMD
