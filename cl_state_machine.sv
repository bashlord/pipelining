`include "definitions.sv"

module cl_state_machine(input  instruction_s instruction_i
                       ,input  state_e       state_i
                       ,input                exception_i
                       ,input                net_PC_write_cmd_IDLE_i
                       ,input                stall_i
                       ,output state_e       state_o
                       );
always_comb	
  if (~stall_i && exception_i)
    state_o = ERR;
  else unique case (state_i)

    RUN:
      if(instruction_i==?`kWAIT)
        state_o = IDLE;
	  else
	    state_o = RUN;
	    
	  IDLE:
      if (net_PC_write_cmd_IDLE_i)   
        state_o = RUN;
	  else
	    state_o = IDLE;
    default:
      state_o = ERR;
  endcase
endmodule
