library verilog;
use verilog.vl_types.all;
library work;
entity memTOwrite is
    port(
        clk             : in     vl_logic;
        stall           : in     vl_logic;
        memTOwrite_s_i  : in     work.\memoryTOwrite_sv_unit\.\memTOwrite_s\;
        memTOwrite_s_o  : out    work.\memoryTOwrite_sv_unit\.\memTOwrite_s\
    );
end memTOwrite;
