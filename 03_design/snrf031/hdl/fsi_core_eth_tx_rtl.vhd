-- ----------------------------------------------------------------------------
--! Library       : snrf031
--! Entity        : fsi_core_eth_tx
--! Lenguaje      : VHDL-2008
-- ---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsi_core_eth_tx is
   port( 
      MiiTxc     : in     std_logic;
      clk        : in     std_logic;
      clk_dly    : in     std_logic;
      clk_eth    : in     std_logic;
      enable     : in     std_logic;
      rst_n      : in     std_logic;
      s_tdata    : in     std_logic_vector (7 downto 0);
      s_tlast    : in     std_logic;
      s_tvalid   : in     std_logic;
      sel_eth    : in     std_logic;
      MiiTxEn    : out    std_logic;
      MiiTxd     : out    std_logic_vector (3 downto 0);
      RgmiiTxCtl : out    std_logic;
      RgmiiTxc   : out    std_logic;
      RgmiiTxd   : out    std_logic_vector (3 downto 0);
      s_tready   : out    std_logic
   );

-- Declarations

end entity fsi_core_eth_tx ;

-- ----------------------------------------------------------------------------
--! @class fsi_core_eth_tx
--! @image html symbol_sbfsi_core_eth_tx.png
--! @author Alicia Bermejo
--! @version 1.0
--! @date 20/06/2024
--!
--! @brief 
--!     Multiplexer to select the Ethernet protocol in the transmitter module: RGMII or MII
--!
--! @details
--!    This module sends Ethernet frames using the RGMII or the MII interface.
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
--! 1.2. Ethernet Clock (Clk_eth): 25 MHz
--! 1.3. Reference Clock (Clk_dly): 200 MHz
--!      
--! 2.   Resources: 
--!
--! @class fsi_core_eth_tx.rtl
--! @image html rtl_bdfsi_core_eth_tx.png
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library ip_rgmii;
library ip_mii;

library implementation_i;
use implementation_i.implementation_i_pkg.all;


architecture rtl of fsi_core_eth_tx is

   -- Architecture declarations

   -- Internal signal declarations
   signal mii_data    : std_logic_vector(7 downto 0);
   signal mii_last    : std_logic;
   signal mii_ready   : std_logic;
   signal mii_valid   : std_logic;
   signal rgmii_data  : std_logic_vector(7 downto 0);
   signal rgmii_last  : std_logic;
   signal rgmii_ready : std_logic;
   signal rgmii_valid : std_logic;


   -- Component Declarations
   component ip_mii_tx100mb
   port (
      clk      : in     STD_LOGIC ;
      enable   : in     std_logic ;                    -- -! Transimision clock received from the external rgmii chip
      rst_n    : in     std_logic ;                    --! System reset
      s_tdata  : in     STD_LOGIC_VECTOR (7 downto 0);
      s_tlast  : in     STD_LOGIC ;
      s_tvalid : in     STD_LOGIC ;
      txc      : in     std_logic ;                    --! Transmitted RGMII clock to the chip
      s_tready : out    STD_LOGIC ;
      txd      : out    std_logic_vector (3 downto 0); --! Transmitted RGMII data to the chip
      txen     : out    std_logic                      --! Transmitted RGMII valid signal  to the chip
   );
   end component ip_mii_tx100mb;
   component ip_rgmii_tx100mb
   port (
      clk      : in     STD_LOGIC ;
      clk_dly  : in     std_logic ;
      clk_eth  : in     std_logic ;
      enable   : in     std_logic ;                   -- -! Transimision clock received from the external rgmii chip
      rst_n    : in     std_logic ;                   --! System reset
      s_tdata  : in     STD_LOGIC_VECTOR (7 downto 0);
      s_tlast  : in     STD_LOGIC ;
      s_tvalid : in     STD_LOGIC ;
      s_tready : out    STD_LOGIC ;
      txc      : out    std_logic ;                   --! Transmitted RGMII clock to the chip
      txctl    : out    std_logic ;                   --! Transmitted RGMII valid signal  to the chip
      txd      : out    std_logic_vector (3 downto 0) --! Transmitted RGMII data to the chip
   );
   end component ip_rgmii_tx100mb;


begin
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 1 p_mux
   -- ----------------------------------------------------------------------------
   --! brief   : Multiplexe module to select the Ethernet protocol by a software 
   --!           register
   --! details : 0 -> Ethernet RGMII
   --!           1 -> Ethernet MII
   -- ----------------------------------------------------------------------------
   rgmii_data <= s_tdata when (sel_eth = c_eth_rgmii) else (others => '0');
   rgmii_valid <= s_tvalid when (sel_eth = c_eth_rgmii) else '0';
   rgmii_last <= s_tlast when (sel_eth = c_eth_rgmii) else '0';
   -- ----------------------------------------------------------------------------
   mii_data <= s_tdata when (sel_eth = c_eth_mii) else (others => '0');
   mii_valid <= s_tvalid when (sel_eth = c_eth_mii) else '0';
   mii_last <= s_tlast when (sel_eth = c_eth_mii) else '0';
   -- ----------------------------------------------------------------------------
   s_tready <= rgmii_ready when (sel_eth = c_eth_rgmii) else mii_ready;
   -- ----------------------------------------------------------------------------


   -- Instance port mappings.
   i_mii : ip_mii_tx100mb
      port map (
         clk      => clk,
         enable   => enable,
         rst_n    => rst_n,
         s_tdata  => mii_data,
         s_tlast  => mii_last,
         s_tvalid => mii_valid,
         txc      => MiiTxc,
         s_tready => mii_ready,
         txd      => MiiTxd,
         txen     => MiiTxEn
      );
   i_rgmii : ip_rgmii_tx100mb
      port map (
         clk      => clk,
         clk_dly  => clk_dly,
         clk_eth  => clk_eth,
         enable   => enable,
         rst_n    => rst_n,
         s_tdata  => rgmii_data,
         s_tlast  => rgmii_last,
         s_tvalid => rgmii_valid,
         s_tready => rgmii_ready,
         txc      => RgmiiTxc,
         txctl    => RgmiiTxCtl,
         txd      => RgmiiTxd
      );

end architecture rtl;

-- ----------------------------------------------------------------------------