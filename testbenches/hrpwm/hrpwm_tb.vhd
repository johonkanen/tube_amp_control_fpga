LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.hrpwm_pkg.all;

entity hrpwm_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of hrpwm_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 5000;
    
    signal simulator_clock    : std_logic := '0';
    signal fast_clock         : std_logic := '1';
    signal simulation_counter : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal serialiser_input : std_logic_vector(3 downto 0);
    signal load_serialiser : boolean := false;
    signal pwm_counter : natural range 0 to 127 := 0;
    signal duty : natural range 0 to 511 := 63;

    signal serialiser_shift_register : std_logic_vector(3 downto 0) := (others => '1');
    signal serializer_counter : unsigned(1 downto 0) := to_unsigned(3,2);

    signal pwm : std_logic;

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
    fast_clock <= not fast_clock after clock_period/16.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            if pwm_counter < 127 then
                pwm_counter <= pwm_counter + 1;
            else
                pwm_counter <= 0;
            end if;

            if simulation_counter mod 128 = 0 then
                duty <= duty + 1;
            end if;

            serialiser_input <= hrpwm(counter => pwm_counter, duty => duty);


        end if; -- rising_edge
    end process stimulus;	

    serialiser : process(fast_clock)
    begin
        if rising_edge(fast_clock) then
            serialiser_shift_register <= serialiser_shift_register(2 downto 0) & serialiser_input(3);
            if serializer_counter = 3 then
                serialiser_shift_register <= serialiser_input;
            end if;
            serializer_counter <= serializer_counter + 1;
        end if; --rising_edge
    end process ;	
    pwm <= serialiser_shift_register(3);
------------------------------------------------------------------------
end vunit_simulation;
