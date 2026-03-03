library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.sine_lut_pkg.all;

entity quarter_sine is
    generic(
        PHASE_WIDTH : natural := 10; -- Phase bits
        AMP_BITS  : natural := 10  -- Amplitude bits
    );
    
    Port ( CLK      : in STD_LOGIC;
           ADDR     : in unsigned(PHASE_WIDTH-1 downto 0);      -- Addresing bits comes from phase accumulator
           SINE_OUT : out signed(AMP_BITS-1 downto 0));
end quarter_sine;

architecture Behavioral of quarter_sine is
    constant QUARTER_BITS : natural := PHASE_WIDTH-2; -- Addressing bits to cover all length in quarter sine LUT
    signal  quadrant      : unsigned(1 downto 0);
    signal index_in       : unsigned(QUARTER_BITS-1 downto 0);
    signal index_mirror   : unsigned(index_in'range);
    signal lut_val        : signed(SINE_OUT'range); 
    
begin
    quadrant <= unsigned(ADDR(ADDR'high downto ADDR'high-1)); -- 2 MSBs of phase accumulator to know the quadrant
    index_in <= unsigned(ADDR(QUARTER_BITS-1 downto 0));      -- LSB range of phase accumulator used to search in LUT
    index_mirror <= not index_in;   -- Equal to 2^QUARTER_BITS -1 - index_in

    process(CLK)
    begin
        if rising_edge(CLK) then
            case quadrant is
                when "00" => lut_val <= signed(sine_lut(to_integer(index_in))); -- 0° to 90°
                when "01" => lut_val <= signed(sine_lut(to_integer(index_mirror))); -- 90° to 180°
                when "10" => lut_val <= -signed(sine_lut(to_integer(index_in)));  -- 180° to 270° 
                when others => lut_val <= -signed(sine_lut(to_integer(index_mirror)));    -- 270° to 360°
            end case;
            
            SINE_OUT <= lut_val;
            
        end if;
    end process;

end Behavioral;
