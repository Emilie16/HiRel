--==============================================================================
--
-- AHB ADC 670 controller
--
-- Drives the ADC 670 in order to sample a signal.
--
-- The sampling is done with the help of enable(1) wich powers-up the ADC.
-- After power-on settling, enable(2) starts an acquisition.
--
--------------------------------------------------------------------------------
--
-- Write registers
--
-- 00 modulator period register: defines by how much the FPGA clock frequency
--   is divided in order to generate the modulator CLK.
--
-- 01 SPI period register: defines by how much the modulator clock is divided
--   in order to generate the SPI clock.
--
-- 02 ADC write register: receives the address and the data to write to one
--   of the ADC's registers.
--
--------------------------------------------------------------------------------
--
-- Read registers
--
-- 00 value low register: provides the last acquired sample's LSBs.
--
-- 01 value high register: provides the last acquired sample's MSBs.
--
-- 02 status register:
--   bit 0: tells when a new conversion value is available.
--

ARCHITECTURE RTL OF ahbAds1282 IS

  signal reset, clock: std_ulogic;
                                                         -- register definitions
  constant modulatorClockDividerRegisterId: natural := 0;
  constant spiClockDividerRegisterId: natural := 1;
	--EMG Modifs
  --constant adcRegisterId: natural := 2;
	constant adcRegisterId: natural := 6;
	----

  constant valueLowRegisterId: natural := 0;
  constant valueHighRegisterId: natural := 1;
  constant statusRegisterId: natural := 2;
  constant adcDataAvailableId: natural := 0;
	--EMG Modifs
	constant adcFSMCorrectionId: natural := 1;
  constant adcCurrentRegisterIDLow: natural := 3;
	constant adcCurrentRegisterIDHigh: natural := 4;
  constant adcVoltageRegisterIDLow: natural := 5;
	constant adcVoltageRegisterIDHigh: natural := 6;
	----

  constant registerNb: positive := adcRegisterId+1;
  constant registerAddresssBitNb: positive := addressBitNb(registerNb);
  signal addressReg: unsigned(registerAddresssBitNb-1 downto 0);
  signal writeReg: std_ulogic;
                                                            -- control registers
  subtype registerType is unsigned(hWdata'range);
  type registerArrayType is array (registerNb-1 downto 0) of registerType;
  signal writeRegisterArray: registerArrayType;
                                                      -- modulator clock divider
  signal modulatorDividerCounter: unsigned(registerType'range);
  signal modulatorRestartCounter: unsigned(2 downto 0);
  signal modulatorClockEn, modulatorClock: std_ulogic;
                                                            -- SPI clock divider
  signal spiDividerCounter: unsigned(registerType'range);
  signal spiClockEn, spiClock: std_ulogic;
                                                           -- ADC register write
  constant adcRegisterAddressBitNb: positive := 4;
  constant adcRegisterDataBitNb: positive := 8;
  signal adcRegisterWriteAddress: unsigned(adcRegisterAddressBitNb-1 downto 0);
  signal adcRegisterWriteValue  : unsigned(adcRegisterDataBitNb-1 downto 0);
                                                               -- ADC SPI access
  constant adcSpiCommandBitNb: positive := 8;
	constant cmdWakeup  : unsigned(adcSpiCommandBitNb-1 downto 0) := x"00";
	constant cmdStandby : unsigned(adcSpiCommandBitNb-1 downto 0) := x"02";
	constant cmdWriteReg: unsigned(adcSpiCommandBitNb-1 downto 0) := x"40";
	--EMG Modifs
	--constant regConfig0 : unsigned(adcSpiCommandBitNb-1 downto 0) := x"01";
	--constant regConfig1 : unsigned(adcSpiCommandBitNb-1 downto 0) := x"02";
	constant cmdSDATAC : unsigned(adcSpiCommandBitNb-1 downto 0) := x"11";
	constant cmdWRConfig1 : unsigned(adcSpiCommandBitNb-1 downto 0) := x"42";
	constant cmdCH1Enable : unsigned(adcSpiCommandBitNb-1 downto 0) := x"08";
	constant cmdCH2Enable : unsigned(adcSpiCommandBitNb-1 downto 0) := x"18";
	constant cmdRDATA : unsigned(adcSpiCommandBitNb-1 downto 0) := x"12";
	signal adcConfigByteNbr	: natural := 0;
	signal adcCurrentCHAcquisition : std_ulogic := '0';
	----
	
  constant adcSpiDataBitNb: positive := 32;
  signal adcCommand: unsigned(adcSpiCommandBitNb-1 downto 0);
  signal adcSendCommand, adcSendRead, adcSending: std_ulogic;
  signal adcSpiDataOut: unsigned(adcCommand'high+1 downto 0);
	--EMG Modifs
  --signal adcSpiDataIn, adcSample: unsigned(adcSpiDataBitNb-1 downto 0);
	signal adcSpiDataIn: unsigned(adcSpiDataBitNb-1 downto 0);
	signal adcConfigured : std_ulogic;
	signal adcCurrentAcquisitionRegister : unsigned(adcSpiDataBitNb-1 downto 0);
	signal adcVoltageAcquisitionRegister : unsigned(adcSpiDataBitNb-1 downto 0);
	signal adcCommandWait: std_ulogic;
	signal adcCmdTimeWait: std_ulogic;
	signal adcTimecounter: natural;
	signal adcCounterEnable: std_ulogic;
	----
  signal adcSpiCounter: unsigned(addressBitNb(adcSpiDataBitNb)-1 downto 0);

                                                                          -- FSM
	--EMG Modifs
  --type adcStateType is (
  --  waitSample,
  --  sendWakeup, waitDataReady, startRead, waitRead, reading, sendStandby
  --);
	type hamming_stateType is array(11 downto 0) of bit;
	type hamming_parityType is array(3 downto 0) of bit;
	type hamming_dataType is array (7 downto 0) of bit;
	--type fsm_stateType is array (7 downto 0) of bit;
	
	--ADC sequence and hamming correction states
	constant waitSample 		: hamming_stateType := "000000010011";
	constant sendSDATAC 		: hamming_stateType := "000000100101"; 
	constant sendConfigCH		: hamming_stateType := "000001000110";
	constant sendReadByCmd 	: hamming_stateType := "000010000111";
	constant waitDataReady 	: hamming_stateType := "000100001001";
	constant startRead 			: hamming_stateType := "001000001010";
	constant waitRead 			: hamming_stateType := "010000001011";
	constant reading		 		: hamming_stateType := "100000001100";
	
	--ADC sequence correction states old
	--constant waitSample 		: fsm_stateType := "00000001";
	--constant sendSDATAC 		: fsm_stateType := "00000010"; 
	--constant sendConfigCH		: fsm_stateType := "00000100";
	--constant sendReadByCmd 	: fsm_stateType := "00001000";
	--constant waitDataReady 	: fsm_stateType := "00010000";
	--constant startRead 			: fsm_stateType := "00100000";
	--constant waitRead 			: fsm_stateType := "01000000";
	--constant reading		 		: fsm_stateType := "10000000";

	--  signal adcState: adcStateType;
	signal adcState							: hamming_stateType;
	signal adcNextState					: hamming_stateType;
	signal adcLastState					: hamming_stateType;
	signal adcHammingCorrection : std_ulogic;
	signal adcHammingState 			: hamming_stateType;
	--ADC sequence correction signals old
	--signal adcState					: fsm_stateType;
	--signal adcNextState			: fsm_stateType;
	--signal adcLastState			: fsm_stateType;
	signal adcFSMCorrection	: std_ulogic;
	----
	
  signal adcDataAvailable: std_ulogic;
  signal adcStatusRegister: registerType;

BEGIN
  ------------------------------------------------------------------------------
                                                              -- reset and clock
  reset <= not hReset_n;
  clock <= hClk;

  --============================================================================
                                                         -- address and controls
  storeControls: process(reset, clock)
  begin
    if reset = '1' then
      addressReg <= (others => '0');
      writeReg <= '0';
    elsif rising_edge(clock) then
      writeReg <= '0';
      if (hSel = '1') and (hTrans = transNonSeq) then
        addressReg <= hAddr(addressReg'range);
        writeReg <= hWrite;
      end if;
    end if;
  end process storeControls;

  ------------------------------------------------------------------------------
                                                                    -- registers
  storeRegisters: process(reset, clock)
  begin
    if reset = '1' then
      writeRegisterArray <= (others => (others => '0'));
			--EMG Modifs
      --writeRegisterArray(modulatorClockDividerRegisterId) <= to_unsigned(2,
      --  writeRegisterArray(modulatorClockDividerRegisterId)'length);
			writeRegisterArray(modulatorClockDividerRegisterId) <= to_unsigned(30,
        writeRegisterArray(modulatorClockDividerRegisterId)'length);
			----
    elsif rising_edge(clock) then
      if writeReg = '1' then
				--EMG Modifs
				--writeRegisterArray(to_integer(addressReg)) <= unsigned(hWData);
				if to_integer(addressReg) = modulatorClockDividerRegisterId then
					if unsigned(hWData) >= 100 or unsigned(hWData) < 25 then
						writeRegisterArray(modulatorClockDividerRegisterId) <= to_unsigned(30,
							writeRegisterArray(modulatorClockDividerRegisterId)'length);
					else
						writeRegisterArray(to_integer(addressReg)) <= unsigned(hWData);
					end if;
				else
					writeRegisterArray(to_integer(addressReg)) <= unsigned(hWData);
				end if;
				----
      end if;
    end if;
  end process storeRegisters;

  --============================================================================
                                                      -- modulator clock divider
  countHalfModulatorPeriod: process(reset, clock)
    variable maxCounterValue: natural;
  begin
    if reset = '1' then
      modulatorDividerCounter <= (others => '0');
      modulatorClockEn <= '0';
    elsif rising_edge(clock) then
      modulatorClockEn <= '0';
      maxCounterValue := to_integer(
        writeRegisterArray(modulatorClockDividerRegisterId)/2 - 1
      );
      if (writeRegisterArray(modulatorClockDividerRegisterId)(0) = '1') and (modulatorClock = '1') then
        maxCounterValue := maxCounterValue + 1;
      end if;
      if modulatorDividerCounter < maxCounterValue then
        modulatorDividerCounter <= modulatorDividerCounter + 1;
      else
        modulatorDividerCounter <= (others => '0');
        modulatorClockEn <= '1';
      end if;
    end if;
  end process countHalfModulatorPeriod;

  divideModulatorClock: process(reset, clock)
  begin
    if reset = '1' then
      modulatorClock <= '0';
    elsif rising_edge(clock) then
      if modulatorClockEn = '1' then
        modulatorClock <= not modulatorClock;
      end if;
    end if;
  end process divideModulatorClock;

  CLK <= modulatorClock;

  delayRestart: process(reset, clock)
  begin
    if reset = '1' then
      modulatorRestartCounter <= (others => '0');
    elsif rising_edge(clock) then
      if (writeReg = '1') and (addressReg = modulatorClockDividerRegisterId) then
        modulatorRestartCounter <= (others => '1');
      elsif (modulatorClockEn = '1') and (modulatorRestartCounter > 0) then
        modulatorRestartCounter <= modulatorRestartCounter - 1;
      end if;
    end if;
  end process delayRestart;

	--EMG Modifs
  --RESET_n <= not '0' when modulatorRestartCounter = 0
  --  else not '1';
	RESET_n <= not '1' when modulatorRestartCounter = 1
    else hReset_n;
	----
	
  ------------------------------------------------------------------------------
                                                            -- SPI clock divider
  countHalfSpiPeriod: process(reset, clock)
    variable maxCounterValue: natural;
  begin
    if reset = '1' then
      spiDividerCounter <= (others => '0');
      spiClockEn <= '0';
    elsif rising_edge(clock) then
      spiClockEn <= '0';
      maxCounterValue := to_integer(
        writeRegisterArray(spiClockDividerRegisterId)/2 - 1
      );
      if (writeRegisterArray(spiClockDividerRegisterId)(0) = '1') and (spiClock = '0') then
        maxCounterValue := maxCounterValue + 1;
      end if;
      if (modulatorClockEn = '1') and (modulatorClock = '0') then
        if spiDividerCounter < maxCounterValue then
          spiDividerCounter <= spiDividerCounter + 1;
        else
          spiDividerCounter <= (others => '0');
          spiClockEn <= '1';
        end if;
      end if;
    end if;
  end process countHalfSpiPeriod;

  divideSpiClock: process(reset, clock)
  begin
    if reset = '1' then
      spiClock <= '0';
    elsif rising_edge(clock) then
      if spiClockEn = '1' then
        spiClock <= not spiClock;
      end if;
    end if;
  end process divideSpiClock;

  --============================================================================
                                                           -- ADC register write
  adcRegisterWriteValue <= writeRegisterArray(adcRegisterId)(adcRegisterWriteValue'range);
  adcRegisterWriteAddress <= writeRegisterArray(adcRegisterId)(
    adcRegisterWriteValue'length+adcRegisterWriteAddress'length-1 downto adcRegisterWriteValue'length
  );

--  signalRegisterAccess: process(reset, clock)
--  begin
--    if reset = '1' then
--      adcSendCommand <= '0';
--      adcCommand <= (others => '0');
--    elsif rising_edge(clock) then
--      adcSendCommand <= '0';
--      if (writeReg = '1') and (addressReg = adcRegisterId) then
--        adcSendCommand <= '1';
--        adcCommand <= unsigned(hwdata(adcCommand'range));
--      end if;
--    end if;
--  end process signalRegisterAccess;

  --============================================================================
                                                                      -- ADC FSM
  adcSequencer: process(reset, clock)
  begin
    if reset = '1' then
      adcState <= waitSample;
			adcLastState <= waitSample;
    elsif rising_edge(clock) then
			--EMG Modifs
			adcLastState <= adcState;
			if adcFSMCorrection = '1' then
				adcState <= adcNextState;
				adcLastState <= adcNextState;
			else
				case adcState is
					when waitSample =>
						if enable = '1' then
						--EMG Modifs
						--	if DRDY_n = not '0' then
						--  adcState <= sendWakeup;
								adcState <= sendSDATAC;
						--	else
						--		adcState <= startRead;
						--	end if;
						--elsif modulatorRestartCounter = 1 then
						--	adcState <= sendStandby;
						----
						end if;
					--EMG Modifs
					--when sendWakeup =>
					--  adcState <= waitDataReady;
					when sendSDATAC =>
						if adcCmdTimeWait='0' and adcCommandWait = '0' then
							adcState <= sendConfigCH;
						end if;
					when sendConfigCH =>
						if adcConfigured = '1' then
							adcState <= sendReadByCmd;		-- Correct state "000010000111";
							--adcState <= "10000000";				-- Wrong state, reading
							--adcState <= "100010001100";				-- Wrong state, reading with one bit modified
							--adcState <= "100000001100";				-- Wrong state, reading
							--adcState <= "000011000111";			-- Wrong state, modify one bit
						end if;
					when sendReadByCmd =>
						if adcCmdTimeWait='0' and adcCommandWait = '0' then
							adcState <= waitDataReady;
						end if;
					----
					when waitDataReady =>
						if DRDY_n = not '1' then
							adcState <= startRead;
						--EMG Modifs
						--elsif enable = '1' then
						--  adcState <= sendStandby;
						----
						end if;
					when startRead =>
						adcState <= waitRead;
					when waitRead =>
						if adcSending = '1' then
							adcState <= reading;
						end if;
					when reading =>
						if adcSending = '0' then
							--EMG Modifs
							--adcState <= sendStandby;
							adcState <= waitSample;
							----
						end if;
					--EMG Modifs
					--when sendStandby =>
					--	adcState <= waitSample;
					--	end if;
					----
					when others =>
						adcState <= waitSample;
				end case;
			end if;
			----
    end if;
  end process adcSequencer;
	
	--EMG Modifs
																																	--Send a three bytes command
	adcLongCmd: process(adcState,reset, clock)
	begin
		if reset = '1' then
      adcConfigured <= '0';
			adcConfigByteNbr <= 0;
    elsif rising_edge(clock) then
			adcConfigured <= '0';
			if adcState = sendConfigCH and adcSending = '0' and adcCommandWait = '0' and adcCmdTimeWait = '0' then
				adcConfigByteNbr <= adcConfigByteNbr+1;
				if adcConfigByteNbr >= 2 then
					adcConfigByteNbr <= 0;
					adcConfigured <= '1';
				end if;
			end if;
		end if;
	end process adcLongCmd;
																																	--Wait 24 clock before next command
	adcCmdTimeWait24: process(reset, modulatorClock, adcSending, adcSendCommand, adcState, adcConfigByteNbr)
	begin
		if reset = '1' then
			adcTimecounter <= 0;
			adcCmdTimeWait <= '0';
			adcCounterEnable <= '0';
		elsif adcSendCommand = '1' then
			if adcState /= sendConfigCH or (adcState=sendConfigCH and adcConfigByteNbr >= 2) then
				if rising_edge(adcSending) then
					adcCmdTimeWait <= '1';
				elsif falling_edge(adcSending) then
					adcTimecounter <= 0;
					adcCounterEnable <= '1';
					adcCmdTimeWait <= '1';
				elsif rising_edge(modulatorClock) and adcCounterEnable = '1' then
					adcCmdTimeWait <= '1';
					adcTimecounter <= adcTimecounter + 1;
					if adcTimecounter >= 24 then
						adcTimecounter <= 0;
						adcCounterEnable <= '0';
						adcCmdTimeWait <= '0';
					end if;
				end if;
			end if;
		end if;
	end process adcCmdTimeWait24;
																																--Wait start of command sending
	adcWaitCmdSend: process(reset,clock,adcSendCommand)
	begin
		if reset = '1' then
			adcCommandWait <='0';
		elsif rising_edge(adcSendCommand) then
			adcCommandWait <='1';
		elsif rising_edge(clock) then
			adcCommandWait <='0';
			if adcSendCommand = '1' and adcSending = '0' and adcCounterEnable = '0' then
				adcCommandWait <='1';
			end if;
		end if;
	end process adcWaitCmdSend;
	
	-- ADC sequence correction old
	--sequenceCorrection: process(adcState)
	--	variable adcShiftState: fsm_stateType;
	--begin
	--	adcFSMCorrection <= '0';
	--	adcNextState <= adcState;
		
		--Detect if currentState follow the lastState
	--	if adcState /= adcLastState then
	--		adcShiftState := adcLastState sll 1;
	--		if adcState/=adcShiftState then
	--			adcFSMCorrection <= '1';
	--			adcNextState <= waitSample;
	--		end if;
	--	end if;
	--end process sequenceCorrection;
	
	-- ADC sequence correction combined with hamming correction
	sequenceCorrection: process(adcHammingState,adcHammingCorrection)
		variable adcShiftState 	: hamming_dataType;
		variable adcStateData		: hamming_dataType;
	begin
		adcFSMCorrection <= adcHammingCorrection;
		adcNextState <= adcHammingState;
		
		--Detect if currentState follow the lastState
		if adcHammingState /= adcLastState and adcHammingState /= waitSample then
			adcStateData := hamming_dataType(adcHammingState(11 downto 4));
			adcShiftState := hamming_dataType(adcLastState(11 downto 4)) sll 1;
			if adcStateData/=adcShiftState then
				adcFSMCorrection <= '1';
				adcNextState <= waitSample;
			end if;
		end if;
	end process sequenceCorrection;
	
	hammingCorrection: process(adcState)
		variable hammPartiyCalc 	: hamming_parityType;
		variable hammPartiyCheck 	: hamming_parityType;
		variable hammPartiyIn 		: hamming_parityType;
		variable hammDataIn				: hamming_dataType;
		variable hammDataOut			: hamming_stateType;
	begin
		--adcFSMCorrection <= '1';
		adcHammingCorrection <= '1';
		
		hammDataIn := hamming_dataType(adcState(11 downto 4));
		hammPartiyIn := hamming_parityType(adcState(3 downto 0));
		
		--Calc parity from data
		hammPartiyCalc(0) := hammDataIn(0) XOR hammDataIn(1) XOR hammDataIn(3) XOR hammDataIn(4) XOR hammDataIn(6);
		hammPartiyCalc(1) := hammDataIn(0) XOR hammDataIn(2) XOR hammDataIn(3) XOR hammDataIn(5) XOR hammDataIn(6);
		hammPartiyCalc(2) := hammDataIn(1) XOR hammDataIn(2) XOR hammDataIn(3) XOR hammDataIn(7);
		hammPartiyCalc(3) := hammDataIn(4) XOR hammDataIn(5) XOR hammDataIn(6) XOR hammDataIn(7);
		
		--Correct error
		hammDataOut := adcState;
		hammPartiyCheck := hammPartiyCalc XOR hammPartiyIn;
		case hammPartiyCheck is
			when "0000" => 								--all ok
					hammDataOut := adcState; 
					--adcFSMCorrection <= '0';
					adcHammingCorrection <= '0';
			when "0001" => 								--Error in p0
					hammDataOut(0) := not adcState(0);
			when "0010" =>								--Error in p1
					hammDataOut(1) := not adcState(1);
			when "0011" =>								--Error in d0
					hammDataOut(4) := not adcState(4);
			when "0100" =>								--Error in p2
					hammDataOut(2) := not adcState(2);
			when "0101" =>								--Error in d1
					hammDataOut(5) := not adcState(5);
			when "0110" =>								--Error in d2
					hammDataOut(6) := not adcState(6);
			when "0111" =>								--Error in d3
					hammDataOut(7) := not adcState(7);
			when "1000" => 								--Error in p3
					hammDataOut(3) := not adcState(3);
			when "1001" => 								--Error in d4
					hammDataOut(8) := not adcState(8);
			when "1010" =>								--Error in d5
					hammDataOut(9) := not adcState(9);
			when "1011" =>								--Error in d6
					hammDataOut(10) := not adcState(10);
			when "1100" =>								--Error in d7
					hammDataOut(11) := not adcState(11);
			when others => 
					hammDataOut := waitSample;
		end case;
		
		--Apply correction
		--adcNextState <= hammDataOut;
		adcHammingState <= hammDataOut;
	end process;
	----
                                                                 -- ADC controls
	--EMG Modifs
  --adcControls: process(adcState)
	adcControls: process(adcNextState,adcConfigByteNbr)
	----
  begin
    adcSendCommand <= '0';
    adcCommand <= (others => '0');
    adcSendRead <= '0';
    adcDataAvailable <= '0';
    case adcNextState is
      when waitSample =>
        adcDataAvailable <= '1';
			--EMG Modifs
      --when sendWakeup =>
      --  adcSendCommand <= '1';
      --  adcCommand <= cmdWakeup;
			when sendSDATAC =>
        adcSendCommand <= '1';
        adcCommand <= cmdSDATAC;
			when sendReadByCmd =>
			  adcSendCommand <= '1';
        adcCommand <= cmdRDATA;
			when sendConfigCH =>
				adcSendCommand <= '1';
				case adcConfigByteNbr is
					when 0 =>
						adcCommand <= cmdWRConfig1;
					when 1 =>
						adcCommand <= x"00";
					when 2 => 
						if adcCurrentCHAcquisition = '0' then
							adcCommand <= cmdCH1Enable;
						else
							adcCommand <= cmdCH2Enable;
						end if;
						adcCurrentCHAcquisition <= not adcCurrentCHAcquisition;
					when others => null;
				end case;
			----
      when startRead =>
        adcSendRead <= '1';
			--EMG Modifs
      --when sendStandby =>
      --  adcSendCommand <= '1';
      --  adcCommand <= cmdStandby;
      --  adcDataAvailable <= '1';
      when others => null;
    end case;
  end process adcControls;

--EMG Modifs
--  SYNC <= '0';
--  PWDN_n <= not '0';
----

  --============================================================================
                                                               -- ADC SPI access
  spiExchangeData: process(reset, clock)
  begin
    if reset = '1' then
      adcSpiDataOut <= (others => '0');
      adcSpiDataIn <= (others => '0');
			--EMG Modifs
      --adcSample <= (others => '0');
			adcSending <= '0';
			adcVoltageAcquisitionRegister <= (others => '0');
			adcCurrentAcquisitionRegister <= (others => '0');
			----
      adcSpiCounter <= (others => '0');
    elsif rising_edge(clock) then
			--EMG Modifs
			if adcCounterEnable = '0' then
			----
				if adcSpiCounter = 0 then
					adcSending <= '0';
					--EMG Modifs
					--if adcSendCommand = '1' then
					if adcSendCommand = '1' and adcCommandWait = '1' and adcConfigured = '0' then
					----
						adcSpiCounter <= to_unsigned(adcSpiCommandBitNb+1, adcSpiCounter'length);
						adcSpiDataOut <= shift_left(
							resize(adcCommand, adcSpiDataOut'length),
							adcSpiDataOut'length - adcCommand'length - 1
						);
					elsif adcSendRead = '1' then
						adcSpiCounter <= to_unsigned(adcSpiDataBitNb+1, adcSpiCounter'length);
					end if;
					--EMG Modifs
					--if adcState = reading then
					--  adcSample <= adcSpiDataIn;
					if adcState = reading and adcCurrentCHAcquisition = '0' then
						adcVoltageAcquisitionRegister <= adcSpiDataIn;
					elsif adcState = reading and adcCurrentCHAcquisition = '1' then
						adcCurrentAcquisitionRegister <= adcSpiDataIn;
					----
					end if;
				elsif (spiClockEn = '1') and (spiClock = '1') then
					adcSpiCounter <= adcSpiCounter - 1;
					adcSpiDataOut <= shift_left(adcSpiDataOut, 1);
					adcSpiDataIn  <= shift_left(adcSpiDataIn, 1);
					adcSpiDataIn(0) <= DOUT;
					if (adcSpiCounter = adcSpiCommandBitNb+1) or (adcSpiCounter = adcSpiDataBitNb+1) then
						adcSending <= '1';
					end if;
				end if;
			end if;
    end if;
  end process spiExchangeData;

  SCLK <= adcSending and spiClock;
  DIN <= adcSpiDataOut(adcSpiDataOut'high);

  --============================================================================
                                                                -- data readback
	--EMG Modifs
  --selectData: process(addressReg, adcSample, adcStatusRegister)
	selectData: process(addressReg, adcVoltageAcquisitionRegister, adcCurrentAcquisitionRegister, adcStatusRegister)
	----
  begin
    case to_integer(addressReg) is
			--EMG Modifs
      --when valueLowRegisterId =>
      --  hRData <= std_ulogic_vector(adcSample(hRData'range));
      --when valueHighRegisterId =>
      --  hRData <= std_ulogic_vector(shift_right(adcSample, hRData'length)(hRData'range));
			----
      when statusRegisterId =>
        hRData <= std_ulogic_vector(adcStatusRegister);
			--EMG Modifs
			when adcCurrentRegisterIDLow => hRData <= std_ulogic_vector(adcCurrentAcquisitionRegister(hRData'range));
			when adcCurrentRegisterIDHigh => hRData <= std_ulogic_vector(shift_right(adcCurrentAcquisitionRegister, hRData'length)(hRData'range));
			when adcVoltageRegisterIDLow => hRData <= std_ulogic_vector(adcVoltageAcquisitionRegister(hRData'range));
			when adcVoltageRegisterIDHigh => hRData <= std_ulogic_vector(shift_right(adcVoltageAcquisitionRegister, hRData'length)(hRData'range));
			----
      when others => hRData <= (others => '-');
    end case;
  end process selectData;

  updateStatusRegister: process (adcDataAvailable, adcFSMCorrection)
  begin
    adcStatusRegister <= (others => '-');
		--EMG Modifs
		adcStatusRegister(adcFSMCorrectionId) <= adcFSMCorrection;
		----
    adcStatusRegister(adcDataAvailableId) <= adcDataAvailable;
  end process updateStatusRegister;

  hReady <= '1';  -- no wait state
  hResp  <= '0';  -- data OK

END ARCHITECTURE RTL;
