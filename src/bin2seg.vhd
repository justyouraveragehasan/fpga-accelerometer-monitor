library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Lookup table: converts a 4-bit BCD digit (0-9) to a 7-segment display pattern
-- Also supports two special codes for the display mux: minus sign and blank
entity bin2seg is
    Port (
        BCD_in  : in  STD_LOGIC_VECTOR(3 downto 0);  -- 4-bit input: 0-9 = digits, 1110 = minus, 1111 = blank
        seg_out : out STD_LOGIC_VECTOR(6 downto 0)   -- 7-bit output: one bit per segment (active-low)
    );
end bin2seg;

architecture dataflow of bin2seg is
begin
    -- Segment mapping: seg_out(6)=CA(top), (5)=CB(upper-right), (4)=CC(lower-right),
    --                  (3)=CD(bottom), (2)=CE(lower-left), (1)=CF(upper-left), (0)=CG(middle)
    --
    -- Active-low encoding: '0' = segment ON (lit), '1' = segment OFF
    -- This is because the Nexys A7 uses common-anode displays where cathodes are driven low to light up
    --
    --    AAA          For example, digit "0" lights segments A,B,C,D,E,F (all except G)
    --   F   B         so seg_out = "0000001" (only CG is '1' = OFF, rest are '0' = ON)
    --    GGG
    --   E   C         Digit "1" lights only B and C
    --    DDD          so seg_out = "1001111" (A,D,E,F,G are OFF, B,C are ON)
    --
    with BCD_in select
        seg_out <=  "0000001" when "0000",  -- 0: segments A,B,C,D,E,F on (all except middle)
                    "1001111" when "0001",  -- 1: segments B,C on (right side only)
                    "0010010" when "0010",  -- 2: segments A,B,D,E,G on
                    "0000110" when "0011",  -- 3: segments A,B,C,D,G on
                    "1001100" when "0100",  -- 4: segments B,C,F,G on
                    "0100100" when "0101",  -- 5: segments A,C,D,F,G on
                    "0100000" when "0110",  -- 6: segments A,C,D,E,F,G on
                    "0001111" when "0111",  -- 7: segments A,B,C on
                    "0000000" when "1000",  -- 8: all segments on
                    "0000100" when "1001",  -- 9: segments A,B,C,D,F,G on
                    "1111110" when "1110",  -- minus sign: only segment G (middle bar) on
                    "1111111" when others;  -- blank: all segments off (used for leading zeros and unused digits)
end dataflow;
