-- ----------------------------------------------------------------------------
--! Library       : snrf031
--! Entity        : fsi_core_eth
--! Lenguaje      : VHDL-2008
-- ---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsi_core_eth is
   generic( 
      g_add_size : integer := 13
   );
   port( 
      MiiCol            : in     std_logic;
      MiiCrs            : in     std_logic;
      MiiDv             : in     std_logic;
      MiiEr             : in     std_logic;
      MiiRxc            : in     std_logic;
      MiiRxd            : in     STD_LOGIC_VECTOR (3 downto 0);
      MiiTxc            : in     std_logic;
      ProcAddr_mii      : in     std_logic_vector (g_add_size-1 downto 0);  -- 63 adresse max.
      ProcAddr_rgmii    : in     std_logic_vector (g_add_size-1 downto 0);  -- 63 adresse max.
      ProcCs_mii        : in     std_logic;
      ProcCs_rgmii      : in     std_logic;
      ProcDataIn_mii    : in     std_logic_vector (31 downto 0);
      ProcDataIn_rgmii  : in     std_logic_vector (31 downto 0);
      ProcRNW_mii       : in     std_logic;
      ProcRNW_rgmii     : in     std_logic;
      RgmiiRxCtl        : in     std_logic;
      RgmiiRxc          : in     std_logic;
      RgmiiRxd          : in     std_logic_vector (3 downto 0);
      clk               : in     std_logic;
      clk_dly           : in     std_logic;
      eth_rx_enable     : in     std_logic;
      eth_rx_sel        : in     std_logic;
      eth_tx_enable     : in     std_logic;
      eth_tx_sel        : in     std_logic;
      m_tx_tready       : in     std_logic;
      rst_n             : in     std_logic;
      s_rx_tdata        : in     std_logic_vector (7 downto 0);             --! Word read from memory
      s_rx_tlast        : in     std_logic;
      s_rx_tvalid       : in     std_logic;                                 --! AXI-S master interface, valid
      tx_clk            : in     std_logic;
      MiiTxEn           : out    std_logic;
      MiiTxd            : out    std_logic_vector (3 downto 0);
      ------------------------------
      -- Interface Ethernet SMI	--
      ------------------------------
      Mii_Mdc           : out    std_logic;
      ProcDataOut_mii   : out    std_logic_vector (31 downto 0);
      ProcDataOut_rgmii : out    std_logic_vector (31 downto 0);
      ProcRdAcq_mii     : out    std_logic;
      ProcRdAcq_rgmii   : out    std_logic;
      ProcWrAcq_mii     : out    std_logic;
      ProcWrAcq_rgmii   : out    std_logic;
      ------------------------------
      -- Interface Ethernet SMI	--
      ------------------------------
      RGMii_Mdc         : out    std_logic;
      RgmiiTxCtl        : out    std_logic;
      RgmiiTxc          : out    std_logic;
      RgmiiTxd          : out    std_logic_vector (3 downto 0);
      m_tx_tdata        : out    std_logic_vector (7 downto 0);             --! Word read from memory
      m_tx_tlast        : out    std_logic;
      m_tx_tvalid       : out    std_logic;                                 --! AXI-S master interface, valid
      mii_rst_n         : out    std_logic;
      rgmii_cfg         : out    std_logic;
      rgmii_rst_n       : out    std_logic;
      s_rx_tready       : out    std_logic;
      Mii_Md            : inout  std_logic;
      RGMii_Md          : inout  std_logic
   );

-- Declarations

end entity fsi_core_eth ;

-- ----------------------------------------------------------------------------
--! @class fsi_core_eth
--! @image html symbol_sbfsi_core_eth.png
--! @author Alicia Bermejo
--! @version 1.0
--! @date 20/06/2024
--!
--! @brief 
--!     Module for Ethernet Interface
--!
--! @details
--!    This module receives the Ethernet frames using one of the two physical connectors 
--!     RGMII or MII, and transmits Ethernet frames to the following module.
--!
--! Requirements
--!    SEN-WB-WF1-HW-324
--!    SEN-WB-WF1-HW-608
--!    SEN-WB-WF1-HW-609
--!    SEN-WB-WF1-HW-322
--!    SEN-WB-WF1-HW-325
--!    SEN-WB-WF1-HW-477
--!    SEN-WB-WF1-HW-612
--!    SEN-WB-WF1-HW-613
--!    SEN-WB-WF1-HW-478
--!    SEN-WB-WF1-HW-614
--!
--! Features:
--! 1. FSI FPGA
--! 2. Protocol RMII: 10Mbps or 100Mbps
--! 3. Protocol MII: 10Mbps or 100Mbps
--! 4. MDI modules are used to configure the physical Ethernet chips
--!
--! Limitations:
--! 1.  Depending on the selected profile, one Ethernet interface is active
--! 
--! Module performances
--! 1.   Frequency: 
--! 1.1. System Clock (Clk): 50 MHz
--! 1.2. Ethernet Clock (tx_clk): 25 MHz
--! 1.3. Reference Clock (Clk_dly): 200 MHz
--!      
--! 2.   Resources: 
--!
--! @class fsi_core_eth.rtl
--! @image html rtl_bdfsi_core_eth.png
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;


architecture rtl of fsi_core_eth is

   -- Architecture declarations

   -- Internal signal declarations
   signal enable_rx  : std_logic;
   signal enable_tx  : std_logic;
   signal m_tdata    : std_logic_vector(7 downto 0);    --! Word read from memory
   signal m_tlast    : std_logic;
   signal m_tready   : std_logic;
   signal m_tvalid   : std_logic;                       --! AXI-S master interface, valid
   signal s_tdata    : std_logic_vector(7 downto 0);
   signal s_tlast    : std_logic;
   signal s_tready   : std_logic;
   signal s_tvalid   : std_logic;
   signal sel_eth_rx : std_logic;
   signal sel_eth_tx : std_logic;


   -- Component Declarations
   component fsi_core_eth_mdio
   generic (
      g_add_size : integer := 0      -- ProcAddr Bus size, default is 13 bits
   );
   port (
      clk         : in     std_logic ;
      rst_n       : in     std_logic ;
      ProcDataIn  : in     std_logic_vector (31 downto 0);
      ProcDataOut : out    std_logic_vector (31 downto 0);
      ProcCs      : in     std_logic ;
      ProcAddr    : in     std_logic_vector (g_add_size-1 downto 0);
      ProcRNW     : in     std_logic ;
      ProcWrAcq   : out    std_logic ;
      ProcRdAcq   : out    std_logic ;
      Mdc         : out    std_logic ;                             -- mdio clk (2.5Mhz)
      Md          : inout  std_logic ;                             -- mdio data (tristate buffer)
      chip_rst_n  : out    std_logic ;
      chip_cfg    : out    std_logic 
   );
   end component fsi_core_eth_mdio;
   component fsi_core_eth_rx
   port (
      MiiCol     : in     std_logic ;
      MiiCrs     : in     std_logic ;
      MiiDv      : in     std_logic ;
      MiiEr      : in     std_logic ;
      MiiRxc     : in     std_logic ;
      MiiRxd     : in     STD_LOGIC_VECTOR (3 downto 0);
      RgmiiRxCtl : in     std_logic ;
      RgmiiRxc   : in     std_logic ;
      RgmiiRxd   : in     std_logic_vector (3 downto 0);
      clk        : in     std_logic ;
      clk_dly    : in     std_logic ;
      enable     : in     std_logic ;
      m_tready   : in     std_logic ;
      rst_n      : in     std_logic ;
      sel_eth    : in     std_logic ;
      m_tdata    : out    std_logic_vector (7 downto 0); --! Word read from memory
      m_tlast    : out    std_logic ;
      m_tvalid   : out    std_logic                      --! AXI-S master interface, valid
   );
   end component fsi_core_eth_rx;
   component fsi_core_eth_tx
   port (
      MiiTxc     : in     std_logic ;
      clk        : in     std_logic ;
      clk_dly    : in     std_logic ;
      clk_eth    : in     std_logic ;
      enable     : in     std_logic ;
      rst_n      : in     std_logic ;
      s_tdata    : in     std_logic_vector (7 downto 0);
      s_tlast    : in     std_logic ;
      s_tvalid   : in     std_logic ;
      sel_eth    : in     std_logic ;
      MiiTxEn    : out    std_logic ;
      MiiTxd     : out    std_logic_vector (3 downto 0);
      RgmiiTxCtl : out    std_logic ;
      RgmiiTxc   : out    std_logic ;
      RgmiiTxd   : out    std_logic_vector (3 downto 0);
      s_tready   : out    std_logic 
   );
   end component fsi_core_eth_tx;


begin
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 1 p_mux_impl
   -- ----------------------------------------------------------------------------
   -- p_mux
   -- ----------------------------------------------------------------------------
   m_tx_tdata  <= m_tdata when (eth_tx_enable = '1') else (others => '0');
   m_tx_tvalid <= m_tvalid when (eth_tx_enable = '1') else '0';
   m_tx_tlast  <= m_tlast when (eth_tx_enable = '1') else '0';
   m_tready    <= m_tx_tready when (eth_tx_enable = '1') else '0';
   -- ----------------------------------------------------------------------------
   s_tdata     <= s_rx_tdata when (eth_rx_enable = '1') else (others => '0');
   s_tvalid    <= s_rx_tvalid when (eth_rx_enable = '1') else '0';
   s_tlast     <= s_rx_tlast when (eth_rx_enable = '1') else '0';
   s_rx_tready <= s_tready when (eth_rx_enable = '1') else '0';
   -- ----------------------------------------------------------------------------
   enable_rx  <= eth_tx_enable;
   sel_eth_rx <= eth_tx_enable and eth_tx_sel;
   enable_tx  <= eth_rx_enable;
   sel_eth_tx <= eth_rx_enable and eth_rx_sel;
   -- ----------------------------------------------------------------------------


   -- Instance port mappings.
   --  declaration de l'entite
   --
   --  declaration de l'entite
   --
   --  declaration de l'entite
   --
   --  declaration de l'entite
   --
   --  declaration de l'entite
   -- 
   --  declaration de l'entite
   -- 
   i_mdio_mii : fsi_core_eth_mdio
      generic map (
         g_add_size => g_add_size                             -- ProcAddr Bus size, default is 13 bits
      )
      port map (
         clk         => clk,
         rst_n       => rst_n,
         ProcDataIn  => ProcDataIn_mii,
         ProcDataOut => ProcDataOut_mii,
         ProcCs      => ProcCs_mii,
         ProcAddr    => ProcAddr_mii,
         ProcRNW     => ProcRNW_mii,
         ProcWrAcq   => ProcWrAcq_mii,
         ProcRdAcq   => ProcRdAcq_mii,
         Mdc         => Mii_Mdc,
         Md          => Mii_Md,
         chip_rst_n  => mii_rst_n,
         chip_cfg    => open
      );
   --  declaration de l'entite
   --
   --  declaration de l'entite
   --
   --  declaration de l'entite
   --
   --  declaration de l'entite
   --
   --  declaration de l'entite
   -- 
   --  declaration de l'entite
   -- 
   i_mdio_rgmii : fsi_core_eth_mdio
      generic map (
         g_add_size => g_add_size                             -- ProcAddr Bus size, default is 13 bits
      )
      port map (
         clk         => clk,
         rst_n       => rst_n,
         ProcDataIn  => ProcDataIn_rgmii,
         ProcDataOut => ProcDataOut_rgmii,
         ProcCs      => ProcCs_rgmii,
         ProcAddr    => ProcAddr_rgmii,
         ProcRNW     => ProcRNW_rgmii,
         ProcWrAcq   => ProcWrAcq_rgmii,
         ProcRdAcq   => ProcRdAcq_rgmii,
         Mdc         => RGMii_Mdc,
         Md          => RGMii_Md,
         chip_rst_n  => rgmii_rst_n,
         chip_cfg    => rgmii_cfg
      );
   i_eth_rx : fsi_core_eth_rx
      port map (
         MiiCol     => MiiCol,
         MiiCrs     => MiiCrs,
         MiiDv      => MiiDv,
         MiiEr      => MiiEr,
         MiiRxc     => MiiRxc,
         MiiRxd     => MiiRxd,
         RgmiiRxCtl => RgmiiRxCtl,
         RgmiiRxc   => RgmiiRxc,
         RgmiiRxd   => RgmiiRxd,
         clk        => clk,
         clk_dly    => clk_dly,
         enable     => enable_rx,
         m_tready   => m_tready,
         rst_n      => rst_n,
         sel_eth    => sel_eth_rx,
         m_tdata    => m_tdata,
         m_tlast    => m_tlast,
         m_tvalid   => m_tvalid
      );
   i_eth_tx : fsi_core_eth_tx
      port map (
         MiiTxc     => MiiTxc,
         clk        => clk,
         clk_dly    => clk_dly,
         clk_eth    => tx_clk,
         enable     => enable_tx,
         rst_n      => rst_n,
         s_tdata    => s_tdata,
         s_tlast    => s_tlast,
         s_tvalid   => s_tvalid,
         sel_eth    => sel_eth_tx,
         MiiTxEn    => MiiTxEn,
         MiiTxd     => MiiTxd,
         RgmiiTxCtl => RgmiiTxCtl,
         RgmiiTxc   => RgmiiTxc,
         RgmiiTxd   => RgmiiTxd,
         s_tready   => s_tready
      );

end architecture rtl;

-- ----------------------------------------------------------------------------