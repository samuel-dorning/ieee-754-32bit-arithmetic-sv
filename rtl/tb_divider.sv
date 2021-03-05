`timescale 1ps/1ps

module tb_divider();



parameter CYCLE = 5000;

//Half Precision (16 bit float):
parameter EXP_BITS = 5;
parameter MANT_BITS = 10;

//Single Precision (32 bit float):
//parameter EXP_BITS = 8;
//parameter MANT_BITS = 23;

//Double Precision (64 bit float):
//parameter EXP_BITS = 11;
//parameter MANT_BITS = 52;

logic clk;
logic reset_n;
logic input_valid;
logic [EXP_BITS+MANT_BITS:0] in_a;
logic [EXP_BITS+MANT_BITS:0] in_b;
logic [EXP_BITS+MANT_BITS:0] data_out;
logic output_valid;

logic [EXP_BITS+MANT_BITS:0] data;
real result;
real percent_difference;
real expected_result;
real input_a;
real input_b;
int oob;
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
		in_a = tobits(input_a); 
		in_b = tobits(input_b);
		input_valid = 1;
		#(CYCLE);
		input_valid = 0;
		while(output_valid == 0) begin
			if(reset_n == 0)
				break;
			#(CYCLE);
		end
		result = toreal(data_out);
		expected_result = toreal(in_a) / toreal(in_b);
		if(tobits(expected_result) == data_out)
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
		$display("A              : %b, %e",in_a,toreal(in_a));
		$display("B              : %b, %e",in_b,toreal(in_b));
		$display("RESULTS:");
		$display("RESULT         : %b %e",data_out,result);
		oob = check_upper_bound(expected_result);
		if(oob == 0)
			$display("EXPECTED RESULT: %b %e",tobits(expected_result),expected_result);
		else
			$display("EXPECTED RESULT: %b %e (out of bounds)",tobits(expected_result),expected_result);
		if(percent_difference > 0.5)
			$display("OFF BY         : %f percent",percent_difference);
		else
			$display("OFF BY         : %f percent (match)",percent_difference);
		$display("****************************************************************************");
		num_tests = num_tests + 1;
		if(percent_difference <= 0.5)
			num_correct = num_correct + 1;

	end
	
	$display("PERCENTAGE CORRECT: %f",num_correct*100.0/num_tests);
	$display("RUNTIME: %d",$time);
	$stop;
end


divider #(MANT_BITS,EXP_BITS) div0(
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

function automatic int check_upper_bound(input real num);
begin
	logic [EXP_BITS+MANT_BITS:0] max_num;
	real val;
	max_num[EXP_BITS+MANT_BITS] = 0;
	for(int i = 0; i < MANT_BITS; i++) begin
		max_num[i] = 0;
	end
	for(int i = MANT_BITS; i < MANT_BITS+EXP_BITS; i++) begin
		max_num[i] = 1;
	end
	val = toreal(max_num);
	if(abs(num) > val)
		return 1;
	else
		return 0;
end
endfunction

function automatic logic [EXP_BITS+MANT_BITS:0] tobits(input real num);
begin
	real mant;
	real e;
	real target;
	logic [EXP_BITS+MANT_BITS:0] result;
	if(EXP_BITS == 8 && MANT_BITS == 23) begin
		result = $shortrealtobits(num);
	end
	else if(EXP_BITS == 11 && MANT_BITS == 52) begin
		result = $realtobits(num);
	end
	else begin
		for(e = 2**(EXP_BITS-1); e > -(2**(EXP_BITS-1)); e--) begin //for e in range(MAX_EXP, MIN_EXP)
			//Test the exponent to see if mant is in the correct range:
			if(num < 0)
				mant = -num/(2**e);
			else
				mant = num/(2**e);
			//See if mant is in correct range. Break if it is, continue loop
				//if it isn't:
			if((e >= -(2**(EXP_BITS-1)) + 2) && (mant < 2 && mant >= 1)) begin
				break;
			end
			else if((e == -(2**(EXP_BITS-1)) + 2) && (mant < 1 && mant >= 0)) begin
				break;
			end
		end
		if(num < 0)
			result[EXP_BITS+MANT_BITS] = 1;
		else
			result[EXP_BITS+MANT_BITS] = 0;
		if(mant < 1) begin
			result[EXP_BITS+MANT_BITS-1:MANT_BITS] = 0;
		end
		else begin
			result[EXP_BITS+MANT_BITS-1:MANT_BITS] = int'(e + 2**(EXP_BITS-1) - 1);
			mant = mant - 1;
		end
		if( & result[EXP_BITS+MANT_BITS-1:MANT_BITS] == 1) begin
			result[MANT_BITS-1:0] = 0;
		end else begin
			for(int i = MANT_BITS - 1; i >= 0; i--) begin
				target = 2.0**(i-MANT_BITS);
				if(mant >= target && mant != 0.0) begin
					result[i] = 1;
					mant = mant - target;
				end
				else 
					result[i] = 0;
			end
		end
	end
	return result;
end
endfunction

function automatic real toreal(input logic [EXP_BITS+MANT_BITS:0] num);
begin
	real result;
	logic sign = num[EXP_BITS+MANT_BITS];
	logic [EXP_BITS-1:0] exp = num[EXP_BITS+MANT_BITS-1:MANT_BITS];
	logic [MANT_BITS-1:0] mant = num[MANT_BITS-1:0];
	int e;
	real m;
	if(EXP_BITS == 8 && MANT_BITS == 23) begin
		result = $bitstoshortreal(num);
	end
	else if(EXP_BITS == 11 && MANT_BITS == 52) begin
		result = $bitstoreal(num);
	end
	else begin
		if(exp == 0) begin
			e = 2 - 2**(EXP_BITS-1);	
			m = 0.0;
		end
		else begin
			e = exp - (2**(EXP_BITS-1)-1);
			m = 1.0;
		end

		for(int i = MANT_BITS-1; i >= 0; i--) begin
			if(mant[i] == 1)
				m = m + 2.0**(i-MANT_BITS);
		end

		result = (2.0**e)*m;
		if(sign == 1)
			result = -result;
	end
	return result;

end
endfunction

endmodule
