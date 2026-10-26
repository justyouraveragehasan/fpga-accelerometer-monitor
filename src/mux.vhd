library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux is
    Port (
        COUNT    : in  STD_LOGIC_VECTOR(2 downto 0);   -- 3-bit digit position from counter (0-7)
        SIGN     : in  STD_LOGIC;                       -- '1' if the number is negative
        BCD      : in  STD_LOGIC_VECTOR(15 downto 0);  -- 4 packed BCD digits from bin2BCD
        BCD_DIGIT: out STD_LOGIC_VECTOR(3 downto 0)    -- selected BCD digit to send to bin2seg
    );
end mux;

architecture behavioral of mux is
    -- Aliases create readable names for each 4-bit BCD digit within the 16-bit packed vector
    -- This avoids repeating bit ranges throughout the code and makes conditions self-documenting
    alias thou : STD_LOGIC_VECTOR(3 downto 0) is BCD(15 downto 12);  -- thousands digit
    alias hund : STD_LOGIC_VECTOR(3 downto 0) is BCD(11 downto 8);   -- hundreds digit
    alias tens : STD_LOGIC_VECTOR(3 downto 0) is BCD(7 downto 4);    -- tens digit
    alias unit : STD_LOGIC_VECTOR(3 downto 0) is BCD(3 downto 0);    -- units digit
begin
    -- This process selects which BCD digit to display based on the current counter value
    -- The counter cycles 0-7 at ~2kHz, so each digit gets ~250us of display time
    -- The display multiplexing is fast enough that all digits appear to be on simultaneously
    -- Sensitivity list includes all inputs to avoid inferred latches
    process(COUNT, SIGN, BCD, thou, hund, tens, unit)
    begin
        case COUNT is
            -- AN(0) = units digit: always displayed (even for value 0)
            when "000" =>
                BCD_DIGIT <= unit;

            -- AN(1) = tens digit: blank if the number has no tens/hundreds/thousands
            -- Leading-zero suppression: only show if a higher-order digit is non-zero
            when "001" =>
                if thou = "0000" and hund = "0000" and tens = "0000" then
                    BCD_DIGIT <= "1111";  -- "1111" is the blank code (all segments off in bin2seg)
                else
                    BCD_DIGIT <= tens;
                end if;

            -- AN(2) = hundreds digit: blank if no thousands or hundreds
            when "010" =>
                if thou = "0000" and hund = "0000" then
                    BCD_DIGIT <= "1111";  -- blank
                else
                    BCD_DIGIT <= hund;
                end if;

            -- AN(3) = thousands digit: blank if zero (max displayable value is 2048)
            when "011" =>
                if thou = "0000" then
                    BCD_DIGIT <= "1111";  -- blank
                else
                    BCD_DIGIT <= thou;
                end if;

            -- AN(4) = sign position: shows minus sign for negative numbers, blank for positive
            when "100" =>
                if SIGN = '1' then
                    BCD_DIGIT <= "1110";  -- "1110" is the minus code (only segment G on in bin2seg)
                else
                    BCD_DIGIT <= "1111";  -- blank (positive numbers have no sign displayed)
                end if;

            -- AN(5), AN(6), AN(7) = unused digit positions: always blank
            -- "others" covers COUNT values "101", "110", "111"
            when others =>
                BCD_DIGIT <= "1111";  -- blank
        end case;
    end process;
end behavioral;
