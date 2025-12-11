-- ----------------------------------------------------------------------------
--! Library       : snrf031
--! Entity        : fsi_core_bus
--! Lenguaje      : VHDL-2008
-- ---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsi_core_bus is
   generic( 
      g_add_size       : integer := 16;
      g_slave_bus_size : integer := 4
   );
   port( 
      ProcAddr           : in     std_logic_vector (g_add_size+g_slave_bus_size-1 downto 0);  -- 63 adresse max.
      ProcCs             : in     std_logic;
      ProcDataIn         : in     std_logic_vector (31 downto 0);
      ProcDataOut_aurora : in     std_logic_vector (31 downto 0);
      ProcDataOut_core   : in     std_logic_vector (31 downto 0);
      ProcDataOut_dds    : in     std_logic_vector (31 downto 0);
      ProcDataOut_decryp : in     std_logic_vector (31 downto 0);
      ProcDataOut_encryp : in     std_logic_vector (31 downto 0);
      ProcDataOut_flink  : in     std_logic_vector (31 downto 0);
      ProcDataOut_mii    : in     std_logic_vector (31 downto 0);
      ProcDataOut_rgmii  : in     std_logic_vector (31 downto 0);
      ProcDataOut_srv    : in     std_logic_vector (31 downto 0);
      ProcDataOut_temp   : in     std_logic_vector (31 downto 0);
      ProcRNW            : in     std_logic;
      ProcRdAck_aurora   : in     std_logic;
      ProcRdAck_core     : in     std_logic;
      ProcRdAck_dds      : in     std_logic;
      ProcRdAck_decryp   : in     std_logic;
      ProcRdAck_encryp   : in     std_logic;
      ProcRdAck_flink    : in     std_logic;
      ProcRdAck_mii      : in     std_logic;
      ProcRdAck_rgmii    : in     std_logic;
      ProcRdAck_srv      : in     std_logic;
      ProcRdAck_temp     : in     std_logic;
      ProcWrAck_aurora   : in     std_logic;
      ProcWrAck_core     : in     std_logic;
      ProcWrAck_dds      : in     std_logic;
      ProcWrAck_decryp   : in     std_logic;
      ProcWrAck_encryp   : in     std_logic;
      ProcWrAck_flink    : in     std_logic;
      ProcWrAck_mii      : in     std_logic;
      ProcWrAck_rgmii    : in     std_logic;
      ProcWrAck_srv      : in     std_logic;
      ProcWrAck_temp     : in     std_logic;
      clk                : in     std_logic;
      rst_n              : in     std_logic;
      ProcAddr_mst       : out    std_logic_vector (g_add_size-1 downto 0);                   -- !! adresse mot et non octet
      ProcCs_aurora      : out    std_logic;
      ProcCs_core        : out    std_logic;
      ProcCs_dds         : out    std_logic;
      ProcCs_decryp      : out    std_logic;
      ProcCs_encryp      : out    std_logic;
      ProcCs_flink       : out    std_logic;
      ProcCs_mii         : out    std_logic;
      ProcCs_rgmii       : out    std_logic;
      ProcCs_srv         : out    std_logic;
      ProcCs_temp        : out    std_logic;
      ProcDataIn_mst     : out    std_logic_vector (31 downto 0);
      ProcDataOut        : out    std_logic_vector (31 downto 0);
      ProcRNW_mst        : out    std_logic;                                                  -- read/not write
      ProcRdAck          : out    std_logic;
      ProcWrAck          : out    std_logic
   );

-- Declarations

end entity fsi_core_bus ;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ip_sdebug;
use ip_sdebug.ip_sdebug_pkg.all;


architecture rtl of fsi_core_bus is

   -- Architecture declarations
   attribute keep : string;
   
   constant c_sel_srv: std_logic_vector(g_slave_bus_size-1 downto 0) := "0000";
   constant c_sel_aurora: std_logic_vector(g_slave_bus_size-1 downto 0) := "0001";
   constant c_sel_core: std_logic_vector(g_slave_bus_size-1 downto 0) := "0010";
   constant c_sel_decryp: std_logic_vector(g_slave_bus_size-1 downto 0) := "0011";
   constant c_sel_encryp: std_logic_vector(g_slave_bus_size-1 downto 0) := "0100";
   constant c_sel_mii: std_logic_vector(g_slave_bus_size-1 downto 0) := "0101";
   constant c_sel_rgmii: std_logic_vector(g_slave_bus_size-1 downto 0) := "0110";
   constant c_sel_dds: std_logic_vector(g_slave_bus_size-1 downto 0) := "0111";
   constant c_sel_temp: std_logic_vector(g_slave_bus_size-1 downto 0) := "1000";
   
   constant c_sel_flink: std_logic_vector(g_slave_bus_size-1 downto 0) := "1111";

   -- Internal signal declarations


   signal cnt_timeout: unsigned(5 downto 0);
   signal timeout: std_logic;

   signal sel: std_logic_vector(g_slave_bus_size-1 downto 0);

   signal ProcWrAck_int: std_logic;
   signal ProcRdAck_int: std_logic;


begin
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 1 p_proc
   -- p_proc 
   -- Select interface for the different modules
   sel <= ProcAddr(ProcAddr_mst'high + g_slave_bus_size downto ProcAddr_mst'high + 1);
   
   -- Assign the address and data to the different modules
   ProcAddr_mst <= ProcAddr(ProcAddr_mst'range);
   
   -- Assign the data in to the different modules
   ProcDataIn_mst <= ProcDataIn;
   
   -- Assign the control signals to the different modules
   ProcCs_aurora <= ProcCs when (sel = c_sel_aurora) else '0';
   ProcCs_core   <= ProcCs when (sel = c_sel_core) else '0';
   ProcCs_decryp <= ProcCs when (sel = c_sel_decryp) else '0';
   ProcCs_encryp <= ProcCs when (sel = c_sel_encryp) else '0';
   ProcCs_mii    <= ProcCs when (sel = c_sel_mii) else '0';
   ProcCs_rgmii  <= ProcCs when (sel = c_sel_rgmii) else '0';
   ProcCs_flink  <= ProcCs when (sel = c_sel_flink) else '0';
   ProcCs_temp   <= ProcCs when (sel = c_sel_temp) else '0';
   ProcCs_dds    <= ProcCs when (sel = c_sel_dds) else '0';
   ProcCs_srv    <= ProcCs when (sel = c_sel_srv) else '0';
   
   -- Assign the read/write signal to the different modules
   ProcRNW_mst <= ProcRNW;
   
   -- Assign the data out from the different modules
   ProcDataOut <= ProcDataOut_aurora when (sel = c_sel_aurora) else
       ProcDataOut_core when (sel = c_sel_core) else
       ProcDataOut_decryp when (sel = c_sel_decryp) else
       ProcDataOut_encryp when (sel = c_sel_encryp) else
       ProcDataOut_mii when (sel = c_sel_mii) else
       ProcDataOut_rgmii when (sel = c_sel_rgmii) else
       ProcDataOut_flink when (sel = c_sel_flink) else
       ProcDataOut_temp when (sel = c_sel_temp) else
       ProcDataOut_dds when (sel = c_sel_dds) else
       ProcDataOut_srv;
   
   ProcWrAck_int <= (ProcWrAck_aurora or timeout) when (sel = c_sel_aurora) else
       (ProcWrAck_core or timeout) when (sel = c_sel_core) else
       (ProcWrAck_decryp or timeout) when (sel = c_sel_decryp) else
       (ProcWrAck_encryp or timeout) when (sel = c_sel_encryp) else
       (ProcWrAck_mii or timeout) when (sel = c_sel_mii) else
       (ProcWrAck_rgmii or timeout) when (sel = c_sel_rgmii) else
       (ProcWrAck_flink or timeout) when (sel = c_sel_flink) else
       (ProcWrAck_temp or timeout) when (sel = c_sel_temp) else
       (ProcWrAck_dds or timeout) when (sel = c_sel_dds) else
       (ProcWrAck_srv or timeout);
   
   ProcRdAck_int <= (ProcRdAck_aurora or timeout) when (sel = c_sel_aurora) else
       (ProcRdAck_core or timeout) when (sel = c_sel_core) else
       (ProcRdAck_decryp or timeout) when (sel = c_sel_decryp) else
       (ProcRdAck_encryp or timeout) when (sel = c_sel_encryp) else
       (ProcRdAck_mii or timeout) when (sel = c_sel_mii) else
       (ProcRdAck_rgmii or timeout) when (sel = c_sel_rgmii) else
       (ProcRdAck_flink or timeout) when (sel = c_sel_flink) else
       (ProcRdAck_temp or timeout) when (sel = c_sel_temp) else
       (ProcRdAck_dds or timeout) when (sel = c_sel_dds) else
       (ProcRdAck_srv or timeout);
   -- -----------------------------------------------------------------------------
   ProcWrAck <= ProcWrAck_int;
   ProcRdAck <= ProcRdAck_int;
   -- -----------------------------------------------------------------------------
   p_timeout : process (clk, rst_n)
       constant c_timeout : unsigned(cnt_timeout'range) := (others => '1');
   begin
       if (rst_n = '0') then
           cnt_timeout <= (others => '0');
           timeout     <= '0';
       elsif rising_edge(clk) then
           if (ProcCs = '1') then
               if (cnt_timeout = c_timeout) then
                   cnt_timeout <= (others => '0');
                   timeout     <= '1';
               else
                   cnt_timeout <= cnt_timeout + 1;
                   timeout     <= '0';
               end if;
           else
               cnt_timeout <= (others => '0');
               timeout     <= '0';
           end if;
       end if;
   end process p_timeout;
   -- -----------------------------------------------------------------------------


   -- Instance port mappings.

end architecture rtl;

-- ----------------------------------------------------------------------------