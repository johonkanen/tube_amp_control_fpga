library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fpga_interconnect_pkg.all;

entity top is
    port (
        main_clock       : in std_logic;
        pll_inst1_LOCKED : in std_logic;
        uart_rx          : in std_logic;
        uart_tx          : out std_logic
    );
end entity top;

architecture rtl of top is

    signal bus_to_communications   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;

    signal bus_out : fpga_interconnect_record := init_fpga_interconnect;

    signal test_data : unsigned(15 downto 0) := (others => '0');

begin

------------------------------------------------
    board_test_main : process(main_clock)
    begin
        if rising_edge(main_clock) then

            init_bus(bus_out);
            connect_read_only_data_to_address(bus_from_communications, bus_out, 1, 44252);
            if data_is_requested_from_address(bus_from_communications, 2) then
                test_data <= test_data + 1;
                write_data_to_address(bus_out, 0, std_logic_vector(test_data));
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
        port map(
            clock => main_clock                              ,
            uart_rx                 => uart_rx               ,
            uart_tx                 => uart_tx               ,
            bus_to_communications   => bus_to_communications ,
            bus_from_communications => bus_from_communications
        );

end rtl;
