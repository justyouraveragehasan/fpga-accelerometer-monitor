library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Top-level entity: directly maps to physical FPGA pins via the XDC constraints file
-- This is a STRUCTURAL architecture — it contains no behavioural logic, only component wiring
entity display is
    Port (
        CLK100MHZ  : in  STD_LOGIC;                     -- 100 MHz system clock from onboard oscillator
        CPU_RESETN : in  STD_LOGIC;                     -- Active-LOW reset button (active-low means '0' = pressed)
        SW         : in  STD_LOGIC_VECTOR(15 downto 0); -- 16 slide switches: SW15=mode, SW14:13=axis, SW11:0=data
        CA         : out STD_LOGIC;                     -- 7-segment cathode A (active-low: '0'=ON)
        CB         : out STD_LOGIC;                     -- 7-segment cathode B
        CC         : out STD_LOGIC;                     -- 7-segment cathode C
        CD         : out STD_LOGIC;                     -- 7-segment cathode D
        CE         : out STD_LOGIC;                     -- 7-segment cathode E
        CF         : out STD_LOGIC;                     -- 7-segment cathode F
        CG         : out STD_LOGIC;                     -- 7-segment cathode G
        DP         : out STD_LOGIC;                     -- 7-segment decimal point (active-low)
        AN         : out STD_LOGIC_VECTOR(7 downto 0);  -- 8 anode enables (active-low: '0'=digit ON)
        -- Accelerometer SPI pins — directly connected to the ADXL362 chip on the Nexys A7 board
        ACL_SCLK   : out STD_LOGIC;                     -- SPI clock output to accelerometer
        ACL_MOSI   : out STD_LOGIC;                     -- SPI data out (Master Out Slave In)
        ACL_MISO   : in  STD_LOGIC;                     -- SPI data in (Master In Slave Out)
        ACL_CSN    : out STD_LOGIC;                     -- SPI chip select (active-low: '0'=selected)
        -- RGB LED for orientation indication
        LED16_R    : out STD_LOGIC;                     -- Red channel of tri-colour LED16
        LED16_G    : out STD_LOGIC;                     -- Green channel
        LED16_B    : out STD_LOGIC                      -- Blue channel
    );
end display;

architecture structural of display is

    -- Internal wiring signals connecting the components together
    signal reset     : STD_LOGIC;                        -- Active-HIGH reset (inverted from CPU_RESETN)
    signal sel_out   : STD_LOGIC_VECTOR(11 downto 0);   -- Output of input_sel: either switches or accel data
    signal sign_out  : STD_LOGIC;                        -- Sign bit from bin2BCD ('1' = negative)
    signal bcd_out   : STD_LOGIC_VECTOR(15 downto 0);   -- 4 packed BCD digits from bin2BCD
    signal pulse     : STD_LOGIC;                        -- Single-cycle pulse at ~2kHz from clock divider
    signal count     : STD_LOGIC_VECTOR(2 downto 0);    -- Current digit position (0-7) from counter
    signal digit     : STD_LOGIC_VECTOR(3 downto 0);    -- Selected BCD digit from mux
    signal seg       : STD_LOGIC_VECTOR(6 downto 0);    -- 7-segment pattern from bin2seg

    -- Accelerometer data signals (12-bit two's complement, range -2048 to +2047)
    signal accel_x   : STD_LOGIC_VECTOR(11 downto 0);   -- X-axis: changes on forward/back tilt
    signal accel_y   : STD_LOGIC_VECTOR(11 downto 0);   -- Y-axis: changes on left/right tilt
    signal accel_z   : STD_LOGIC_VECTOR(11 downto 0);   -- Z-axis: ~-1024 flat face-up, ~+1024 upside-down
    signal accel_tmp : STD_LOGIC_VECTOR(11 downto 0);   -- Temperature sensor data (not displayed)
    signal x_mg      : STD_LOGIC_VECTOR(11 downto 0);   -- X-axis converted to milligravity
    signal axis_data : STD_LOGIC_VECTOR(11 downto 0);   -- Selected axis output from axis_sel mux

    -- Component declarations: these must match the entity ports of each sub-module exactly
    -- They tell the synthesiser what interface each component has, so it can check the wiring

    component ACC_XYZ is
        Generic (
            SYSCLK_FREQUENCY_HZ : integer := 100000000;  -- system clock frequency for timing calculations
            SCLK_FREQUENCY_HZ   : integer := 1000000;    -- SPI clock: 1 MHz
            NUM_READS_AVG        : integer := 16;         -- number of samples to average (must be power of 2)
            UPDATE_FREQUENCY_HZ  : integer := 100         -- how often to output new averaged data
        );
        Port (
            SYSCLK        : in  STD_LOGIC;
            RESET         : in  STD_LOGIC;
            SCLK          : out STD_LOGIC;
            MOSI          : out STD_LOGIC;
            MISO          : in  STD_LOGIC;
            SS            : out STD_LOGIC;
            ACCEL_X_OUT   : out STD_LOGIC_VECTOR(11 downto 0);
            ACCEL_Y_OUT   : out STD_LOGIC_VECTOR(11 downto 0);
            ACCEL_Z_OUT   : out STD_LOGIC_VECTOR(11 downto 0);
            ACCEL_TMP_OUT : out STD_LOGIC_VECTOR(11 downto 0)
        );
    end component;

    component input_sel is
        Port (
            sel : in  STD_LOGIC;
            A   : in  STD_LOGIC_VECTOR(11 downto 0);
            B   : in  STD_LOGIC_VECTOR(11 downto 0);
            Y   : out STD_LOGIC_VECTOR(11 downto 0)
        );
    end component;

    component axis_sel is
        Port (
            sel   : in  STD_LOGIC_VECTOR(1 downto 0);
            X     : in  STD_LOGIC_VECTOR(11 downto 0);
            Y     : in  STD_LOGIC_VECTOR(11 downto 0);
            Z     : in  STD_LOGIC_VECTOR(11 downto 0);
            X_mg  : in  STD_LOGIC_VECTOR(11 downto 0);
            Y_out : out STD_LOGIC_VECTOR(11 downto 0)
        );
    end component;

    component mg_convert is
        Port (
            raw_in : in  STD_LOGIC_VECTOR(11 downto 0);
            mg_out : out STD_LOGIC_VECTOR(11 downto 0)
        );
    end component;

    component rgb_ctrl is
        Port (
            X : in  STD_LOGIC_VECTOR(11 downto 0);
            Y : in  STD_LOGIC_VECTOR(11 downto 0);
            Z : in  STD_LOGIC_VECTOR(11 downto 0);
            R : out STD_LOGIC;
            G : out STD_LOGIC;
            B : out STD_LOGIC
        );
    end component;

    component bin2BCD is
        Port (
            bin_in  : in  STD_LOGIC_VECTOR(11 downto 0);
            sign    : out STD_LOGIC;
            BCD_out : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    component bin2seg is
        Port (
            BCD_in  : in  STD_LOGIC_VECTOR(3 downto 0);
            seg_out : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;

    component clock_div is
        Generic (
            DIVISOR : integer := 50000
        );
        Port (
            CLK   : in  STD_LOGIC;
            RESET : in  STD_LOGIC;
            PULSE : out STD_LOGIC
        );
    end component;

    component counter is
        Port (
            CLK    : in  STD_LOGIC;
            RESET  : in  STD_LOGIC;
            ENABLE : in  STD_LOGIC;
            COUNT  : out STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;

    component mux is
        Port (
            COUNT    : in  STD_LOGIC_VECTOR(2 downto 0);
            SIGN     : in  STD_LOGIC;
            BCD      : in  STD_LOGIC_VECTOR(15 downto 0);
            BCD_DIGIT: out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    component DAnC is
        Port (
            COUNT : in  STD_LOGIC_VECTOR(2 downto 0);
            AN    : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

begin

    -- CPU_RESETN is active-low (pressed = '0'), but all our modules use active-high reset
    -- Invert it so reset='1' when the button is pressed
    reset <= not CPU_RESETN;

    -- Decimal point permanently off: DP='1' because the 7-seg display is active-low
    DP <= '1';

    -- ==================== ACCELEROMETER (Stage 2) ====================

    -- Instantiate the provided accelerometer controller
    -- NUM_READS_AVG=32 means it averages 32 consecutive readings before updating output
    -- This reduces noise but adds latency (32 samples at 200Hz ODR = 160ms per update)
    -- UPDATE_FREQUENCY_HZ=100 means the averaging cycle repeats 100 times per second
    u_acc_xyz: ACC_XYZ
        generic map (
            SYSCLK_FREQUENCY_HZ => 100000000,  -- 100 MHz system clock
            SCLK_FREQUENCY_HZ   => 1000000,    -- 1 MHz SPI clock (must be <= SYSCLK/4)
            NUM_READS_AVG        => 32,         -- average over 32 samples (must be power of 2)
            UPDATE_FREQUENCY_HZ  => 100         -- output 100 averaged readings per second
        )
        port map (
            SYSCLK        => CLK100MHZ,   -- connect system clock
            RESET         => reset,        -- connect active-high reset
            SCLK          => ACL_SCLK,    -- SPI clock → accelerometer chip pin
            MOSI          => ACL_MOSI,    -- SPI data out → accelerometer chip pin
            MISO          => ACL_MISO,    -- SPI data in ← accelerometer chip pin
            SS            => ACL_CSN,     -- SPI chip select → accelerometer chip pin
            ACCEL_X_OUT   => accel_x,     -- 12-bit signed X acceleration (forward/back tilt)
            ACCEL_Y_OUT   => accel_y,     -- 12-bit signed Y acceleration (left/right tilt)
            ACCEL_Z_OUT   => accel_z,     -- 12-bit signed Z acceleration (-1024 face-up, +1024 upside-down)
            ACCEL_TMP_OUT => accel_tmp    -- 12-bit temperature (not used in display)
        );

    -- Convert raw X-axis reading to milligravity (mg) units
    -- This feeds into the axis_sel mux as the 4th option (SW14:13 = "11")
    u_mg_convert: mg_convert
        port map (
            raw_in => accel_x,   -- raw 12-bit X reading
            mg_out => x_mg       -- X reading expressed in mg (±2000 range)
        );

    -- 4-to-1 axis selector: SW14 and SW13 choose which data to display
    -- "00"=X raw, "01"=Y raw, "10"=Z raw, "11"=X in milligravity
    u_axis_sel: axis_sel
        port map (
            sel   => SW(14 downto 13),  -- 2-bit select from switches
            X     => accel_x,           -- X-axis raw data (forward/back tilt)
            Y     => accel_y,           -- Y-axis raw data (left/right tilt)
            Z     => accel_z,           -- Z-axis raw data (gravity direction)
            X_mg  => x_mg,             -- X-axis converted to milligravity
            Y_out => axis_data          -- selected axis output → feeds into input_sel
        );

    -- RGB LED driven by all three axes simultaneously (always active, independent of SW15)
    -- Red = left/right tilt (Y), Green = flat face-up (Z negative), Blue = forward/back tilt (X)
    u_rgb_ctrl: rgb_ctrl
        port map (
            X => accel_x,     -- X-axis data for forward/back detection
            Y => accel_y,     -- Y-axis data for left/right detection
            Z => accel_z,     -- Z-axis data for flat/inverted detection
            R => LED16_R,     -- Red LED output pin
            G => LED16_G,     -- Green LED output pin
            B => LED16_B      -- Blue LED output pin
        );

    -- ==================== DATA SOURCE SELECTOR ====================

    -- 2-to-1 mux: SW15 selects between accelerometer data and manual switch input
    -- sel='1' (SW15 ON) → port A (accelerometer axis_data)
    -- sel='0' (SW15 OFF) → port B (switches SW11:0 for manual testing)
    u_input_sel: input_sel
        port map (
            sel => SW(15),              -- mode switch: ON=accelerometer, OFF=manual
            A   => axis_data,           -- accelerometer data (selected axis)
            B   => SW(11 downto 0),     -- manual 12-bit input from slide switches
            Y   => sel_out              -- chosen data → feeds into bin2BCD
        );

    -- ==================== DISPLAY PIPELINE ====================

    -- Convert the 12-bit signed binary value to BCD for display
    -- Outputs: sign bit + 4 packed BCD digits (16 bits)
    u_bin2BCD: bin2BCD
        port map (
            bin_in  => sel_out,    -- 12-bit signed value from input selector
            sign    => sign_out,   -- '1' if negative → used by mux for minus sign display
            BCD_out => bcd_out     -- 4 BCD digits packed into 16 bits
        );

    -- Clock divider: produces a single-cycle pulse at ~2kHz
    -- 100 MHz / 50000 = 2000 Hz → each of 8 digits gets refreshed at 250 Hz
    -- This is fast enough that the human eye sees all digits lit simultaneously (persistence of vision)
    u_clock_div: clock_div
        generic map (
            DIVISOR => 50000    -- 100MHz / 50000 = 2kHz display refresh rate
        )
        port map (
            CLK   => CLK100MHZ,  -- driven by 100 MHz system clock
            RESET => reset,
            PULSE => pulse       -- single-cycle pulse output → enables counter
        );

    -- 3-bit counter: cycles 0→1→2→...→7→0 on each pulse
    -- Determines which of the 8 display digits is currently active
    u_counter: counter
        port map (
            CLK    => CLK100MHZ,  -- clocked at 100MHz (but only increments when ENABLE is high)
            RESET  => reset,
            ENABLE => pulse,      -- only counts on the 2kHz pulse edges
            COUNT  => count       -- 3-bit output: current digit position (0-7)
        );

    -- Selects which BCD digit to display at the current counter position
    -- Also implements leading-zero blanking (e.g. "0042" displays as "  42")
    -- and sign display (minus sign at position 4 for negative numbers)
    u_mux: mux
        port map (
            COUNT     => count,      -- which digit position (0=units, 4=sign, 5-7=blank)
            SIGN      => sign_out,   -- whether to show minus sign at position 4
            BCD       => bcd_out,    -- all 4 BCD digits
            BCD_DIGIT => digit       -- selected digit → feeds into bin2seg
        );

    -- Converts the selected 4-bit BCD digit into a 7-segment display pattern
    -- Also handles special codes: "1110"=minus sign, "1111"=blank
    u_bin2seg: bin2seg
        port map (
            BCD_in  => digit,   -- 4-bit BCD digit (0-9, or special code)
            seg_out => seg      -- 7-bit segment pattern (active-low)
        );

    -- Map the 7-bit segment vector to individual cathode output pins
    -- seg(6)=CA (top), seg(5)=CB (upper-right), ..., seg(0)=CG (middle)
    -- Active-low: '0' turns a segment ON, '1' turns it OFF
    CA <= seg(6);  -- segment A (top horizontal)
    CB <= seg(5);  -- segment B (upper-right vertical)
    CC <= seg(4);  -- segment C (lower-right vertical)
    CD <= seg(3);  -- segment D (bottom horizontal)
    CE <= seg(2);  -- segment E (lower-left vertical)
    CF <= seg(1);  -- segment F (upper-left vertical)
    CG <= seg(0);  -- segment G (middle horizontal)

    -- Anode controller: activates one digit at a time using one-hot-low encoding
    -- e.g. count=0 → AN="11111110" (only AN0 is '0', so only the rightmost digit is ON)
    -- Combined with the mux above, this creates time-division multiplexing of the display
    u_DAnC: DAnC
        port map (
            COUNT => count,   -- current digit position
            AN    => AN       -- 8-bit anode output (active-low, directly to FPGA pins)
        );

end structural;
