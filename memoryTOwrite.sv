`include "definitions.sv"

module memTOwrite
(
	 input logic clk,
	 input logic stall,
	 input memTOwrite_s memTOwrite_s_i,
	 output memTOwrite_s memTOwrite_s_o
);
always_ff @(posedge clk) //enable SystemVerilog to make always_ff work!
begin
	if(stall)
		memTOwrite_s_o <= memTOwrite_s_o;
		
	else
		memTOwrite_s_o <= memTOwrite_s_i;
end

endmodule