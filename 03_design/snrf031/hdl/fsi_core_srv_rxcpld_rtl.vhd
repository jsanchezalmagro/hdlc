-- ----------------------------------------------------------------------------
--! Library       : snrf031
--! Entity        : fsi_core_srv_rxcpld
--! Lenguaje      : VHDL-2008
-- ---------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
--! @brief        : Uart receptor 
--!
--! @details      : Serial receiver
--!                       Baudrate configurable
--!                       8 bits
--!                       Parity : odd, even or none
--!                       Stop bit :1 or 2 bits.
-- ----------------------------------------------------------------------------
-- Date      Author Version Change-Description
-- 01/01/21  JSA    1.0     Initial  
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsi_core_srv_rxcpld is
   port( 
      clk           : in     std_logic;                      -- System clock
      rst_n         : in     std_logic;                      -- System reset
      rx            : in     std_logic;                      -- Received signal
      rx_parity_cfg : in     std_logic_vector (1 downto 0);  -- "00" is not bit parity, "11" is even bit parity, "10" is odd bit parity
      rx_rate_cfg   : in     std_logic_vector;               -- Baud Rate = Frecuency_clk / n
      rx_stop_cfg   : in     std_logic;                      -- to '0' 1 bit stop, to '1' 2 bits stop
      rx_data       : out    std_logic_vector (7 downto 0);  -- Byte received
      rx_error      : out    std_logic;                      -- Byte received with parity error, pulse active to '1'
      rx_rdy        : out    std_logic                       -- Byte received without error, pulse active to '1'
   );

-- Declarations

end entity fsi_core_srv_rxcpld ;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


architecture rtl of fsi_core_srv_rxcpld is

   -- Architecture declarations

   -- Internal signal declarations
   signal dbit      : std_logic;    -- Received bit
   signal rx_bit    : std_logic;    -- Reception lock
   signal rx_lock   : std_logic;    -- Reception lock
   signal rx_parity : std_logic;    -- Internal data ready flag
   signal rx_stop   : std_logic;    -- Reception lock
   signal start_bit : std_logic;    -- Start bit signal
   signal tick_bit  : std_logic;    -- Sample signal


   signal rx_delay1 : std_logic; -- Delay the rx imput, to do triple voting
   signal rx_delay2 : std_logic; -- Delay the rx imput, to do triple voting
   signal rx_delay3 : std_logic; -- Delay the rx imput, to do triple voting

   signal rx_cnt_bit : std_logic_vector(3 downto 0); -- Bit counter
   signal cnt_rate :  std_logic_vector(rx_rate_cfg'range); -- Clock divisor

   signal parity : std_logic; -- Parity bit calcultated and registered
   signal tmp_parity : std_logic; -- Parity bit calcultated


begin
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 2 p_baudrate
   -- --------------------------------------------------------------------------
   -- Generation of reception frequency
   -- --------------------------------------------------------------------------
   p_rx_rate : process (rst_n, clk)
   
      constant c_zero : std_logic_vector(cnt_rate'range) := conv_std_logic_vector(0, cnt_rate'length);
      constant c_one  : std_logic_vector(cnt_rate'range) := conv_std_logic_vector(1, cnt_rate'length);
   
   begin
      if (rst_n = '0') then
         cnt_rate <= c_zero;
         tick_bit <= '0';
   
      elsif rising_edge(clk) then
   
         if (start_bit = '1') then
            cnt_rate <= '0' & rx_rate_cfg(cnt_rate'high downto 1);
            tick_bit <= '0';
   
         elsif (cnt_rate = c_one) then
            cnt_rate <= cnt_rate - c_one;
            tick_bit <= '1';
   
         elsif (cnt_rate = c_zero) then
            cnt_rate <= rx_rate_cfg;
            tick_bit <= '0';
         else
            cnt_rate <= cnt_rate - c_one;
            tick_bit <= '0';
   
         end if;
      end if;
   
   end process p_rx_rate;
   -- --------------------------------------------------------------------------

   -- HDL Embedded Text Block 3 p_detect
   ----------------------------------------------------------------------------
   -- Detection of a new reception
   ----------------------------------------------------------------------------
   p_start_bit_detect : process (rst_n, clk)
   begin
      if (rst_n = '0') then
         rx_lock <= '0';
   
      elsif rising_edge(clk) then
   
         if (start_bit = '1') then
            rx_lock <= '1';
         elsif (rx_stop = '1') then
            rx_lock <= '0';
         end if;
   
      end if;
   end process p_start_bit_detect;
   
   ----------------------------------------------------------------------------
   -- Detection of ending of a reception
   -- Start (with start_bit)
   -- Sample = 8 data + 1/0 parity + 1/2 stop
   ----------------------------------------------------------------------------
   process (rst_n, clk)
   
      constant c_zero : std_logic_vector(rx_cnt_bit'range) := conv_std_logic_vector(0, rx_cnt_bit'length);
      constant c_one  : std_logic_vector(rx_cnt_bit'range) := conv_std_logic_vector(1, rx_cnt_bit'length);
      constant c_7    : std_logic_vector(rx_cnt_bit'range) := conv_std_logic_vector(7, rx_cnt_bit'length);
      constant c_8    : std_logic_vector(rx_cnt_bit'range) := conv_std_logic_vector(8, rx_cnt_bit'length);
      constant c_9    : std_logic_vector(rx_cnt_bit'range) := conv_std_logic_vector(9, rx_cnt_bit'length);
   begin
      if (rst_n = '0') then
         rx_cnt_bit <= c_zero;
         rx_bit     <= '0';
         rx_parity  <= '0';
         rx_stop    <= '0';
   
      elsif clk'event and clk = '1' then
   
         -- Detect bit and end of RX
         if (rx_lock = '0') then
            rx_cnt_bit <= c_zero;
            rx_bit     <= '0';
            rx_stop    <= '0';
   
         elsif (tick_bit = '1' and rx_cnt_bit = c_zero) then
            rx_cnt_bit <= rx_cnt_bit + c_one;
   
         elsif (tick_bit = '1' and rx_cnt_bit = c_8 and rx_parity_cfg(1) = '0') then
            rx_cnt_bit <= rx_cnt_bit + c_one;
            rx_bit     <= '1';
            rx_stop    <= '1';
   
         elsif (tick_bit = '1' and rx_cnt_bit = c_9 and rx_parity_cfg(1) = '1') then
            rx_cnt_bit <= rx_cnt_bit + c_one;
            rx_stop    <= '1';
   
         elsif (tick_bit = '1') then
            rx_cnt_bit <= rx_cnt_bit + c_one;
            rx_bit     <= '1';
   
         else
            rx_stop <= '0';
            rx_bit  <= '0';
         end if;
   
         -- Detect the parity bit
         if (tick_bit = '1' and rx_cnt_bit = c_9) then
            rx_parity <= '1';
         else
            rx_parity <= '0';
         end if;
   
      end if;
   end process;
   -- ------------------------------------------------------------------------------

   -- HDL Embedded Text Block 5 p_sampling
   --------------------------------------------------------------------------------
   -- Sampling the line three times, and triple voting
   --------------------------------------------------------------------------------
   p_sampling : process (rst_n, clk)
   begin
      if (rst_n = '0') then
         rx_delay1 <= '0';
         rx_delay2 <= '0';
         rx_delay3 <= '0';
         dbit      <= '0';
         start_bit <= '0';
   
      elsif clk'event and clk = '1' then
   
         rx_delay1 <= rx;
         rx_delay2 <= rx_delay1;
         rx_delay3 <= rx_delay2;
         dbit      <= (rx_delay1 and rx_delay2) or (rx_delay1 and rx_delay3) or (rx_delay2 and rx_delay3);
         if (rx_lock = '1') then
            start_bit <= '0';
         else
            start_bit <= not(rx_delay2) and rx_delay3;
         end if;
   
      end if;
   end process p_sampling;
   --------------------------------------------------------------------------------

   -- HDL Embedded Text Block 7 p_data
   -- ------------------------------------------------------------------------------
   -- Conversion from serial to parallel data
   -- ------------------------------------------------------------------------------
   p_parallel_to_serial : process (rst_n, clk)
   begin
   
      if (rst_n = '0') then
         rx_data <= (others => '0');
   
      elsif rising_edge(clk) then
   
         if (rx_bit = '1') then
            rx_data <= dbit & rx_data(7 downto 1);
         end if;
   
      end if;
   
   end process p_parallel_to_serial;
   -- ------------------------------------------------------------------------------
   -- Detect the end of transmission
   ---------------------------------------------------------------------------------
   p_rx_end : process (rst_n, clk)
   begin
   
      if (rst_n = '0') then
         rx_rdy   <= '0';
         rx_error <= '0';
   
      elsif rising_edge(clk) then
   
         if (rx_stop = '1') then
            rx_rdy <= '1';
            if (rx_parity_cfg(1) = '1') then
               rx_error <= tmp_parity;
            else
               rx_error <= '0';
            end if;
         else
            rx_rdy <= '0';
         end if;
   
      end if;
   
   end process p_rx_end;
   -- ------------------------------------------------------------------------------
   -- Calculate the even parity
   -- ------------------------------------------------------------------------------
   p_rx_parity : process (rst_n, clk)
   begin
   
      if (rst_n = '0') then
         parity <= '0';
   
      elsif rising_edge(clk) then
   
         if (start_bit = '1') then
            parity <= rx_parity_cfg(0);
         elsif (rx_bit = '1' or rx_parity = '1') then
            parity <= tmp_parity;
         end if;
   
      end if;
   
   end process p_rx_parity;
   -- ------------------------------------------------------------------------------
   tmp_parity <= (parity xor dbit);
   -- ------------------------------------------------------------------------------


   -- Instance port mappings.

end architecture rtl;

-- ----------------------------------------------------------------------------