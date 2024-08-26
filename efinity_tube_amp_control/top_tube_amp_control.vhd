library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.ads7056_pkg.all;
    use work.hrpwm_pkg.all;

entity top is
    port (
        main_clock       : in std_logic;
        pll_inst1_LOCKED : in std_logic;
        uart_rx          : in std_logic;
        uart_tx          : out std_logic;

        anode_gate_hi  : out std_logic;
        anode_gate_lo  : out std_logic;
        preamp_gate_hi : out std_logic;
        preamp_gate_lo : out std_logic;

        -- iic adc
        adc_scl     : out std_logic;
        adc_sda_IN  : in std_logic;
        adc_sda_OUT : out std_logic;
        adc_sda_OE  : out std_logic;
        -- iic dac
        dac_scl     : out std_logic;
        dac_sda_IN  : in std_logic;
        dac_sda_OUT : out std_logic;
        dac_sda_OE  : out std_logic;
        -- muxed adc
        admux    : out std_logic_vector(2 downto 0);
        ad_cs    : out std_logic;
        ad_clock : out std_logic;
        ad_data  : in std_logic

        --
    );
end entity top;

architecture rtl of top is

    package fpga_interconnect_pkg is new work.fpga_interconnect_generic_pkg generic map(16,16);
    use fpga_interconnect_pkg.all;

    signal bus_to_communications   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;

    signal bus_out : fpga_interconnect_record := init_fpga_interconnect;

    signal duty_ratio       : natural range 0 to 8191    := 2000;
    signal duty             : natural range 0 to 8191    := 63;
    signal pwm_counter      : natural range 0 to 2**13   := 0;

    signal anode_pwm : std_logic_vector(1 downto 0) := "00";

    signal deadtime_counter : natural range 0 to 255 := 160;

    signal ads7056 : ads7056_record := init_ads7056;
    signal mux_selection : std_logic_vector(15 downto 0) := (others => '0');
    signal sample_delay : natural range 0 to 1023 := 0;

begin

    adc_sda_OE  <= '0';
    adc_sda_OUT <= '0';
    adc_scl     <= '1';

    dac_sda_OE  <= '0';
    dac_sda_OUT <= '1';
    dac_scl     <= '1';

    admux    <= mux_selection(2 downto 0);

------------------------------------------------
    board_test_main : process(main_clock)
    begin
        if rising_edge(main_clock) then

            create_ads7056_driver(ads7056                   ,
                                  cs            => ad_cs    ,
                                  spi_clock_out => ad_clock ,
                                  serial_io     => ad_data);

            init_bus(bus_out);
            connect_read_only_data_to_address(bus_from_communications, bus_out, 1, 44252);
            connect_read_only_data_to_address(bus_from_communications, bus_out, 2, get_converted_measurement(ads7056));
            connect_data_to_address(bus_from_communications, bus_out, 3, mux_selection);
            connect_data_to_address(bus_from_communications, bus_out, 12, duty_ratio);
            connect_data_to_address(bus_from_communications, bus_out, 13, sample_delay);

            -----
            if pwm_counter < 4999 then
                pwm_counter <= pwm_counter + 1;
            else
                pwm_counter <= 0;
            end if;

            if pwm_counter = duty/2-100 + sample_delay then
                request_conversion(ads7056);
            end if;

            -----
            if duty_ratio > integer(0.5*5000.0) then
                duty <= integer(0.5*5000.0);
            else
                duty <= duty_ratio;
            end if;

            -----
            if duty < pwm_counter then
                anode_pwm(0) <= '1';
            else
                anode_pwm(0) <= '0';
            end if;
            anode_pwm(1) <= anode_pwm(0);
            if anode_pwm(1) /= anode_pwm(0) then
                deadtime_counter <= 0;
            end if;

            if deadtime_counter < 40 then
                deadtime_counter <= deadtime_counter + 1;
                anode_gate_hi  <= '0';
                anode_gate_lo  <= '0';
                preamp_gate_hi <= '0';
                preamp_gate_lo <= '0';
            else
                anode_gate_hi  <= anode_pwm(1);
                anode_gate_lo  <= not anode_pwm(1);

                preamp_gate_hi <= anode_pwm(1);
                preamp_gate_lo <= not anode_pwm(1);
            end if;

            if duty_ratio < 300 then
                anode_gate_hi  <= '0';
                anode_gate_lo  <= '0';
                preamp_gate_hi <= '0';
                preamp_gate_lo <= '0';
            end if;

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
            bus_from_communications => bus_from_communications);

end rtl;
