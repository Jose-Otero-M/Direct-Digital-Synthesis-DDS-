library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity NCO is
    generic(
        PHASE_BITS : natural := 32;
        -- Frequency tuning words (FTW)
        F1_INC     : unsigned(31 downto 0) := TO_UNSIGNED(   858_993, 32); -- FTW used for f1 (30 KHz)
        F2_INC     : unsigned(31 downto 0) := TO_UNSIGNED( 1_288_490, 32)  -- FCW used for f2 (20 KHz)
        -- Example: For f_clk=100 MHz, PHASE_BITS=32:
        -- FTW = round(f_out / 100e6 * 2^32)
    );
    Port (
        CLK           : in std_logic;     -- DDS/NCO system clock.
        RST_n         : in std_logic;     -- Active low reset signal.
        BIT_IN        : in std_logic;     -- Bit to transmit.
        SYM_STB       : in std_logic;     -- Strobe always '1' when starts a symbol (1 clk of duration).
        PHASE_SYNC_en : in std_logic;     -- '1' => Reset phase for each symbol.
        OUT_SQ        : out std_logic;    -- DDS MSB.
        PHASE_OUT     : out unsigned(PHASE_BITS-1 downto 0) := (others => '0'); -- DDS/NCO phase out for LUT.
        LEDs          : out std_logic_vector(3 downto 0)
    );
end NCO;

architecture Behavioral of NCO is
    
    signal phase_acc : unsigned(PHASE_BITS-1 downto 0) := (others => '0');
    signal ftw_selected   : unsigned(phase_acc'range);
    signal sym_stb_d : std_logic := '0';
    signal sym_rise  : std_logic := '0';
    
begin
    -- MUX for the increment word depending of the bit to transmit
    ftw_selected <= F1_INC when BIT_IN = '1' else F2_INC;
    
    -- Estrobe rising edge detector (here we make sure that strobe has always the correct 1 clk duration).
    process(CLK)
    begin
        if rising_edge(CLK) then
            sym_stb_d <= SYM_STB;
            sym_rise <= SYM_STB and not sym_stb_d;
        end if;
    end process;
    
    -- Phase Accumulator (DDS/NCO)
    process(clk)
    begin
        if rising_edge(CLK) then
            if RST_n = '0' then
                phase_acc <= (others => '0');
            else
                -- If we want that every symbol starts in a known phase (0):
                if (PHASE_SYNC_en = '1') and (sym_rise = '1') then
                    phase_acc <= (others => '0');
                else
                    phase_acc <= phase_acc + resize(ftw_selected, PHASE_BITS);
                end if;
            end if;
        end if;
    end process;
    
    -- Outputs.
    OUT_SQ    <= std_logic(phase_acc(PHASE_BITS-1)); -- MSB square wave of DDS/NCO
    PHASE_OUT <= phase_acc;     -- For extern LUT/CORDIC
    
    
    LEDs(3) <= RST_n;
    LEDs(2) <= PHASE_SYNC_en;
    LEDs(1) <= SYM_STB;
    LEDs(0) <= BIT_IN;
    
end Behavioral;
