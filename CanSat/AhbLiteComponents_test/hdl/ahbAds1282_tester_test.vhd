LIBRARY common_test;
  USE common_test.testUtils.all;
library ieee;
  use ieee.math_real.all;

ARCHITECTURE test OF ahbAds1282_tester IS
                                                              -- indication text
  signal indicationString: string(1 to 20);
                                                              -- reset and clock
  constant clockFrequency: real := 100.0E6;
  constant clockPeriod: time := (1.0/clockFrequency) * 1 sec;
  signal clock_int: std_uLogic := '1';
  signal reset_int: std_uLogic;
                                                              -- sampling enable
  constant samplingPeriod: time := 20 us;
	--EMG modifs
  --constant enablePeriodNb: positive := 2*samplingPeriod / clockPeriod;
	constant enablePeriodNb: positive := 6*samplingPeriod / clockPeriod;
	----
  signal enable_int: std_uLogic := '0';
                                                         -- register definitions
  constant modulatorClockDividerRegisterId: natural := 0;
  constant spiClockDividerRegisterId: natural := 1;
  constant adcRegisterId: natural := 2;
  constant valueLowRegisterId: natural := 0;
  constant valueHighRegisterId: natural := 1;
  constant statusRegisterId: natural := 2;
                                                               -- AHB bus access
  signal registerAddress: natural;
  signal registerWData, registerWDataReg: integer;
  signal registerRData: integer;
  signal registerWrite: std_uLogic;
  signal registerRead: std_uLogic;
                                                               -- analog signals
  constant samplingFrequency: real := 10.0E3;
  constant sineFrequency: real := samplingFrequency/10.0;
  constant sinePeriod: time := 1 sec / sineFrequency;
  constant outAmplitude: real := 5.0;
  signal tReal: real := 0.0;
  signal aIn1, aIn2: real := 0.0;

BEGIN
  ------------------------------------------------------------------------------
                                                              -- reset and clock
  reset_int <= '1', '0' after 2*clockPeriod;
  hReset_n <= not(reset_int);

  clock_int <= not clock_int after clockPeriod/2;
  hClk <= transport clock_int after clockPeriod*9.0/10.0;

  ------------------------------------------------------------------------------
                                                              -- sampling enable
  buildEnable: process
  begin
		--EMG Test
    --for index in 1 to enablePeriodNb-1 loop
    --  wait until rising_edge(clock_int);
    --end loop;
		--enable_int <= '1';
		--wait until rising_edge(clock_int);
    --enable_int <= '0';
		for i in 1 to 5 loop
			for index in 1 to enablePeriodNb-1 loop
				wait until rising_edge(clock_int);
			end loop;
			enable_int <= '1';
			wait until rising_edge(clock_int);
			enable_int <= '0';
		end loop;
		enable_int <= '1';
		wait for 800 us;
		enable_int <= '0';
		----
  end process buildEnable;

  enable <= enable_int;

  ------------------------------------------------------------------------------
                                                                -- test sequence
  testSequence: process
  begin
    registerAddress <= 0;
    registerWData <= 0;
    registerWrite <= '0';
    registerRead <= '0';
    wait for 1 us;
                               -- write even value to spi clock divider register
    registerAddress <= spiClockDividerRegisterId;
    registerWData <= 4;
    wait until rising_edge(clock_int);
    registerWrite <= '1', '0' after clockPeriod;
    wait for 1 us;
                                -- write odd value to spi clock divider register
    registerAddress <= spiClockDividerRegisterId;
    registerWData <= 3;
    wait until rising_edge(clock_int);
    registerWrite <= '1', '0' after clockPeriod;
    wait for 1 us;
		
		--EMG Modifs
                          -- write odd value to modulator clock divider register
    registerAddress <= modulatorClockDividerRegisterId;
    --registerWData <= 3;
		registerWData <= 50;
    wait until rising_edge(clock_int);
    registerWrite <= '1', '0' after clockPeriod;
    wait for 1 us;
                         -- write even value to modulator clock divider register
    registerAddress <= modulatorClockDividerRegisterId;
		--registerWData <= 4;
		registerWData <= 3;
		----	
    wait until rising_edge(clock_int);
    registerWrite <= '1', '0' after clockPeriod;
    wait for 1 us;
		
                                                  -- write value to ADC register
    registerAddress <= adcRegisterId;
    registerWData <= 16#100# * 16#01# + 16#52#;
    wait until rising_edge(clock_int);
    registerWrite <= '1', '0' after clockPeriod;
    wait for 1 us;
                                                        -- select ADC value MSBs
    registerAddress <= valueHighRegisterId;
    wait until rising_edge(clock_int);
    registerRead <= '1', '0' after clockPeriod;
    wait for 1 us;
    ----------------------------------------------------------------------------
                                                               -- get ADC sample
    wait for 130 us - now;	
                                                              -- read ADC status
    registerAddress <= statusRegisterId;
    wait until rising_edge(clock_int);
    registerRead <= '1', '0' after clockPeriod/10;
    wait for clockPeriod;
                                                                -- read ADC LSBs
    registerAddress <= valueLowRegisterId;
    wait until rising_edge(clock_int);
    registerRead <= '1', '0' after clockPeriod/10;
    wait for 2*clockPeriod/10;
                                                                -- read ADC MSBs
    registerAddress <= valueHighRegisterId;
    wait until rising_edge(clock_int);
    registerRead <= '1', '0' after clockPeriod/10;
    wait for 100 ns;

		--EMG Modifs
		wait for 100 us;
		registerAddress <= 3;											--read ADC LSB current register
    wait until rising_edge(clock_int);
    registerRead <= '1', '0' after clockPeriod/10;
    wait for 100 ns;
		
		registerAddress <= 4;											--read ADC MSB current register
    wait until rising_edge(clock_int);
    registerRead <= '1', '0' after clockPeriod/10;
    wait for 100 ns;
		
		registerAddress <= 5;											-- read ADC LSB voltage register
    wait until rising_edge(clock_int);
    registerRead <= '1', '0' after clockPeriod/10;
    wait for 100 ns;
		
		registerAddress <= 6;											-- read ADC MSB voltage register
    wait until rising_edge(clock_int);
    registerRead <= '1', '0' after clockPeriod/10;
    wait for 100 ns;
		----
		
    wait;
  end process testSequence;

  ------------------------------------------------------------------------------
                                                                   -- bus access
                                                -- phase 1: address and controls
  busAccessPhase1: process
    variable writeAccess: boolean;
  begin
    hAddr <= (others => '-');
    hTrans <= transIdle;
    hSel <= '0';
    hWrite <= '0';
    registerWDataReg <= 0;
    wait on registerWrite, registerRead;
    writeAccess := false;
    if rising_edge(registerWrite) then
      writeAccess := true;
    end if;
    hAddr <= to_unsigned(registerAddress, hAddr'length);
    hTrans <= transNonSeq;
    hSel <= '1';
    if writeAccess then
      hWrite <= '1';
    end if;
    if writeAccess then
      registerWDataReg <= registerWData;
    end if;
    wait until rising_edge(clock_int);
  end process busAccessPhase1;
                                                                -- phase 2: data
  busAccessPhase2: process
  begin
    wait until rising_edge(clock_int);
    hWData <= std_uLogic_vector(to_signed(registerWDataReg, hWData'length));
    registerRData <= to_integer(signed(hRData));
  end process busAccessPhase2;

  ------------------------------------------------------------------------------
                                                                 -- time signals
  process(clock_int)
  begin
    if rising_edge(clock_int) then
      tReal <= tReal + 1.0/clockFrequency;
    end if;
  end process;

  aIn1 <= outAmplitude * sin(2.0*math_pi*sineFrequency*tReal);
  aIn2 <= outAmplitude * cos(2.0*math_pi*sineFrequency/2.0*tReal);

	--EMG Modifs
  AINP1 <= aIn1 when aIn1 >= 0.0 else -aIn1;
--  AINN1 <= 0.0  when aIn1 >= 0.0 else -aIn1;
  AINP2 <= aIn2 when aIn2 >= 0.0 else -aIn2;
--  AINN2 <= 0.0  when aIn2 >= 0.0 else -aIn2;
	----

END ARCHITECTURE test;
