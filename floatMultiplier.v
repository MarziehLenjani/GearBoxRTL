
module floatMultiplier(a, b, out);
  input  [31:0] a, b;
  output [31:0] out;

  wire [31:0] out;
	reg a_sign;
  reg [7:0] a_exponent;
  reg [23:0] a_mantissa;
	reg b_sign;
  reg [7:0] b_exponent;
  reg [23:0] b_mantissa;

  reg o_sign;
  reg [7:0] o_exponent;
  reg [24:0] o_mantissa;

	reg [47:0] product;

  assign out[31] = o_sign;
  assign out[30:23] = o_exponent;
  assign out[22:0] = o_mantissa[22:0];

	reg  [7:0] i_e;
	reg  [47:0] i_m;
	wire [7:0] o_e;
	wire [47:0] o_m;

	multiplication_normaliser norm1
	(
		.in_e(i_e),
		.in_m(i_m),
		.out_e(o_e),
		.out_m(o_m)
	);


  always @ ( * ) begin
		a_sign = a[31];
		if(a[30:23] == 0) begin
			a_exponent = 8'b00000001;
			a_mantissa = {1'b0, a[22:0]};
		end else begin
			a_exponent = a[30:23];
			a_mantissa = {1'b1, a[22:0]};
		end
		b_sign = b[31];
		if(b[30:23] == 0) begin
			b_exponent = 8'b00000001;
			b_mantissa = {1'b0, b[22:0]};
		end else begin
			b_exponent = b[30:23];
			b_mantissa = {1'b1, b[22:0]};
		end
    o_sign = a_sign ^ b_sign;
    o_exponent = a_exponent + b_exponent - 127;
    product = a_mantissa * b_mantissa;
		// Normalization
    if(product[47] == 1) begin
      o_exponent = o_exponent + 1;
      product = product >> 1;
    end else if((product[46] != 1) && (o_exponent != 0)) begin
      i_e = o_exponent;
      i_m = product;
      o_exponent = o_e;
      product = o_m;
    end
		o_mantissa = product[46:23];
	end
endmodule
module multiplication_normaliser(in_e, in_m, out_e, out_m);
  input [7:0] in_e;
  input [47:0] in_m;
  output [7:0] out_e;
  output [47:0] out_m;

  wire [7:0] in_e;
  wire [47:0] in_m;
  reg [7:0] out_e;
  reg [47:0] out_m;

  always @ ( * ) begin
	  if (in_m[46:41] == 6'b000001) begin
			out_e = in_e - 5;
			out_m = in_m << 5;
		end else if (in_m[46:42] == 5'b00001) begin
			out_e = in_e - 4;
			out_m = in_m << 4;
		end else if (in_m[46:43] == 4'b0001) begin
			out_e = in_e - 3;
			out_m = in_m << 3;
		end else if (in_m[46:44] == 3'b001) begin
			out_e = in_e - 2;
			out_m = in_m << 2;
		end else if (in_m[46:45] == 2'b01) begin
			out_e = in_e - 1;
			out_m = in_m << 1;
		end
  end
endmodule

module divider (a, b, out);
	input [31:0] a;
	input [31:0] b;
	output [31:0] out;

	wire [31:0] b_reciprocal;

	reciprocal recip
	(
		.in(b),
		.out(b_reciprocal)
	);

	multiplier mult
	(
		.a(a),
		.b(b_reciprocal),
		.out(out)
	);

endmodule


