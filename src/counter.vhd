library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- 3-bit counter: cycles 0 through 7, used to select which display digit is active
-- Increments only when ENABLE is high (driven by the clock divider pulse)
entity counter is
    Port (
        CLK    : in  STD_LOGIC;                     -- system clock (100 MHz)
        RESET  : in  STD_LOGIC;                     -- active-high synchronous reset
        ENABLE : in  STD_LOGIC;                     -- increment on rising edge when '1' (from clock_div pulse)
        COUNT  : out STD_LOGIC_VECTOR(2 downto 0)   -- 3-bit output: current digit position (0-7)
    );
end counter;

architecture behavioral of counter is
    -- Internal counter uses STD_LOGIC_VECTOR with STD_LOGIC_UNSIGNED for arithmetic
    -- Initialised to zero; (others => '0') sets all 3 bits to '0'
    signal cnt : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
begin
    process(CLK)
    begin
        if rising_edge(CLK) then
            if RESET = '1' then
                cnt <= (others => '0');          -- reset counter to 0
            elsif ENABLE = '1' then
                -- Increment by 1; because cnt is 3-bit, it wraps naturally:
                -- 0→1→2→3→4→5→6→7→0 (overflow discarded, modular arithmetic)
                -- No explicit wrap check needed — this is a key property of fixed-width unsigned
                cnt <= cnt + 1;
            end if;
            -- If ENABLE='0', cnt holds its value (implicit latch-free: clocked process)
        end if;
    end process;

    -- Output the counter value directly (no type conversion needed)
    COUNT <= cnt;
end behavioral;
