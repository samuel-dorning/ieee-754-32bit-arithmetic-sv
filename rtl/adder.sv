module adder #(MANT_BITS=23, EXP_BITS=8)(
	input logic reset_n,
	input logic clk,

	input logic [EXP_BITS+MANT_BITS:0]  in_a,
	input logic [EXP_BITS+MANT_BITS:0] in_b,
	input logic input_valid,


	output logic [EXP_BITS+MANT_BITS:0] data_out,
	output logic output_valid

);


enum logic [3:0]{
	WAIT = 4'b0000,
	INIT = 4'b0001,
	STO = 4'b0010,
	SHIFT = 4'b0011,
	ADD = 4'b0100,
	CMP = 4'b0101,
	ABS = 4'b0110,
	CHK = 4'b0111,
	NORM = 4'b1000,
	DONE = 4'b1001,
	RES = 4'b1010
} ps, ns;

logic [EXP_BITS+MANT_BITS:0] data_a;
logic [EXP_BITS+MANT_BITS:0] data_b;
logic signed [MANT_BITS+2:0] shift_reg;
logic signed [MANT_BITS+2:0] mant1;
logic signed [MANT_BITS+2:0] mant2;
logic signed [MANT_BITS+2:0] final_mant;
logic [EXP_BITS-1:0] exp;
logic inv_bit_a;
logic inv_bit_b;


logic signed [EXP_BITS:0] e1;
logic signed [EXP_BITS:0] e2;
logic signed [EXP_BITS:0] exp_diff;

/*****************************************************************************************************************
* DATA PATH 
*****************************************************************************************************************/
always_ff @ (posedge clk)
begin
	if(ps == WAIT) begin
		output_valid <= 0;
	end
	else if(ps == INIT) begin
		data_a <= in_a;
		data_b <= in_b;
		data_out <= 0;
		exp <= 0;
		final_mant <= 0;
	end
	else if(ps == STO) begin
		if(e1 >= e2) begin
			shift_reg <= mant2;
			exp <= data_a[EXP_BITS+MANT_BITS-1:MANT_BITS];
		end
		else begin
			shift_reg <= mant1;
			exp <= data_b[EXP_BITS+MANT_BITS-1:MANT_BITS];
		end
	end
	else if(ps == RES) begin
		if(data_a[EXP_BITS+MANT_BITS-1:MANT_BITS] == (2**(EXP_BITS)-1) && data_b[EXP_BITS+MANT_BITS-1:MANT_BITS] == (2**(EXP_BITS)-1) && data_a[EXP_BITS+MANT_BITS] == 0 && data_b[EXP_BITS+MANT_BITS] == 0) begin
		   	data_out <= { 1'b0,{EXP_BITS{1'b1}},{MANT_BITS{1'b0}} };
			output_valid <= 1;
		end
		else if(data_a[EXP_BITS+MANT_BITS-1:MANT_BITS] == (2**(EXP_BITS)-1) && data_b[EXP_BITS+MANT_BITS-1:MANT_BITS] == (2**(EXP_BITS)-1) && data_a[EXP_BITS+MANT_BITS] == 1 && data_b[EXP_BITS+MANT_BITS] == 1) begin
		   	data_out <= { 1'b1,{EXP_BITS{1'b1}},{MANT_BITS{1'b0}} };
			output_valid <= 1;
		end
		else if(data_a[EXP_BITS+MANT_BITS-1:MANT_BITS] == (2**(EXP_BITS)-1) && data_b[EXP_BITS+MANT_BITS-1:MANT_BITS] == (2**(EXP_BITS)-1) && (data_a[EXP_BITS+MANT_BITS] == 1 ^ data_b[EXP_BITS+MANT_BITS] == 1)) begin
		   	data_out <= { 1'b1,{EXP_BITS{1'b1}},{MANT_BITS{1'b1}} };
			output_valid <= 1;		
		end
		else if(e1 > e2) begin
			data_out <= data_a;
			output_valid <= 1;
		end
		else if(e2 > e1) begin
			data_out <= data_b;
			output_valid <= 1;
		end
		else begin
		   	data_out <= { 1'b1,{EXP_BITS{1'b1}},{MANT_BITS{1'b1}} };
			output_valid <= 1;
		end	
	end
	else if(ps == SHIFT) begin
		shift_reg <= shift_reg >>> exp_diff;
	end
	else if(ps == ADD)
		if(e1 >= e2)
			final_mant <= mant1 + shift_reg;
		else
			final_mant <= mant2 + shift_reg;
	//else if(ps == CMP)
	else if(ps == ABS) begin
		final_mant <= ~(final_mant) + 1;
		data_out[EXP_BITS+MANT_BITS] <= 1;
	end
	//else if(ps == CHK)
	else if(ps == NORM) begin
		if(final_mant[MANT_BITS+1] == 1 && exp < 2**(EXP_BITS)-2) begin
			final_mant <= final_mant >> 1;
			exp <= exp + 1;
		end
		else if(final_mant[MANT_BITS+1] == 1 && exp >= 2**(EXP_BITS)-2) begin
			final_mant <= 0;
			exp <= (2**(EXP_BITS)-1);
		end
		else if(final_mant[MANT_BITS+1:MANT_BITS] == 2'b00 && exp > 1) begin
			final_mant <= final_mant << 1;
			exp <= exp - 1;
		end
		else if(final_mant[MANT_BITS+1:MANT_BITS] == 2'b00 && exp <= 1) begin
			exp <= 0;
		end
		else if(final_mant[MANT_BITS] == 1 && exp == 0) begin
			exp <= 1;
		end
		else begin
			exp <= 0;
			final_mant <= 0;
		end
	end
	else if(ps == DONE) begin
		data_out[EXP_BITS+MANT_BITS-1:0] <= {exp,final_mant[MANT_BITS-1:0]};
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

always_comb
begin
	if(e1 >= e2)
		exp_diff = e1 - e2;
	else
		exp_diff = e2 -e1;
end

always_comb
begin
	if(data_a[EXP_BITS+MANT_BITS] == 1)
		mant1 = ~{2'b00,inv_bit_a,data_a[MANT_BITS-1:0]} + 1;
	else
		mant1 = {2'b00,inv_bit_a,data_a[MANT_BITS-1:0]};
end

always_comb
begin
	if(data_b[EXP_BITS+MANT_BITS] == 1)
		mant2 = ~{2'b00,inv_bit_b,data_b[MANT_BITS-1:0]} + 1;
	else
		mant2 = {2'b00,inv_bit_b,data_b[MANT_BITS-1:0]};
end

always_comb
begin
	if(data_a[EXP_BITS+MANT_BITS-1:MANT_BITS] == 0)
		inv_bit_a = 0;
	else
		inv_bit_a = 1;
end

always_comb
begin
	if(data_b[EXP_BITS+MANT_BITS-1:MANT_BITS] == 0)
		inv_bit_b = 0;
	else
		inv_bit_b = 1;
end


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
			ns = STO;
		STO:
			if(exp_diff > MANT_BITS || data_a[EXP_BITS+MANT_BITS-1:MANT_BITS] == {EXP_BITS{1'b1}} || data_b[EXP_BITS+MANT_BITS-1:MANT_BITS] == {EXP_BITS{1'b1}})
				ns = RES;
			else if(e1 == e2 && data_a[EXP_BITS+MANT_BITS-1:MANT_BITS] != {EXP_BITS{1'b1}} && data_b[EXP_BITS+MANT_BITS-1:MANT_BITS] != {EXP_BITS{1'b1}})
				ns = ADD;
			else
				ns = SHIFT;
		RES:
			ns = WAIT;
		SHIFT:
			ns = ADD;
		ADD:
			ns = CMP;
		CMP:
			if(final_mant[MANT_BITS+2])
				ns = ABS;
			else if((final_mant[MANT_BITS+1:MANT_BITS] == 2'b01 && exp != 0) || (exp == 0 && final_mant[MANT_BITS+1:MANT_BITS] == 2'b00))
				ns = DONE;
			else
				ns = NORM;
		ABS:
			ns = CHK;
		CHK:
			if((final_mant[MANT_BITS+1:MANT_BITS] == 2'b01 && exp != 0) || (exp == 0 && final_mant[MANT_BITS+1:MANT_BITS] == 2'b00))
				ns = DONE;
			else
				ns = NORM;
		NORM:
			if(final_mant[MANT_BITS+1] == 1 || exp == 0 || final_mant[MANT_BITS-1] == 1 || exp == (2**(EXP_BITS)-1))
				ns = DONE;
			else
				ns = NORM;
		DONE:
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
