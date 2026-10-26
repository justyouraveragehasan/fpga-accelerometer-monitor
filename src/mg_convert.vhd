library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Converts a raw 12-bit accelerometer reading to milligravity (mg) units
-- The ADXL362 is configured for ±2g range with 12-bit output
-- Full scale: 4g across 4096 counts → 1 LSB = 4g/4096 = 0.9766 mg
-- So the raw value is close to mg but not exact — this module does the precise conversion
entity mg_convert is
    Port (
        raw_in : in  STD_LOGIC_VECTOR(11 downto 0);  -- raw 12-bit signed accelerometer reading
        mg_out : out STD_LOGIC_VECTOR(11 downto 0)   -- result in milligravity (range ±2000)
    );
end mg_convert;

architecture behavioral of mg_convert is
begin
    process(raw_in)
        -- Multiplication of signed(12) × signed(8) produces signed(20) in VHDL
        -- This is because VHDL's "*" operator returns a vector of width = sum of input widths
        variable product : signed(19 downto 0);
    begin
        -- Conversion formula: mg = raw × 1000 / 1024
        -- Simplified to avoid large intermediate values: mg = raw × 125 / 128
        -- (1000/1024 = 125/128 — dividing both by 8)
        -- 125 fits in 8 bits (signed range: -128 to +127)
        -- Multiply: signed(raw_in) is 12-bit, to_signed(125,8) is 8-bit → result is 20-bit
        product := signed(raw_in) * to_signed(125, 8);

        -- Divide by 128 using arithmetic right-shift by 7 bits
        -- Arithmetic shift preserves the sign bit (unlike logical shift)
        -- product(18 downto 7) extracts bits 18:7, which is equivalent to >>7
        -- We skip bit 19 (the MSB) because the result fits in 12 bits:
        --   max: 2048 × 125 = 256000, >> 7 = 2000 → fits in 12-bit signed (max 2047)
        --   min: -2048 × 125 = -256000, >> 7 = -2000 → fits in 12-bit signed (min -2048)
        mg_out <= std_logic_vector(product(18 downto 7));
    end process;
end behavioral;
