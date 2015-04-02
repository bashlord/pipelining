module reg_file#(parameter addr_width_p = 6, addr_width_q = 32)
(
	 input clk,
	 input wen_i,
	 input [addr_width_p -1:0] write_i,
	 input [addr_width_q -1:0] wd_i,
	 input [addr_width_p -1:0] read0_i,
	 input [addr_width_p -1:0] read1_i,
	 output [addr_width_q -1:0] read0_o,
	 output [addr_width_q -1:0] read1_o
);
 logic [addr_width_q -1:0] regf [2**addr_width_p -1:0];
 logic [addr_width_q -1:0] read0_a, read1_a;
 
 always_comb
 begin
	if((write_i == read0_i) && wen_i)
		read0_a = wd_i;
		
	else
		read0_a = regf[read0_i];
		
	if((write_i == read1_i) && wen_i)
		read1_a = wd_i;
		
	else
		read1_a = regf[read1_i];
 end
 
 assign read0_o = read0_a;
 assign read1_o = read1_a;

always_ff @(posedge clk) 
begin
	if(wen_i)
	begin
		regf[write_i] <= wd_i;
	end
end

endmodule
