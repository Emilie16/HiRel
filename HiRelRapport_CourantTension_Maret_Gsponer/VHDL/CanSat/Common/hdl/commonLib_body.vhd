PACKAGE BODY CommonLib IS

  function requiredBitNb (val : integer) return integer is
    variable powerOfTwo, bitNb : integer;
  begin
    powerOfTwo := 1;
    bitNb := 0;
    while powerOfTwo <= val loop
      powerOfTwo := 2 * powerOfTwo;
      bitNb := bitNb + 1;
    end loop;
    return bitNb;
  end requiredBitNb;

END CommonLib;
