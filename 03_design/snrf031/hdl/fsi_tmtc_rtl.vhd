-- ----------------------------------------------------------------------------
--! Library       : snrf031
--! Entity        : fsi_tmtc
--! Lenguaje      : VHDL-2008
-- ---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsi_tmtc is
   generic( 
      g_add_size       : integer := 16;
      g_slave_bus_size : integer := 4
   );
   port( 
      ProcDataOut : in     std_logic_vector (31 downto 0);
      ProcRdAck   : in     std_logic;
      ProcWrAck   : in     std_logic;
      clk         : in     std_logic;
      rs422_1_in  : in     std_logic;
      rst_n       : in     std_logic;                                                  -- System reset
      ProcAddr    : out    std_logic_vector (g_add_size+g_slave_bus_size-1 downto 0);  -- !! adresse mot et non octet
      ProcCs      : out    std_logic;
      ProcDataIn  : out    std_logic_vector (31 downto 0);
      ProcRNW     : out    std_logic;                                                  -- read/not write
      rs422_1_out : out    std_logic
   );

-- Declarations

end entity fsi_tmtc ;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ip_sdebug;
use ip_sdebug.ip_sdebug_pkg.all;

library proc;


architecture rtl of fsi_tmtc is

   -- Architecture declarations

   -- Internal signal declarations
   signal ProcAddr_up   : std_logic_vector(31 downto 0) := (others=>'0');    -- !! adresse mot et non octet
   signal ProcCs_up     : std_logic                     := '0';
   signal ProcDataIn_up : std_logic_vector(31 downto 0) := (others=>'0');
   signal ProcRNW_up    : std_logic                     := '0';              -- read/not write
   signal ack           : std_logic;
   signal cmd_add       : std_logic_vector(31 downto 0);
   signal cmd_rdata     : std_logic_vector(31 downto 0);                     -- Word to be stored at FIFO
   signal cmd_wdata     : std_logic_vector(31 downto 0);
   signal rd            : std_logic;
   signal sdebug_rx     : std_logic;                                         -- Received signal
   signal sdebug_tx     : std_logic;
   signal sdebug_txen   : std_logic;
   signal wr            : std_logic;

   -- Implicit buffer signal declarations
   signal rs422_1_out_internal : std_logic;


   signal busy: std_logic; -- Indicate access in progress
   signal sel_sdebug: std_logic; -- Select the debug interface

   -- Component Declarations
   component ip_sdebug
   generic (
      g_reset_polarity : std_logic             := '0';       --! Reset active  polarity
      g_parity_cfg     : std_logic_vector      := "00";      --! Parity, '00' is null, '10' is even and '11'is odd
      g_rate_cfg       : positive              := 125;       --! Rate configuration, baudrate = clk_frequency
      g_stop_cfg       : std_logic             := '1';       --! Number of stop bit '0'  is 1 and '1' is 2
      g_data_size      : positive              := 32;        -- Data size 8/16/32
      g_incr_add       : positive              := 1;         -- the increment vsalue for address in mode buffer and Fifo
      g_hw_add         : integer range 0 to 15 := 0          -- Module hardware add used in Daisy Chain
   );
   port (
      ack         : in     std_logic ;
      clk         : in     std_logic ;
      cmd_wdata   : in     std_logic_vector (g_data_size-1 downto 0);
      reset_n     : in     std_logic ;                                -- System reset
      sdebug_rx   : in     std_logic ;                                -- Received signal
      cmd_add     : out    std_logic_vector (31 downto 0);
      cmd_rdata   : out    std_logic_vector (g_data_size-1 downto 0); -- Word to be stored at FIFO
      rd          : out    std_logic ;
      sdebug_tx   : out    std_logic ;
      sdebug_txen : out    std_logic ;
      wr          : out    std_logic 
   );
   end component ip_sdebug;
   component proc
   generic (
      g_add_size : integer := 16
   );
   port (
      ProcClk     : in     std_logic                                := '0';
      ProcDataOut : in     std_logic_vector (31 downto 0)           := (others=>'0');
      ProcRdAck   : in     std_logic                                := '0';
      ProcRstN    : in     std_logic ;
      ProcWrAck   : in     std_logic                                := '0';
      ProcAddr    : out    std_logic_vector (g_add_size-1 downto 0) := (others=>'0'); -- !! adresse mot et non octet
      ProcCs      : out    std_logic                                := '0';
      ProcDataIn  : out    std_logic_vector (31 downto 0)           := (others=>'0');
      ProcRNW     : out    std_logic                                := '0'            -- read/not write
   );
   end component proc;


begin
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 1 p_proc
   -- -----------------------------------------------------------------------------                                       
   cmd_wdata <= ProcDataOut;
   ack       <= (ProcRdAck or ProcWrAck) and sel_sdebug;
   -- -----------------------------------------------------------------------------
   -- Generate the PrpcCs and ProcRnW signals based on the command signals
   -- -----------------------------------------------------------------------------
   p_access : process (clk, rst_n)
   begin
      if (rst_n = '0') then
         ProcAddr   <= (others => '0');
         ProcDataIn <= (others => '0');
         ProcCs     <= '0';
         ProcRnW    <= '0';
         busy       <= '0';
         sel_sdebug <= '0';
      elsif rising_edge(clk) then
   
         if ((wr = '1' or rd = '1') and busy = '0') then
            sel_sdebug <= '1'; -- Select the sdebug for access
            busy       <= '1';
            ProcAddr   <= cmd_add(ProcAddr'range);
            ProcDataIn <= cmd_rdata(ProcDataIn'range);
            ProcCs     <= '1';
            ProcRnW    <= rd; -- Write operation
   
         elsif (ProcCs_up = '1' and busy = '0') then
            sel_sdebug <= '0'; -- Select the processor for access
            busy       <= '1';
            ProcAddr   <= ProcAddr_up(ProcAddr'range);
            ProcDataIn <= ProcDataIn_up(ProcDataIn'range);
            ProcCs     <= '1';
            ProcRnW    <= ProcRnW_up; -- Write operation         
         elsif (ProcRdAck = '1' or ProcWrAck = '1') then
            ProcCs <= '0'; -- Clear chip select after acknowledge
            busy   <= '0';
         end if;
   
      end if;
   end process p_access;
   -- -----------------------------------------------------------------------------

   -- HDL Embedded Text Block 2 p_mux
   -- p_mux
   sdebug_rx    <= rs422_1_in;
   rs422_1_out_internal  <= sdebug_tx;
   


   -- Instance port mappings.
   i_sdebug : ip_sdebug
      generic map (
         g_reset_polarity => '0',                                  --! Reset active  polarity
         g_parity_cfg     => "00",                                 --! Parity, '00' is null, '10' is even and '11'is odd
         g_rate_cfg       => 50,                                   --! Rate configuration, baudrate = clk_frequency
         g_stop_cfg       => '1',                                  --! Number of stop bit '0'  is 1 and '1' is 2
         g_data_size      => 32,                                   -- Data size 8/16/32
         g_incr_add       => 4,                                    -- the increment vsalue for address in mode buffer and Fifo
         g_hw_add         => 0                                     -- Module hardware add used in Daisy Chain
      )
      port map (
         ack         => ack,
         clk         => clk,
         cmd_wdata   => cmd_wdata,
         reset_n     => rst_n,
         sdebug_rx   => sdebug_rx,
         cmd_add     => cmd_add,
         cmd_rdata   => cmd_rdata,
         rd          => rd,
         sdebug_tx   => sdebug_tx,
         sdebug_txen => sdebug_txen,
         wr          => wr
      );
   i_proc : proc
      generic map (
         g_add_size => 32
      )
      port map (
         ProcClk     => clk,
         ProcDataOut => ProcDataOut,
         ProcRdAck   => ProcRdAck,
         ProcRstN    => rst_n,
         ProcWrAck   => ProcWrAck,
         ProcAddr    => ProcAddr_up,
         ProcCs      => ProcCs_up,
         ProcDataIn  => ProcDataIn_up,
         ProcRNW     => ProcRNW_up
      );

   -- Implicit buffered output assignments
   rs422_1_out <= rs422_1_out_internal;

end architecture rtl;

-- ----------------------------------------------------------------------------