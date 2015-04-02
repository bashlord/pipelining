library verilog;
use verilog.vl_types.all;
library work;
entity hazard_detection is
    port(
        is_load_op_o    : in     vl_logic;
        is_store_op_o   : in     vl_logic;
        fetchTOdecode_s_o: in     work.hazard_detection_sv_unit.\fetchTOdecode_s\;
        decodeTOexecute_s_o: in     work.hazard_detection_sv_unit.\decodeTOexecute_s\;
        executeTOmem_s_o: in     work.hazard_detection_sv_unit.\executeTOmem_s\;
        memTOwrite_s_o  : in     work.hazard_detection_sv_unit.\memTOwrite_s\;
        itr             : out    vl_logic;
        f_0             : out    vl_logic_vector(1 downto 0);
        f_1             : out    vl_logic_vector(1 downto 0);
        f_2             : out    vl_logic_vector(1 downto 0)
    );
end hazard_detection;
