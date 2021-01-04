module multiplier(
	input wire clk,
	input wire reset_n,

	input wire input_valid,
	input logic [31:0] in_a,
	input logic [31:0] in_b,
	output logic [31:0] data_out,
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


logic [31:0] data_a;
logic [31:0] data_b;
logic [8:0] exp;
logic [47:0] mant;

wire exp_a_0;
wire exp_b_0;

wire need_to_shift;

logic signed [9:0] e1;
logic signed [9:0] e2;
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
		exp <= 9'b000000000;
		mant <= 48'h000000000000;
	end
	else if(ps == CALC_MANT)
	begin
		mant <= {exp_a_0,data_a[22:0]} * {exp_b_0,data_b[22:0]};
	end
	else if(ps == CALC_EXP)
	begin
		if(((e1 + e2) >= 128) || (e1 == 128) || (e2 == 128))
			exp <= 511;
		else if(mant == 0 && (data_a[30:23] == 0 || data_b[30:23] == 0))
			exp <= 0;
		else if(((e1+e2) > -126) && ((e1+e2) < 128)) 
			exp <= e1 + e2 + 127;
		else if(((e1 + e2) == -126) && (mant[47:46] == 2'b00))
			exp <= 0;
		else if(((e1 + e2) == -126) && (mant[47:46] != 2'b00))
			exp <= 1;
		else
		begin
			exp <= 0;
			mant <= 0;
		end
		data_out[31] <= data_a[31] ^ data_b[31];
	end
	else if(ps == INC_EXP)
	begin
		if(mant[47] == 1)
		begin
			exp <= exp + 1;
			mant <= mant >> 1;
		end
		else
		begin
			exp <= exp - 1;
			mant <= mant << 1;
		end
	end
	else if(ps == OVERFLOW)
	begin
		exp <= 9'b011111111;
		mant <= 48'h000000000000;
	end
	else if(ps == DATA_OUT)
	begin
		data_out[30:0] <= {exp[7:0],mant[45:23]};
		output_valid <= 1;
	end
end


always_comb
begin
	if(data_a[30:23] != 0)
		e1 = data_a[30:23] - 127;
	else
		e1 = -126;
end


always_comb
begin
	if(data_b[30:23] != 0)
		e2 = data_b[30:23] - 127;
	else
		e2 = -126;
end

assign need_to_shift = ((mant[47:46] != 2'b01) && (exp[7:0] != 0)) || ((mant[47:46] != 2'b00) && (exp[7:0] == 0));
assign exp_a_0 = | data_a[30:23];
assign exp_b_0 = | data_b[30:23];



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
			if(need_to_shift && !exp[8])
				ns = INC_EXP;
			else if(exp[8])
				ns = OVERFLOW;
			else
				ns = DATA_OUT;
		INC_EXP:
			if(exp[8])
				ns = OVERFLOW;
			else if(need_to_shift && !exp[8] && !((mant[47:45] == 3'b001) || (mant[47] == 1)))
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
