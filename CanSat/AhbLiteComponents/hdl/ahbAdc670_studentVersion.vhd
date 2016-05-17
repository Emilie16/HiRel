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
-- The control register stores the ADC configuration lines defining the format
-- of the analog input.
--
-- The step register allows to ensure the ADC timings independently of the clock
-- period.
--
--------------------------------------------------------------------------------
--
-- Read registers
--
-- The status register, bit 0, tells when a new conversion value is available.
--
-- The value register provides the last acquired sample.
--
ARCHITECTURE studentVersion OF ahbAdc670 IS
BEGIN

  -- AHB-Lite
  hRData  <=	(OTHERS => '0');
  hReady  <=	'0';	
  hResp	  <=	'0';	

  -- ADC controls
  CS_n      <= '1';
  CE_n      <= '1';
  R_W       <= '0';
  FORMAT    <= '0';
  BPO_UPO_n <= '1';
 
END ARCHITECTURE studentVersion;
