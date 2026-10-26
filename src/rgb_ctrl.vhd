library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Controls the tri-colour RGB LED (LED16) based on board orientation
-- The accelerometer provides X, Y, Z readings; this module maps tilt to colours
-- Board axis orientation (Nexys A7):
--   X axis = forward/back tilt
--   Y axis = left/right tilt
--   Z axis = gravity direction: ~-1024 when flat face-up, ~+1024 when upside-down
entity rgb_ctrl is
    Port (
        X : in  STD_LOGIC_VECTOR(11 downto 0);  -- X-axis acceleration (forward/back)
        Y : in  STD_LOGIC_VECTOR(11 downto 0);  -- Y-axis acceleration (left/right)
        Z : in  STD_LOGIC_VECTOR(11 downto 0);  -- Z-axis acceleration (up/down, gravity)
        R : out STD_LOGIC;                        -- Red LED ('1' = on)
        G : out STD_LOGIC;                        -- Green LED ('1' = on)
        B : out STD_LOGIC                         -- Blue LED ('1' = on)
    );
end rgb_ctrl;

architecture behavioral of rgb_ctrl is
    -- Threshold for tilt detection: 256 counts ≈ 0.25g (about 14 degrees of tilt)
    -- This prevents the LED from flickering due to noise when the board is nearly flat
    constant THRESHOLD : signed(11 downto 0) := to_signed(256, 12);

    -- Internal signed versions of the inputs (needed for signed comparison and negation)
    signal x_s, y_s, z_s : signed(11 downto 0);

    -- Absolute values of X and Y (used to detect tilt magnitude regardless of direction)
    signal x_abs, y_abs   : signed(11 downto 0);
begin
    -- Cast std_logic_vector inputs to signed type for arithmetic operations
    x_s <= signed(X);
    y_s <= signed(Y);
    z_s <= signed(Z);

    -- Compute absolute values using conditional negation
    -- If negative, negate (flip sign); otherwise keep as-is
    -- This lets us detect tilt magnitude without caring about tilt direction
    x_abs <= -x_s when x_s < 0 else x_s;
    y_abs <= -y_s when y_s < 0 else y_s;

    -- RED: lights when board is tilted left or right (Y-axis exceeds threshold)
    R <= '1' when y_abs > THRESHOLD else '0';

    -- GREEN: lights when board is flat face-up
    -- On this board, Z is negative (~-1024) when face-up, so we check Z < -threshold
    G <= '1' when z_s < -THRESHOLD else '0';

    -- BLUE: lights when board is tilted forward or backward (X-axis exceeds threshold)
    B <= '1' when x_abs > THRESHOLD else '0';

    -- Colour mixing: multiple LEDs can be on simultaneously
    -- Flat + slight tilt → green + red/blue = yellow/cyan
    -- Diagonal tilt → red + blue = magenta
    -- Upside-down → Z is positive, so green is off; only tilt colours show
end behavioral;
