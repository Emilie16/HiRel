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
	constant adcRegisterId: natural := 4;
	----

  constant valueLowRegisterId: natural := 0;
  constant valueHighRegisterId: natural := 1;
  constant statusRegisterId: natural := 2;
  constant adcDataAvailableId: natural := 0;
	--EMG Modifs
  constant adcCurrentRegisterID: natural := 3;
  constant adcVoltageRegisterID: natural := 4;
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
	----
  signal adcSpiCounter: unsigned(addressBitNb(adcSpiDataBitNb)-1 downto 0);

                                                                          -- FSM
	--EMG Modifs
  --type adcStateType is (
  --  waitSample,
  --  sendWakeup, waitDataReady, startRead, waitRead, reading, sendStandby
  --);
	type hamming_stateType is array(6 downto 0) of bit;
	type hamming_parityType is array(2 downto 0) of bit;
	type hamming_dataType is array (3 downto 0) of bit;
	
	constant waitSample 		: hamming_stateType := "0000000";
	constant sendSDATAC 		: hamming_stateType := "0001011"; 
	constant waitDataReady	: hamming_stateType := "0011110";
	constant startRead 			: hamming_stateType := "0010101";
	constant waitRead 			: hamming_stateType := "0110011";
	constant reading 				: hamming_stateType := "0111000";
	constant sendStandby 		: hamming_stateType := "0101101";
	constant sendConfigCH 	: hamming_stateType := "0100110";
	constant sendReadByCmd 	: hamming_stateType := "1100001";

	--  signal adcState: adcStateType;
	signal adcState					: hamming_stateType;
	signal adcNextState			: hamming_stateType;
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
      writeRegisterArray(modulatorClockDividerRegisterId) <= to_unsigned(
        2,
        writeRegisterArray(modulatorClockDividerRegisterId)'length
      );
    elsif rising_edge(clock) then
      if writeReg = '1' then
        writeRegisterArray(to_integer(addressReg)) <= unsigned(hWData);
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

  RESET_n <= not '0' when modulatorRestartCounter = 0
    else not '1';

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
    elsif rising_edge(clock) then
			--EMG Modifs
			if adcFSMCorrection = '1' then
				adcState <= adcNextState;
			else
				case adcState is
					when waitSample =>
						if enable = '1' then
							if DRDY_n = not '0' then
								--EMG Modifs
								--adcState <= sendWakeup;
								adcState <= sendSDATAC;
								--adcState <= "0011011";
								----
							else
								adcState <= startRead;
							end if;
						elsif modulatorRestartCounter = 1 then
							adcState <= sendStandby;
						end if;
					--EMG Modifs
					--when sendWakeup =>
					--  adcState <= waitDataReady;
					when sendSDATAC =>
						if adcSending = '0' and adcCommandWait='0' and adcSpiCounter /= 0 then
							adcState <= sendConfigCH;
						end if;
					when sendConfigCH =>
						if adcConfigured = '1' then
							adcState <= sendReadByCmd;
						end if;
					when sendReadByCmd =>
						if adcSending = '0' and adcCommandWait='0' then
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
							adcState <= sendStandby;
						end if;
					when sendStandby =>
						adcState <= waitSample;
					when others =>
						adcState <= waitSample;
				end case;
			end if;
			----
    end if;
  end process adcSequencer;
	
	--EMG Modifs
	adcLongCmd: process(adcState,reset, clock)
	begin
		if reset = '1' then
      adcConfigured <= '0';
			adcConfigByteNbr <= 0;
    elsif rising_edge(clock) then
			adcConfigured <= '0';
			if adcState = sendConfigCH and adcSending = '0' and adcCommandWait = '0' then
				adcConfigByteNbr <= adcConfigByteNbr+1;
				if adcConfigByteNbr >= 2 then
					adcConfigByteNbr <= 0;
					adcConfigured <= '1';
				end if;
			end if;
		end if;
	end process adcLongCmd;
	
	adcWaitCmdSend: process(reset,clock)
	begin
		if reset = '1' then
			adcCommandWait <='0';
		elsif rising_edge(clock) then
			adcCommandWait <='0';
			if adcSendCommand = '1' and adcSending = '0' then
				adcCommandWait <='1';
			end if;
		end if;
	end process;
	
	hammingCorrection: process(adcState)
		variable hammPartiyCalc 	: hamming_parityType;
		variable hammPartiyCheck 	: hamming_parityType;
		variable hammPartiyIn 		: hamming_parityType;
		variable hammDataIn				: hamming_dataType;
		variable hammDataOut			: hamming_stateType;
	begin
		adcFSMCorrection <= '0';
		
		hammDataIn := hamming_dataType(adcState(6 downto 3));
		hammPartiyIn := hamming_parityType(adcState(2 downto 0));
		
		--Calc parity from data
		hammPartiyCalc(0) := hammDataIn(0) XOR hammDataIn(1) XOR hammDataIn(3);
		hammPartiyCalc(1) := hammDataIn(0) XOR hammDataIn(2) XOR hammDataIn(3);
		hammPartiyCalc(2) := hammDataIn(1) XOR hammDataIn(2) XOR hammDataIn(3);
		
		--Correct error
		hammDataOut := adcState;
		hammPartiyCheck := hammPartiyCalc XOR hammPartiyIn;
		case hammPartiyCheck is
			when "000" => hammDataOut := adcState; --all ok
			when "001" => 
					adcFSMCorrection <= '1';
					hammDataOut(0) := not adcState(0);
			when "010" =>
					adcFSMCorrection <= '1';
					hammDataOut(1) := not adcState(1);
			when "011" =>
					adcFSMCorrection <= '1';
					hammDataOut(3) := not adcState(3);
			when "100" =>
					adcFSMCorrection <= '1';
					hammDataOut(2) := not adcState(2);
			when "101" =>
					adcFSMCorrection <= '1';
					hammDataOut(4) := not adcState(4);
			when "110" =>
					adcFSMCorrection <= '1';
					hammDataOut(5) := not adcState(5);
			when "111" =>
					adcFSMCorrection <= '1';
					hammDataOut(6) := not adcState(6);
			when others => null;
		end case;
		
		--Apply correction
		adcNextState <= hammDataOut;
		
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
				case adcConfigByteNbr is
					when 0 =>
						adcSendCommand <= '1';
						adcCommand <= cmdWRConfig1;
					when 1 =>
						adcSendCommand <= '1';
						adcCommand <= x"00";
					when 2 => 
						adcSendCommand <= '1';
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
      when sendStandby =>
        adcSendCommand <= '1';
        adcCommand <= cmdStandby;
        adcDataAvailable <= '1';
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
			adcVoltageAcquisitionRegister <= (others => '0');
			adcCurrentAcquisitionRegister <= (others => '0');
			----
      adcSpiCounter <= (others => '0');
    elsif rising_edge(clock) then
      if adcSpiCounter = 0 then
        adcSending <= '0';
        if adcSendCommand = '1' then
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
			when adcCurrentRegisterID => hRData <= std_ulogic_vector(adcCurrentAcquisitionRegister(hRData'range));
			when adcVoltageRegisterID => hRData <= std_ulogic_vector(adcVoltageAcquisitionRegister(hRData'range));
			----
      when others => hRData <= (others => '-');
    end case;
  end process selectData;

  updateStatusRegister: process (adcDataAvailable)
  begin
    adcStatusRegister <= (others => '-');
    adcStatusRegister(adcDataAvailableId) <= adcDataAvailable;
  end process updateStatusRegister;

  hReady <= '1';  -- no wait state
  hResp  <= '0';  -- data OK

END ARCHITECTURE RTL;
