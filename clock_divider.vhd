library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clk_divider is
    Generic (
        -- 54 MHz / 1 MHz = 54. 
        DIVIDE_BY : integer := 54 
    );
    Port (
        clk_in  : in  std_logic;  -- PLL output
        reset_n : in  std_logic;  -- Reset (Active Low)
        clk_out : out std_logic   -- SPI clock
    );
end clk_divider;

architecture Behavioral of clk_divider is
    signal counter : integer range 0 to DIVIDE_BY := 0;
    signal tmp_clk : std_logic := '0';
begin
    process(clk_in, reset_n)
    begin
        if reset_n = '0' then
            counter <= 0;
            tmp_clk <= '0';
        elsif rising_edge(clk_in) then

            if counter = (DIVIDE_BY/2) - 1 then
                tmp_clk <= not tmp_clk;
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;


    clk_out <= tmp_clk;
end Behavioral;