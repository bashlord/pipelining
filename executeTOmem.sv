`include "definitions.sv"

module executeTOmem
(
	 input logic clk,
	 input logic stall,
	 input executeTOmem_s executeTOmem_s_i,
	 output executeTOmem_s executeTOmem_s_o
);

always_ff @(posedge clk) //enable SystemVerilog to make always_ff work!
begin
	if(stall)
		executeTOmem_s_o <= executeTOmem_s_o;
	else
		executeTOmem_s_o <= executeTOmem_s_i;
end

endmodule