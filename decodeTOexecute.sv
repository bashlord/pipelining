`include "definitions.sv"

module decodeTOexecute
(
	 input logic clk,
	 input logic stall,
	 input logic flush,
	 input logic itr,
	 input decodeTOexecute_s decodeTOexecute_s_i,
	 output decodeTOexecute_s decodeTOexecute_s_o
);

always_ff @(posedge clk) //enable SystemVerilog to make always_ff work!
begin
	if(stall)
	begin
		decodeTOexecute_s_o <= decodeTOexecute_s_o;
	end
	
	else
	begin
		if(itr | flush)
		begin
		  decodeTOexecute_s_o.op_writes_rf_c_decodeTOexecute <= 1'b0;
		  
			decodeTOexecute_s_o.is_store_op_c_decodeTOexecute <= 1'b0;
			
			decodeTOexecute_s_o.is_mem_op_c_decodeTOexecute <= 1'b0;
			
			decodeTOexecute_s_o.is_byte_op_c_decodeTOexecute <= 1'b0;
			
			decodeTOexecute_s_o.instruction_decodeTOexecute <= `kNOP;
			
			decodeTOexecute_s_o.PC_r_decodeTOexecute <= decodeTOexecute_s_o.PC_r_decodeTOexecute;
			
			decodeTOexecute_s_o.rs_val_decodeTOexecute <= 32'b0;
			
			decodeTOexecute_s_o.rd_val_decodeTOexecute <= 32'b0;
			
			decodeTOexecute_s_o.is_load_op_c_decodeTOexecute <= 1'b0;

		end
		else 
			decodeTOexecute_s_o <= decodeTOexecute_s_i;
	end
end

endmodule
