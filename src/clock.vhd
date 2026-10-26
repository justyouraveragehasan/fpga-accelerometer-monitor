library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Clock divider: generates a single-cycle pulse at a lower frequency
-- Used to control the 7-segment display refresh rate
-- Formula: output frequency = CLK frequency / DIVISOR
-- Default: 100 MHz / 50000 = 2 kHz (each of 8 digits refreshed at 250 Hz)
entity clock_div is
    Generic (
        DIVISOR : integer := 50000  -- number of clock cycles per output pulse
    );
    Port (
        CLK   : in  STD_LOGIC;  -- system clock input (100 MHz)
        RESET : in  STD_LOGIC;  -- active-high synchronous reset
        PULSE : out STD_LOGIC   -- single-cycle pulse output (high for exactly one CLK period)
    );
end clock_div;

architecture behavioral of clock_div is
    -- Integer range constraint: tells the synthesiser this counter only needs
    -- enough bits to count from 0 to DIVISOR-1 (for 50000: 16 bits)
    -- This is more efficient than using a full 32-bit integer
    signal count : integer range 0 to DIVISOR - 1 := 0;
begin
    -- Sequential process: all assignments happen on the rising edge of CLK
    process(CLK)
    begin
        if rising_edge(CLK) then
            if RESET = '1' then
                -- Synchronous reset: counter and pulse both cleared
                count <= 0;
                PULSE <= '0';
            elsif count = DIVISOR - 1 then
                -- Terminal count reached: reset counter and emit a one-cycle pulse
                -- The pulse is high for exactly one clock period (10 ns at 100 MHz)
                count <= 0;
                PULSE <= '1';
            else
                -- Normal counting: increment counter, keep pulse low
                count <= count + 1;
                PULSE <= '0';
            end if;
        end if;
    end process;
end behavioral;
