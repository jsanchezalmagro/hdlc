-- ----------------------------------------------------------------------------
--! @class %unit
--! @image html symbol_sb%unit.png
--! @author Fernando Domínguez
--! @version 1.0
--! @date 21/05/2025
--!
--! @brief Module implements the Proc - MDIO conversion to communicate with
--! MII or RGMII devices connected to the FPGA.
--!
--! @details Module based on code from hw manufacturer which has been refactored.
--!
--! Features:
--! 1.  ????
--! 2.  ????
--!
--! Limitations:
--! 1.  ?????
--! 2.  ?????
--! 
--! Module performances
--! 1.   Frequency:
--! 1.1. Processor Frequency: 50 MHz (clk)
--! 1.2. MDIO Frequency: 2.5 MHz (mdc / mdio_clock)
--! 2.   Resources: ???
--!
--! @class %unit.%view
--! @image html rtl_bd%unit.png

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsi_core_eth_mdio is
   generic
   (
      g_add_size : integer := 0 -- ProcAddr Bus size, default is 13 bits
   );
   port
   (
      clk         : in std_logic;
      rst_n       : in std_logic;
      ProcDataIn  : in std_logic_vector (31 downto 0);
      ProcDataOut : out std_logic_vector (31 downto 0);
      ProcCs      : in std_logic;
      ProcAddr    : in std_logic_vector (g_add_size - 1 downto 0);
      ProcRNW     : in std_logic;
      ProcWrAcq   : out std_logic;
      ProcRdAcq   : out std_logic;
      Mdc         : out std_logic;   -- mdio clk (2.5Mhz)
      Md          : inout std_logic; -- mdio data (tristate buffer)
      chip_rst_n  : out std_logic;
      chip_cfg    : out std_logic
   );

   -- Declarations

end entity fsi_core_eth_mdio;

architecture rtl of fsi_core_eth_mdio is

   constant c_reg_phy_addr : integer := 128;
   constant c_reg_cfg_addr : integer := 132;

   constant c_mdio_start : std_logic_vector(1 downto 0) := "01";
   constant c_mdio_write : std_logic_vector(1 downto 0) := "01";
   constant c_mdio_read  : std_logic_vector(1 downto 0) := "10";
   constant c_mdio_ta    : std_logic_vector(1 downto 0) := "10";

   -- counters expressed in last count value (max-1)
   constant c_mdio_wtransfer_out_count : integer := 31;
   constant c_mdio_rtransfer_out_count : integer := 13;

   -- 16 cycles read data + one cycle last value in shift register (17 - 1)
   constant c_mdio_rtransfer_in_count : integer := 15;
   constant c_mdio_turnaround_count   : integer := 1;
   constant c_mdio_wait_count         : integer := 31;
   -- constant to convert cycles between clk (50 Mhz) and the required
   -- mdio clock (mdc) at 2.5 Mhz. Factor is 20 but divided by 2 to
   -- produce a clock duty cycle of 50%
   constant c_clk_to_mdio_clock_cycles : integer := 10 - 1;

   -- srl to convert from parallel to mdio serial data and viceversa
   signal mdio_serial_out : std_logic_vector(31 downto 0); -- mdio write
   signal mdio_serial_in  : std_logic_vector(15 downto 0); -- mdio read

   signal mdio_mdo : std_logic; -- serial data bit to out
   signal mdio_mdi : std_logic; -- serial data bit from in
   signal mdio_en  : std_logic; -- if enabled mdo at Md, if not 'Z' at Md

   -- mdio counter to switch from different fields of mdio frame
   signal cnt_cycles_in_field : integer range 0 to 31 := 0;

   -- mdio clk signals
   signal cnt_mdio_clk     : integer range 0 to c_clk_to_mdio_clock_cycles := 0;   -- counter for clk conversion
   signal mdio_clock       : std_logic                                     := '0'; -- mdio mdc clock pin
   signal mdio_clock_prev  : std_logic                                     := '0'; -- previous mdio_clock value
   signal mdio_sample_tick : std_logic                                     := '0'; -- tick to sample data (mdio_clock rising edge)

   -- phy address used in mdio transactions
   signal ProcCs_dly     : std_logic;
   signal mdio_phy_addr  : std_logic_vector(4 downto 0);
   signal mdio_reg_addr  : std_logic_vector(4 downto 0);
   signal mdio_write     : std_logic_vector(1 downto 0);
   signal mdio_wdata     : std_logic_vector(15 downto 0);
   signal mdio_rdata     : std_logic_vector(15 downto 0);
   signal start          : std_logic;
   signal busy           : std_logic;
   signal rnw            : std_logic;
   signal stopx          : std_logic;
   signal chip_cfg_int   : std_logic;
   signal chip_rst_int_n : std_logic;

   signal last_mdio_reg_addr : std_logic_vector(4 downto 0);
   signal last_mdio_phy_addr : std_logic_vector(4 downto 0);
   signal valid_addr         : std_logic;

   type tState is (
      ST_IDLE,
      ST_PREAMBLE,
      ST_MDIO_WRITE,
      ST_MDIO_READ_REQUEST,
      ST_MDIO_READ_TURNAROUND,
      ST_MDIO_READ_RECEIVE);

   signal iState : tState := ST_IDLE;

begin

   -- --------------------------------------------------------------------------
   p_proc : process (rst_n, clk)
   begin
      if (rst_n = '0') then
         ProcCs_dly         <= '0';
         ProcDataOut        <= (others => '0');
         ProcWrAcq          <= '0';
         ProcRdAcq          <= '0';
         chip_rst_int_n     <= '0';
         chip_cfg_int       <= '0';
         mdio_phy_addr      <= (others => '0');
         mdio_reg_addr      <= (others => '0');
         mdio_write         <= "00";
         mdio_wdata         <= (others => '0');
         mdio_rdata         <= (others => '0');
         start              <= '0';
         busy               <= '0';
         rnw                <= '0';
         last_mdio_reg_addr <= (others => '1');
         last_mdio_phy_addr <= (others => '0');

      elsif rising_edge(clk) then
         ProcCs_dly <= ProcCs;

         if (unsigned(ProcAddr) = c_reg_cfg_addr and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '0' and busy = '0') then -- Write configuration
            chip_rst_int_n <= ProcDataIn(0);
            chip_cfg_int   <= ProcDataIn(1);
            ProcWrAcq      <= '1';

         elsif (unsigned(ProcAddr) = c_reg_cfg_addr and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '1' and busy = '0') then -- Write configuration
            ProcDataOut <= busy & "00000000000000000000000000000" & chip_cfg_int & chip_rst_int_n;
            ProcRdAcq   <= '1';

         elsif (unsigned(ProcAddr) = c_reg_phy_addr and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '0' and busy = '0') then -- Write phy address
            mdio_phy_addr      <= ProcDataIn(mdio_phy_addr'range);
            ProcWrAcq          <= '1';
            last_mdio_phy_addr <= mdio_phy_addr;

         elsif (unsigned(ProcAddr) < c_reg_phy_addr and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '0' and busy = '0') then -- Write Mdio
            mdio_wdata    <= ProcDataIn(mdio_wdata'range);
            mdio_reg_addr <= ProcAddr(6 downto 2);
            start         <= '1';
            rnw           <= '0';
            busy          <= '1';
            ProcWrAcq     <= '1';
            mdio_write    <= c_mdio_write;

         elsif (unsigned(ProcAddr) < c_reg_phy_addr and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '1' and busy = '0') then -- Read Mdio
            ProcDataOut        <= "00000000000000" & busy & valid_addr & mdio_rdata;
            mdio_reg_addr      <= ProcAddr(6 downto 2);
            start              <= '1';
            rnw                <= '1';
            busy               <= '1';
            ProcRdAcq          <= '1';
            mdio_write         <= c_mdio_read;
            last_mdio_reg_addr <= ProcAddr(6 downto 2);

         elsif (busy = '1' and stopx = '1') then
            busy       <= '0';
            start      <= '0';
            mdio_rdata <= mdio_serial_in;

         else
            ProcDataOut <= (others => '0');
            ProcWrAcq   <= '0';
            ProcRdAcq   <= '0';
         end if;

      end if;
   end process p_proc;
   -- --------------------------------------------------------------------------
   valid_addr <= '1' when (rnw = '1' and ProcAddr(6 downto 2) = last_mdio_reg_addr and mdio_phy_addr = last_mdio_phy_addr) else
      '0';
   -- --------------------------------------------------------------------------
   -- handle the tristate inout buffer depending on 
   chip_cfg   <= chip_cfg_int;
   chip_rst_n <= chip_rst_int_n;
   Md         <= mdio_mdo when (mdio_en = '1') else
      'Z';
   mdio_mdi <= Md;
   -- --------------------------------------------------------------------------
   --! @brief   : Clock divider from 50 MHz to 2.5 MHz 
   --! @details : This process generates the mdio clock (mdio_clock) to be routed through Mdc pin
   --!            Generated clock has a duty cycle of 50%, conversion rate is 20:1.
   --!            In addition a tick is generated in the rising edge of mdio_clock to enable the
   --!            fsm operation in p_mdio_transfer.
   -- --------------------------------------------------------------------------
   p_clk_2_5_mhz : process (rst_n, clk)
   begin
      if (rst_n = '0') then
         mdio_clock   <= '0';
         cnt_mdio_clk <= 0;
      elsif rising_edge(clk) then
         if (cnt_mdio_clk < c_clk_to_mdio_clock_cycles) then
            cnt_mdio_clk <= cnt_mdio_clk + 1;
         else
            mdio_clock   <= not mdio_clock;
            cnt_mdio_clk <= 0;
         end if;
         mdio_clock_prev <= mdio_clock;
      end if;
   end process p_clk_2_5_mhz;
   -- --------------------------------------------------------------------------
   -- state machine evaluated at rising edge
   mdio_sample_tick <= mdio_clock and (not mdio_clock_prev);
   Mdc              <= not(mdio_clock);
   -- --------------------------------------------------------------------------
   --! @brief   : MDIO Control Tranfer FSM
   --! @details : Following the MDIO standard the MDIO transfer is defined by a
   --!  clock line (Mdc) and bidirectional data line (Md). Depending on timing of the transfer
   --!  the present module can be writing on line or listening from slave. The following
   --!  states have been defined to accomplish the communication:
   --!  - ST_IDLE : Waiting for a write/read or configuration request
   --!  - ST_MDIO_TRANSFER_CONFIG : Configure module internal parameter from Proc iface,
   --!                              this state does not issue a transfer.
   --!  - ST_PREAMBLE : Send common preamble for write and read operation
   --!  - ST_MDIO_WRITE : Issue a Write Operation
   --!  - ST_MDIO_READ_REQUEST : Issue a Read Operation, send firs transfer 14 bits
   --!  - ST_MDIO_READ_TURNAROUND : Control passed to slave, module listens 2 bits
   --!  - ST_MDIO_READ_RECEIVE : Listen the transfer, module receives 16 bits
   -- --------------------------------------------------------------------------
   p_mdio_transfer : process (rst_n, clk)
   begin
      if (rst_n = '0') then
         cnt_cycles_in_field <= 0;
         iState              <= ST_IDLE;
         mdio_en             <= '0';
         mdio_mdo            <= '1';
         mdio_serial_in      <= (others => '0');
         mdio_serial_out     <= (others => '0');
         stopx               <= '0';

      elsif rising_edge(clk) then
         if (mdio_sample_tick = '1') then

            case iState is

               when ST_IDLE =>
                  stopx               <= '0';
                  mdio_mdo            <= '1';
                  mdio_en             <= '0';
                  cnt_cycles_in_field <= c_mdio_wait_count;

                  if (start = '1') then
                     mdio_en         <= '1';
                     iState          <= ST_PREAMBLE;
                     mdio_serial_out <= c_mdio_start & mdio_write & mdio_phy_addr & mdio_reg_addr & c_mdio_ta & mdio_wdata;
                  end if;

               when ST_PREAMBLE =>
                  if (cnt_cycles_in_field /= 0) then
                     cnt_cycles_in_field <= cnt_cycles_in_field - 1;
                  elsif (rnw = '0') then
                     cnt_cycles_in_field <= c_mdio_wtransfer_out_count;
                     iState              <= ST_MDIO_WRITE;
                     mdio_mdo            <= mdio_serial_out(31);
                     mdio_serial_out     <= mdio_serial_out(30 downto 0) & '1';
                  else
                     cnt_cycles_in_field <= c_mdio_rtransfer_out_count;
                     iState              <= ST_MDIO_READ_REQUEST;
                     mdio_mdo            <= mdio_serial_out(31);
                     mdio_serial_out     <= mdio_serial_out(30 downto 0) & '1';
                  end if;

               when ST_MDIO_WRITE =>
                  mdio_mdo <= mdio_serial_out(31);
                  if (cnt_cycles_in_field /= 0) then
                     mdio_serial_out     <= mdio_serial_out(30 downto 0) & '1';
                     cnt_cycles_in_field <= cnt_cycles_in_field - 1;
                  else
                     mdio_en <= '0';
                     stopx   <= '1';
                     iState  <= ST_IDLE;
                  end if;

               when ST_MDIO_READ_REQUEST =>
                  mdio_mdo        <= mdio_serial_out(31);
                  mdio_serial_out <= mdio_serial_out(30 downto 0) & '1';
                  if (cnt_cycles_in_field /= 0) then
                     cnt_cycles_in_field <= cnt_cycles_in_field - 1;
                  else
                     cnt_cycles_in_field <= c_mdio_turnaround_count;
                     mdio_en             <= '0';
                     iState              <= ST_MDIO_READ_TURNAROUND;
                  end if;

               when ST_MDIO_READ_TURNAROUND =>
                  mdio_mdo        <= mdio_serial_out(31);
                  mdio_serial_out <= mdio_serial_out(30 downto 0) & '1'; -- Pour les Tests
                  if (cnt_cycles_in_field /= 0) then
                     cnt_cycles_in_field <= cnt_cycles_in_field - 1;
                  else
                     mdio_serial_in      <= mdio_serial_in(14 downto 0) & mdio_mdi;
                     cnt_cycles_in_field <= c_mdio_rtransfer_in_count;
                     iState              <= ST_MDIO_READ_RECEIVE;
                  end if;

               when ST_MDIO_READ_RECEIVE =>

                  if (cnt_cycles_in_field /= 0) then
                     cnt_cycles_in_field <= cnt_cycles_in_field - 1;
                     mdio_serial_in      <= mdio_serial_in(14 downto 0) & mdio_mdi;
                  else
                     stopx   <= '1'; -- Read request satisfied at this point
                     mdio_en <= '0';
                     iState  <= ST_IDLE;
                  end if;

               when others =>
                  iState <= ST_IDLE;

            end case;
         end if;
      end if;
   end process;

end rtl;