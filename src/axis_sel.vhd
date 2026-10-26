library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 4-to-1 multiplexer: selects which accelerometer axis data to display
-- Controlled by SW14 and SW13 (2-bit select)
entity axis_sel is
    Port (
        sel   : in  STD_LOGIC_VECTOR(1 downto 0);   -- 2-bit select from SW(14 downto 13)
        X     : in  STD_LOGIC_VECTOR(11 downto 0);  -- X-axis raw reading (forward/back tilt)
        Y     : in  STD_LOGIC_VECTOR(11 downto 0);  -- Y-axis raw reading (left/right tilt)
        Z     : in  STD_LOGIC_VECTOR(11 downto 0);  -- Z-axis raw reading (gravity direction)
        X_mg  : in  STD_LOGIC_VECTOR(11 downto 0);  -- X-axis converted to milligravity
        Y_out : out STD_LOGIC_VECTOR(11 downto 0)   -- selected axis output → feeds input_sel
    );
end axis_sel;

architecture dataflow of axis_sel is
begin
    -- "with...select" is a concurrent selected signal assignment (combinational mux)
    -- SW14:SW13 encoding:
    --   "00" → X raw   (forward/back acceleration)
    --   "01" → Y raw   (left/right acceleration)
    --   "10" → Z raw   (gravity, ~-1024 flat, ~+1024 inverted)
    --   "11" → X in mg (X-axis expressed in milligravity units)
    -- "others" covers "11" and any undefined states (defensive coding)
    with sel select
        Y_out <= X    when "00",
                 Y    when "01",
                 Z    when "10",
                 X_mg when others;
end dataflow;
