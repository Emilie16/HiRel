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
-- 00 control register: stores the ADC configuration lines defining the format
--   of the analog input.
--
-- 01 step register: allows to ensure the ADC timings independently of
--   the clock period.
--
--------------------------------------------------------------------------------
--
-- Read registers
--
-- 00 status register:
--   bit 0: tells when a new conversion value is available.
--
-- 01 value register: provides the last acquired sample.
--

ARCHITECTURE RTL OF ahbAdc670 IS

  signal reset, clock: std_ulogic;
                                                         -- register definitions
  constant controlRegisterId: natural := 0;
  constant controlBpoId: natural := 0;
  constant controlFormatId: natural := 0;
  constant stepRegisterId: natural := 1;

  constant statusRegisterId: natural := 0;
  constant statusValidId: natural := 0;
  constant valueRegisterId: natural := 1;

  constant registerNb: positive := stepRegisterId+1;
  constant registerAddresssBitNb: positive := addressBitNb(registerNb);
  signal addressReg: unsigned(registerAddresssBitNb-1 downto 0);
  signal writeReg: std_ulogic;
                                                            -- control registers
  subtype registerType is unsigned(hWdata'range);
  type registerArrayType is array (registerNb-1 downto 0) of registerType;
  signal registerArray: registerArrayType;
                                                             -- FSM step counter
  constant fsmEnableCounterBitNb: positive := 8;
  signal fsmEnableCounter: unsigned(fsmEnableCounterBitNb-1 downto 0);
  signal fsmEnable: std_ulogic;
                                                                          -- FSM
  constant powerEnableId: positive := 1;
  signal powerEnable: std_ulogic;
  constant startEnableId: positive := 2;
  signal startEnable: std_ulogic;
  type adcStateType is (
    idle, powerOn,
    startConv1, startConv2, waitConv1, waitConv2, readConv,
    powerOff
  );
  signal adcState: adcStateType;
                                                                   -- data value
  signal adcData: signed(hWdata'range);
  signal adcDataValid: std_ulogic;

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

  --============================================================================
                                                                    -- registers
  storeRegisters: process(reset, clock)
  begin
    if reset = '1' then
      registerArray <= (others => (others => '0'));
    elsif rising_edge(clock) then
      if writeReg = '1' then
        registerArray(to_integer(addressReg)) <= unsigned(hWData);
      end if;
    end if;
  end process storeRegisters;

  BPO_UPO_n <= registerArray(controlRegisterId)(controlBpoId);
  FORMAT    <= registerArray(controlRegisterId)(controlFormatId);

  --============================================================================
                                                           -- FSM enable counter
  countDelay: process(reset, clock)
  begin
    if reset = '1' then
      fsmEnableCounter <= (others => '0');
    elsif rising_edge(clock) then
      if fsmEnable = '0' then
        fsmEnableCounter <= fsmEnableCounter + 1;
      else
        fsmEnableCounter <= (others => '0');
      end if;
    end if;
  end process countDelay;

  fsmEnable <= '1' when fsmEnableCounter >= registerArray(stepRegisterId)-1
    else '0';

  powerEnable <= enable(powerEnableId);
  startEnable <= enable(startEnableId);
                                                                      -- ADC FSM
  adcSequencer: process(reset, clock)
  begin
    if reset = '1' then
      adcState <= idle;
    elsif rising_edge(clock) then
      case adcState is
        when idle =>
          if powerEnable = '1' then
            adcState <= powerOn;
          end if;
        when powerOn =>
          if startEnable = '1' then
            adcState <= startConv1;
          end if;
        when startConv1 =>
          if fsmEnable = '1' then
            adcState <= startConv2;
          end if;
        when startConv2 =>
          if fsmEnable = '1' then
            if STATUS = '0' then
              adcState <= waitConv1;
            else
              adcState <= waitConv2;
            end if;
          end if;
        when waitConv1 =>
          if fsmEnable = '1' then
            if STATUS = '1' then
              adcState <= waitConv2;
            end if;
          end if;
        when waitConv2 =>
          if fsmEnable = '1' then
            if STATUS = '0' then
              adcState <= readConv;
            end if;
          end if;
        when readConv =>
          if fsmEnable = '1' then
            adcState <= powerOff;
          end if;
        when powerOff =>
          if fsmEnable = '1' then
            adcState <= idle;
          end if;
      end case;
    end if;
  end process adcSequencer;
                                                                 -- ADC controls
  adcControls: process(adcState)
  begin
    CS_n <= not('1');
    CE_n <= not('0');
    R_W <= '1';
    adcDataValid <= '0';
    case adcState is
      when idle =>
        CS_n <= not('0');
        adcDataValid <= '1';
      when startConv2 =>
        R_W <= '0';
        CE_n <= not('1');
      when waitConv1 | waitConv2 =>
        CE_n <= not('0');
      when readConv =>
        CE_n <= not('1');
      when powerOff =>
        adcDataValid <= '1';
      when others => null;
    end case;
  end process adcControls;

  --============================================================================
                                                                -- data readback
  storeData: process(reset, clock)
  begin
    if reset = '1' then
      adcData <= (others => '0');
    elsif rising_edge(clock) then
      if (adcState = readConv) and (fsmEnable = '1') then
        adcData <= resize(D, adcData'length);
      end if;
    end if;
  end process storeData;

  hRData <= std_ulogic_vector(adcData) when addressReg = valueRegisterId
    else (statusValidId => adcDataValid, others => '0');
  hReady <= '1';  -- no wait state
  hResp  <= '0';  -- data OK

END ARCHITECTURE RTL;
