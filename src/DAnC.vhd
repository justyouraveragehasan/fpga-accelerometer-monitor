library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Display Anode Controller: converts the 3-bit digit counter to a one-hot-low anode pattern
-- The Nexys A7 has 8 seven-segment digits sharing common cathodes (CA-CG)
-- To display different digits, we rapidly switch between them using the anodes (AN0-AN7)
-- Only one anode is active (low) at a time; the others are inactive (high)
entity DAnC is
    Port (
        COUNT : in  STD_LOGIC_VECTOR(2 downto 0);  -- 3-bit digit position from counter
        AN    : out STD_LOGIC_VECTOR(7 downto 0)   -- 8 anode outputs (active-low: '0' = digit ON)
    );
end DAnC;

architecture dataflow of DAnC is
begin
    -- One-hot-low decode: exactly one bit is '0' (active), the rest are '1' (inactive)
    -- This ensures only one digit is illuminated at any moment
    -- The display appears fully lit because the counter cycles through all 8 positions
    -- at ~2kHz (250 Hz per digit), faster than the eye can perceive (persistence of vision)
    with COUNT select
        AN <=   "11111110" when "000",  -- AN(0) = rightmost digit (units)
                "11111101" when "001",  -- AN(1) = tens
                "11111011" when "010",  -- AN(2) = hundreds
                "11110111" when "011",  -- AN(3) = thousands
                "11101111" when "100",  -- AN(4) = sign position
                "11011111" when "101",  -- AN(5) = unused (always blank via mux)
                "10111111" when "110",  -- AN(6) = unused
                "01111111" when "111",  -- AN(7) = unused (leftmost digit)
                "11111111" when others; -- safety: all off (should never occur with 3-bit input)
end dataflow;
