-- ############################################################################
--
-- ############################################################################
library ieee;
use ieee.std_logic_1164.all;
-- ############################################################################
entity modulo_const is
    generic
    (
        g_divisor_1 : integer := 160; -- entre 128 y 1022
        g_divisor_2 : integer := 254;-- entre 128 y 1022
        g_divisor_3 : integer := 1022-- entre 128 y 1022
    );
    port
    (
        a_in  : in std_logic_vector(9 downto 0); -- 0–1023
        r_out_1 : out std_logic_vector(9 downto 0);
        r_out_2 : out std_logic_vector(9 downto 0);
        r_out_3 : out std_logic_vector(9 downto 0)
    );
end entity;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- ############################################################################
architecture rtl of modulo_const is

    -- Funcion 
    function mod10bits(
        a_in    : unsigned(9 downto 0);
        divisor : unsigned(9 downto 0)
    ) return std_logic_vector is

        variable v_a_in : unsigned(9 downto 0);

    begin
        -- Se usa unsigned para poder sumar
        v_a_in := a_in;

        if v_a_in >= divisor then
            v_a_in := v_a_in - divisor;
        end if;
        if v_a_in >= divisor then
            v_a_in := v_a_in - divisor;
        end if;
        if v_a_in >= divisor then
            v_a_in := v_a_in - divisor;
        end if;
        if v_a_in >= divisor then
            v_a_in := v_a_in - divisor;
        end if;
        if v_a_in >= divisor then
            v_a_in := v_a_in - divisor;
        end if;
        if v_a_in >= divisor then
            v_a_in := v_a_in - divisor;
        end if;
        if v_a_in >= divisor then
            v_a_in := v_a_in - divisor;
        end if;
        if v_a_in >= divisor then
            v_a_in := v_a_in - divisor;
        end if;

        return std_logic_vector(v_a_in);
    end function;
    -- Fin funcion

begin

    r_out_1 <= mod10bits(unsigned(a_in), to_unsigned(g_divisor_1, 10));
    r_out_2 <= mod10bits(unsigned(a_in), to_unsigned(g_divisor_2, 10));
    r_out_3 <= mod10bits(unsigned(a_in), to_unsigned(g_divisor_3, 10));

end architecture rtl;
-- ############################################################################