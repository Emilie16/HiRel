ARCHITECTURE sim OF ads1282 IS
                                                                      -- timings
  constant t_DR : time := 700 ns;
                                                            -- voltage to number
  constant vRef : real := VREFP - VREFN;
  constant adcBitNb : positive := 24;
  signal vIn1, vIn2 : real;
  signal nIn1, nIn2 : integer;
  signal sIn1, sIn2 : signed(adcBitNb-1 downto 0) := (others => '0');
                                                            -- command reception
  constant commandBitNb : positive := 8;
  signal commandBitId : natural := commandBitNb-1;
  signal commandId : natural;
                                                                    -- ADC state
  constant cmdWakeup0 : natural := 0;
  constant cmdWakeup1 : natural := 1;
  constant cmdStandby0 : natural := 2;
  constant cmdStandby1 : natural := 3;
  
  --EMG modifs
  constant cmdSDATAC : natural := 17;
  constant cmdRDATA	: natural := 18;
  constant cmdWRConfig1	: natural := 66;
  ----
  
  type adcStateType is (
    reset, standby,
    readContinuous, readByCommand, waitForCommandPart
  );
  signal adcState : adcStateType;
  signal trigTimeout, dataReadyTimeout : std_ulogic := '0';
	--EMG modifs
	signal canalToRead : std_ulogic := '0';
	signal trigTimeout2, dataReadyTimeout2 : std_ulogic := '0';
	----
                                                                     -- sampling
--  signal samplingPeriod : time := 1.0/4.0E3 * 1 sec;
  signal samplingPeriod : time := 1.0/10.0E3 * 1 sec;
  signal dataReady : std_ulogic := '0';

BEGIN
  ------------------------------------------------------------------------------
                                                            -- voltage to number
	--EMG Modifs
  --vIn1 <= AINP1 - AINN1;
  --vIn2 <= AINP2 - AINN2;
	vIn1 <= AINP1;
  vIn2 <= AINP2;
	----

  nIn1 <= 2**(adcBitNb-1)-1 when vIn1 >= VRef
    else -2**(adcBitNb-1) when vIn1 <= -VRef
    else integer(2.0**(adcBitNb-1) * vIn1/VRef);
  nIn2 <= 2**(adcBitNb-1)-1 when vIn2 >= VRef
    else -2**(adcBitNb-1) when vIn2 <= -VRef
    else integer(2.0**(adcBitNb-1) * vIn2/VRef);

  sIn1 <= to_signed(nIn1, sIn1'length) when rising_edge(dataReady);
  sIn2 <= to_signed(nIn2, sIn2'length) when rising_edge(dataReady);

  ------------------------------------------------------------------------------
                                                            -- command reception
  countCommandBitId: process
  begin
    wait until rising_edge(SCLK);
    wait until falling_edge(SCLK);
    if commandBitId = 0 then
      commandBitId <= commandBitNb-1;
    else
      commandBitId <= commandBitId - 1;
    end if;
  end process countCommandBitId;

  storeCommand: process
    variable commandUnsigned: unsigned(commandBitNb-1 downto 0);
  begin
    wait until rising_edge(SCLK);
    commandUnsigned := shift_left(commandUnsigned, 1);
    commandUnsigned(0) := DIN;
    if commandBitId = 0 then
      commandId <= to_integer(commandUnsigned);
    end if;
  end process storeCommand;

  ------------------------------------------------------------------------------
                                                                    -- ADC state
  updateAdcState: process
  begin
    wait on commandId, RESET_n, dataReadyTimeout, dataReadyTimeout2;
    if commandId'event then
			--EMG Modifs
			if adcState /= waitForCommandPart then
			----
				case commandId is
					when cmdWakeup0 => 
								--EMG Modifs
								--trigTimeout <= '1' , '0' after 1 ns;
								if adcState /= readByCommand then
									trigTimeout <= '1' , '0' after 1 ns;
								end if;
								----
					when cmdWakeup1 => trigTimeout <= '1' , '0' after 1 ns;
					when cmdStandby0 => adcState <= standby;
					when cmdStandby1 => adcState <= standby;
					--EMG Modifs
					when cmdSDATAC => adcState <= standby;
					when cmdRDATA	=> trigTimeout2 <= '1' , '0' after 1 ns;
					when cmdWRConfig1 =>
						adcState <= waitForCommandPart;
					---
					when others => null;
				end case;
			--EMG Modifs
			else
				if commandId = 8 then
					canalToRead <= '0';
					adcState <= standby;
				elsif commandId = 24 then
					canalToRead <= '1';
					adcState <= standby;
				end if;
			end if;
			----
    elsif rising_edge(RESET_n) then
      adcState <= reset;
      trigTimeout <= '1' , '0' after 1 ns;
    elsif rising_edge(dataReadyTimeout) then
				adcState <= readContinuous;
		--EMG Modifs
		elsif rising_edge(dataReadyTimeout2) then
				adcState <= readByCommand;
		----
    end if;
  end process;

  dataReadyTimeout <= '1' after t_DR when rising_edge(trigTimeout)
    else '0' after 1 ns when rising_edge(dataReadyTimeout);

	dataReadyTimeout2 <= '1' after t_DR when rising_edge(trigTimeout2)
    else '0' after 1 ns when rising_edge(dataReadyTimeout2);
  ------------------------------------------------------------------------------
                                                                     -- sampling
  signalNewSample: process
  begin
    wait on dataReady, adcState;
    if adcState'event then
      dataReady <= '0';
			--EMG Modifs
      --if adcState = readContinuous then
			if adcState = readContinuous or adcState = readByCommand then
			----
        dataReady <= '1';
      end if;
    elsif rising_edge(dataReady) then 
      if adcState = readContinuous then
				dataReady <= '0', '1' after samplingPeriod;
			--EMG Modifs
			elsif adcState = readByCommand then
				dataReady <= '0';
			----
      end if;
    end if;
  end process signalNewSample;

  DRDY_n <= not '0' when adcState = reset
    else not '1' when rising_edge(dataReady)
    else not '0' when rising_edge(SCLK);

  ------------------------------------------------------------------------------
                                                                  -- output data
  shiftData: process
    variable outputShiftRegister : signed(sIn1'range);
  begin
    wait on dataReady, SCLK;
		--EMG Modifs
    --if adcState = readContinuous then
		if adcState = readContinuous or adcState = readByCommand then
		----
      if rising_edge(dataReady) then
        wait for 1 ns;
				--EMG Modifs
				--outputShiftRegister := sIn1;
				if canalToRead = '1' then
					outputShiftRegister := sIn2;
				else
					outputShiftRegister := sIn1;
				end if;
				----
      elsif falling_edge(SCLK) then
        outputShiftRegister := shift_left(outputShiftRegister, 1);
      end if;
      DOUT <= outputShiftRegister(outputShiftRegister'high);
    else
      DOUT <= '0';
    end if;
  end process;

END ARCHITECTURE sim;
