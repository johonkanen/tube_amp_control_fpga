library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package clock_divider_pkg is

    type clock_divider_record is record
        ad_clock : std_logic;
        clock_counter    : natural range 0 to 7;
        number_of_clocks : natural range 0 to 63;
        requested_number_of_clock_pulses : natural;
    end record;

    constant init_clock_divider : clock_divider_record := ('1',0,8,7);

    procedure request_number_of_clock_pulses (
        signal self : inout clock_divider_record;
        number_of_clock_pulses : natural);

end package clock_divider_pkg;

package body clock_divider_pkg is

    procedure request_number_of_clock_pulses
    (
        signal self : inout clock_divider_record;
        number_of_clock_pulses : natural
    ) is
    begin
        self.requested_number_of_clock_pulses <= number_of_clock_pulses;
        self.number_of_clocks <= 0;
    end request_number_of_clock_pulses;

end package body clock_divider_pkg;
--
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

begin

    clock_counter <= self.clock_counter;
    ad_clock      <= self.ad_clock;

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

            if self.number_of_clocks <= self.requested_number_of_clock_pulses then
                if self.clock_counter < 3 then
                    self.clock_counter <= self.clock_counter + 1;
                else
                    self.number_of_clocks <= self.number_of_clocks + 1;
                    self.clock_counter <= 0;
                end if;
                if self.clock_counter < 2 then
                    self.ad_clock <= '0';
                else 
                    self.ad_clock <= '1';
                end if;
            end if;

            if simulation_counter = 15 then
                request_number_of_clock_pulses(self,7);
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
