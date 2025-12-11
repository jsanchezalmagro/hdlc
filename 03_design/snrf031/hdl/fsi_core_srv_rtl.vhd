-- ----------------------------------------------------------------------------
--! Library       : snrf031
--! Entity        : fsi_core_srv
--! Lenguaje      : VHDL-2008
-- ---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsi_core_srv is
   generic( 
      g_version  : std_logic_vector(31 downto 0);
      g_add_size : integer := 16
   );
   port( 
      ProcAddr    : in     std_logic_vector (g_add_size-1 downto 0);  -- !! adresse mot et non octet
      ProcCs      : in     std_logic;
      ProcDataIn  : in     std_logic_vector (31 downto 0);
      ProcRNW     : in     std_logic;                                 -- read/not write
      clk         : in     std_logic;
      rst_n       : in     std_logic;                                 -- System reset
      rx_cpld     : in     std_logic;                                 -- Received signal
      ProcDataOut : out    std_logic_vector (31 downto 0);
      ProcRdAck   : out    std_logic;
      ProcWrAck   : out    std_logic;
      tm_1        : out    std_logic;
      tm_2        : out    std_logic
   );

-- Declarations

end entity fsi_core_srv ;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


architecture rtl of fsi_core_srv is

   -- Architecture declarations

   -- Internal signal declarations
   signal rx_data       : std_logic_vector(7 downto 0);     -- Byte received
   signal rx_error      : std_logic;                        -- Byte received with parity error, pulse active to '1'
   signal rx_parity_cfg : std_logic_vector(1 downto 0);     -- "00" is not bit parity, "11" is even bit parity, "10" is odd bit parity
   signal rx_rate_cfg   : std_logic_vector(12 downto 0);    -- Baud Rate = Frecuency_clk / n
   signal rx_rdy        : std_logic;                        -- Byte received without error, pulse active to '1'
   signal rx_stop_cfg   : std_logic;                        -- to '0' 1 bit stop, to '1' 2 bits stop
   signal tm_data_1     : std_logic_vector(7 downto 0);
   signal tm_data_2     : std_logic_vector(7 downto 0);
   signal tm_enable     : std_logic;


   signal readback: std_logic_vector(31 downto 0);

   signal ProcCs_dly: std_logic;

   signal tm_1_2: std_logic;

   signal cnt: unsigned(15 downto 0);

   -- Component Declarations
   component fsi_core_srv_rxcpld
   port (
      clk           : in     std_logic ;                    -- System clock
      rst_n         : in     std_logic ;                    -- System reset
      rx            : in     std_logic ;                    -- Received signal
      rx_parity_cfg : in     std_logic_vector (1 downto 0); -- "00" is not bit parity, "11" is even bit parity, "10" is odd bit parity
      rx_rate_cfg   : in     std_logic_vector ;             -- Baud Rate = Frecuency_clk / n
      rx_stop_cfg   : in     std_logic ;                    -- to '0' 1 bit stop, to '1' 2 bits stop
      rx_data       : out    std_logic_vector (7 downto 0); -- Byte received
      rx_error      : out    std_logic ;                    -- Byte received with parity error, pulse active to '1'
      rx_rdy        : out    std_logic                      -- Byte received without error, pulse active to '1'
   );
   end component fsi_core_srv_rxcpld;


begin
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 1 p_srv
   -- -----------------------------------------------------------------------------
   -- p_srv
   -- -----------------------------------------------------------------------------
   p_proc : process (clk, rst_n)
   begin
       if rst_n = '0' then
           ProcDataOut <= (others => '0');
           readback    <= (others => '0');
           ProcCs_dly  <= '0';
           ProcWrAck   <= '0';
           ProcRdAck   <= '0';
           tm_enable   <= '0';
   
       elsif rising_edge(clk) then
           ProcCs_dly <= ProcCs;
           if (unsigned(ProcAddr) = 0 and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '0') then
               readback  <= ProcDataIn;
               ProcWrAck <= '1';
           elsif (unsigned(ProcAddr) = 0 and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '1') then
               ProcDataOut <= readback;
               ProcRdAck   <= '1';
           elsif (unsigned(ProcAddr) = 4 and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '1') then
               ProcDataOut <= g_version;
               ProcRdAck   <= '1';
           elsif (unsigned(ProcAddr) = 8 and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '0') then
               tm_enable <= ProcDataIn(0);
               ProcWrAck <= '1';
           elsif (unsigned(ProcAddr) = 8 and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '1') then
               ProcDataOut <= X"0000" & tm_data_2 & tm_data_1;
               ProcRdAck   <= '1';
           else
               ProcWrAck <= '0';
               ProcRdAck <= '0';
           end if;
   
       end if;
   end process p_proc;
   -- -----------------------------------------------------------------------------

   -- HDL Embedded Text Block 2 p_tm
   -- -----------------------------------------------------------------------------
   -- p_srv
   -- -----------------------------------------------------------------------------
   p_tm_ctrl : process (clk, rst_n)
   
       constant c_tm_start : unsigned(15 downto 0) := to_unsigned(1, 16);
       constant c_tm_stop  : unsigned(15 downto 0) := to_unsigned(8, 16);
       constant c_max      : unsigned(15 downto 0) := to_unsigned (49999, 16); -- 1 msec
   begin
       if rst_n = '0' then
           cnt    <= (others => '0');
           tm_1   <= '0';
           tm_2   <= '0';
           tm_1_2 <= '0';
   
       elsif rising_edge(clk) then
   
           if (tm_enable = '0') then
               cnt    <= (others => '0');
               tm_1   <= '0';
               tm_2   <= '0';
               tm_1_2 <= '0';
   
           elsif (cnt = c_tm_start) then
               cnt    <= cnt + 1;
               tm_1   <= not(tm_1_2);
               tm_2   <= tm_1_2;
               tm_1_2 <= not(tm_1_2);
   
           elsif (cnt = c_tm_stop) then
               cnt  <= cnt + 1;
               tm_1 <= '0';
               tm_2 <= '0';
   
           elsif (cnt = c_max) then
               cnt <= (others => '0');
   
           end if;
   
       end if;
   end process p_tm_ctrl;
   -- -----------------------------------------------------------------------------
   --
   -- ------------------------------------------------------------------------------
   p_tm : process (clk, rst_n)
   begin
       if (rst_n = '0') then
           tm_data_1 <= (others => '0');
           tm_data_2 <= (others => '0');
   
       elsif rising_edge(clk) then
           if (tm_1_2 = '1' and rx_rdy = '1') then
               tm_data_1 <= rx_data;
           end if;
   
           if (tm_1_2 = '0' and rx_rdy = '1') then
               tm_data_2 <= tm_data_2;
           end if;
   
       end if;
   end process;
   -- ------------------------------------------------------------------------------
   -- 1 stop bits, 9600 baud (50.000.000 / 9600 = 5208.3333), even parity
   rx_stop_cfg   <= '0';
   rx_rate_cfg   <= std_logic_vector(to_unsigned(5208 + 1, rx_rate_cfg'length));
   rx_parity_cfg <= "11";
   -- ------------------------------------------------------------------------------
   


   -- Instance port mappings.
   i_uart : fsi_core_srv_rxcpld
      port map (
         clk           => clk,
         rst_n         => rst_n,
         rx            => rx_cpld,
         rx_parity_cfg => rx_parity_cfg,
         rx_rate_cfg   => rx_rate_cfg,
         rx_stop_cfg   => rx_stop_cfg,
         rx_data       => rx_data,
         rx_error      => rx_error,
         rx_rdy        => rx_rdy
      );

end architecture rtl;

-- ----------------------------------------------------------------------------