-- ----------------------------------------------------------------------------
--! Library       : snrf031
--! Entity        : fsi_core_eth_rx
--! Lenguaje      : VHDL-2008
-- ---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsi_core_eth_rx is
   port( 
      MiiCol     : in     std_logic;
      MiiCrs     : in     std_logic;
      MiiDv      : in     std_logic;
      MiiEr      : in     std_logic;
      MiiRxc     : in     std_logic;
      MiiRxd     : in     STD_LOGIC_VECTOR (3 downto 0);
      RgmiiRxCtl : in     std_logic;
      RgmiiRxc   : in     std_logic;
      RgmiiRxd   : in     std_logic_vector (3 downto 0);
      clk        : in     std_logic;
      clk_dly    : in     std_logic;
      enable     : in     std_logic;
      m_tready   : in     std_logic;
      rst_n      : in     std_logic;
      sel_eth    : in     std_logic;
      m_tdata    : out    std_logic_vector (7 downto 0);  --! Word read from memory
      m_tlast    : out    std_logic;
      m_tvalid   : out    std_logic                       --! AXI-S master interface, valid
   );

-- Declarations

end entity fsi_core_eth_rx ;

-- ----------------------------------------------------------------------------
--! @class fsi_core_eth_rx
--! @image html symbol_sbfsi_core_eth_rx.png
--! @author Alicia Bermejo
--! @version 1.0
--! @date 20/06/2024
--!
--! @brief 
--!     Multiplexer to select the Ethernet protocol in the receiver module: RGMII or MII
--!
--! @details
--!    This module receives Ethernet frames using the RGMII or the MII interface.
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
--! 1. Protocol RGMII: 10Mbps or 100Mbps
--! 2. Protocol MII: 10Mbps or 100Mbps
--!
--! Limitations:
--! 1.  Depending on the selected profile, one Ethernet interface is active
--! 
--! Module performances
--! 1.   Frequency: 
--! 1.1. System Clock (Clk): 50 MHz
--! 1.2. Reference Clock (Clk_dly): 200 MHz
--!      
--! 2.   Resources: 
--!
--! @class fsi_core_eth_rx.rtl
--! @image html rtl_bdfsi_core_eth_rx.png
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library ip_rgmii;
library ip_mii;

library implementation_i;
use implementation_i.implementation_i_pkg.all;


architecture rtl of fsi_core_eth_rx is

   -- Architecture declarations

   -- Internal signal declarations
   signal mii_tdata    : std_logic_vector(7 downto 0);    --! Word read from memory
   signal mii_tlast    : std_logic;
   signal mii_tready   : STD_LOGIC;
   signal mii_tvalid   : std_logic;                       --! AXI-S master interface, valid
   signal rgmii_tdata  : STD_LOGIC_VECTOR(7 downto 0);
   signal rgmii_tlast  : STD_LOGIC;
   signal rgmii_tready : STD_LOGIC;
   signal rgmii_tvalid : std_logic;


   -- Component Declarations
   component ip_mii_rx100mb
   port (
      clk      : in     STD_LOGIC ;
      enable   : in     std_logic ;                  -- -! Transimision clock received from the external rgmii chip
      m_tready : in     STD_LOGIC ;
      rst_n    : in     std_logic ;
      rxc      : in     std_logic ;
      rxcol    : in     std_logic ;
      rxcrs    : in     std_logic ;
      rxd      : in     std_logic_vector (3 downto 0);
      rxdv     : in     std_logic ;
      rxer     : in     std_logic ;
      m_tdata  : out    STD_LOGIC_VECTOR (7 downto 0);
      m_tlast  : out    STD_LOGIC ;
      m_tvalid : out    STD_LOGIC 
   );
   end component ip_mii_rx100mb;
   component ip_rgmii_rx100mb
   port (
      clk      : in     STD_LOGIC ;
      clk_dly  : in     std_logic ;
      enable   : in     std_logic ;                  -- -! Transimision clock received from the external rgmii chip
      m_tready : in     STD_LOGIC ;
      rst_n    : in     std_logic ;
      rxc      : in     std_logic ;
      rxctl    : in     std_logic ;
      rxd      : in     std_logic_vector (3 downto 0);
      m_tdata  : out    STD_LOGIC_VECTOR (7 downto 0);
      m_tlast  : out    STD_LOGIC ;
      m_tvalid : out    STD_LOGIC 
   );
   end component ip_rgmii_rx100mb;


begin
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 1 p_mux
   -- ----------------------------------------------------------------------------
   --! brief   : Multiplexe module to select the Ethernet protocol by a software 
   --!           register
   --! details : 0 -> Ethernet RGMII
   --!           1 -> Ethernet MII
   -- ----------------------------------------------------------------------------
   m_tdata      <= rgmii_tdata when (sel_eth = c_eth_rgmii) else mii_tdata;
   m_tvalid     <= rgmii_tvalid when (sel_eth = c_eth_rgmii) else mii_tvalid;
   m_tlast      <= rgmii_tlast when (sel_eth = c_eth_rgmii) else mii_tlast;
   rgmii_tready <= m_tready when (sel_eth = c_eth_rgmii) else '0';
   mii_tready   <= m_tready when (sel_eth = c_eth_mii) else '0';
   -- ----------------------------------------------------------------------------


   -- Instance port mappings.
   i_mii : ip_mii_rx100mb
      port map (
         clk      => clk,
         enable   => enable,
         m_tready => mii_tready,
         rst_n    => rst_n,
         rxc      => MiiRxc,
         rxcol    => MiiCol,
         rxcrs    => MiiCrs,
         rxd      => MiiRxd,
         rxdv     => MiiDv,
         rxer     => MiiEr,
         m_tdata  => mii_tdata,
         m_tlast  => mii_tlast,
         m_tvalid => mii_tvalid
      );
   i_rgmii : ip_rgmii_rx100mb
      port map (
         clk      => clk,
         clk_dly  => clk_dly,
         enable   => enable,
         m_tready => rgmii_tready,
         rst_n    => rst_n,
         rxc      => RgmiiRxc,
         rxctl    => RgmiiRxCtl,
         rxd      => RgmiiRxd,
         m_tdata  => rgmii_tdata,
         m_tlast  => rgmii_tlast,
         m_tvalid => rgmii_tvalid
      );

end architecture rtl;

-- ----------------------------------------------------------------------------