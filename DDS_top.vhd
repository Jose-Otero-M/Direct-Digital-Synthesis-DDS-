library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity DDS is
    generic(
        FTW_WIDTH : natural := 32;
        ADDR_BITS : natural := 10;
        AMP_BITS  : natural := 10
    );
    Port ( CLK      : in STD_LOGIC;
           RST_n    : in STD_LOGIC;
           ENABLE   : in STD_LOGIC;
           FTW_IN   : in unsigned(FTW_WIDTH-1 downto 0);
           OUT_SQ   : out std_logic;
           SINE_OUT : out signed(AMP_BITS-1 downto 0) := (others => '0') -- DDS/NCO phase out for LUT.
           );
           -- Example: For f_clk=100 MHz, FTW_WIDTH=32:
           -- FTW_IN = round(f_out / 100e6 * 2^32)
end DDS;

architecture Behavioral of DDS is
    signal phase_addr : unsigned(ADDR_BITS-1 downto 0);
    
begin
    NCO_UNIT : entity work.NCO
        generic map(
            FTW_WIDTH => FTW_WIDTH,
            ADDR_BITS => ADDR_BITS
        )
        port map(
            CLK => CLK,
            RST_n => RST_n,
            ENABLE => ENABLE,
            FTW_IN => FTW_IN,
            OUT_SQ => OUT_SQ,
            PHASE_OUT => phase_addr
        );
    
    SINE_UNIT : entity work.quarter_sine
        generic map(
            ADDR_BITS => ADDR_BITS,
            AMP_BITS => AMP_BITS 
        )
        port map(
            CLK => CLK,
            ADDR => phase_addr,
            SINE_OUT => SINE_OUT
        );
        
end Behavioral;
