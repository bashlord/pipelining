`include "definitions.sv"

//---- Controller ----//
module cl_decode (input instruction_s instruction_i

                 ,output logic is_load_op_o
                 ,output logic op_writes_rf_o
                 ,output logic is_store_op_o
                 ,output logic is_mem_op_o
                 ,output logic is_byte_op_o
                 );


//controller that decides if instruction gets data from memory or register file 
always_comb
  unique casez (instruction_i)
    `kLW,`kLBU:
      is_load_op_o = 1'b1;
        
    default:
      is_load_op_o = 1'b0;
  endcase


//gives a flag deciding if a write to a register file is necessary
always_comb

  unique casez (instruction_i)
    `kADDU, `kSUBU, `kSLLV, `kSRAV, `kSRLV,
    `kAND,  `kOR,   `kNOR,  `kSLT,  `kSLTU, 
    `kMOV,  `kSLLR, `kJALR, `kLW,   `kLBU,
	 `kXOR, 	`kROR:
      op_writes_rf_o = 1'b1; 
    
    default:
      op_writes_rf_o = 1'b0;
  endcase
  
// memory flag that checks to see if the instruction uses memory 
always_comb  
     
  unique casez (instruction_i)
    `kLW, `kLBU, `kSW, `kSB:
      is_mem_op_o = 1'b1;
    
    default:
      is_mem_op_o = 1'b0;
      
  endcase



//checks to see if the instruction is a store
always_comb       
  unique casez (instruction_i)
    `kSW, `kSB:
      is_store_op_o = 1'b1;
    
    default:
      is_store_op_o = 1'b0;
      
  endcase


//checks to see what sort of data is used in the instruction
always_comb
  unique casez (instruction_i)
    `kLBU,`kSB:
      is_byte_op_o = 1'b1;
       
    default: 
      is_byte_op_o = 1'b0;
  endcase

endmodule

