`include "definitions.sv"

module fetchTOdecode
(
	 input logic clk,
	 input logic stall,
	 input logic flush,
	 input logic itr,
	 input logic IW,
	 input fetchTOdecode_s fetchTOdecode_s_i,
	 output fetchTOdecode_s fetchTOdecode_s_o
);

always_ff @(posedge clk) //enable SystemVerilog to make always_ff work!
begin
	if(itr |stall)
		fetchTOdecode_s_o <= fetchTOdecode_s_o;
	else
	begin
		if(flush |IW)
		begin
			fetchTOdecode_s_o.instruction_fetchTOdecode <= `kNOP;
			fetchTOdecode_s_o.PC_r_fetchTOdecode <= fetchTOdecode_s_o.PC_r_fetchTOdecode;
		end
		else 
			fetchTOdecode_s_o <= fetchTOdecode_s_i;
	end
end

endmodule
