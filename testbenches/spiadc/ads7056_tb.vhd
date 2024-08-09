LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity ads7056_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of ads7056_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 5000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal clock_counter : natural range 0 to 7;
    signal number_of_clocks : natural range 0 to 63 := 8;

    signal ad_clock : std_logic := '1';
    signal requested_number_of_clock_pulses : natural := 7;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        procedure request_number_of_clock_pulses
        (
            number_of_clock_pulses : natural
        ) is
        begin
            requested_number_of_clock_pulses <= number_of_clock_pulses;
            number_of_clocks <= 0;
        end request_number_of_clock_pulses;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            if number_of_clocks <= requested_number_of_clock_pulses then
                if clock_counter < 3 then
                    clock_counter <= clock_counter + 1;
                else
                    number_of_clocks <= number_of_clocks + 1;
                    clock_counter <= 0;
                end if;
                if clock_counter < 2 then
                    ad_clock <= '0';
                else 
                    ad_clock <= '1';
                end if;
            end if;


            if simulation_counter = 15 then
                request_number_of_clock_pulses(7);
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
