library verilog;
use verilog.vl_types.all;
library work;
entity executeTOmem is
    port(
        clk             : in     vl_logic;
        stall           : in     vl_logic;
        executeTOmem_s_i: in     work.\executeTOmem_sv_unit\.\executeTOmem_s\;
        executeTOmem_s_o: out    work.\executeTOmem_sv_unit\.\executeTOmem_s\
    );
end executeTOmem;
