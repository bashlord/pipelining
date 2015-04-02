library verilog;
use verilog.vl_types.all;
entity reg_file is
    generic(
        addr_width_p    : integer := 6;
        addr_width_q    : integer := 32
    );
    port(
        clk             : in     vl_logic;
        wen_i           : in     vl_logic;
        write_i         : in     vl_logic_vector;
        wd_i            : in     vl_logic_vector;
        read0_i         : in     vl_logic_vector;
        read1_i         : in     vl_logic_vector;
        read0_o         : out    vl_logic_vector;
        read1_o         : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of addr_width_p : constant is 1;
    attribute mti_svvh_generic_type of addr_width_q : constant is 1;
end reg_file;
