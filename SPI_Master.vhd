library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity spi_master is
  generic(
    data_length : integer := 16);
  port(
    clk     : in      std_logic;
    reset_n : in      std_logic;
    enable  : in      std_logic;
    cpol    : in      std_logic;
    cpha    : in      std_logic;
    miso    : in      std_logic;
    sclk    : out     std_logic;
    ss_n    : out     std_logic;
    mosi    : out     std_logic;
    busy    : out     std_logic;
    tx      : in      std_logic_vector(data_length-1 downto 0);
    rx      : out     std_logic_vector(data_length-1 downto 0));
end spi_master;

architecture behavioural of spi_master is
  type fsm is (init, execute);
  signal state           : fsm;                                 
  signal receive_transmit : std_logic;
  signal clk_toggles : integer range 0 to data_length*2 + 1;
  signal last_bit    : integer range 0 to data_length*2;
  signal rxbuffer    : std_logic_vector(data_length-1 downto 0) := (others => '0'); 
  signal txbuffer    : std_logic_vector(data_length-1 downto 0) := (others => '0'); 
  signal int_ss_n    : std_logic;
  signal int_sclk    : std_logic;

begin

  ss_n <= int_ss_n;
  sclk <= int_sclk;
  
  process(clk, reset_n)
  begin

    if(reset_n = '0') then        
      busy <= '1';                
      int_ss_n <= '1';            
      mosi <= '0';         
      rx <= (others => '0');      
      state <= init;              

    elsif(falling_edge(clk)) then
      case state is               

        when init =>
          busy <= '0';             
          int_ss_n <= '1';          
          mosi <= '0';      
   
          if(enable = '1') then
            busy <= '1';             
            int_sclk <= cpol;        
            receive_transmit <= not cpha; 
            txbuffer <= tx;         
            clk_toggles <= 0;        
            last_bit <= data_length*2 + conv_integer(cpha) - 1; 
            state <= execute;        
          else
            state <= init;          
          end if;

        when execute =>
          busy <= '1';               
          int_ss_n <= '0';            
          receive_transmit <= not receive_transmit;  
          
          if(clk_toggles = data_length*2 + 1) then
            clk_toggles <= 0;                        
          else
            clk_toggles <= clk_toggles + 1;         
          end if;
            
          if(clk_toggles <= data_length*2 and int_ss_n = '0') then 
            int_sclk <= not int_sclk; 
          end if;
            
          if(receive_transmit = '0' and clk_toggles < last_bit + 1 and int_ss_n = '0') then 
            rxbuffer <= rxbuffer(data_length-2 downto 0) & miso; 
          end if;
            
          if(receive_transmit = '1' and clk_toggles < last_bit) then 
            mosi <= txbuffer(data_length-1);                        
            txbuffer <= txbuffer(data_length-2 downto 0) & '0'; 
          end if;
            
          if(clk_toggles = data_length*2 + 1) then   
            busy <= '0';             
            int_ss_n <= '1';         
            mosi <= '0';     
            rx <= rxbuffer;    
            state <= init;          
          else                       
            state <= execute;        
          end if;
      end case;
    end if;
  end process; 
end behavioural;