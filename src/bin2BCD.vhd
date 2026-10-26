library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity bin2BCD is
    Port (
        bin_in  : in  STD_LOGIC_VECTOR(11 downto 0);  -- 12-bit signed input (two's complement, range -2048 to +2047)
        sign    : out STD_LOGIC;                        -- '1' if input is negative, '0' if positive/zero
        BCD_out : out STD_LOGIC_VECTOR(15 downto 0)    -- 4 packed BCD digits: thou(15:12), hund(11:8), tens(7:4), units(3:0)
    );
end bin2BCD;

architecture behavioral of bin2BCD is
begin
    -- Purely combinational process: no clock, output updates whenever bin_in changes
    -- Uses variables (not signals) so assignments take effect immediately within the process
    process(bin_in)
        variable abs_val : STD_LOGIC_VECTOR(11 downto 0);  -- absolute value of the input (always positive)
        variable bcd     : STD_LOGIC_VECTOR(15 downto 0);  -- working register for the Double Dabble algorithm
    begin
        -- STEP 1: Extract sign and compute absolute value
        -- In two's complement, the MSB (bit 11) is the sign bit: '1' = negative
        if bin_in(11) = '1' then
            sign <= '1';
            -- Two's complement negation: invert all bits then add 1
            -- e.g. -5 in 12-bit = "111111111011", NOT = "000000000100", +1 = "000000000101" = 5
            -- Special case: -2048 ("100000000000") → NOT = "011111111111", +1 = "100000000000" = 2048
            -- This works because unsigned can hold 0 to 4095, and 2048 fits
            abs_val := not bin_in + 1;
        else
            sign <= '0';
            abs_val := bin_in;  -- positive numbers: just use directly
        end if;

        -- STEP 2: Double Dabble algorithm (also called "shift-and-add-3")
        -- Converts a binary number to BCD by shifting bits in one at a time
        -- The key insight: before each shift, if any BCD digit is > 4, add 3
        -- This pre-correction ensures that after the shift (which doubles the value),
        -- no BCD digit exceeds 9 (staying valid BCD)
        -- Why 3? A digit of 5 becomes 8 after adding 3; when shifted left (doubled),
        -- 8*2=16, which carries 1 into the next digit and leaves 6 — correct BCD behaviour
        bcd := (others => '0');  -- initialise all 16 bits to zero

        -- Process each input bit from MSB (bit 11) to LSB (bit 0)
        -- After 12 iterations, the bcd variable holds the final 4-digit BCD result
        for i in 11 downto 0 loop
            -- Check each of the 4 BCD digits (4 bits each) and add 3 if > 4
            -- This must happen BEFORE the shift, not after
            if bcd(15 downto 12) > 4 then                  -- thousands digit
                bcd(15 downto 12) := bcd(15 downto 12) + 3;
            end if;
            if bcd(11 downto 8) > 4 then                   -- hundreds digit
                bcd(11 downto 8) := bcd(11 downto 8) + 3;
            end if;
            if bcd(7 downto 4) > 4 then                    -- tens digit
                bcd(7 downto 4) := bcd(7 downto 4) + 3;
            end if;
            if bcd(3 downto 0) > 4 then                    -- units digit
                bcd(3 downto 0) := bcd(3 downto 0) + 3;
            end if;

            -- Shift the entire BCD register left by 1, bringing in the next binary bit
            -- bcd(14 downto 0) drops the MSB and shifts everything up
            -- abs_val(i) is the next input bit, appended at the LSB position
            bcd := bcd(14 downto 0) & abs_val(i);
        end loop;

        -- STEP 3: Output the result
        -- Result is 4 packed BCD digits, e.g. 1234 → x"1234" = "0001 0010 0011 0100"
        BCD_out <= bcd;
    end process;
end behavioral;
