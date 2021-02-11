`timescale 1ps/1ps

module tb_multiplier();



parameter CYCLE = 5000;


logic clk;
logic reset_n;
logic input_valid;
logic [31:0] in_a;
logic [31:0] in_b;
logic [31:0] data_out;
logic output_valid;

logic [31:0] data;
shortreal result;
real percent_difference;
shortreal expected_result;
shortreal input_a;
shortreal input_b;

int rndm_num_file;

real num_tests;
real num_correct;

logic signed [7:0] test;

// CLOCK GENERATION:
initial begin
	clk = 1;
	forever #(CYCLE/2.0) clk = ~clk;
end


initial begin
	reset_n = 1;
	input_valid = 0;
	#(CYCLE);
	reset_n = 0;
	#(CYCLE);
	reset_n = 1;
	#(CYCLE);

	num_tests = 0;
	num_correct = 0;

	rndm_num_file = $fopen("./scripts/rndm_nums.csv", "rb");
	if(rndm_num_file == 0)begin
		$display("Error load file");
	end

	while(! $feof(rndm_num_file))
	begin
		$fscanf(rndm_num_file, "%f,%f",input_a,input_b);
		in_a = $shortrealtobits(input_a); 
		in_b = $shortrealtobits(input_b);
		input_valid = 1;
		#(CYCLE);
		input_valid = 0;
		while(output_valid == 0) begin
			if(reset_n == 0)
				break;
			#(CYCLE);
		end
		result = $bitstoshortreal(data_out);
		expected_result = $bitstoshortreal($shortrealtobits(input_a)) *  $bitstoshortreal($shortrealtobits(input_b));
		if($shortrealtobits(expected_result) == data_out)
			percent_difference = 0.0;
		else if(abs(expected_result) < 1e-40 && abs(result) < 1e-40)
			percent_difference = 0.0;
		else if((result != 0.0) || (expected_result != 0.0))
			percent_difference = (abs(abs(result)-abs(expected_result)))/((abs(result)+abs(expected_result))/2.0)*100.0;
		else
			percent_difference = 0.0;
		$display("****************************************************************************");
		$display("TEST NUMBER: %d",num_tests);
		$display("INPUTS: (%f)",$time);
		$display("A              : %b, %e",in_a,$bitstoshortreal($shortrealtobits(input_a)));
		$display("B              : %b, %e",in_b,$bitstoshortreal($shortrealtobits(input_b)));
		$display("RESULTS:");
		$display("RESULT         : %b %e",data_out,result);
		$display("EXPECTED RESULT: %b %e",$shortrealtobits(expected_result),expected_result);
		if(percent_difference > 0.5)
		$display("OFF BY         : %f percent",percent_difference);
		else
		$display("SAME           : %f percent", percent_difference);
		$display("****************************************************************************");
		num_tests = num_tests + 1;
		if(percent_difference <= 0.5)
			num_correct = num_correct + 1;

	end
	
	$display("PERCENTAGE CORRECT: %f",num_correct*100.0/num_tests);
	$display("RUNTIME: %d",$time);
	$stop;
end


multiplier mult0(
	.clk			(clk),
	.reset_n		(reset_n),
	.input_valid	(input_valid),
	.in_a			(in_a),
	.in_b			(in_b),
	.data_out		(data_out),
	.output_valid	(output_valid)


);

function automatic real abs(input real num);
begin
	if(num < 0)
		num = -num;
	return num;
end
endfunction

endmodule
