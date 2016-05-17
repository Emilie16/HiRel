LIBRARY common_test;
  USE common_test.testUtils.all;
library ieee;
  use ieee.math_real.all;

ARCHITECTURE test OF ads1282_tester IS
                                                             -- indication text
  signal indicationString: string(1 to 20);
                                                                    -- SD clock
  constant modulatorFrequency: real := 4.096E6;
  constant modulatorPeriod: time := (1.0/modulatorFrequency) * 1 sec;
  signal modulatorClock: std_uLogic := '1';
                                                                   -- SPI clock
  constant spiFrequency: real := modulatorFrequency / 4.0;
  constant spiPeriod: time := (1.0/spiFrequency) * 1 sec;
  signal spiClock: std_uLogic := '1';
                                                                     -- SPI data
  constant CPOL: std_ulogic := '0';
  constant CPHA: std_ulogic := '0';
  constant delayBetweenCommands : time := 24 * modulatorPeriod;
  constant spiCommandLength: positive := 8;
	constant cmdWakeup : unsigned(spiCommandLength-1 downto 0) := x"00";
	constant cmdStandby: unsigned(spiCommandLength-1 downto 0) := x"02";
	--EMG Modifs
	constant cmdSDATAC : unsigned(spiCommandLength-1 downto 0) := x"11";
	constant cmdRDATA: unsigned(spiCommandLength-1 downto 0) := x"12";
	constant cmdWRConfig1: unsigned(spiCommandLength-1 downto 0) := x"42";
		----
  constant spiDataLength: positive := 32;
  signal spiSend: std_ulogic;
  signal spiReadData: std_ulogic;
  signal spiRisingEdgeClock: std_ulogic;
  signal spiSlaveSelect: std_ulogic;
  signal spiCommand: unsigned(spiCommandLength-1 downto 0);
  signal spiDataIn: unsigned(spiDataLength-1 downto 0);
  signal sampledValue: signed(spiDataIn'range);
                                                                -- sampling rate
  constant samplingFrequency: real := 10.0E3;
  constant samplingPeriod: time := (1.0/samplingFrequency) * 1 sec;
  constant samplingEnPulseWidth: time := 0.5 us;
  signal samplingEn: std_uLogic := '0';
                                                               -- analog signals
  constant sineFrequency: real := samplingFrequency/10.0;
  constant sinePeriod: time := 1 sec / sineFrequency;
  constant outAmplitude: real := 5.0;
  signal tReal: real := 0.0;
  signal aIn1, aIn2: real := 0.0;
  signal vIn1_int, vIn2_int: real := 0.0;
  signal vIn1Sampled, vIn2Sampled : unsigned(spiDataLength-1 downto 0);

BEGIN
  ------------------------------------------------------------------------------
                                                             -- reset and clocks
  modulatorClock <= not modulatorClock after modulatorPeriod/2;
  CLK <= transport modulatorClock after modulatorPeriod * 9/10;

  spiClock <= not spiClock after spiPeriod/2;
  RESET_n <= not('1'), not('0') after 2 * spiPeriod;

  ------------------------------------------------------------------------------
                                                                -- test sequence
  testSequence: process
  begin
    indicationString <= pad(indicationString'length, "test start");
    spiSend <= '0';
    spiReadData <= '0';
    wait for 1 us;
                                                         -- read data continuous
    indicationString <= pad(indicationString'length, "read continuous");
    spiReadData <= '1';
    while now < 400 us loop
      wait until falling_edge(DRDY_n);
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
      sampledValue <= signed(spiDataIn);
    end loop;
    wait for delayBetweenCommands;
    wait for 500 us - now;
                                                                     -- one shot
    indicationString <= pad(indicationString'length, "one shot operations");
    for index in 1 to 4 loop
                                                                      -- standby
      spiReadData <= '0';
      spiCommand <= cmdStandby;
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
      wait for delayBetweenCommands;
                                                                       -- wakeup
      spiCommand <= cmdWakeup;
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
      wait for delayBetweenCommands;
                                                                    -- read data
      spiReadData <= '1';
      if DRDY_n = '1' then
        wait until falling_edge(DRDY_n);
      end if;
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
      sampledValue <= signed(spiDataIn);
      wait for delayBetweenCommands;
                                                                      -- standby
      spiReadData <= '0';
      spiCommand <= cmdStandby;
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
      wait for delayBetweenCommands;
		end loop;
		
		--EMG Modifs
																									-- Alternate CH1 and CH2 read		
		for index in 1 to 20 loop
		
			spiReadData <= '0';
			spiCommand <= cmdSDATAC;										-- Stop read continuous
			spiSend <= '1', '0' after spiPeriod;
			wait until falling_edge(spiSlaveSelect);
			wait for delayBetweenCommands;
		
			indicationString <= pad(indicationString'length, "Read CH1");
			spiReadData <= '0';
			spiCommand <= cmdWRConfig1;							-- Configure CH1 acquisition
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
			spiCommand <= x"00";							
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
			spiCommand <= x"08";							
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
      wait for delayBetweenCommands;
			
			spiCommand <= cmdRDATA;										--Read data cmd
			spiSend <= '1', '0' after spiPeriod;
			wait until falling_edge(spiSlaveSelect);
			wait for delayBetweenCommands;
		
			spiReadData <= '1';
      if DRDY_n = '1' then
        wait until falling_edge(DRDY_n);
      end if;
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
      sampledValue <= signed(spiDataIn);
			wait for delayBetweenCommands;
			
			spiReadData <= '0';
			spiCommand <= cmdSDATAC;										-- Stop read continuous
			spiSend <= '1', '0' after spiPeriod;
			wait until falling_edge(spiSlaveSelect);
			wait for delayBetweenCommands;
			
			indicationString <= pad(indicationString'length, "Read CH2");
			spiReadData <= '0';
			spiCommand <= cmdWRConfig1;							-- Configure CH2 acquisition
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
			spiCommand <= x"00";							
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
			spiCommand <= x"18";							
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
      wait for delayBetweenCommands;
			
			spiCommand <= cmdRDATA;										--Read data cmd
			spiSend <= '1', '0' after spiPeriod;
			wait until falling_edge(spiSlaveSelect);
			wait for delayBetweenCommands;
			
			spiReadData <= '1';
      if DRDY_n = '1' then
        wait until falling_edge(DRDY_n);
      end if;
      spiSend <= '1', '0' after spiPeriod;
      wait until falling_edge(spiSlaveSelect);
      sampledValue <= signed(spiDataIn);
      wait for delayBetweenCommands;
    end loop;
		----
                                                            -- end of simulation
    wait;
  end process testSequence;

  ------------------------------------------------------------------------------
                                                                -- SPI send data
  spiRisingEdgeClock <= spiClock when (CPOL xor CPHA) = '0'
    else not spiClock;

  spiExchangeData: process
    variable messageLength: positive;
    variable outputShiftRegister: unsigned(spiDataLength-1 downto 0);
    variable inputShiftRegister: unsigned(spiDataLength-1 downto 0);
  begin
    DIN <= '-';
    spiSlaveSelect <= '0';
                                                             -- wait for sending
    wait until rising_edge(spiSend);
    wait until falling_edge(spiRisingEdgeClock);
    spiSlaveSelect <= '1' after 1.1*spiPeriod;
                                                            -- select parameters
    if spiReadData = '0' then
      messageLength := spiCommand'length;
      outputShiftRegister := shift_left(
        resize(spiCommand, outputShiftRegister'length),
        outputShiftRegister'length - spiCommand'length - 1
      );
    else
      messageLength := spiDataIn'length;
      outputShiftRegister := (others => '0');
    end if;
                                                                 -- loop on bits
    for index in 1 to messageLength loop
                                                                     -- send bit
      wait until falling_edge(spiRisingEdgeClock);
      outputShiftRegister := shift_left(outputShiftRegister, 1);
      DIN <= outputShiftRegister(outputShiftRegister'high);
                                                                     -- read bit
      wait until rising_edge(spiRisingEdgeClock);
      inputShiftRegister := shift_left(inputShiftRegister, 1);
      inputShiftRegister(0) := DOUT;
    end loop;
                                                      -- deactivate slave enable
    wait until falling_edge(spiRisingEdgeClock);
    spiDataIn <= inputShiftRegister;

  end process spiExchangeData;

  SCLK <= CPOL when spiSlaveSelect = '0'
    else spiClock;

  ------------------------------------------------------------------------------
                                                                 -- time signals
  process(spiClock)
  begin
    if rising_edge(spiClock) then
      tReal <= tReal + 1.0/spiFrequency;
    end if;
  end process;

  aIn1 <= outAmplitude * sin(2.0*math_pi*sineFrequency*tReal);
  aIn2 <= outAmplitude * cos(2.0*math_pi*sineFrequency/2.0*tReal);

  AINP1 <= aIn1 when aIn1 >= 0.0 else 0.0;
--  AINN1 <= 0.0;
  AINP2 <= aIn2 when aIn2 >= 0.0 else 0.0;
--  AINN2 <= 0.0;

END ARCHITECTURE test;
