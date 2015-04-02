`include "definitions.sv"

module hazard_flags
(
	 input logic is_load_op_o,
	 input logic is_store_op_o,
	 input fetchTOdecode_s fetchTOdecode_s_o,
	 input decodeTOexecute_s decodeTOexecute_s_o,
	 input executeTOmem_s executeTOmem_s_o,
	 input memTOwrite_s memTOwrite_s_o,
	 output logic itr,
	 output logic [1:0] f_0,
	 output logic [1:0] f_1,
	 output logic [1:0] f_2
);

always_comb
begin
	if((executeTOmem_s_o.instruction_executeTOmem.rd == decodeTOexecute_s_o.instruction_decodeTOexecute.rs_imm) &&
	       executeTOmem_s_o.op_writes_rf_c_executeTOmem && executeTOmem_s_o.instruction_executeTOmem.rd)
		f_0 = 2'b10;
	else if(~(executeTOmem_s_o.op_writes_rf_c_executeTOmem && executeTOmem_s_o.instruction_executeTOmem.rd &&
			 (executeTOmem_s_o.instruction_executeTOmem.rd == decodeTOexecute_s_o.instruction_decodeTOexecute.rs_imm))
			  && (memTOwrite_s_o.instruction_memTOwrite.rd == decodeTOexecute_s_o.instruction_decodeTOexecute.rs_imm)&& 
			  memTOwrite_s_o.op_writes_rf_c_memTOwrite && memTOwrite_s_o.instruction_memTOwrite.rd)
		f_0 = 2'b01;
	else
		f_0 = 2'b00;
end

always_comb
begin
	if(executeTOmem_s_o.op_writes_rf_c_executeTOmem && executeTOmem_s_o.instruction_executeTOmem.rd &&
		(executeTOmem_s_o.instruction_executeTOmem.rd === decodeTOexecute_s_o.instruction_decodeTOexecute.rd))
		f_1 = 2'b10;
	else if( (memTOwrite_s_o.instruction_memTOwrite.rd === decodeTOexecute_s_o.instruction_decodeTOexecute.rd)
	       &&memTOwrite_s_o.op_writes_rf_c_memTOwrite && memTOwrite_s_o.instruction_memTOwrite.rd &&
			~(executeTOmem_s_o.op_writes_rf_c_executeTOmem && executeTOmem_s_o.instruction_executeTOmem.rd &&
			 (executeTOmem_s_o.instruction_executeTOmem.rd === decodeTOexecute_s_o.instruction_decodeTOexecute.rd)))
		f_1 = 2'b01;
	else
		f_1 = 2'b00;
end

always_comb
begin
	if(memTOwrite_s_o.is_load_op_c_memTOwrite && executeTOmem_s_o.is_mem_op_c_executeTOmem)
	begin
		if(memTOwrite_s_o.instruction_memTOwrite.rd == executeTOmem_s_o.instruction_executeTOmem.rd)
			f_2 = 2'b10;
		else if(memTOwrite_s_o.instruction_memTOwrite.rd == executeTOmem_s_o.instruction_executeTOmem.rs_imm)
			f_2 = 2'b01;
		else
			f_2 = 2'b00;
	end
	else
		f_2 = 2'b00;
end

always_comb
begin
	itr = 1'b0;
	if(((decodeTOexecute_s_o.instruction_decodeTOexecute.rd == fetchTOdecode_s_o.instruction_fetchTOdecode.rd) ||
		 (decodeTOexecute_s_o.instruction_decodeTOexecute.rd == fetchTOdecode_s_o.instruction_fetchTOdecode.rs_imm))
		 && decodeTOexecute_s_o.is_load_op_c_decodeTOexecute)
		itr = 1'b1;
end

endmodule