module divider #(MANT_BITS=23, EXP_BITS=8)(
	input wire clk,
	input wire reset_n,

	input wire input_valid,
	input logic [EXP_BITS+MANT_BITS:0] in_a,
	input logic [EXP_BITS+MANT_BITS:0] in_b,
	output logic [EXP_BITS+MANT_BITS:0] data_out,
	output logic output_valid
);


enum logic [2:0]{
	WAIT 		= 3'b000,
	INIT 		= 3'b001,
	CALC_EXP 	= 3'b010,
	INC_EXP 	= 3'b011,
	OVERFLOW 	= 3'b100,
	DATA_OUT 	= 3'b101,
	CHECK		= 3'b110,
	CALC_MANT 	= 3'b111
} ps, ns;


logic [EXP_BITS+MANT_BITS:0] data_a;
logic [EXP_BITS+MANT_BITS:0] data_b;
logic [EXP_BITS+1:0] exp; //Total exponent bits + 2
logic [((MANT_BITS)*2+1)-1:0] mant;	//(Total mantissa bits * 2 + 1

wire exp_a_0;
wire exp_b_0;

logic need_to_shift;
logic greater_than_max;
logic less_than_min;
logic underflow;


logic [EXP_BITS-1:0] exp_out;

logic signed [EXP_BITS+1:0] e1; //Total exponent bits + 2
logic signed [EXP_BITS+1:0] e2;	//Total exponent bits + 2
/*****************************************************************************************************************
* DATA PATH 
*****************************************************************************************************************/
always_ff @ (posedge clk)
begin
	if(ps == WAIT)
		output_valid <= 0;
	else if(ps == INIT)
	begin
		data_a <= in_a;
		data_b <= in_b;
		exp <= 0;
		mant <= 0;
	end
	else if(ps == CALC_MANT)
	begin
		mant <= {exp_a_0,data_a[MANT_BITS-1:0],{MANT_BITS{1'b0}}} / {{MANT_BITS{1'b0}},exp_b_0,data_b[MANT_BITS-1:0]};
	end
	else if(ps == CALC_EXP)
	begin
		if(((e1 - e2) >= 2**(EXP_BITS))) begin
			exp <= 2**(EXP_BITS+1)-1;
			mant <= 0;
		end
		else if((e1 == 2**(EXP_BITS-1)) && (e2 == 2**(EXP_BITS-1))) begin //if both inputs are infinity
			//Set output to NaN
			exp <= 2**(EXP_BITS+1)-1;
			mant <= {(MANT_BITS+1)*2{1'b1}};
		end
		else if((e1 != 2**(EXP_BITS-1)) && (e2 == 2**(EXP_BITS-1))) begin //if b is infinity
			//Set output to 0
			exp <= 2**(EXP_BITS-1); //0
			mant <= 0;
		end
		else if((e1 == 2**(EXP_BITS-1)) && (e2 != 2**(EXP_BITS-1))) begin //if a is infinity
			//Set output to infinity
			exp <= 2**(EXP_BITS+1)-1;
			mant <= 0;
		end
		else if(data_b[EXP_BITS+MANT_BITS-1:0] == 0) begin //if dividing by 0
			//Set output to NaN
			exp <= 2**(EXP_BITS+1)-1;
			mant <= {(MANT_BITS+1)*2{1'b1}};
		end
		else if(data_a[EXP_BITS+MANT_BITS-1:0] == 0) begin //if 0 is begin divided
			//Set output to 0
			exp <= 2**(EXP_BITS-1); //0
			mant <= 0;
		end
		else if(((e1-e2) > 2-2**(EXP_BITS)) && ((e1-e2) < 2**(EXP_BITS))) 
			//exp <= e1 - e2 + 2**(EXP_BITS-1)-1;
			exp <= e1 - e2 + 2**(EXP_BITS)-1;
		else if(((e1 - e2) == 2-2**(EXP_BITS-1)) && (mant[MANT_BITS*2:MANT_BITS+1] == 0)) //enable gradual underflow
			exp <= 2**(EXP_BITS-1); //0
		else if(((e1 - e2) == 2-2**(EXP_BITS-1)) && (mant[MANT_BITS*2:MANT_BITS+1] != 0))
			exp <= 2**(EXP_BITS-1) + 1; //1
		else
		begin
			exp <= 2**(EXP_BITS-1); //0
			mant <= 0;
		end
		data_out[EXP_BITS+MANT_BITS] <= data_a[EXP_BITS+MANT_BITS] ^ data_b[EXP_BITS+MANT_BITS];
	end
	else if(ps == INC_EXP)
	begin
		if(greater_than_max && (mant[MANT_BITS*2:MANT_BITS] >= 1 || mant == 0) ) begin
			exp <= 2**(EXP_BITS-1) + 2**(EXP_BITS)-1; //Infinity
			mant <= 0;
		end
		else if(less_than_min && mant == 0 && !underflow) begin
			exp <= 2**(EXP_BITS-1); //0
		end
		else if(less_than_min && mant != 0 && !underflow) begin
			exp <= exp + 1;
			mant <= mant >> 1;
		end
		else if(underflow && mant[MANT_BITS*2:MANT_BITS] == 1) begin
			exp <= 2**(EXP_BITS-1) + 1; //1
		end
		else if(underflow && mant[MANT_BITS*2:MANT_BITS] != 1) begin
			exp <= 2**(EXP_BITS-1); //0
		end
		else if(mant[MANT_BITS*2:MANT_BITS+1] != 0) 
		begin
			exp <= exp + 1;
			mant <= mant >> 1;
		end
		else if(exp == -(2**(EXP_BITS-1) - 2) + 2**(EXP_BITS) - 1 && mant[MANT_BITS] == 0) begin
			exp <= -(2**(EXP_BITS-1) - 2) + 2**(EXP_BITS) - 2;
		end
		else
		begin
			exp <= exp - 1;
			mant <= mant << 1;
		end
	end
	else if(ps == OVERFLOW)
	begin
		exp <= 2**(EXP_BITS+1)-1;
		mant <= 0;
	end
	else if(ps == DATA_OUT)
	begin
		data_out[EXP_BITS+MANT_BITS-1:0] <= {exp_out,mant[MANT_BITS-1:0]};
		output_valid <= 1;
	end
end


always_comb
begin
	if(data_a[EXP_BITS+MANT_BITS-1:MANT_BITS] != 0)
		e1 = data_a[EXP_BITS+MANT_BITS-1:MANT_BITS] - (2**(EXP_BITS-1)-1);
	else
		e1 = 2-2**(EXP_BITS-1);
end


always_comb
begin
	if(data_b[EXP_BITS+MANT_BITS-1:MANT_BITS] != 0)
		e2 = data_b[EXP_BITS+MANT_BITS-1:MANT_BITS] - (2**(EXP_BITS-1)-1);
	else
		e2 = 2-2**(EXP_BITS-1);
end


always_comb begin
	if(greater_than_max) begin //exp greater than max
		need_to_shift = 1;
	end
	else if(less_than_min) begin //exp less than minimum
		need_to_shift = 1;
	end
	else begin //exp within bounds
		if(((mant[MANT_BITS*2:MANT_BITS+1] == 1) || (mant[MANT_BITS*2:MANT_BITS-1] == 1)) && ps == INC_EXP)
			need_to_shift = 0;
		else if(ps != INC_EXP && ((mant[MANT_BITS*2:MANT_BITS] == 1 && exp_out > 0) || (mant[MANT_BITS*2:MANT_BITS] == 0 && exp_out == 0) ))
			need_to_shift = 0;
		else
			need_to_shift = 1;
	end
end

assign greater_than_max = exp > 2**(EXP_BITS-1) - 1 + 2**(EXP_BITS) - 1;
assign less_than_min = exp < -(2**(EXP_BITS-1) - 2) + 2**(EXP_BITS) - 1; 
assign underflow = exp == -(2**(EXP_BITS-1) - 2) + 2**(EXP_BITS) - 1 ; 

assign exp_a_0 = | data_a[EXP_BITS+MANT_BITS-1:MANT_BITS];
assign exp_b_0 = | data_b[EXP_BITS+MANT_BITS-1:MANT_BITS];

assign exp_out = exp - (2**(EXP_BITS)-1) + (2**(EXP_BITS-1)-1);

/*****************************************************************************************************************
* NEXT STATE LOGIC
*****************************************************************************************************************/
always_comb
begin
	case(ps)
		WAIT:
			if(input_valid)
				ns = INIT;
			else
				ns = WAIT;
		INIT:
			ns = CALC_MANT;
		CALC_MANT:
			ns = CALC_EXP;
		CALC_EXP:
			ns = CHECK;
		CHECK:
			if(need_to_shift && !exp[EXP_BITS+1])
				ns = INC_EXP;
			else if(exp[EXP_BITS+1])
				ns = OVERFLOW;
			else
				ns = DATA_OUT;
		INC_EXP:
			if(exp[EXP_BITS+1])
				ns = OVERFLOW;
			else if(need_to_shift && !(greater_than_max && mant == 0) && !(less_than_min && mant == 0) && !underflow )
				ns = INC_EXP;
			else
				ns = DATA_OUT;
		OVERFLOW:
			ns = DATA_OUT;
		DATA_OUT:	
			ns = WAIT;
	endcase
end

always_ff @ (posedge clk, negedge reset_n)
begin
	if(!reset_n)
		ps <= WAIT;
	else
		ps <= ns;
end

endmodule
