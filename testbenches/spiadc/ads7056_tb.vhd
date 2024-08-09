LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.clock_divider_pkg.all;

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

    signal self : clock_divider_record := init_clock_divider;

    signal clock_counter    : natural range 0 to 7;
    signal number_of_clocks : natural range 0 to 63;

    signal ad_clock : std_logic := '1';

    type ads_7056_states is (wait_for_init, initializing, ready);
    signal state : ads_7056_states := wait_for_init;
    signal conversion_requested : boolean := false;

    type ads_7056_record is record
        clock_divider : clock_divider_record;
        state : ads_7056_states;
        conversion_requested : boolean;
    end record;

    constant init_ads_7056 : ads_7056_record := (init_clock_divider,wait_for_init, false);

begin

    clock_counter <= self.clock_counter;
    /* state <= self.state; */

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

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            ad_clock <= get_clock_from_divider(self);
            create_clock_divider(self);

            conversion_requested <= false;
            CASE state is 
                WHEN wait_for_init =>
                    if conversion_requested then
                        request_number_of_clock_pulses(self, 24);
                        state <= initializing;
                    end if;
                WHEN initializing  =>
                    if clock_divider_is_ready(self) then
                        state <= ready;
                    end if;
                WHEN ready =>
                    if conversion_requested then
                        request_number_of_clock_pulses(self, 18);
                    end if;
            end CASE;

            CASE simulation_counter is
                WHEN 15 => conversion_requested <= true;
                WHEN 200 => conversion_requested <= true;
                WHEN others => --do nothing
            end CASE; --simulation_counter

            if simulation_counter = 15 then
                conversion_requested <= true;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
