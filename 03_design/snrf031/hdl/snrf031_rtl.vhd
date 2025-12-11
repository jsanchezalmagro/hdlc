-- ----------------------------------------------------------------------------
--! Library       : snrf031
--! Entity        : snrf031
--! Lenguaje      : VHDL-2008
-- ---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity snrf031 is
   generic( 
      g_fpga_number : integer range 0 to 255 := 31;
      g_fpga_mayor  : integer range 0 to 31  := 1;
      g_fpga_minor  : integer range 0 to 31  := 0;
      g_fpga_rev    : integer range 0 to 255 := 0
   );
   port( 
      RXN                 : in     std_logic;
      -- GTX Serial I/O
      RXP                 : in     std_logic;
      clk_aurora_n        : in     std_ulogic  := '1';
      clk_aurora_p        : in     std_ulogic  := '0';
      clk_eth_p           : in     std_logic;
      clk_p               : in     std_logic;
      dds_sdio_1          : in     std_logic;
      dds_sdio_2          : in     std_logic;
      mii_rx_clk          : in     std_logic   := '0';
      mii_rx_col          : in     std_logic;
      mii_rx_crs          : in     std_logic;
      mii_rx_data         : in     std_logic_vector (3 downto 0);
      mii_rx_dv           : in     std_logic;
      mii_rx_er           : in     std_logic;
      mii_tx_clk          : in     std_logic;
      reset_n             : in     std_logic;
      rgmii_rx_clk        : in     std_logic   := '0';
      rgmii_rx_ctl        : in     std_logic;
      rgmii_rx_data       : in     std_logic_vector (3 downto 0);
      rs422_1_in          : in     std_logic;
      TXN                 : out    std_logic;
      TXP                 : out    std_logic;
      dds_cs_n            : out    std_logic;
      dds_ioupdate        : out    std_logic;
      dds_pwr_dwn         : out    std_logic;                      -- Power down DDS
      dds_rst             : out    std_logic;                      -- Reset DDS
      dds_sclk            : out    std_logic;
      dds_sdio_0          : out    std_logic;
      dds_sdio_3          : out    std_logic;
      ------------------------------
      -- Interface Ethernet SMI	--
      ------------------------------
      mii_mdc             : out    std_logic;
      mii_rst_n           : out    std_logic;
      mii_tx_data         : out    std_logic_vector (3 downto 0);
      mii_tx_en           : out    std_logic;
      pw_dw_clk_adc_bot_n : out    std_logic;
      pw_dw_clk_adc_top_n : out    std_logic;
      pw_dw_clk_dac_bot_n : out    std_logic;
      pw_dw_clk_dac_top_n : out    std_logic;
      pw_dw_ref_fre_rx_n  : out    std_logic;
      pw_dw_ref_fre_tx_n  : out    std_logic;
      rgmii_cfg           : out    std_logic;
      ------------------------------
      -- Interface Ethernet SMI	--
      ------------------------------
      rgmii_mdc           : out    std_logic;
      rgmii_rst_n         : out    std_logic;
      rgmii_tx_clk        : out    std_logic;
      rgmii_tx_ctl        : out    std_logic;
      rgmii_tx_data       : out    std_logic_vector (3 downto 0);
      rs422_1_de          : out    std_logic;
      rs422_1_halfduplex  : out    std_logic;
      rs422_1_out         : out    std_logic;
      rs422_1_re_n        : out    std_logic;
      rs422_1_rxp         : out    std_logic;
      rs422_1_srl         : out    std_logic;
      rs422_1_txp         : out    std_logic;
      data_n              : inout  std_logic;
      data_p              : inout  std_logic;
      mii_md              : inout  std_logic;
      rgmii_md            : inout  std_logic;
      strobe_n            : inout  std_logic;
      strobe_p            : inout  std_logic;
      temp_scl            : inout  std_logic;
      temp_sda            : inout  std_logic
   );

-- Declarations

end entity snrf031 ;

-- ----------------------------------------------------------------------------
--! @class snrf031
--! @image html symbol_sbsnrf031.png
--! @author Alicia Bermejo
--! @version 1.0
--! @date 16/06/2023
--!
--! @brief 
--!  Complete FSI FPGA
--!
--! @details
--!  Serial Communication for the telecommands and telemetries
--!  Ethernet Interface
--!  Aurora Communications with the FTS FPGA
--! Features:
--! 1.  FSI FPGA
--!
--! Limitations:
--! 1.  
--! 
--! Module performances
--! 1.   Frequency: 
--! 1.1. System Clock (Clk): 50 MHz
--! 1.2. Ethernet Clock (tx_clk): 25 MHz
--! 1.3. Reference Clock (Clk_dly): 200 MHz
--! 1.4 Aurora Clock (Clk_aurora): 125 MHz
--! 2.   Resources: 
--!
--! @class snrf031.rtl
--! @image html rtl_bdsnrf031.png
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library ipx_pll_eth;
library ipx_pll_sys;

-- synthesis translate_off
library unisim;
library secureip;
use unisim.vpkg.all;
-- synthesis translate_on


architecture rtl of snrf031 is

   -- Architecture declarations
   ------------------------------------------------------------------------
   --         ILA core compiler-specific attributes
   ------------------------------------------------------------------------ 
   attribute box_type      : string;
   attribute syn_black_box   : boolean;
   attribute syn_noprune   : boolean;
   
   constant c_add_size: integer := 16;
   constant c_slave_bus_size: integer := 4;

   -- Internal signal declarations
   signal ProcAddr    : std_logic_vector(19 downto 0);    -- !! adresse mot et non octet
   signal ProcCs      : std_logic;
   signal ProcDataIn  : std_logic_vector(31 downto 0);
   signal ProcDataOut : std_logic_vector(31 downto 0);
   signal ProcRNW     : std_logic;                        -- read/not write
   signal ProcRdAck   : std_logic;
   signal ProcWrAck   : std_logic;
   signal ceb         : std_ulogic;
   signal clk         : std_logic;
   signal clk_200mhz  : std_logic;
   signal clk_aurora  : std_ulogic;
   signal clk_eth     : std_logic;
   signal rst         : std_logic;
   signal rst_n       : std_logic;

   -- Implicit buffer signal declarations
   signal rs422_1_out_internal : std_logic;


   signal rst_d1: std_logic;
   signal rst_d2: std_logic;

   -- Component Declarations
   component ipx_pll_eth_virtex6_wrapper
   port (
      clk     : in     std_logic ;
      rst_n   : in     std_logic ;
      clk_eth : out    std_logic ;
      locked  : out    std_logic 
   );
   end component ipx_pll_eth_virtex6_wrapper;
   component ipx_pll_sys_virtex6_wrapper
   port (
      clk        : in     std_logic ;
      rst_n      : in     std_logic ;
      clk_200mhz : out    std_logic ;
      clk_50mhz  : out    std_logic ;
      locked     : out    std_logic 
   );
   end component ipx_pll_sys_virtex6_wrapper;
   component fsi_core
   generic (
      g_add_size       : integer                := 16;
      g_slave_bus_size : integer                := 4;
      g_fpga_mayor     : integer range 0 to 31  := 0;
      g_fpga_minor     : integer range 0 to 31  := 0;
      g_fpga_number    : integer range 0 to 255 := 31;
      g_fpga_rev       : integer range 0 to 255 := 1
   );
   port (
      ProcAddr            : in     std_logic_vector (g_add_size+g_slave_bus_size-1 downto 0); -- 63 adresse max.
      ProcCs              : in     std_logic ;
      ProcDataIn          : in     std_logic_vector (31 downto 0);
      ProcRNW             : in     std_logic ;
      RXN                 : in     std_logic ;
      -- GTX Serial I/O
      RXP                 : in     std_logic ;
      clk                 : in     std_logic ;
      clk_aurora          : in     std_ulogic  := '0';
      clk_dly             : in     std_logic ;
      clk_eth             : in     std_logic ;
      dds_sdio_1          : in     std_logic ;
      dds_sdio_2          : in     std_logic ;
      mii_rx_clk          : in     std_logic   := '0';
      mii_rx_col          : in     std_logic ;
      mii_rx_crs          : in     std_logic ;
      mii_rx_data         : in     std_logic_vector (3 downto 0);
      mii_rx_dv           : in     std_logic ;
      mii_rx_er           : in     std_logic ;
      mii_tx_clk          : in     std_logic ;
      rgmii_rx_clk        : in     std_logic   := '0';
      rgmii_rx_ctl        : in     std_logic ;
      rgmii_rx_data       : in     std_logic_vector (3 downto 0);
      rst_n               : in     std_logic ;
      ProcDataOut         : out    std_logic_vector (31 downto 0);
      ProcRdAck           : out    std_logic ;
      ProcWrAck           : out    std_logic ;
      TXN                 : out    std_logic ;
      TXP                 : out    std_logic ;
      dds_cs_n            : out    std_logic ;
      dds_ioupdate        : out    std_logic ;
      dds_pwr_dwn         : out    std_logic ;                                                -- Power down DDS
      dds_rst             : out    std_logic ;                                                -- Reset DDS
      dds_sclk            : out    std_logic ;
      dds_sdio_0          : out    std_logic ;
      dds_sdio_3          : out    std_logic ;
      ------------------------------
      -- Interface Ethernet SMI	--
      ------------------------------
      mii_mdc             : out    std_logic ;
      mii_rst_n           : out    std_logic ;
      mii_tx_data         : out    std_logic_vector (3 downto 0);
      mii_tx_en           : out    std_logic ;
      pw_dw_clk_adc_bot_n : out    std_logic ;
      pw_dw_clk_adc_top_n : out    std_logic ;
      pw_dw_clk_dac_bot_n : out    std_logic ;
      pw_dw_clk_dac_top_n : out    std_logic ;
      pw_dw_ref_fre_rx_n  : out    std_logic ;
      pw_dw_ref_fre_tx_n  : out    std_logic ;
      rgmii_cfg           : out    std_logic ;
      ------------------------------
      -- Interface Ethernet SMI	--
      ------------------------------
      rgmii_mdc           : out    std_logic ;
      rgmii_rst_n         : out    std_logic ;
      rgmii_tx_clk        : out    std_logic ;
      rgmii_tx_ctl        : out    std_logic ;
      rgmii_tx_data       : out    std_logic_vector (3 downto 0);
      data_n              : inout  std_logic ;
      data_p              : inout  std_logic ;
      mii_md              : inout  std_logic ;
      rgmii_md            : inout  std_logic ;
      strobe_n            : inout  std_logic ;
      strobe_p            : inout  std_logic ;
      temp_scl            : inout  std_logic ;
      temp_sda            : inout  std_logic 
   );
   end component fsi_core;
   component fsi_tmtc
   generic (
      g_add_size       : integer := 16;
      g_slave_bus_size : integer := 4
   );
   port (
      ProcDataOut : in     std_logic_vector (31 downto 0);
      ProcRdAck   : in     std_logic ;
      ProcWrAck   : in     std_logic ;
      clk         : in     std_logic ;
      rs422_1_in  : in     std_logic ;
      rst_n       : in     std_logic ;                                                -- System reset
      ProcAddr    : out    std_logic_vector (g_add_size+g_slave_bus_size-1 downto 0); -- !! adresse mot et non octet
      ProcCs      : out    std_logic ;
      ProcDataIn  : out    std_logic_vector (31 downto 0);
      ProcRNW     : out    std_logic ;                                                -- read/not write
      rs422_1_out : out    std_logic 
   );
   end component fsi_tmtc;
   component IBUFDS_GTXE1
   generic (
      CLKCM_CFG     : boolean    := TRUE;
      CLKRCV_TRST   : boolean    := TRUE;
      REFCLKOUT_DLY : bit_vector := b"0000000000"
   );
   port (
      CEB   : in     std_ulogic;
      I     : in     std_ulogic;
      IB    : in     std_ulogic;
      O     : out    std_ulogic;
      ODIV2 : out    std_ulogic
   );
   end component IBUFDS_GTXE1;
   component IDELAYCTRL
   port (
      REFCLK : in     std_ulogic;
      RST    : in     std_ulogic;
      RDY    : out    std_ulogic
   );
   end component IDELAYCTRL;


begin
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 3 p_rs422_1
   -- p_mon_top MAX3079EESD
   rs422_1_re_n       <= '0'; -- Enable recieiver
   rs422_1_rxp        <= '0'; -- Not invert polariry for receiver
   rs422_1_halfduplex <= '0'; -- Select full duplex
   rs422_1_txp        <= '0'; -- Not invert polartity for transmit
   rs422_1_de         <= '1'; -- Enable transmit
   rs422_1_srl        <= '0'; -- LSlew rate limit selection

   -- HDL Embedded Text Block 9 p_gnd
   -- p_fsi_pad
   ceb <= '0'; 
   


   -- ModuleWare code(v1.12) for instance 'i_1' of 'inv'
   rst <= not(rst_n);

   -- Instance port mappings.
   i_pll_eth : ipx_pll_eth_virtex6_wrapper
      port map (
         clk     => clk_eth_p,
         rst_n   => reset_n,
         clk_eth => clk_eth,
         locked  => open
      );
   i_pll_sys : ipx_pll_sys_virtex6_wrapper
      port map (
         clk        => clk_p,
         rst_n      => reset_n,
         clk_200mhz => clk_200mhz,
         clk_50mhz  => clk,
         locked     => rst_n
      );
   i_core : fsi_core
      generic map (
         g_add_size       => c_add_size,
         g_slave_bus_size => c_slave_bus_size,
         g_fpga_mayor     => g_fpga_mayor,
         g_fpga_minor     => g_fpga_minor,
         g_fpga_number    => g_fpga_number,
         g_fpga_rev       => g_fpga_rev
      )
      port map (
         ProcAddr            => ProcAddr,
         ProcCs              => ProcRNW,
         ProcDataIn          => ProcDataIn,
         ProcRNW             => ProcCs,
         RXN                 => RXN,
         RXP                 => RXP,
         clk                 => clk,
         clk_aurora          => clk_aurora,
         clk_dly             => clk_200mhz,
         clk_eth             => clk_eth,
         dds_sdio_1          => dds_sdio_1,
         dds_sdio_2          => dds_sdio_2,
         mii_rx_clk          => mii_rx_clk,
         mii_rx_col          => mii_rx_col,
         mii_rx_crs          => mii_rx_crs,
         mii_rx_data         => mii_rx_data,
         mii_rx_dv           => mii_rx_dv,
         mii_rx_er           => mii_rx_er,
         mii_tx_clk          => mii_tx_clk,
         rgmii_rx_clk        => rgmii_rx_clk,
         rgmii_rx_ctl        => rgmii_rx_ctl,
         rgmii_rx_data       => rgmii_rx_data,
         rst_n               => rst_n,
         ProcDataOut         => ProcDataOut,
         ProcRdAck           => ProcRdAck,
         ProcWrAck           => ProcWrAck,
         TXN                 => TXN,
         TXP                 => TXP,
         dds_cs_n            => dds_cs_n,
         dds_ioupdate        => dds_ioupdate,
         dds_pwr_dwn         => dds_pwr_dwn,
         dds_rst             => dds_rst,
         dds_sclk            => dds_sclk,
         dds_sdio_0          => dds_sdio_0,
         dds_sdio_3          => dds_sdio_3,
         mii_mdc             => mii_mdc,
         mii_rst_n           => mii_rst_n,
         mii_tx_data         => mii_tx_data,
         mii_tx_en           => mii_tx_en,
         pw_dw_clk_adc_bot_n => pw_dw_clk_adc_bot_n,
         pw_dw_clk_adc_top_n => pw_dw_clk_adc_top_n,
         pw_dw_clk_dac_bot_n => pw_dw_clk_dac_bot_n,
         pw_dw_clk_dac_top_n => pw_dw_clk_dac_top_n,
         pw_dw_ref_fre_rx_n  => pw_dw_ref_fre_rx_n,
         pw_dw_ref_fre_tx_n  => pw_dw_ref_fre_tx_n,
         rgmii_cfg           => rgmii_cfg,
         rgmii_mdc           => rgmii_mdc,
         rgmii_rst_n         => rgmii_rst_n,
         rgmii_tx_clk        => rgmii_tx_clk,
         rgmii_tx_ctl        => rgmii_tx_ctl,
         rgmii_tx_data       => rgmii_tx_data,
         data_n              => data_n,
         data_p              => data_p,
         mii_md              => mii_md,
         rgmii_md            => rgmii_md,
         strobe_n            => strobe_n,
         strobe_p            => strobe_p,
         temp_scl            => temp_scl,
         temp_sda            => temp_sda
      );
   i_tmtc : fsi_tmtc
      generic map (
         g_add_size       => c_add_size,
         g_slave_bus_size => c_slave_bus_size
      )
      port map (
         ProcDataOut => ProcDataOut,
         ProcRdAck   => ProcRdAck,
         ProcWrAck   => ProcWrAck,
         clk         => clk,
         rs422_1_in  => rs422_1_in,
         rst_n       => rst_n,
         ProcAddr    => ProcAddr,
         ProcCs      => ProcRNW,
         ProcDataIn  => ProcDataIn,
         ProcRNW     => ProcCs,
         rs422_1_out => rs422_1_out_internal
      );
   i_gt : IBUFDS_GTXE1
      generic map (
         CLKCM_CFG     => TRUE,
         CLKRCV_TRST   => TRUE,
         REFCLKOUT_DLY => b"0000000000"
      )
      port map (
         O     => clk_aurora,
         ODIV2 => open,
         CEB   => ceb,
         I     => clk_aurora_p,
         IB    => clk_aurora_n
      );
   i_ctrl : IDELAYCTRL
      port map (
         RDY    => open,
         REFCLK => clk_200mhz,
         RST    => rst
      );

   -- Implicit buffered output assignments
   rs422_1_out <= rs422_1_out_internal;

end architecture rtl;

-- ----------------------------------------------------------------------------