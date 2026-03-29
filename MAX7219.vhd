library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MAX7219_Top is
    Port ( 
        clk_in_raw : in  std_logic;
        reset_n    : in  std_logic;
        sclk       : out std_logic;
        ss_n       : out std_logic;
        mosi       : out std_logic 
    );
end MAX7219_Top;

architecture Behavioral of MAX7219_Top is

    signal clk_54mhz : std_logic;
    signal clk_1mhz  : std_logic;
    signal spi_en    : std_logic := '0';
    signal spi_tx    : std_logic_vector(15 downto 0);
    signal spi_busy  : std_logic;

    type STATE_TYPE is (ST_IDLE, ST_INIT_SHUTDOWN, ST_INIT_SCAN, ST_INIT_DECODE, 
                        ST_INIT_BRIGHT, ST_CLEAN_ALL, ST_SHOW_DATA, ST_WAIT);
    signal state      : STATE_TYPE := ST_IDLE;
    signal next_state : STATE_TYPE := ST_IDLE; 

    signal clean_cnt  : integer range 1 to 9 := 1;
    signal wait_timer : integer range 0 to 10000 := 0;
------------------------------------------------------------
     constant onesec : integer := 54_000_000 - 1;
     signal   counter : integer range 0 to onesec := 0;
     signal select_val     : integer range 1 to 8 := 1;
     signal   binary_counter : unsigned(7 downto 0) := (others => '0'); 
------------------------------------------------------------
begin

    -- PLL: 27MHz to 54MHz
    U_PLL: entity work.Gowin_rPLL
        port map ( clkin => clk_in_raw, clkout => clk_54mhz );

    U_DIV: entity work.clk_divider       -- 1MHZ SPI SCLK
        generic map ( DIVIDE_BY => 54 ) 
        port map ( clk_in => clk_54mhz, reset_n => reset_n, clk_out => clk_1mhz );

    U_SPI: entity work.spi_master
        generic map ( data_length => 16 )
        port map (
            clk => clk_1mhz, reset_n => reset_n, enable => spi_en,
            cpol => '0', cpha => '0', miso => '0',
            sclk => sclk, ss_n => ss_n, mosi => mosi,
            busy => spi_busy, tx => spi_tx, rx => open
        );

    process(clk_1mhz, reset_n)
    begin
        if reset_n = '0' then
            state <= ST_IDLE;
            spi_en <= '0';
            clean_cnt <= 1;
            wait_timer <= 0;
            next_state <= ST_IDLE;
        elsif rising_edge(clk_1mhz) then

            case state is
                
                when ST_IDLE =>
                    state <= ST_INIT_SHUTDOWN;

                when ST_INIT_SHUTDOWN =>
                    if spi_busy = '0' then
                        spi_tx <= x"0C01"; 
                        spi_en <= '1';
                        next_state <= ST_INIT_SCAN;
                        state  <= ST_WAIT;
                    end if;

                when ST_INIT_SCAN =>
                    if spi_busy = '0' then
                        spi_tx <= x"0B07"; 
                        spi_en <= '1';
                        next_state <= ST_INIT_DECODE;
                        state  <= ST_WAIT;
                    end if;

                when ST_INIT_DECODE =>
                    if spi_busy = '0' then
                        spi_tx <= x"09FF";
                        spi_en <= '1';
                        next_state <= ST_INIT_BRIGHT;
                        state  <= ST_WAIT;
                    end if;

                when ST_INIT_BRIGHT =>
                    if spi_busy = '0' then
                        spi_tx <= x"0A05";
                        spi_en <= '1';
                        next_state <= ST_CLEAN_ALL;
                        state  <= ST_WAIT;
                    end if;

                when ST_CLEAN_ALL =>
                    if spi_busy = '0' then

                        spi_tx <= std_logic_vector(to_unsigned(clean_cnt, 8)) & x"0F";
                        spi_en <= '1';
                        
                        if clean_cnt < 8 then
                            clean_cnt <= clean_cnt + 1;
                            next_state <= ST_CLEAN_ALL;
                        else
                            next_state <= ST_SHOW_DATA;
                        end if;

                        state <= ST_WAIT;
                    end if;

                when ST_SHOW_DATA =>
                       if spi_busy = '0' then
        
                           if (binary_counter < to_unsigned(2**(select_val-1), 8)) and (select_val > 1) then
                               spi_tx <= std_logic_vector(to_unsigned(select_val, 8)) & x"0F";
                           else
                               if binary_counter(select_val-1) = '1' then
                                   spi_tx <= std_logic_vector(to_unsigned(select_val, 8)) & x"01";
                               else
                                   spi_tx <= std_logic_vector(to_unsigned(select_val, 8)) & x"00";
                               end if;
                           end if;

                           spi_en <= '1';
                           if select_val < 8 then
                               select_val <= select_val + 1;
                           else
                               select_val <= 1;
                           end if;

        next_state <= ST_SHOW_DATA;
        state <= ST_WAIT;
    end if;

                when ST_WAIT => 
                    spi_en <= '0'; 
                    if spi_busy = '0' then

                        if wait_timer < 1000 then 
                            wait_timer <= wait_timer + 1;
                        else
                            wait_timer <= 0;
                            state <= next_state; 
                        end if;
                    end if;

                when others =>
                    state <= ST_IDLE;
            end case;
        end if;
    end process;

----------------------------------------------------------------------------
timer_process : process(clk_54mhz, reset_n)
begin

     if rising_edge(clk_54mhz) then
        if (counter = onesec) then
            counter <= 0;
            binary_counter <= binary_counter + 1;
        else
            counter <= counter + 1;
        end if;
    end if;
end process;

---------------------------------------------------------------------------------


end Behavioral;