`include "definitions.sv"

module core #(parameter imem_addr_width_p=10
                       ,net_ID_p = 10'b0000000001)
             (input  clk
             ,input  reset

             ,input  net_packet_s net_packet_i
             ,output net_packet_s net_packet_o

             ,input  mem_out_s from_mem_i
             ,output mem_in_s  to_mem_o

             ,output logic [mask_length_gp-1:0] barrier_o
             ,output logic                      exception_o
             ,output debug_s                    debug_o
             ,output logic [31:0]               data_mem_addr
             );
			 
//flags used to check which state the pipeline should be in
			   
logic itr;
logic flush;
logic IW;
logic [1:0] counter;
logic [1:0] f_0, f_1, f_2;
logic [31:0] mem_write_data;
// stages input & output
fetchTOdecode_s fetchTOdecode_s_i, fetchTOdecode_s_o;
decodeTOexecute_s decodeTOexecute_s_i, decodeTOexecute_s_o;
executeTOmem_s executeTOmem_s_i, executeTOmem_s_o;
memTOwrite_s memTOwrite_s_i, memTOwrite_s_o;

logic [31:0] memTOwrite_n;			 
			 

//---- Adresses and Data ----//
// Ins. memory address signals
logic [imem_addr_width_p-1:0] PC_r, PC_n,
                              pc_plus1, imem_addr,
                              imm_jump_add;
// Ins. memory output
instruction_s instruction, imem_out, instruction_r;

// Result of ALU, Register file outputs, Data memory output data
logic [31:0] alu_result, rs_val_or_zero, rd_val_or_zero, rs_val, rd_val;

// Reg. File address
logic [($bits(instruction.rs_imm))-1:0] rd_addr;
logic [($bits(instruction.rs_imm))-1:0] rd_read_addr;

// Data for Reg. File signals
logic [31:0] regfile_sig;

//---- Control signals ----//
// ALU output to determin whether to jump or not
logic jump_now;

// controller output signals
logic is_load_op_c,  op_writes_rf_c, valid_to_mem_c,
      is_store_op_c, is_mem_op_c,    PC_wen,
      is_byte_op_c,  PC_wen_r;

// Handshak protocol signals for memory
logic yumi_to_mem_c;

// Final signals after network interfere
logic imem_wen, rf_wen;

// Network operation signals
logic net_ID_match,      net_PC_write_cmd,  net_imem_write_cmd,
      net_reg_write_cmd, net_bar_write_cmd, net_PC_write_cmd_IDLE;

// Memory stages and stall signals
logic [1:0] mem_stage_r, mem_stage_n;
logic stall, stall_non_mem;

// Exception signal
logic exception_n;

// State machine signals
state_e state_r,state_n;

//---- network and barrier signals ----//
instruction_s net_instruction;
logic [mask_length_gp-1:0] barrier_r,      barrier_n,
                           barrier_mask_r, barrier_mask_n;
//modules to update hazard flags later for forwarding/stalling/flushing,etc
      fetchTOdecode fetch_reg(.clk(clk)
			 ,.stall(stall)
			 ,.flush(flush)
			 ,.itr(itr)
			 ,.IW(IW)
		   ,.fetchTOdecode_s_i(fetchTOdecode_s_i)
       ,.fetchTOdecode_s_o(fetchTOdecode_s_o)
			 );
			 
			 decodeTOexecute decode_reg(.clk(clk)
			 ,.stall(stall)
			 ,.flush(flush)
			 ,.itr(itr)
		   ,.decodeTOexecute_s_i(decodeTOexecute_s_i)
       ,.decodeTOexecute_s_o(decodeTOexecute_s_o)
			 );

      executeTOmem executeTOmem(.clk(clk)
			 ,.stall(stall)
			 ,.executeTOmem_s_i(executeTOmem_s_i)
			 ,.executeTOmem_s_o(executeTOmem_s_o)
			 );
			 
			 memTOwrite mem_reg(.clk(clk)
			 ,.stall(stall)
			 ,.memTOwrite_s_i(memTOwrite_s_i)
			 ,.memTOwrite_s_o(memTOwrite_s_o)
			 );
assign fetchTOdecode_s_i = '{instruction_fetchTOdecode : instruction ,PC_r_fetchTOdecode : PC_r};

always_comb
begin
	IW= 1'b0;
	if(fetchTOdecode_s_o.instruction_fetchTOdecode==?`kWAIT || counter > 2'b00)
		IW= 1'b1;
	else
		IW= 1'b0;
end

always_ff @(posedge clk)
begin
	if(fetchTOdecode_s_o.instruction_fetchTOdecode==?`kWAIT)
		counter<= 2'b11;
	else if(counter > 2'b00)
		counter <= counter - 2'b01;
	else
		counter <= 2'b00;
end

assign decodeTOexecute_s_i = '{instruction_decodeTOexecute	: fetchTOdecode_s_o.instruction_fetchTOdecode,
				  PC_r_decodeTOexecute : fetchTOdecode_s_o.PC_r_fetchTOdecode,
				  rs_val_decodeTOexecute	: rs_val,
				  rd_val_decodeTOexecute : rd_val,
				  is_load_op_c_decodeTOexecute : is_load_op_c,
				  op_writes_rf_c_decodeTOexecute : op_writes_rf_c,
				  is_store_op_c_decodeTOexecute	: is_store_op_c,
				  is_mem_op_c_decodeTOexecute	: is_mem_op_c,
				  is_byte_op_c_decodeTOexecute	: is_byte_op_c
				 };
				 
assign executeTOmem_s_i = '{instruction_executeTOmem	: decodeTOexecute_s_o.instruction_decodeTOexecute,
				  PC_r_executeTOmem : decodeTOexecute_s_o.PC_r_decodeTOexecute,
				  alu_result_executeTOmem		: alu_result,
				  rs_val_or_zero_executeTOmem : rs_val_or_zero,
				  is_load_op_c_executeTOmem	: decodeTOexecute_s_o.is_load_op_c_decodeTOexecute,
				  op_writes_rf_c_executeTOmem : decodeTOexecute_s_o.op_writes_rf_c_decodeTOexecute,
				  is_store_op_c_executeTOmem	: decodeTOexecute_s_o.is_store_op_c_decodeTOexecute,
				  is_mem_op_c_executeTOmem	: decodeTOexecute_s_o.is_mem_op_c_decodeTOexecute,
				  is_byte_op_c_executeTOmem	: decodeTOexecute_s_o.is_byte_op_c_decodeTOexecute
				 };
				 

assign memTOwrite_s_i = '{instruction_memTOwrite	: executeTOmem_s_o.instruction_executeTOmem,
				  PC_r_memTOwrite			: executeTOmem_s_o.PC_r_executeTOmem,
				  rf_wd_memTOwrite			: memTOwrite_n,
				  op_writes_rf_c_memTOwrite : executeTOmem_s_o.op_writes_rf_c_executeTOmem,
				  alu_result_memTOwrite		: executeTOmem_s_o.alu_result_executeTOmem,
				  is_load_op_c_memTOwrite	: executeTOmem_s_o.is_load_op_c_executeTOmem
				 };

always_comb
begin
	if (executeTOmem_s_o.is_load_op_c_executeTOmem)
		memTOwrite_n = from_mem_i.read_data;
	else
		memTOwrite_n = executeTOmem_s_o.alu_result_executeTOmem;
end
				 

//---- Connection to external modules ----//

// Suppress warnings
assign net_packet_o = net_packet_i;

// Data_mem
assign to_mem_o = '{write_data    : mem_write_data
                   ,valid         : valid_to_mem_c
                   ,wen           : executeTOmem_s_o.is_store_op_c_executeTOmem
                   ,byte_not_word : executeTOmem_s_o.is_byte_op_c_executeTOmem
                   ,yumi          : yumi_to_mem_c
                   };

assign debug_o = {memTOwrite_s_o.PC_r_memTOwrite, memTOwrite_s_o.instruction_memTOwrite, state_r, barrier_mask_r, barrier_r};
// Insruction memory
instr_mem #(.addr_width_p(imem_addr_width_p)) imem
           (.clk(clk)
           ,.addr_i(imem_addr)
           ,.instruction_i(net_instruction)
           ,.wen_i(imem_wen)
           ,.instruction_o(imem_out)
           );

assign instruction = (PC_wen_r) ? imem_out : instruction_r;

// Register file
reg_file #(.addr_width_p($bits(instruction.rs_imm))) rf
          (.clk(clk)
          ,.read0_i(fetchTOdecode_s_o.instruction_fetchTOdecode.rs_imm)
          ,.read1_i(rd_read_addr)
          ,.wen_i(rf_wen)
          ,.wd_i(regfile_sig)  
          ,.read0_o(rs_val)
          ,.read1_o(rd_val)
			    ,.write_i(rd_addr)
          );

always_comb
begin
	unique casez (f_0)
	  2'b10:
		rs_val_or_zero = executeTOmem_s_o.alu_result_executeTOmem;
		
	  2'b01:
		rs_val_or_zero = regfile_sig;
		
	  default:
		rs_val_or_zero = decodeTOexecute_s_o.instruction_decodeTOexecute.rs_imm ? decodeTOexecute_s_o.rs_val_decodeTOexecute : 32'b0;
	
	endcase
end	

always_comb
begin
	unique casez(f_1)
	  2'b10:
		rd_val_or_zero = executeTOmem_s_o.alu_result_executeTOmem;
		
	  2'b01:
		rd_val_or_zero = regfile_sig;
	  
	  default:
		rd_val_or_zero = decodeTOexecute_s_o.instruction_decodeTOexecute.rd 
		                  ? decodeTOexecute_s_o.rd_val_decodeTOexecute : 32'b0;
	  
	  endcase
end

always_comb
begin
	unique casez(f_2)
	  2'b10:
	   begin
		  data_mem_addr = memTOwrite_s_o.rf_wd_memTOwrite;
		  mem_write_data = executeTOmem_s_o.rs_val_or_zero_executeTOmem;
	   end
	  
	  2'b01:
	   begin
		    data_mem_addr = executeTOmem_s_o.alu_result_executeTOmem;
		    mem_write_data = memTOwrite_s_o.rf_wd_memTOwrite;
	  end
	  
	  default:
	   begin
		    data_mem_addr = executeTOmem_s_o.alu_result_executeTOmem;
		    mem_write_data = executeTOmem_s_o.rs_val_or_zero_executeTOmem;
	   end
	  
	endcase
end

// ALU
alu alu_1 (.rd_i(rd_val_or_zero)
          ,.rs_i(rs_val_or_zero)
          ,.op_i(decodeTOexecute_s_o.instruction_decodeTOexecute)
          ,.result_o(alu_result)
          ,.jump_now_o(jump_now)
          );
          
always_comb
  begin
    if (net_reg_write_cmd)
      regfile_sig = net_packet_i.net_data;

    else if (memTOwrite_s_o.instruction_memTOwrite ==?`kJALR)
      regfile_sig = memTOwrite_s_o.PC_r_memTOwrite + 1;

    else
      regfile_sig= memTOwrite_s_o.rf_wd_memTOwrite;
  end

// Determine next PC
assign pc_plus1     = PC_r + 1'b1;
assign imm_jump_add = $signed(decodeTOexecute_s_o.instruction_decodeTOexecute.rs_imm)  
                                          + $signed(decodeTOexecute_s_o.PC_r_decodeTOexecute);

// Next pc is based on network or the instruction
always_comb
  begin
    PC_n = pc_plus1;
    if (net_PC_write_cmd_IDLE)
      PC_n = net_packet_i.net_addr;
      
    else
      unique casez (decodeTOexecute_s_o.instruction_decodeTOexecute)
        `kJALR: 
         
		  if(f_0 == 2'b10)
			PC_n = executeTOmem_s_o.alu_result_executeTOmem;
			
		  else
			PC_n = alu_result[0+:imem_addr_width_p];
        `kBNEQZ,`kBEQZ,`kBLTZ,`kBGTZ: 
        
          if (jump_now)
            PC_n = imm_jump_add;
            
        default: begin end
          
      endcase
  end
  
always_comb
begin
	if(decodeTOexecute_s_o.instruction_decodeTOexecute==?`kJALR)
		flush = 1'b1;
		
	else
		flush = jump_now;
		
end
  
hazard_flags hazard (.is_load_op_o(is_load_op_c),
						 .is_store_op_o(is_store_op_c),
						 .fetchTOdecode_s_o(fetchTOdecode_s_o),
						 .decodeTOexecute_s_o(decodeTOexecute_s_o),
						 .executeTOmem_s_o(executeTOmem_s_o),
						 .memTOwrite_s_o(memTOwrite_s_o),
						 .itr(itr),
						 .f_0(f_0),
						 .f_1(f_1),
						 .f_2(f_2)
                  );

assign PC_wen = (net_PC_write_cmd_IDLE || (~stall && ~itr && ~IW) || flush);

// Sequential part, including PC, barrier, exception and state
always_ff @ (posedge clk)
  begin
    if (!reset)
      begin
        PC_r            <= 0;
        barrier_mask_r  <= {(mask_length_gp){1'b0}};
        barrier_r       <= {(mask_length_gp){1'b0}};
        state_r         <= IDLE;
        instruction_r   <= 0;
        PC_wen_r        <= 0;
        exception_o     <= 0;
        mem_stage_r     <= 2'b00;
      end

    else
      begin
        if (PC_wen)
          PC_r         <= PC_n;
        barrier_mask_r <= barrier_mask_n;
        barrier_r      <= barrier_n;
        state_r        <= state_n;
        instruction_r  <= instruction;
        PC_wen_r       <= PC_wen;
        exception_o    <= exception_n;
        mem_stage_r    <= mem_stage_n;
      end
  end

// stall and memory stages signals
// rf structural hazard and imem structural hazard (can't load next instruction)
assign stall_non_mem = (net_reg_write_cmd && memTOwrite_s_o.op_writes_rf_c_memTOwrite)
                    || (net_imem_write_cmd);
// Stall if LD/ST still active; or in non-RUN state
assign stall = stall_non_mem || (mem_stage_n != 2'b00) || (state_r != RUN);

// Launch LD/ST
assign valid_to_mem_c = executeTOmem_s_o.is_mem_op_c_executeTOmem & (mem_stage_r < 2'b10);

always_comb
  begin
    yumi_to_mem_c = 1'b0;
    mem_stage_n   = mem_stage_r;

    if (valid_to_mem_c)
        mem_stage_n   = 2'b01;

    if (from_mem_i.yumi)
        mem_stage_n   = 2'b10;

    if (from_mem_i.valid & ~stall_non_mem)
      begin
        mem_stage_n   = 2'b00;
        yumi_to_mem_c = 1'b1;
      end
  end

// Decode module
cl_decode decode (.instruction_i(fetchTOdecode_s_o.instruction_fetchTOdecode)

                  ,.is_load_op_o(is_load_op_c)
                  ,.op_writes_rf_o(op_writes_rf_c)
                  ,.is_store_op_o(is_store_op_c)
                  ,.is_mem_op_o(is_mem_op_c)
                  ,.is_byte_op_o(is_byte_op_c)
                  );

cl_state_machine state_machine (.instruction_i(memTOwrite_s_o.instruction_memTOwrite)
                               ,.state_i(state_r)
                               ,.exception_i(exception_o)
                               ,.net_PC_write_cmd_IDLE_i(net_PC_write_cmd_IDLE)
                               ,.stall_i(stall)
                               ,.state_o(state_n)
                               );
//---- Datapath with network ----//
// Detect a valid packet for this core
assign net_ID_match = (net_packet_i.ID==net_ID_p);

// Network operation
assign net_PC_write_cmd      = (net_ID_match && (net_packet_i.net_op==PC));
assign net_imem_write_cmd    = (net_ID_match && (net_packet_i.net_op==INSTR));
assign net_reg_write_cmd     = (net_ID_match && (net_packet_i.net_op==REG));
assign net_bar_write_cmd     = (net_ID_match && (net_packet_i.net_op==BAR));
assign net_PC_write_cmd_IDLE = (net_PC_write_cmd && (state_r==IDLE));

// Barrier final result, in the barrier mask, 1 means not mask and 0 means mask
assign barrier_o = barrier_mask_r & barrier_r;

// The instruction write is just for network
assign imem_wen  = net_imem_write_cmd;

// Register write could be from network or the controller
assign rf_wen    = (net_reg_write_cmd || (memTOwrite_s_o.op_writes_rf_c_memTOwrite && ~stall));

// Selection between network and core for instruction address
assign imem_addr = (net_imem_write_cmd) ? net_packet_i.net_addr
                                       : PC_n;

// Selection between network and address included in the instruction which is exeuted
// Address for Reg. File is shorter than address of Ins. memory in network data
// Since network can write into immediate registers, the address is wider
// but for the destination register in an instruction the extra bits must be zero
assign rd_addr = (net_reg_write_cmd)
                 ? (net_packet_i.net_addr [0+:($bits(instruction.rs_imm))])
                 : ({{($bits(instruction.rs_imm)-$bits(instruction.rd)){1'b0}}
                    ,{memTOwrite_s_o.instruction_memTOwrite.rd}});
					
assign rd_read_addr = (net_reg_write_cmd)
                 ? (net_packet_i.net_addr [0+:($bits(instruction.rs_imm))])
                 : ({{($bits(instruction.rs_imm)-$bits(instruction.rd)){1'b0}}
                    ,{fetchTOdecode_s_o.instruction_fetchTOdecode.rd}});

// Instructions are shorter than 32 bits of network data
assign net_instruction = net_packet_i.net_data [0+:($bits(instruction))];

// barrier_mask_n, which stores the mask for barrier signal
always_comb
  // Change PC packet
  if (net_bar_write_cmd && (state_r != ERR))
    barrier_mask_n = net_packet_i.net_data [0+:mask_length_gp];
  else
    barrier_mask_n = barrier_mask_r;

assign barrier_n = net_PC_write_cmd_IDLE
                   ? net_packet_i.net_data[0+:mask_length_gp]
                   : ((memTOwrite_s_o.instruction_memTOwrite ==?`kBAR) & ~stall)
                     ? memTOwrite_s_o.alu_result_memTOwrite  [0+:mask_length_gp]
                     : barrier_r;
// barrier_n signal, which contains the barrier value
// it can be set by PC write network command if in IDLE
// or by an an BAR instruction that is committing
// exception_n signal, which indicates an exception
// We cannot determine next state as ERR in WORK state, since the instruction
// must be completed, WORK state means start of any operation and in memory
// instructions which could take some cycles, it could mean wait for the
// response of the memory to aknowledge the command. So we signal that we recieved
// a wrong package, but do not stop the execution. Afterwards the exception_r
// register is used to avoid extra fetch after this instruction.
always_comb
  if ((state_r==ERR) || (net_PC_write_cmd && (state_r!=IDLE)))
    exception_n = 1'b1;
  else
    exception_n = exception_o;

endmodule
