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
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.hrpwm_pkg.all;

entity top is
    port (
        main_clock       : in std_logic;
        pll_inst1_LOCKED : in std_logic;
        uart_rx          : in std_logic;
        uart_tx          : out std_logic;

        power_connector_io_0            : out std_logic;
        power_connector_io_1            : out std_logic;
        power_connector_io_2            : out std_logic;
        power_connector_io_3            : out std_logic;
        power_connector_io_15_downto_4  : out std_logic_vector(15 downto 4);
        power_connector_io_16           : out std_logic;
        power_connector_io_23_downto_17 : out std_logic_vector(23 downto 17);
        gpio_inst28                     : out std_logic_vector(3 downto 0);

        -- iic adc
        adc_scl     : out std_logic;
        adc_sda_IN  : in std_logic;
        adc_sda_OUT : out std_logic;
        adc_sda_OE  : out std_logic;
        -- iic dac
        dac_scl     : out std_logic;
        dac_sda_IN  : in std_logic;
        dac_sda_OUT : out std_logic;
        dac_sda_OE  : out std_logic
        --
    );
end entity top;

architecture rtl of top is

    package fpga_interconnect_pkg is new work.fpga_interconnect_generic_pkg generic map(16,16);
    use fpga_interconnect_pkg.all;

    signal bus_to_communications   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;

    signal bus_out : fpga_interconnect_record := init_fpga_interconnect;

    signal test_data : unsigned(15 downto 0) := (others => '0');

    signal power_connector_io1 : std_logic_vector(15 downto 0);
    signal power_connector_io2 : std_logic_vector(15 downto 0);

    signal counter_for_10us : natural range 0 to 2**16-1 := 0;
    signal duty_ratio :       natural range 0 to 8191 := 63;
    signal pwm_counter :      natural range 0 to 1023 := 0;

begin

    adc_sda_OE  <= '0';
    adc_sda_OUT <= power_connector_io1(0);
    adc_scl     <= '1';

    dac_sda_OE  <= '1';
    dac_sda_OUT <= power_connector_io1(0);
    dac_scl     <= power_connector_io1(0);

    power_connector_io_0            <= power_connector_io1(0);
    power_connector_io_1            <= power_connector_io1(1);
    power_connector_io_2            <= power_connector_io1(2);
    power_connector_io_3            <= power_connector_io1(3);
    power_connector_io_15_downto_4  <= power_connector_io1(15 downto 4);
    power_connector_io_16           <= power_connector_io2(0);
    power_connector_io_23_downto_17 <= power_connector_io2(7 downto 1);

------------------------------------------------
    board_test_main : process(main_clock)
        ----
        function "+"
        (
            left : std_logic_vector; right : integer
        )
        return std_logic_vector
        is
        begin
            return std_logic_vector(unsigned(left) + right);
        end "+";
        ----
    begin
        if rising_edge(main_clock) then

            init_bus(bus_out);
            connect_read_only_data_to_address(bus_from_communications, bus_out, 1, 44252);
            connect_data_to_address(bus_from_communications, bus_out, 10, power_connector_io1);
            connect_data_to_address(bus_from_communications, bus_out, 11, power_connector_io2);
            connect_data_to_address(bus_from_communications, bus_out, 12, duty_ratio);

            if data_is_requested_from_address(bus_from_communications, 2) then
                test_data <= test_data + 1;
                write_data_to_address(bus_out, 0, std_logic_vector(test_data));
            end if;

            if write_is_requested_to_address(bus_from_communications, 2) then
                test_data <= to_unsigned(get_data(bus_from_communications),test_data'length);
            end if;


            /* if counter_for_10us < 1279 then */
            /*     counter_for_10us <= counter_for_10us + 1; */
            /* else */
            /*     counter_for_10us <= 0; */
            /* end if; */

            /* if counter_for_10us > 128 then */
            /*     power_connector_io1 <= (others => '0'); */
            /*     power_connector_io2 <= (others => '0'); */
            /* else */
            /*     power_connector_io1 <= (others => '1'); */
            /*     power_connector_io2 <= (others => '1'); */
            /* end if; */

            if pwm_counter < 1023 then
                pwm_counter <= pwm_counter + 1;
            else
                pwm_counter <= 0;
            end if;

            gpio_inst28 <= hrpwm(pwm_counter, duty_ratio);

        end if;
    end process;

------------------------------------------------
    combine_buses : process(main_clock)
    begin
        if rising_edge(main_clock) then
            bus_to_communications <= bus_out;
        end if; --rising_edge
    end process combine_buses;	

------------------------------------------------
    u_communications : entity work.fpga_communications
        generic map(fpga_interconnect_pkg => fpga_interconnect_pkg, g_clock_divider => 40)
        port map(
            clock => main_clock                              ,
            uart_rx                 => uart_rx               ,
            uart_tx                 => uart_tx               ,
            bus_to_communications   => bus_to_communications ,
            bus_from_communications => bus_from_communications
        );

end rtl;
