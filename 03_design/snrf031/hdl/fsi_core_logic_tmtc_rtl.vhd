-- ----------------------------------------------------------------------------
--! Library       : snrf031
--! Entity        : fsi_core_logic_tmtc
--! Lenguaje      : VHDL-2008
-- ---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsi_core_logic_tmtc is
   generic( 
      g_add_size : integer := 16
   );
   port( 
      ProcAddr        : in     std_logic_vector (g_add_size-1 downto 0);  -- 63 adresse max.
      ProcCs          : in     std_logic;
      ProcDataIn      : in     std_logic_vector (31 downto 0);
      ProcRNW         : in     std_logic;
      ch_fl_rdata     : in     std_logic_vector (7 downto 0);
      ch_rl_rdata     : in     std_logic_vector (7 downto 0);
      clk             : in     std_logic;
      fl_status       : in     std_logic_vector (31 downto 0);
      nav_rdata       : in     std_logic_vector (15 downto 0);
      rl_status       : in     std_logic_vector (31 downto 0);
      rst_n           : in     std_logic;
      sel_adt_gdt     : in     std_logic;
      ProcDataOut     : out    std_logic_vector (31 downto 0);
      ProcRdAck       : out    std_logic;
      ProcWrAck       : out    std_logic;
      adt_gdt         : out    std_logic_vector (4 downto 0);
      aes_newkey      : out    std_logic;
      ch_clear        : out    std_logic;
      ch_rd           : out    std_logic;
      ch_sel          : out    std_logic_vector (3 downto 0);
      ch_wdata        : out    std_logic_vector (8 downto 0);
      ch_wr           : out    std_logic;
      fl_status_clear : out    std_logic;
      nav_rd          : out    std_logic;
      nav_start       : out    std_logic;
      nav_stop        : out    std_logic;
      nav_wdata       : out    std_logic_vector (15 downto 0);
      nav_wr          : out    std_logic;
      profile_cfg     : out    std_logic_vector (5 downto 0);
      rl_status_clear : out    std_logic
   );

-- Declarations

end entity fsi_core_logic_tmtc ;

-- ----------------------------------------------------------------------------
--! @class fsi_core_logic_tmtc
--! @image html symbol_sbfsi_core_logic_tmtc.png
--! @author Alicia Bermejo
--! @version 1.0
--! @date 20/06/2023
--!
--! @brief 
--!  This module implements the telecommand/telemetry interface in the FSI FPGA.
--!
--! @details
--!  The telecommands and the telemetries are described in the HW/SW ICD
--!
--! Requirements
--!    SEN-WB-WF1-HW-318
--!    SEN-WB-WF1-HW-326
--!    SEN-WB-WF1-HW-610
--!    SEN-WB-WF1-HW-611
--!    SEN-WB-WF1-HW-334
--!    SEN-WB-WF1-HW-335
--!    SEN-WB-WF1-HW-336
--!    SEN-WB-WF1-HW-337
--!    SEN-WB-WF1-HW-379
--!    SEN-WB-WF1-HW-380
--!    SEN-WB-WF1-HW-382
--!    SEN-WB-WF1-HW-383
--!    SEN-WB-WF1-HW-479
--!    SEN-WB-WF1-HW-615
--!    SEN-WB-WF1-HW-616
--!    SEN-WB-WF1-HW-503
--!    SEN-WB-WF1-HW-504
--!    SEN-WB-WF1-HW-505
--!    SEN-WB-WF1-HW-513
--!    SEN-WB-WF1-HW-514
--!    SEN-WB-WF1-HW-515
--!    SEN-WB-WF1-HW-516
--!    SEN-WB-WF1-HW-517
--!
--! Features:
--! 1.  FSI FPGA
--!
--! Limitations:
--! 1. 
--! 
--! Module performances
--! 1.   Frequency: 
--! 1.1. System Clock (Clk): 50 MHz
--!
--! 2.   Resources: 
--!
--! @class fsi_core_logic_tmtc.rtl
--! @image html rtl_bdfsi_core_logic_tmtc.png
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library snrf031;
use snrf031.fsi_core_logic_registers_pkg.all;


architecture rtl of fsi_core_logic_tmtc is

   -- Architecture declarations

   -- Internal signal declarations


   signal fl_status_clear_tmp: std_logic;
   signal rl_status_clear_tmp: std_logic;

   signal adt_gdt_int: std_logic_vector(4 downto 0);

   signal ProcCs_dly : std_logic := '0';


begin
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 1 p_reg
   
   -- -----------------------------------------------------------------------------
   --! @brief   : Write configuration registers
   --! @details : This process generates the write registers and generates write
   --!            acknowledgement signal.
   --!            adt_gdt signal: ABCYX Select ADT or GDT for Tx and Rx
   --!            bit 0: Selet the transmitter 
   --!               '0' -> RL
   --!               '1' -> FL
   --!            bit 1: Select the receiver
   --!               '0' -> RL
   --!               '1' -> FL
   --!            bit 2: Ethernet transmitter 
   --!               '0' -> RGMII
   --!               '1' -> MII
   --!            bit 3: Ethernet receiver
   --!               '0' -> RGMII
   --!               '1' -> MII
   --!            bit 4: Test mode for ethernet
   --!               '0' -> Bypass
   --!               '1' -> Test
   --!            RL Mode : 00 (TX RL, RX RL)
   --!            FL Mode : 11 (TX FL, RX FL)
   --!            ADT Mode: 10 (TX RL, RX FL)
   --!            GDT Mode: 01 (TX FL, RX RL)
   -- -----------------------------------------------------------------------------
   p_wr_reg : process (clk, rst_n)
   begin
      if (rst_n = '0') then
   
         ProcRdAck   <= '0';
         ProcWrAck   <= '0';
         ProcDataOut <= (others => '0');
         ProcCs_dly  <= '0';
         -- Config profiles
         adt_gdt_int <= (others => '0');
         aes_newkey  <= '0';
         profile_cfg <= (others => '0');
         -- Config channel
         ch_sel   <= (others => '0');
         ch_clear <= '0';
         ch_wr    <= '0';
         ch_rd    <= '0';
         ch_wdata <= (others => '0');
         -- Config nav
         nav_start <= '0';
         nav_stop  <= '0';
         nav_wdata <= (others => '0');
   
      elsif rising_edge(clk) then
         ProcCs_dly <= ProcCs;
         -- Write registers
         if (unsigned(ProcAddr) = c_profile_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '0') then
            profile_cfg <= ProcDatain(profile_cfg'range);
            ProcWrAck   <= '1';
   
         elsif (unsigned(ProcAddr) = c_sel_mode_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '0') then
            if (ProcDatain(31 downto 24) = x"00") then -- Nominal mode
               -- Input sel_adt_gdt = '0' : Select ADT
               -- Tx RL and Rx FL
               -- Input sel_adt_gdt = '1' : Select GDT 
               -- Tx FL and Rx RL
               if (sel_adt_gdt = '0') then -- ADT mode: TX RL (bit 0) and RX FL (bit 1)
                  adt_gdt_int <= "00010";
               else -- GDT mode: TX FL (bit 0) and RX RL (bit 1)
                  adt_gdt_int <= "00001";
               end if;
            elsif (ProcDatain(31 downto 24) = x"5A") then -- Test mode: Select by register
               -- adt_gdt = A B C Y X
               adt_gdt_int <= ProcDatain(4 downto 0);
            else
               adt_gdt_int <= (others => '0');
            end if;
            ProcWrAck <= '1';
   
         elsif (unsigned(ProcAddr) = c_channel_sel_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '0') then
            ch_sel    <= ProcDatain(ch_sel'range);
            ch_clear  <= '1';
            ProcWrAck <= '1';
   
         elsif (unsigned(ProcAddr) = c_channel_filter_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '0') then
            ch_wdata  <= ProcDatain(ch_wdata'range);
            ch_wr     <= '1';
            ProcWrAck <= '1';
   
         elsif (unsigned(ProcAddr) = c_channel_filter_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '1') then
            ch_rd     <= '1';
            ProcRdAck <= '1';
   
         elsif (unsigned(ProcAddr) = c_nav_sel_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '0') then
            nav_start <= ProcDatain(0);
            nav_stop  <= not(ProcDatain(0));
            ProcWrAck <= '1';
   
         elsif (unsigned(ProcAddr) = c_nav_data_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '0') then
            nav_wdata <= ProcDatain(nav_wdata'range);
            nav_wr    <= '1';
            ProcWrAck <= '1';
   
         elsif (unsigned(ProcAddr) = c_nav_data_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '1') then
            nav_rd                       <= '1';
            ProcDataOut(nav_rdata'range) <= nav_rdata;
            ProcRdAck                    <= '1';
   
         elsif (unsigned(ProcAddr) = c_aes_newkey_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '0') then
            aes_newkey <= '1';
            ProcWrAck  <= '1';
   
         elsif (unsigned(ProcAddr) = c_fl_status_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '1') then
            ProcDataOut(fl_status'range) <= fl_status;
            ProcRdAck                    <= '1';
   
         elsif (unsigned(ProcAddr) = c_rl_status_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '1') then
            ProcDataOut(rl_status'range) <= rl_status;
            ProcRdAck                    <= '1';
   
         elsif (unsigned(ProcAddr) = c_channel_filter_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '1') then
            if (sel_adt_gdt = '0') then --ADT
               ProcDataOut(ch_rl_rdata'range) <= ch_rl_rdata;
            else --GDT
               ProcDataOut(ch_fl_rdata'range) <= ch_fl_rdata;
            end if;
            ProcRdAck <= '1';
   
         else
            ProcWrAck   <= '0';
            ProcRdAck   <= '0';
            ProcDataOut <= (others => '0');
            ch_clear    <= '0';
            ch_wr       <= '0';
            nav_wr      <= '0';
            ch_rd       <= '0';
            nav_rd      <= '0';
            aes_newkey  <= '0';
   
         end if;
      end if;
   end process p_wr_reg;
   -- -----------------------------------------------------------------------------
   adt_gdt <= adt_gdt_int;
   -- -----------------------------------------------------------------------------
   p_clear_status : process (clk, rst_n)
   begin
      if rst_n = '0' then
         fl_status_clear     <= '0';
         rl_status_clear     <= '0';
         fl_status_clear_tmp <= '0';
         rl_status_clear_tmp <= '0';
      elsif rising_edge(clk) then
   
         -- Clear status registers
         fl_status_clear <= fl_status_clear_tmp;
         rl_status_clear <= rl_status_clear_tmp;
   
         -- Clear status registers      
         if (unsigned(ProcAddr) = c_fl_status_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '1') then
            fl_status_clear_tmp <= '1';
         elsif (unsigned(ProcAddr) = c_rl_status_add and ProcCs = '1' and ProcCs_dly = '0' and ProcRNW = '1') then
            rl_status_clear_tmp <= '1';
         else
            fl_status_clear_tmp <= '0';
            rl_status_clear_tmp <= '0';
         end if;
   
      end if;
   end process p_clear_status;
   -- -----------------------------------------------------------------------------


   -- Instance port mappings.

end architecture rtl;

-- ----------------------------------------------------------------------------