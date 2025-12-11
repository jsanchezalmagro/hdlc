-- ----------------------------------------------------------------------------
--! Library       : snrf031
--! Entity        : snrf031_mb
--! Lenguaje      : VHDL-2008
-- ---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity snrf031_mb is
   generic( 
      g_fpga_number : integer range 0 to 255 := 31;
      g_fpga_mayor  : integer range 0 to 31  := 1;
      g_fpga_minor  : integer range 0 to 31  := 0;
      g_fpga_rev    : integer range 0 to 255 := 0
   );
   port( 
      clk_p      : in     std_logic;
      reset_n    : in     std_logic;
      ddr2x_addr : out    std_logic_vector (13 downto 0);
      ddr_ba     : out    std_logic_vector (2 downto 0);
      ddr_cas_n  : out    std_logic;
      ddr_ck_n   : out    std_logic;
      ddr_ck_p   : out    std_logic;
      ddr_cke    : out    std_logic;
      ddr_cs_n   : out    std_logic;
      ddr_dm     : out    std_logic_vector (1 downto 0);
      ddr_odt    : out    std_logic;
      ddr_ras_n  : out    std_logic;
      ddr_we_n   : out    std_logic;
      ddr2_dq    : inout  std_logic_vector (15 downto 0);
      ddr2_dqs_n : inout  std_logic_vector (1 downto 0);
      ddr2_dqs_p : inout  std_logic_vector (1 downto 0)
   );

-- Declarations

end entity snrf031_mb ;

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
use ieee.numeric_std.all;

library microblaze;

-- synthesis translate_off
library unisim;
-- synthesis translate_on


architecture rtl of snrf031_mb is

   -- Architecture declarations

   -- Internal signal declarations
   signal ddr2_addr : std_logic_vector(12 downto 0);
   signal reset     : std_logic;


   -- Component Declarations
   component proc
   port (
      clkin      : in     std_logic ;
      reset      : in     std_logic ;
      ddr_ck_p   : out    std_logic ;
      ddr_ck_n   : out    std_logic ;
      ddr_cke    : out    std_logic ;
      ddr_cs_n   : out    std_logic ;
      ddr_odt    : out    std_logic ;
      ddr_ras_n  : out    std_logic ;
      ddr_cas_n  : out    std_logic ;
      ddr_we_n   : out    std_logic ;
      ddr_dm     : out    std_logic_vector (1 downto 0);
      ddr_ba     : out    std_logic_vector (2 downto 0);
      ddr2_addr  : out    std_logic_vector (12 downto 0);
      ddr2_dq    : inout  std_logic_vector (15 downto 0);
      ddr2_dqs_p : inout  std_logic_vector (1 downto 0);
      ddr2_dqs_n : inout  std_logic_vector (1 downto 0)
   );
   end component proc;


begin
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 2 p_not
   reset <= reset_n;

   -- HDL Embedded Text Block 4 p_ddr_addr
   ddr2x_addr <= '0' & ddr2_addr;
   


   -- Instance port mappings.
   i_microblaze : proc
      port map (
         clkin      => clk_p,
         reset      => reset,
         ddr_ck_p   => ddr_ck_p,
         ddr_ck_n   => ddr_ck_n,
         ddr_cke    => ddr_cke,
         ddr_cs_n   => ddr_cs_n,
         ddr_odt    => ddr_odt,
         ddr_ras_n  => ddr_ras_n,
         ddr_cas_n  => ddr_cas_n,
         ddr_we_n   => ddr_we_n,
         ddr_dm     => ddr_dm,
         ddr_ba     => ddr_ba,
         ddr2_addr  => ddr2_addr,
         ddr2_dq    => ddr2_dq,
         ddr2_dqs_p => ddr2_dqs_p,
         ddr2_dqs_n => ddr2_dqs_n
      );

end architecture rtl;

-- ----------------------------------------------------------------------------