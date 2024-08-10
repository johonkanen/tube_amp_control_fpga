library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.clock_divider_pkg.all;

package ads7056_pkg is

    signal ad_clock : std_logic := '1';

    type ads7056_states is (wait_for_init, initializing, ready, converting);
    signal state : ads7056_states := wait_for_init;

    type ads7056_record is record
        clock_divider        : clock_divider_record;
        data_capture_counter : clock_divider_record;
        data_capture_delay   : natural range 0 to 7;
        state                : ads7056_states;
        conversion_requested : boolean;
        ad_conversion        : std_logic_vector(17 downto 0);
    end record;

    constant init_ads7056 : ads7056_record := (init_clock_divider,init_clock_divider,4,wait_for_init, false, (others => '0'));

-------------------------------------------------------------------
    procedure create_ads7056_driver (
        signal self          : inout ads7056_record;
        serial_io            : in std_logic;
        signal cs            : out std_logic;
        signal spi_clock_out : out std_logic);

-------------------------------------------------------------------
    procedure request_conversion (
        signal self : inout ads7056_record);

-------------------------------------------------------------------
    function ad_conversion_is_ready ( self : ads7056_record)
        return boolean;

-------------------------------------------------------------------
    function get_converted_measurement ( self : ads7056_record)
        return std_logic_vector;
-------------------------------------------------------------------

end package ads7056_pkg;
-------------------------------------------------------------------

package body ads7056_pkg is

-------------------------------------------------------------------
    procedure create_ads7056_driver
    (
        signal self          : inout ads7056_record;
        serial_io            : in std_logic;
        signal cs            : out std_logic;
        signal spi_clock_out : out std_logic
    ) is
    begin
        spi_clock_out <= get_clock_from_divider(self.clock_divider);
        create_clock_divider(self.clock_divider);
        create_clock_divider(self.data_capture_counter);

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
                    self.data_capture_delay <= 3;
                    request_number_of_clock_pulses(self.clock_divider, 18);
                    self.state <= converting;
                end if;
            WHEN converting =>
                if clock_divider_is_ready(self.data_capture_counter) then
                    self.state <= ready;
                end if;
        end CASE;

        if self.data_capture_delay < 4 then
            self.data_capture_delay <= self.data_capture_delay + 1;
        end if;

        if self.data_capture_delay = 3 then
            request_number_of_clock_pulses(self.data_capture_counter, 18);
        end if;

        if self.conversion_requested then
            cs <= '0';
        end if;

        if clock_divider_is_ready(self.clock_divider) then
            cs <= '1';
        end if;

        if get_clock_counter(self.data_capture_counter) = 2 then
            self.ad_conversion <= self.ad_conversion(self.ad_conversion'left-1 downto 0) & serial_io;
        end if;

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
    function ad_conversion_is_ready
    (
        self : ads7056_record
    )
    return boolean
    is
    begin

        return clock_divider_is_ready(self.data_capture_counter);
        
    end ad_conversion_is_ready;
-------------------------------------------------------------------
    function get_converted_measurement
    (
        self : ads7056_record
    )
    return std_logic_vector
    is
    begin
        return self.ad_conversion(15 downto 0);
        
    end get_converted_measurement;

end package body ads7056_pkg;
-------------------------------------------------------------------
