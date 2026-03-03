library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity DDS is
    generic(
        FTW_WIDTH : natural := 32;        -- Frequency Tuning Word width.
        PHASE_WIDTH : natural := 10;
        AMP_WIDTH  : natural := 10
    );
    Port ( CLK      : in STD_LOGIC;
           RST_n    : in STD_LOGIC;
           ENABLE   : in STD_LOGIC;
           FTW_IN   : in unsigned(FTW_WIDTH-1 downto 0);        -- Frequency Tuning Word input.
           POW_IN   : in unsigned(PHASE_WIDTH-1 downto 0);      -- Phase Offset Word.
           OUT_SQ   : out std_logic;                            -- NCO's MSB in order to produce a square wave of FTW duration.
           SINE_OUT : out signed(AMP_WIDTH-1 downto 0) := (others => '0') -- DDS/NCO phase out for LUT.
           );
           -- Example: For f_clk=100 MHz, FTW_WIDTH=32:
           -- FTW_IN = round(f_out / 100e6 * 2^32)
           -- where f_out is the desired output frequency.
end DDS;

architecture Behavioral of DDS is
    signal lut_addr : unsigned(PHASE_WIDTH-1 downto 0);
    signal phase_with_offset : unsigned(lut_addr'range);
    
begin
    phase_with_offset <= lut_addr + POW_IN;
    
    NCO_UNIT : entity work.NCO
        generic map(
            FTW_WIDTH => FTW_WIDTH,
            PHASE_WIDTH => PHASE_WIDTH
        )
        port map(
            CLK => CLK,
            RST_n => RST_n,
            ENABLE => ENABLE,
            FTW_IN => FTW_IN,
            OUT_SQ => OUT_SQ,
            PHASE_OUT => lut_addr
        );
    
    SINE_UNIT : entity work.quarter_sine
        generic map(
            PHASE_WIDTH => PHASE_WIDTH,
            AMP_WIDTH => AMP_WIDTH 
        )
        port map(
            CLK => CLK,
            ADDR => phase_with_offset,
            SINE_OUT => SINE_OUT
        );
        
end Behavioral;
