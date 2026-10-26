library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Testbench for bin2BCD: drives the unit under test with known inputs and checks outputs
entity bin2BCD_tb is
end bin2BCD_tb;

architecture behavioral of bin2BCD_tb is

    -- Component declaration must match the bin2BCD entity exactly
    component bin2BCD is
        Port (
            bin_in  : in  STD_LOGIC_VECTOR(11 downto 0);
            sign    : out STD_LOGIC;
            BCD_out : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Testbench signals: these connect to the UUT ports
    signal bin_in  : STD_LOGIC_VECTOR(11 downto 0);
    signal sign    : STD_LOGIC;
    signal BCD_out : STD_LOGIC_VECTOR(15 downto 0);

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: bin2BCD
        port map (
            bin_in  => bin_in,
            sign    => sign,
            BCD_out => BCD_out
        );

    -- Stimulus process: runs once from top to bottom (no sensitivity list = runs at time 0)
    stim_proc: process
    begin
        -- Test zero: simplest case
        bin_in <= "000000000000";
        wait for 10 ns;
        assert sign = '0' and BCD_out = x"0000"
            report "FAIL: input 0" severity error;

        -- Test maximum positive 12-bit signed value (2047)
        bin_in <= "011111111111";
        wait for 10 ns;
        assert sign = '0' and BCD_out = x"2047"
            report "FAIL: input 2047" severity error;

        -- Test maximum negative 12-bit signed value (-2048)
        bin_in <= "100000000000";
        wait for 10 ns;
        assert sign = '1' and BCD_out = x"2048"
            report "FAIL: input -2048" severity error;

        -- Test negative one: NOT("111111111111")+1 = "000000000001" = 1
        bin_in <= "111111111111";
        wait for 10 ns;
        assert sign = '1' and BCD_out = x"0001"
            report "FAIL: input -1" severity error;

        -- Test small positive (5)
        bin_in <= "000000000101";
        wait for 10 ns;
        assert sign = '0' and BCD_out = x"0005"
            report "FAIL: input 5" severity error;

        -- Test small negative (-5): sign differs, magnitude same as +5
        bin_in <= "111111111011";
        wait for 10 ns;
        assert sign = '1' and BCD_out = x"0005"
            report "FAIL: input -5" severity error;

        -- Test hundreds digit (100)
        bin_in <= "000001100100";
        wait for 10 ns;
        assert sign = '0' and BCD_out = x"0100"
            report "FAIL: input 100" severity error;

        -- Test largest 3-digit number (999)
        bin_in <= "001111100111";
        wait for 10 ns;
        assert sign = '0' and BCD_out = x"0999"
            report "FAIL: input 999" severity error;

        -- Test negative of largest 3-digit number (-999)
        bin_in <= "110000011001";
        wait for 10 ns;
        assert sign = '1' and BCD_out = x"0999"
            report "FAIL: input -999" severity error;

        -- Test smallest 4-digit number (1000)
        bin_in <= "001111101000";
        wait for 10 ns;
        assert sign = '0' and BCD_out = x"1000"
            report "FAIL: input 1000" severity error;

        -- Test 255 (all lower 8 bits set)
        bin_in <= "000011111111";
        wait for 10 ns;
        assert sign = '0' and BCD_out = x"0255"
            report "FAIL: input 255" severity error;

        -- Test -128
        bin_in <= "111110000000";
        wait for 10 ns;
        assert sign = '1' and BCD_out = x"0128"
            report "FAIL: input -128" severity error;

        -- Test 1 (smallest positive non-zero)
        bin_in <= "000000000001";
        wait for 10 ns;
        assert sign = '0' and BCD_out = x"0001"
            report "FAIL: input 1" severity error;

        -- Test -1024 (typical flat Z-axis reading)
        bin_in <= "110000000000";
        wait for 10 ns;
        assert sign = '1' and BCD_out = x"1024"
            report "FAIL: input -1024" severity error;

        -- Test 512
        bin_in <= "001000000000";
        wait for 10 ns;
        assert sign = '0' and BCD_out = x"0512"
            report "FAIL: input 512" severity error;

        -- If we reach here with no assertion failures, all tests passed
        report "All tests completed." severity note;

        -- wait without a condition suspends the process forever, ending the simulation cleanly
        wait;
    end process;

end behavioral;
