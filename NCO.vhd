library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity NCO is
    generic(
        FTW_WIDTH : natural := 32;
        PHASE_WIDTH : natural := 10
    );
    Port ( CLK : in STD_LOGIC;
           RST_n : in STD_LOGIC;
           ENABLE : in STD_LOGIC;
           FTW_IN : in unsigned(FTW_WIDTH-1 downto 0);
           OUT_SQ : out std_logic;
           PHASE_OUT     : out unsigned(PHASE_WIDTH-1 downto 0) := (others => '0') -- DDS/NCO phase out for LUT.
           );
           -- Example: For f_clk=100 MHz, FTW_WIDTH=32:
           -- FTW_IN = round(f_out / 100e6 * 2^32)
end NCO;

architecture Behavioral of NCO is
    signal ftw : unsigned(FTW_IN'range); -- Frequency Tuning Word signal
    signal phase_acc : unsigned(ftw'range) := (others => '0');
    
begin
    ftw <= FTW_IN;
    
    process(CLK)
    begin
        if rising_edge(CLK) then                        
            if RST_n = '0' or ENABLE = '0' then
                phase_acc <= (others => '0');
            else
                phase_acc <= phase_acc + resize(ftw, FTW_WIDTH);
            end if;
        end if;
    end process;
    
    -- Outputs.
    OUT_SQ    <= std_logic(phase_acc(FTW_WIDTH-1)); -- MSB of phase_acc in order to produce a square wave of FTW duration
    PHASE_OUT <= phase_acc(phase_acc'high downto phase_acc'length - PHASE_WIDTH); -- For extern LUT/CORDIC.

end Behavioral;
