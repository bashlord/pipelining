//This file defines the structs and parameters used in the core

`ifndef _definitions_v_
`define _definitions_v_

// Instruction map
`define kADDU		16'b00000_?????_??????		// 0
`define kSUBU		16'b00001_?????_??????		// 1
`define kSLLV		16'b00010_?????_?????? 		// 2
`define kSRAV		16'b00011_?????_??????		// 3
`define kSRLV		16'b00100_?????_??????		// 4
`define kAND   		16'b00101_?????_??????		// 5
`define kOR    		16'b00110_?????_??????		// 6
`define kNOR   		16'b00111_?????_??????		// 7

`define kSLT   		16'b01000_?????_??????		// 8
`define kSLTU  		16'b01001_?????_??????		// 9

`define kMOV   		16'b01010_?????_??????		// 10

`define kSLLR    	16'b01011_?????_??????		// 11 

// `define kBAR   16'b01100_10000_??????
`define kBAR   		16'b01100_100??_??????		// 12 
`define kWAIT  		16'b01100_00000_000000		// 1
`define kXOR			16'b01101_?????_??????		// 13 
`define kROR			16'b01110_?????_??????		// 14 
// 15
`define kBEQZ  		16'b10000_?????_??????		// 16
`define kBNEQZ 	16'b10001_?????_??????		// 17
`define kBGTZ  		16'b10010_?????_??????		// 18
`define kBLTZ  		16'b10011_?????_??????		// 19
// 20
// 21
// 22
`define kJALR  		16'b10111_?????_??????		// 23

`define kLW    		16'b11000_?????_??????		// 24
`define kLBU   		16'b11001_?????_??????		// 25
`define kSW    		16'b11010_?????_??????		// 26
`define kSB    			16'b11011_?????_??????		// 27

`define kNOP		16'b11111_?????_??????
// 28
// 29
// 30
// 31

//---- Controller states ----//
// WORK state means start of any operation or wait for the 
// response of memory in acknowledge of the command
// MEM_WAIT state means the memory acknowledged the command, 
// but it did not send the valid signal and core is waiting for it
typedef enum logic [1:0] {
IDLE = 2'b00,
RUN  = 2'b01,    
ERR  = 2'b11
} state_e;


// size of rd and rs field in the instruction, 
// which is log of register file size as well
parameter rd_size_gp             = 5;
parameter rs_imm_size_gp         = 6; 
parameter instruction_size_gp    = 16;
// instruction memory and data memory address widths, 
// which is log of their sizes as well
parameter imem_addr_width_gp     = 10; 
parameter data_mem_addr_width_gp = 12;  

// Length of ID part in network packet
parameter ID_length_gp = 10;

// Length of barrier output, which is equal to its mask size 
parameter mask_length_gp = 3;

// a struct for instructions
typedef struct packed{
        logic [4:0]  opcode;
        logic [rd_size_gp-1:0] rd;
        logic [rs_imm_size_gp-1:0] rs_imm;
        } instruction_s;

// Types of network packets
typedef enum logic [2:0] {
// Nothing
NULL  = 3'b000,
// Instruction for instruction memory
INSTR = 3'b001,
// Value for a register
REG   = 3'b010,
// Change PC 
PC    = 3'b011,
// Barrier mask
BAR   = 3'b100
} net_op_e;

// a struct for network packets
typedef struct packed{
        logic [ID_length_gp-1:0] ID; // 31..22  +32
        net_op_e     net_op;         // 21..19  +32
        logic [5:0]  reserved;       // 18..14  +32
        logic [13:0] net_addr;       // 13..0   +32 // later we may steal more bits for net_op
        logic [31:0] net_data;       // 32..0
        } net_packet_s;

// a struct for the packets froms core to memory
typedef struct packed{
        logic [31:0] write_data;
        logic valid;
        logic wen;
        logic byte_not_word;
        // in response to data memory
        logic yumi;    
        } mem_in_s;

// a struct for the packets from data memory to core
typedef struct packed{
        logic [31:0] read_data;
        logic valid;
        // in response to core
        logic yumi;    
        } mem_out_s;

// a struct for debugging the core during timing simulation
typedef struct packed {
        logic [imem_addr_width_gp-1:0] PC_r_f;
        logic [$bits(instruction_s)-1:0] instruction_i_f;
        logic [1:0] state_r_f;
        logic [mask_length_gp-1:0] barrier_mask_r_f;
        logic [mask_length_gp-1:0] barrier_r_f;
} debug_s;

typedef struct packed{
	instruction_s instruction_fetchTOdecode;
	logic [imem_addr_width_gp-1:0] PC_r_fetchTOdecode;
} fetchTOdecode_s;

typedef struct packed{
	instruction_s instruction_decodeTOexecute;
	logic [imem_addr_width_gp-1:0] PC_r_decodeTOexecute;
	logic [31:0] rs_val_decodeTOexecute;
	logic [31:0] rd_val_decodeTOexecute;
	logic is_store_op_c_decodeTOexecute;
	logic is_mem_op_c_decodeTOexecute;
	logic is_byte_op_c_decodeTOexecute;
	logic is_load_op_c_decodeTOexecute;
	logic op_writes_rf_c_decodeTOexecute;

} decodeTOexecute_s;

typedef struct packed{
	instruction_s instruction_executeTOmem;
	logic [imem_addr_width_gp-1:0] PC_r_executeTOmem;
	logic [31:0] rs_val_or_zero_executeTOmem;
	logic [31:0] alu_result_executeTOmem;
	logic is_store_op_c_executeTOmem;
	logic is_mem_op_c_executeTOmem;
	logic is_byte_op_c_executeTOmem;
	logic is_load_op_c_executeTOmem;
	logic op_writes_rf_c_executeTOmem;

} executeTOmem_s;

typedef struct packed{
	instruction_s instruction_memTOwrite;
	logic [imem_addr_width_gp-1:0] PC_r_memTOwrite;
	logic [31:0] rf_wd_memTOwrite;
	logic [31:0] alu_result_memTOwrite;
	logic op_writes_rf_c_memTOwrite;
	logic is_load_op_c_memTOwrite;

} memTOwrite_s;

`endif