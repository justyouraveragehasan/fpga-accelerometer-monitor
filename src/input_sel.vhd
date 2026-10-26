library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 2-to-1 multiplexer: selects between two 12-bit data sources
-- In this design, SW15 controls the selection:
--   sel='1' (SW15 ON)  → port A = accelerometer axis data (Stage 2)
--   sel='0' (SW15 OFF) → port B = manual switch input SW[11:0] (Stage 1)
entity input_sel is
    Port (
        sel : in  STD_LOGIC;                        -- select line (from SW15)
        A   : in  STD_LOGIC_VECTOR(11 downto 0);   -- input A: accelerometer data
        B   : in  STD_LOGIC_VECTOR(11 downto 0);   -- input B: switch data
        Y   : out STD_LOGIC_VECTOR(11 downto 0)    -- output: selected 12-bit value
    );
end input_sel;

architecture dataflow of input_sel is
begin
    -- Concurrent conditional assignment (combinational logic, no clock needed)
    -- This is equivalent to a hardware mux gate: sel controls which input passes through
    Y <= A when sel = '1' else B;
end dataflow;
