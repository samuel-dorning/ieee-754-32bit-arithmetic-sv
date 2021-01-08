# ieee-754-32bit-arithmetic-sv
This repo contains four files:
  adder.sv - Synthesizeable 32-bit floating point adder
  multiplier.sv - Synthesizable 32-bit floating point multiplier
  tb_adder.sv - Testbench for adder module
  tb_multiplier.sv - Testbench for multiplier module
  
Both the adder module and multiplier module have the same interfaces:
  Inputs:
    reset_n - active low reset to put state machine into known state
    clk - clock signal
    in_a (32 bits) - One of the operands to use in the operation
    in_b (32 bits) - The other operand to use in the operation
    input_valid - A signal to let the state machine know that the present in_a and in_b values are valid and should have the operation performed on them. 
                  Assert this high for one clock cycle
  Outputs:
    data_out (32 bits) - The result of the operation
    output_valid - When high, the result found in "data_out" is valid. When this is low, the data may not be ready yet. This will only stay high for one clock cycle.

Both of these modules work the same from a black box perspective:
  -Assert reset_n to put state machine into a known state 
  -Assert input_valid for one clock cycle when data in in_a and in_b have valid data
  -Wait
  -When output_valid is high, data in data_out is valid and should be clocked out
  
The testbenches both require a file of inputs to feed the module. Each line in the file should consist of a comma separated pair of numbers. The pair of numbers 
correspond to in_a and in_b. Ex:

0.29345345,102.4534534
3523423.12312,7567.123124
123.5457,141364.2452452
...

Update the filename in the testbench to use the file you create.

The testbench will feed the data from the file into the SystemVerilog module, and clock out the result of the operation. It will also perform the operation at a high level
using shortreal data types to get the expected result of the operation. The testbech will print out the result and the expected result, along with the percent difference
between them. If the percent difference is above a certain amount, it will be flagged as wrong. The total percent of passing tests will be printed at the end.
