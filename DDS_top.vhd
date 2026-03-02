library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DDS_top is    
    Port ( CLK           : in STD_LOGIC;
           RST_n         : in STD_LOGIC;
           BIT_IN        : in STD_LOGIC;
           SYM_STB       : in std_logic;
           PHASE_SYNC_en : in std_logic;
           OUT_SQ        : out std_logic;
           LEDs          : out std_logic_vector(3 downto 0);
           SINE_OUT      : out signed(9 downto 0)
           );
end DDS_top;

architecture Behavioral of DDS_top is
    component NCO
        generic(
            PHASE_BITS : natural := 32;
            -- Frequency tuning words (FTW)
            F1_INC     : unsigned(31 downto 0) := TO_UNSIGNED( 450_972, 32); -- FTW used for f1 (10.5 KHz)
            F2_INC     : unsigned(31 downto 0) := TO_UNSIGNED( 408_022, 32)  -- FCW used for f2 (9.5 KHz)
            -- F1_INC     : unsigned(31 downto 0) := TO_UNSIGNED(  858993, 32); -- FTW used for f1 (30 KHz)
            -- F2_INC     : unsigned(31 downto 0) := TO_UNSIGNED( 1288490, 32)  -- FCW used for f2 (20 KHz)
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
    end component;
    
    component quarter_sine
        generic(
            ADDR_BITS : natural := 10; -- Phase bits
            AMP_BITS  : natural := 10  -- Amplitude bits
        );
        
        Port ( CLK : in STD_LOGIC;
               ADDR : in unsigned(ADDR_BITS-1 downto 0);      -- Addresing bits comes from phase accumulator
               SINE_OUT : out signed(AMP_BITS-1 downto 0));
    end component;
    
    constant PHASE_BITS : natural := 32;
    constant ADDR_BITS : natural := 10;
    constant AMP_BITS : natural := 10;
    signal acc_addr : unsigned(PHASE_BITS-1 downto 0); 
    
begin

    NCO_unit : NCO
        generic map(
            PHASE_BITS => PHASE_BITS,
            F1_INC => TO_UNSIGNED( 450_972, 32),
            F2_INC => TO_UNSIGNED( 408_022, 32)
        )
        port map(
            CLK => CLK,
            RST_n => RST_n,
            BIT_IN => BIT_IN,
            SYM_STB => SYM_STB,
            PHASE_SYNC_en => PHASE_SYNC_en,
            OUT_SQ => OUT_SQ,
            PHASE_OUT => acc_addr,
            LEDs => LEDs
        );
    
    sine_unit : quarter_sine
        generic map(
            ADDR_BITS => ADDR_BITS,
            AMP_BITS => AMP_BITS
        )
        port map(
            CLK => CLK,
            ADDR => acc_addr(acc_addr'high downto acc_addr'length - ADDR_BITS),
            SINE_OUT => SINE_OUT
        );
end Behavioral;
