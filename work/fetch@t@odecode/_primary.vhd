library verilog;
use verilog.vl_types.all;
library work;
entity fetchTOdecode is
    port(
        clk             : in     vl_logic;
        stall           : in     vl_logic;
        flush           : in     vl_logic;
        itr             : in     vl_logic;
        IW              : in     vl_logic;
        fetchTOdecode_s_i: in     work.\fetchTOdecode_sv_unit\.\fetchTOdecode_s\;
        fetchTOdecode_s_o: out    work.\fetchTOdecode_sv_unit\.\fetchTOdecode_s\
    );
end fetchTOdecode;
