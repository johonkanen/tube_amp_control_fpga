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
