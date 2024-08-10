library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.clock_divider_pkg.all;

package ads7056_pkg is

    signal ad_clock : std_logic := '1';

    type ads7056_states is (wait_for_init, initializing, ready, converting);
    signal state : ads7056_states := wait_for_init;

    type ads7056_record is record
        clock_divider : clock_divider_record;
        state : ads7056_states;
        conversion_requested : boolean;
    end record;

    constant init_ads7056 : ads7056_record := (init_clock_divider,wait_for_init, false);

-------------------------------------------------------------------
    procedure create_ads7056_driver (
        signal self : inout ads7056_record;
        signal spi_clock_out : out std_logic);

-------------------------------------------------------------------
    procedure request_conversion (
        signal self : inout ads7056_record);

end package ads7056_pkg;
-------------------------------------------------------------------

package body ads7056_pkg is

-------------------------------------------------------------------
    procedure create_ads7056_driver
    (
        signal self : inout ads7056_record;
        signal spi_clock_out : out std_logic
    ) is
    begin
        spi_clock_out <= get_clock_from_divider(self.clock_divider);
        create_clock_divider(self.clock_divider);

        self.conversion_requested <= false;
        CASE self.state is 
            WHEN wait_for_init =>
                if self.conversion_requested then
                    request_number_of_clock_pulses(self.clock_divider, 24);
                    self.state <= initializing;
                end if;
            WHEN initializing  =>
                if clock_divider_is_ready(self.clock_divider) then
                    self.state <= ready;
                end if;
            WHEN ready =>
                if self.conversion_requested then
                    request_number_of_clock_pulses(self.clock_divider, 18);
                    self.state <= converting;
                end if;
            WHEN converting =>
                if clock_divider_is_ready(self.clock_divider) then
                    self.state <= ready;
                end if;
        end CASE;
        
    end create_ads7056_driver;

-------------------------------------------------------------------
    procedure request_conversion
    (
        signal self : inout ads7056_record
    ) is
    begin
        self.conversion_requested <= true;
    end request_conversion;

-------------------------------------------------------------------
    function conversion_is_ready
    (
        self : ads7056_record
    )
    return boolean
    is
    begin

        return clock_divider_is_ready(self.clock_divider);
        
    end conversion_is_ready;

end package body ads7056_pkg;
-------------------------------------------------------------------

LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.clock_divider_pkg.all;
    use work.ads7056_pkg.all;

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

    signal clock_counter    : natural range 0 to 7;
    signal number_of_clocks : natural range 0 to 63;

    signal self : ads7056_record := init_ads7056;

begin

    clock_counter <= self.clock_divider.clock_counter;
    state <= self.state;
    number_of_clocks <= self.clock_divider.number_of_clocks;

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

            create_ads7056_driver(self, ad_clock);

            CASE simulation_counter is
                WHEN 15  => request_conversion(self);
                WHEN 200 => request_conversion(self);
                WHEN others => --do nothing
            end CASE; --simulation_counter

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
