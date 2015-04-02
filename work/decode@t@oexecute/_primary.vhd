library verilog;
use verilog.vl_types.all;
library work;
entity decodeTOexecute is
    port(
        clk             : in     vl_logic;
        stall           : in     vl_logic;
        flush           : in     vl_logic;
        itr             : in     vl_logic;
        decodeTOexecute_s_i: in     work.\decodeTOexecute_sv_unit\.\decodeTOexecute_s\;
        decodeTOexecute_s_o: out    work.\decodeTOexecute_sv_unit\.\decodeTOexecute_s\
    );
end decodeTOexecute;
