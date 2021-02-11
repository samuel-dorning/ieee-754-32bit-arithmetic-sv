`timescale 1ps/1ps

module tb_adder();



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

		//in_a = float2bin(round(input_a)); 
		//in_b = float2bin(round(input_b));
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
		//result = bin2float(data_out);
		//expected_result = ex_add(input_a,input_b);
		result = $bitstoshortreal(data_out);
		expected_result = $bitstoshortreal($shortrealtobits(input_a)) +  $bitstoshortreal($shortrealtobits(input_b));
		if($shortrealtobits(expected_result) == data_out)
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
		$display("OFF BY         : %f %%",percent_difference);
		else
		$display("SAME           : %f %%", percent_difference);
		$display("****************************************************************************");
		num_tests = num_tests + 1;
		if(percent_difference <= 0.5)
			num_correct = num_correct + 1;

	end
	
	$display("PERCENTAGE CORRECT: %f",num_correct*100.0/num_tests);
	$display("RUNTIME: %d",$time);
	$stop;
end


adder add0(
	.clk			(clk),
	.reset_n		(reset_n),
	.input_valid	(input_valid),
	.in_a			(in_a),
	.in_b			(in_b),
	.data_out		(data_out),
	.output_valid	(output_valid)


);

function automatic real ex_add(input real a, input real b);
begin
	real result = 0;
	if(abs(a) >= 340282366920938463463374607431768211456.000000 || abs(b) >= 340282366920938463463374607431768211456.000000)
		result = bin2float(32'h7fffffff);
	else
		result = a + b;
	if(result < 1.40129846432e-45)
		result = 0;
	else if(result > 340282366920938463463374607431768211456.000000)
		result = 340282366920938463463374607431768211456.000000;
	return result;
end
endfunction

function automatic real round(input real num);
begin
	if(num >= 340282366920938463463374607431768211456.00000)
		num = 340282366920938463463374607431768211456.000000;
	else if(num < 1.40129846432e-45)
		num = 0.0;
	return num;
end
endfunction


function automatic real abs(input real num);
begin
	if(num < 0)
		num = -num;
	return num;
end
endfunction


function automatic real bin2float(input logic [31:0] data);
begin

	real n = 0;
	real m = 0;
	int e = 0;

  	if(data[30:23] != 0)
	begin
		e = data[30:23];
		n = 2.0**(e - 127);
		m = 1;
	end
	else
	begin
		e = 1;
		n = 2.0**(e - 127);
		m = 0;
	end
	for(int i = 22; i >= 0; i--)
	begin
		if(data[i] == 1)
		begin
			m = m + 2.0**(i-23);
		end
	end
	//$display("e: %f",e - 127);
	//$display("m: %f",m);
	//$display("n: %f",n);
	n = n * m;
	if(data[31] == 1)
		n = -n;
	return n;
end
endfunction


function automatic shortreal float2bin(input real num);
begin
	logic [31:0] out;
	logic sign = 0;
	int exponent = 0;
	real mantissa = 0;

	logic [22:0] m = 0;
	logic [7:0] e;

	if(num < 0)
	begin
		num = num * -1;
		sign = 1;
	end

	if(num >= 2.35098856151e-38)
	begin
		for(int i = 128; i >= -126; i--)
		begin
			if(num >= (2.0**i))
			begin
				exponent = i;
				break;
			end
		end

		mantissa = num / (2.0**exponent);
		mantissa = (mantissa - 1);
		exponent = exponent + 127;	

		out[31] = sign;
		out[30:23] = exponent;

		for(int i = 22; i >= 0; i--)
		begin
			//$display("Remaing: %f Place: %f", mantissa, (2.0**(i-23))*256);
			if(mantissa >= (2.0**(i-23)))
			begin
				mantissa = mantissa - (2.0**(i-23));
				m[i] = 1;
			end
		end

		out[22:0] = m;
	end
	else
	begin
		out[31] = sign;
		out[30:23] = 0;
		mantissa = num * 2.0**(126);
		for(int i = 22; i >= 0; i--)
		begin
			//$display("Remaing: %f Place: %f", mantissa, (2.0**(i-23))*256);
			if(mantissa >= (2.0**(i-23)))
			begin
				mantissa = mantissa - (2.0**(i-23));
				m[i] = 1;
			end
		end
			
		out[22:0] = m;
		
	end

	return out;
end
endfunction

endmodule
