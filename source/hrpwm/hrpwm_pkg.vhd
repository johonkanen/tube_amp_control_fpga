library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package hrpwm_pkg is

    function hrpwm (
        counter : natural;
        duty : natural)
    return std_logic_vector;

end package hrpwm_pkg;

package body hrpwm_pkg is

    function hrpwm
    (
        counter : natural;
        duty : natural
    )
    return std_logic_vector
    is
        variable retval : std_logic_vector(3 downto 0);
        variable hrpwm_value : unsigned(15 downto 0);
    begin

        if duty/4 > counter then
            retval := "1111";
        else
            retval := "0000";
        end if;

        hrpwm_value := to_unsigned(duty,hrpwm_value'length);
        if duty/4 = counter then

            CASE to_integer(hrpwm_value(1 downto 0)) is
                WHEN 0 => retval := "0000";
                WHEN 1 => retval := "0001";
                WHEN 2 => retval := "0011";
                WHEN 3 => retval := "0111";
                WHEN others => retval := "0000";
            end CASE;
        end if;

        return retval;
        
    end hrpwm;

end package body hrpwm_pkg;
----------------------------
