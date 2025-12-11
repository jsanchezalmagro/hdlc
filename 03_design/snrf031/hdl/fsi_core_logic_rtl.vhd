-- ----------------------------------------------------------------------------
--! Library       : snrf031
--! Entity        : fsi_core_logic
--! Lenguaje      : VHDL-2008
-- ---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsi_core_logic is
   generic( 
      g_add_size : integer := 16
   );
   port( 
      ProcAddr               : in     std_logic_vector (g_add_size-1 downto 0);  -- 63 adresse max.
      ProcCs                 : in     std_logic;
      ProcDatain             : in     std_logic_vector (31 downto 0);
      ProcRNW                : in     std_logic;
      clk                    : in     std_logic;                                 --! Clock signal
      fl_pmec_sync_in        : in     std_logic;
      m_rx_tready            : in     std_logic;
      m_tx_tready            : in     std_logic;
      pn_code_gen_trck_st_in : in     std_logic_vector (1 downto 0);
      rst_n                  : in     std_logic;
      s_rx_tdata             : in     std_logic_vector (31 downto 0);            --! AXI-S Slave interface, data
      s_rx_tvalid            : in     std_logic;                                 --! AXI-S Slave interface, valid
      s_tx_tdata             : in     std_logic_vector (7 downto 0);             --! Word read from memory
      s_tx_tlast             : in     std_logic;
      s_tx_tvalid            : in     std_logic;                                 --! AXI-S master interface, valid
      sel_adt_gdt            : in     std_logic;
      ProcDataout            : out    std_logic_vector (31 downto 0);
      ProcRdAck              : out    std_logic;
      ProcWrAck              : out    std_logic;
      decryp_bypass          : out    std_logic;
      decryp_enable          : out    std_logic;
      enable_fsi_rx          : out    std_logic;
      enable_fsi_tx          : out    std_logic;
      encryp_bypass          : out    std_logic;
      encryp_enable          : out    std_logic;
      encryp_newkey          : out    std_logic;
      eth_rx_enable          : out    std_logic;
      eth_rx_sel             : out    std_logic;
      eth_tx_enable          : out    std_logic;
      eth_tx_sel             : out    std_logic;
      fl_pmec_sync_out       : out    std_logic;
      m_rx_tdata             : out    std_logic_vector (7 downto 0);
      m_rx_tlast             : out    std_logic;
      m_rx_tvalid            : out    std_logic;
      m_tx_tdata             : out    std_logic_vector (31 downto 0);
      m_tx_tvalid            : out    std_logic;
      profile_cfg            : out    std_logic_vector (5 downto 0);
      s_rx_tready            : out    std_logic  := '0';                         --! AXI-S Slave interface, ready
      s_tx_tready            : out    std_logic
   );

-- Declarations

end entity fsi_core_logic ;

-- ----------------------------------------------------------------------------
--! @class fsi_core_logic
--! @image html symbol_sbfsi_core_logic.png
--! @author Alicia Bermejo
--! @version 1.0
--! @date 20/06/2023
--!
--! @brief 
--!  This module implements the Ethernet frame multiplexer and
--!  the telecommand/telemetry interface in the FSI FPGA.
--!
--! @details
--!  The modem configuration determines the selection of both the transmitter (Multiplexer) 
--!   and the receiver (Demultiplexer) modules
--!
--! Requirements
--!   All
--!    SEN-WB-WF1-HW-94
--!    SEN-WB-WF1-HW-316
--!    SEN-WB-WF1-HW-317
--!    SEN-WB-WF1-HW-318
--! 
--!   TMTC Interface
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
--!  Multiplexer Interface
--!    SEN-WB-WF1-HW-594
--!    SEN-WB-WF1-HW-595
--!    SEN-WB-WF1-HW-610
--!    SEN-WB-WF1-HW-611
--!    SEN-WB-WF1-HW-327
--!    SEN-WB-WF1-HW-329
--!    SEN-WB-WF1-HW-330
--!    SEN-WB-WF1-HW-331
--!    SEN-WB-WF1-HW-332
--!    SEN-WB-WF1-HW-334
--!    SEN-WB-WF1-HW-335
--!    SEN-WB-WF1-HW-336
--!    SEN-WB-WF1-HW-337
--!    SEN-WB-WF1-HW-363
--!    SEN-WB-WF1-HW-364
--!    SEN-WB-WF1-HW-365
--!    SEN-WB-WF1-HW-366
--!    SEN-WB-WF1-HW-617
--!    SEN-WB-WF1-HW-339
--!    SEN-WB-WF1-HW-618
--!    SEN-WB-WF1-HW-340
--!    SEN-WB-WF1-HW-341
--!    SEN-WB-WF1-HW-342
--!    SEN-WB-WF1-HW-345
--!    SEN-WB-WF1-HW-346
--!    SEN-WB-WF1-HW-347
--!    SEN-WB-WF1-HW-348
--!    SEN-WB-WF1-HW-349
--!    SEN-WB-WF1-HW-350
--!    SEN-WB-WF1-HW-352
--!    SEN-WB-WF1-HW-353
--!    SEN-WB-WF1-HW-619
--!    SEN-WB-WF1-HW-356
--!    SEN-WB-WF1-HW-357
--!    SEN-WB-WF1-HW-358
--!    SEN-WB-WF1-HW-360
--!    SEN-WB-WF1-HW-361
--!    SEN-WB-WF1-HW-620
--!    SEN-WB-WF1-HW-368
--!    SEN-WB-WF1-HW-369
--!    SEN-WB-WF1-HW-370
--!    SEN-WB-WF1-HW-371
--!    SEN-WB-WF1-HW-372
--!    SEN-WB-WF1-HW-374
--!    SEN-WB-WF1-HW-375
--!    SEN-WB-WF1-HW-376
--!    SEN-WB-WF1-HW-377
--!    SEN-WB-WF1-HW-388
--!    SEN-WB-WF1-HW-389
--!    SEN-WB-WF1-HW-390
--!    SEN-WB-WF1-HW-391
--!    SEN-WB-WF1-HW-621
--!    SEN-WB-WF1-HW-592
--!    SEN-WB-WF1-HW-593
--!    SEN-WB-WF1-HW-615
--!    SEN-WB-WF1-HW-616
--!    SEN-WB-WF1-HW-480
--!    SEN-WB-WF1-HW-468
--!    SEN-WB-WF1-HW-469
--!    SEN-WB-WF1-HW-470
--!    SEN-WB-WF1-HW-471
--!    SEN-WB-WF1-HW-472
--!    SEN-WB-WF1-HW-622
--!    SEN-WB-WF1-HW-473
--!    SEN-WB-WF1-HW-474
--!    SEN-WB-WF1-HW-475
--!    SEN-WB-WF1-HW-481
--!    SEN-WB-WF1-HW-482
--!    SEN-WB-WF1-HW-483
--!    SEN-WB-WF1-HW-484
--!    SEN-WB-WF1-HW-485
--!    SEN-WB-WF1-HW-486
--!    SEN-WB-WF1-HW-487
--!    SEN-WB-WF1-HW-488
--!    SEN-WB-WF1-HW-623
--!    SEN-WB-WF1-HW-489
--!    SEN-WB-WF1-HW-490
--!    SEN-WB-WF1-HW-491
--!    SEN-WB-WF1-HW-492
--!    SEN-WB-WF1-HW-493
--!    SEN-WB-WF1-HW-625
--!    SEN-WB-WF1-HW-494
--!    SEN-WB-WF1-HW-495
--!    SEN-WB-WF1-HW-496
--!    SEN-WB-WF1-HW-497
--!    SEN-WB-WF1-HW-498
--!    SEN-WB-WF1-HW-499
--!    SEN-WB-WF1-HW-500
--!    SEN-WB-WF1-HW-501
--!    SEN-WB-WF1-HW-502
--!    SEN-WB-WF1-HW-503
--!    SEN-WB-WF1-HW-504
--!    SEN-WB-WF1-HW-505
--!    SEN-WB-WF1-HW-506
--!    SEN-WB-WF1-HW-507
--!    SEN-WB-WF1-HW-508
--!    SEN-WB-WF1-HW-509
--!    SEN-WB-WF1-HW-626
--!    SEN-WB-WF1-HW-510
--!    SEN-WB-WF1-HW-624
--!    SEN-WB-WF1-HW-511
--!    SEN-WB-WF1-HW-512
--!    SEN-WB-WF1-HW-518
--!    SEN-WB-WF1-HW-450
--!    SEN-WB-WF1-HW-451
--!    SEN-WB-WF1-HW-452
--!    SEN-WB-WF1-HW-453
--!    SEN-WB-WF1-HW-627
--!
--! Features:
--! 1.  FSI FPGA
--! 2.  Modem ADT Configuration: 
--! 2.1. Select the FSI_ADT_RL module: Multiplexer module 
--! 2.2. Select the FSI_ADT_FL module: Demultiplexer module 
--! 3.  Modem GDT Configuration: 
--! 3.1. Select the FSI_GDT_RL module: Demultiplexer module 
--! 3.2. Select the FSI_GDT_FL module: Multiplexer module 
--!
--! Limitations:
--! 1. All the possibilities in the FSI configuration are included in the same module
--! 2.  
--! 
--! Module performances
--! 1.   Frequency: 
--! 1.1. System Clock (Clk): 50 MHz
--!
--! 2.   Resources: 
--!
--! @class fsi_core_logic.rtl
--! @image html rtl_bdfsi_core_logic.png
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library fsi_adt_rl;
library fsi_adt_fl;
library fsi_gdt_rl;
library fsi_gdt_fl;


architecture rtl of fsi_core_logic is

   -- Architecture declarations

   -- Internal signal declarations
   signal adt_gdt          : std_logic_vector(4 downto 0);
   signal ch_clear         : std_logic;
   signal ch_fl_rdata      : std_logic_vector(7 downto 0);
   signal ch_rd            : std_logic;
   signal ch_rl_rdata      : std_logic_vector(7 downto 0);
   signal ch_sel           : std_logic_vector(3 downto 0);
   signal ch_wdata         : std_logic_vector(8 downto 0);
   signal ch_wr            : std_logic;
   signal decryp_fl_bypass : std_logic;
   signal decryp_fl_enable : std_logic;
   signal decryp_rl_bypass : std_logic;
   signal decryp_rl_enable : std_logic;
   signal encryp_fl_bypass : std_logic;
   signal encryp_fl_enable : std_logic;
   signal encryp_rl_bypass : std_logic;
   signal encryp_rl_enable : std_logic;
   signal eth_rx_fl_enable : std_logic;
   signal eth_rx_fl_sel    : std_logic;
   signal eth_rx_rl_enable : std_logic;
   signal eth_rx_rl_sel    : std_logic;
   signal eth_tx_fl_enable : std_logic;
   signal eth_tx_fl_sel    : std_logic;
   signal eth_tx_rl_enable : std_logic;
   signal eth_tx_rl_sel    : std_logic;
   signal fl_pmec_sync     : std_logic;
   signal fl_status        : std_logic_vector(31 downto 0);
   signal fl_status_clear  : std_logic;
   signal m_rx_fl_tdata    : std_logic_vector(7 downto 0);                        --! Word read from memory
   signal m_rx_fl_tlast    : std_logic;
   signal m_rx_fl_tready   : std_logic;
   signal m_rx_fl_tvalid   : std_logic;                                           --! AXI-S master interface, valid
   signal m_rx_rl_tdata    : std_logic_vector(7 downto 0);                        --! Word read from memory
   signal m_rx_rl_tlast    : std_logic;
   signal m_rx_rl_tready   : std_logic                     := '0';
   signal m_rx_rl_tvalid   : std_logic;                                           --! AXI-S master interface, valid
   signal m_tx_fl_tdata    : std_logic_vector(31 downto 0);
   signal m_tx_fl_tready   : std_logic;
   signal m_tx_fl_tvalid   : std_logic;
   signal m_tx_rl_tdata    : std_logic_vector(31 downto 0);
   signal m_tx_rl_tready   : std_logic                     := '0';
   signal m_tx_rl_tvalid   : std_logic;
   signal nav_eop          : std_logic;
   signal nav_rd           : std_logic;
   signal nav_rdata        : std_logic_vector(15 downto 0);
   signal nav_start        : std_logic;
   signal nav_stop         : std_logic;
   signal nav_wdata        : std_logic_vector(15 downto 0);
   signal nav_wr           : std_logic;
   signal rl_ch_wr         : std_logic;
   signal rl_status        : std_logic_vector(31 downto 0);
   signal rl_status1       : std_logic_vector(31 downto 0);
   signal rl_status_clear  : std_logic;
   signal rl_status_clear1 : std_logic;
   signal s_rx_fl_tdata    : std_logic_vector(31 downto 0) := (others => '0');    --! AXI-S Slave interface, data
   signal s_rx_fl_tready   : std_logic;                                           --! AXI-S Slave interface, ready
   signal s_rx_fl_tvalid   : std_logic                     := '0';                --! AXI-S Slave interface, valid
   signal s_rx_rl_tdata    : std_logic_vector(31 downto 0) := (others => '0');    --! AXI-S Slave interface, data
   signal s_rx_rl_tready   : std_logic;                                           --! AXI-S Slave interface, ready
   signal s_rx_rl_tvalid   : std_logic                     := '0';                --! AXI-S Slave interface, valid
   signal s_tx_fl_tdata    : std_logic_vector(7 downto 0);                        --! Word read from memory
   signal s_tx_fl_tlast    : std_logic;
   signal s_tx_fl_tready   : std_logic;
   signal s_tx_fl_tvalid   : std_logic;                                           --! AXI-S master interface, valid
   signal s_tx_rl_tdata    : std_logic_vector(7 downto 0);                        --! Word read from memory
   signal s_tx_rl_tlast    : std_logic;
   signal s_tx_rl_tready   : std_logic;
   signal s_tx_rl_tvalid   : std_logic;                                           --! AXI-S master interface, valid
   signal trigger_range    : STD_LOGIC;

   -- Implicit buffer signal declarations
   signal profile_cfg_internal : std_logic_vector (5 downto 0);


   -- Component Declarations
   component fsi_adt_fl
   port (
      clk             : in     std_logic ;
      fl_profile_cfg  : in     std_logic_vector (5 downto 0);
      fl_status_clear : in     std_logic ;
      m_tready        : in     std_logic ;
      rst_n           : in     std_logic ;
      s_tdata         : in     std_logic_vector (31 downto 0); --! AXI-S Slave interface, data
      s_tvalid        : in     std_logic ;                     --! AXI-S Slave interface, valid
      decryp_bypass   : out    std_logic ;
      decryp_enable   : out    std_logic ;
      enable          : out    std_logic ;
      fl_status       : out    std_logic_vector (31 downto 0);
      m_tdata         : out    std_logic_vector (7 downto 0);
      m_tlast         : out    std_logic ;
      m_tvalid        : out    std_logic ;
      s_tready        : out    std_logic ;                     --! AXI-S Slave interface, ready
      sel_eth         : out    std_logic ;
      trigger_range   : out    std_logic 
   );
   end component fsi_adt_fl;
   component fsi_adt_rl
   port (
      clk                 : in     std_logic ;
      fl_pmec_sync        : in     std_logic ;
      m_tready            : in     std_logic ;
      pn_code_gen_trck_st : in     std_logic_vector (1 downto 0);
      rl_ch_clear         : in     std_logic ;
      rl_ch_rd            : in     std_logic ;
      rl_ch_wdata         : in     std_logic_vector (8 downto 0);
      rl_ch_wr            : in     std_logic ;
      rl_nav_start        : in     std_logic ;
      rl_nav_stop         : in     std_logic ;
      rl_nav_wdata        : in     std_logic_vector (15 downto 0);
      rl_nav_wr           : in     std_logic ;
      rl_profile_cfg      : in     std_logic_vector (5 downto 0);
      rst_n               : in     std_logic ;
      s_tdata             : in     std_logic_vector (7 downto 0); --! Word read from memory
      s_tlast             : in     std_logic ;
      s_tvalid            : in     std_logic ;                    --! AXI-S master interface, valid
      trigger_range       : in     STD_LOGIC ;
      enable              : out    std_logic ;
      encryp_bypass       : out    std_logic ;
      encryp_enable       : out    std_logic ;
      m_tdata             : out    std_logic_vector (31 downto 0);
      m_tvalid            : out    std_logic ;
      rl_ch_rdata         : out    std_logic_vector (7 downto 0);
      s_tready            : out    std_logic ;
      sel_eth             : out    std_logic 
   );
   end component fsi_adt_rl;
   component fsi_gdt_fl
   port (
      clk            : in     std_logic ;
      fl_ch_clear    : in     std_logic ;
      fl_ch_rd       : in     std_logic ;
      fl_ch_sel      : in     std_logic_vector (3 downto 0);
      fl_ch_wdata    : in     std_logic_vector (8 downto 0);
      fl_ch_wr       : in     std_logic ;
      fl_pmec_sync   : in     std_logic ;
      fl_profile_cfg : in     std_logic_vector (5 downto 0);
      m_tready       : in     std_logic ;
      rst_n          : in     std_logic ;
      s_tdata        : in     std_logic_vector (7 downto 0); --! Word read from memory
      s_tlast        : in     std_logic ;
      s_tvalid       : in     std_logic ;                    --! AXI-S master interface, valid
      enable         : out    std_logic ;
      encryp_bypass  : out    std_logic ;
      encryp_enable  : out    std_logic ;
      fl_ch_rdata    : out    std_logic_vector (7 downto 0);
      m_tdata        : out    std_logic_vector (31 downto 0);
      m_tvalid       : out    std_logic ;
      s_tready       : out    std_logic ;
      sel_eth        : out    std_logic 
   );
   end component fsi_gdt_fl;
   component fsi_gdt_rl
   port (
      clk             : in     std_logic ;
      m_tready        : in     std_logic ;
      rl_nav_rd       : in     std_logic ;
      rl_nav_start    : in     std_logic ;
      rl_nav_stop     : in     std_logic ;
      rl_profile_cfg  : in     std_logic_vector (5 downto 0);
      rl_status_clear : in     std_logic ;
      rst_n           : in     std_logic ;
      s_tdata         : in     std_logic_vector (31 downto 0); --! AXI-S Slave interface, data
      s_tvalid        : in     std_logic ;                     --! AXI-S Slave interface, valid
      decryp_bypass   : out    std_logic ;
      decryp_enable   : out    std_logic ;
      enable          : out    std_logic ;
      fl_pmec_sync    : out    std_logic ;
      m_tdata         : out    std_logic_vector (7 downto 0);
      m_tlast         : out    std_logic ;
      m_tvalid        : out    std_logic ;
      rl_nav_data     : out    std_logic_vector (15 downto 0);
      rl_nav_eop      : out    std_logic ;
      rl_status       : out    std_logic_vector (31 downto 0);
      s_tready        : out    std_logic ;                     --! AXI-S Slave interface, ready
      sel_eth         : out    std_logic 
   );
   end component fsi_gdt_rl;
   component fsi_core_logic_tmtc
   generic (
      g_add_size : integer := 16
   );
   port (
      ProcAddr        : in     std_logic_vector (g_add_size-1 downto 0); -- 63 adresse max.
      ProcCs          : in     std_logic ;
      ProcDataIn      : in     std_logic_vector (31 downto 0);
      ProcRNW         : in     std_logic ;
      ch_fl_rdata     : in     std_logic_vector (7 downto 0);
      ch_rl_rdata     : in     std_logic_vector (7 downto 0);
      clk             : in     std_logic ;
      fl_status       : in     std_logic_vector (31 downto 0);
      nav_rdata       : in     std_logic_vector (15 downto 0);
      rl_status       : in     std_logic_vector (31 downto 0);
      rst_n           : in     std_logic ;
      sel_adt_gdt     : in     std_logic ;
      ProcDataOut     : out    std_logic_vector (31 downto 0);
      ProcRdAck       : out    std_logic ;
      ProcWrAck       : out    std_logic ;
      adt_gdt         : out    std_logic_vector (4 downto 0);
      aes_newkey      : out    std_logic ;
      ch_clear        : out    std_logic ;
      ch_rd           : out    std_logic ;
      ch_sel          : out    std_logic_vector (3 downto 0);
      ch_wdata        : out    std_logic_vector (8 downto 0);
      ch_wr           : out    std_logic ;
      fl_status_clear : out    std_logic ;
      nav_rd          : out    std_logic ;
      nav_start       : out    std_logic ;
      nav_stop        : out    std_logic ;
      nav_wdata       : out    std_logic_vector (15 downto 0);
      nav_wr          : out    std_logic ;
      profile_cfg     : out    std_logic_vector (5 downto 0);
      rl_status_clear : out    std_logic 
   );
   end component fsi_core_logic_tmtc;


begin
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 1 p_mux_rx
   -- -----------------------------------------------------------------------------
   -- p_mux_rx: Select the receptor between GDT RL and ADT FL 
   -- -----------------------------------------------------------------------------
   -- adt_gdt = YX -> Y Select the receiver, X select the transmitter
   -- -----------------------------------------------------------------------------
   -- Return Link: adt_gdt(1) = 0
   -- Forward Link: adt_gdt(1) = 1
   -- -----------------------------------------------------------------------------
   s_rx_rl_tdata <= s_rx_tdata;
   s_rx_fl_tdata <= s_rx_tdata;
   
   s_rx_rl_tvalid <= s_rx_tvalid when(adt_gdt(1) = '0') else
      '0';
   s_rx_fl_tvalid <= s_rx_tvalid when(adt_gdt(1) = '1') else
      '0';
   
   s_rx_tready <= s_rx_rl_tready when(adt_gdt(1) = '0') else
      s_rx_fl_tready;
   
   decryp_enable <= decryp_rl_enable when(adt_gdt(1) = '0') else
      decryp_fl_enable;
   decryp_bypass <= decryp_rl_bypass when(adt_gdt(1) = '0') else
      decryp_fl_bypass;
   -- -----------------------------------------------------------------------------
   enable_fsi_rx <= (decryp_rl_enable or decryp_rl_bypass) when(adt_gdt(1) = '0') else
      (decryp_fl_enable or decryp_fl_bypass);
   -- -----------------------------------------------------------------------------
   fl_pmec_sync_out <= fl_pmec_sync_in when (adt_gdt(0) = '1' or adt_gdt(1) = '1') else fl_pmec_sync;
   -- -----------------------------------------------------------------------------

   -- HDL Embedded Text Block 2 p_mux_tx
   -- -----------------------------------------------------------------------------
   -- p_mux_tx: Select the transmitter between ADT RL and GDT FL
   -- -----------------------------------------------------------------------------
   -- adt_gdt = YX -> Y Select the receiver, X select the transmitter
   -- -----------------------------------------------------------------------------
   -- Return Link: adt_gdt(0) = 0
   -- Forward Link: adt_gdt(0) = 1
   -- -----------------------------------------------------------------------------
   m_tx_tdata <= m_tx_rl_tdata when(adt_gdt(0) = '0') else
      m_tx_fl_tdata;
   
   m_tx_tvalid <= m_tx_rl_tvalid when(adt_gdt(0) = '0') else
      m_tx_fl_tvalid;
   
   m_tx_rl_tready <= m_tx_tready when(adt_gdt(0) = '0') else
      '0';
   m_tx_fl_tready <= m_tx_tready when(adt_gdt(0) = '1') else
      '0';
   
   encryp_enable <= encryp_rl_enable when(adt_gdt(0) = '0') else
      encryp_fl_enable;
   
   encryp_bypass <= encryp_rl_bypass when(adt_gdt(0) = '0') else
      encryp_fl_bypass;
   -- -----------------------------------------------------------------------------
   enable_fsi_tx <= (encryp_rl_enable or encryp_rl_bypass) when(adt_gdt(0) = '0') else
      (encryp_fl_enable or encryp_fl_bypass);
   -- -----------------------------------------------------------------------------

   -- HDL Embedded Text Block 3 p_eth_tx
   -- -----------------------------------------------------------------------------
   -- p_eth_tx: Select the transmitter between ADT RL and GDT FL
   -- -----------------------------------------------------------------------------
   -- adt_gdt = YX -> Y Select the receiver, X select the transmitter
   -- -----------------------------------------------------------------------------
   -- Return Link: adt_gdt(0) = 0
   -- Forward Link: adt_gdt(0) = 1
   -- -----------------------------------------------------------------------------
   s_tx_fl_tdata <= s_tx_tdata;
   s_tx_rl_tdata <= s_tx_tdata;
   
   s_tx_fl_tlast <= s_tx_tlast;
   s_tx_rl_tlast <= s_tx_tlast;
   
   s_tx_fl_tvalid <= s_tx_tvalid when((adt_gdt(0) = '1')) else
      '0';
   s_tx_rl_tvalid <= s_tx_tvalid when((adt_gdt(0) = '0')) else
      '0';
   
   s_tx_tready <= s_tx_fl_tready when((adt_gdt(0) = '1')) else
      s_tx_rl_tready when((adt_gdt(0) = '0')) else
      '0';
   
   eth_tx_enable <= eth_tx_fl_enable when((adt_gdt(0) = '1')) else
      eth_tx_rl_enable when((adt_gdt(0) = '0')) else
      '0';
   
   eth_tx_sel <= eth_tx_fl_sel when(adt_gdt(4) = '0' and adt_gdt(0) = '1') else
      eth_tx_rl_sel when(adt_gdt(4) = '0' and adt_gdt(0) = '0') else
      adt_gdt(2) when(adt_gdt(4) = '1') else
      '0';
   -- -----------------------------------------------------------------------------    

   -- HDL Embedded Text Block 4 p_eth_rx
   -- -----------------------------------------------------------------------------
   -- p_eth_rx: Select the receptor between GDT RL and ADT FL 
   -- -----------------------------------------------------------------------------
   -- adt_gdt = YX -> Y Select the receiver, X select the transmitter
   -- -----------------------------------------------------------------------------
   -- Return Link: adt_gdt(1) = 0
   -- Forward Link: adt_gdt(1) = 1
   -- -----------------------------------------------------------------------------
   m_rx_tdata <= m_rx_rl_tdata when(adt_gdt(1) = '0' and m_rx_rl_tvalid = '1' and m_rx_rl_tready = '1') else
      m_rx_fl_tdata when(adt_gdt(1) = '1' and m_rx_fl_tvalid = '1' and m_rx_fl_tready = '1') else
      (others => '0');
   
   m_rx_tlast <= m_rx_rl_tlast when(adt_gdt(1) = '0') else
      m_rx_fl_tlast;
   
   m_rx_tvalid <= m_rx_rl_tvalid when(adt_gdt(1) = '0') else
      m_rx_fl_tvalid;
   
   m_rx_rl_tready <= m_rx_tready when(adt_gdt(1) = '0') else
      '0';
   m_rx_fl_tready <= m_rx_tready when(adt_gdt(1) = '1') else
      '0';
   
   eth_rx_enable <= eth_rx_rl_enable when(adt_gdt(1) = '0') else
      eth_rx_fl_enable;
   
   eth_rx_sel <= eth_rx_rl_sel when(adt_gdt(4) = '0' and adt_gdt(1) = '0') else
      eth_rx_fl_sel when(adt_gdt(4) = '0' and adt_gdt(1) = '1') else
      adt_gdt(3) when(adt_gdt(4) = '1') else
      '0';
   -- -----------------------------------------------------------------------------


   -- Instance port mappings.
   i_fl_rx : fsi_adt_fl
      port map (
         clk             => clk,
         fl_profile_cfg  => profile_cfg_internal,
         fl_status_clear => fl_status_clear,
         m_tready        => m_rx_fl_tready,
         rst_n           => rst_n,
         s_tdata         => s_rx_fl_tdata,
         s_tvalid        => s_rx_fl_tvalid,
         decryp_bypass   => decryp_fl_bypass,
         decryp_enable   => decryp_fl_enable,
         enable          => eth_rx_fl_enable,
         fl_status       => fl_status,
         m_tdata         => m_rx_fl_tdata,
         m_tlast         => m_rx_fl_tlast,
         m_tvalid        => m_rx_fl_tvalid,
         s_tready        => s_rx_fl_tready,
         sel_eth         => eth_rx_fl_sel,
         trigger_range   => trigger_range
      );
   i_rl_tx : fsi_adt_rl
      port map (
         clk                 => clk,
         fl_pmec_sync        => fl_pmec_sync_in,
         m_tready            => m_tx_rl_tready,
         pn_code_gen_trck_st => pn_code_gen_trck_st_in,
         rl_ch_clear         => ch_clear,
         rl_ch_rd            => ch_rd,
         rl_ch_wdata         => ch_wdata,
         rl_ch_wr            => ch_wr,
         rl_nav_start        => nav_start,
         rl_nav_stop         => nav_stop,
         rl_nav_wdata        => nav_wdata,
         rl_nav_wr           => nav_wr,
         rl_profile_cfg      => profile_cfg_internal,
         rst_n               => rst_n,
         s_tdata             => s_tx_rl_tdata,
         s_tlast             => s_tx_rl_tlast,
         s_tvalid            => s_tx_rl_tvalid,
         trigger_range       => trigger_range,
         enable              => eth_tx_rl_enable,
         encryp_bypass       => encryp_rl_bypass,
         encryp_enable       => encryp_rl_enable,
         m_tdata             => m_tx_rl_tdata,
         m_tvalid            => m_tx_rl_tvalid,
         rl_ch_rdata         => ch_rl_rdata,
         s_tready            => s_tx_rl_tready,
         sel_eth             => eth_tx_rl_sel
      );
   i_fl_tx : fsi_gdt_fl
      port map (
         clk            => clk,
         fl_ch_clear    => ch_clear,
         fl_ch_rd       => ch_rd,
         fl_ch_sel      => ch_sel,
         fl_ch_wdata    => ch_wdata,
         fl_ch_wr       => ch_wr,
         fl_pmec_sync   => fl_pmec_sync_in,
         fl_profile_cfg => profile_cfg_internal,
         m_tready       => m_tx_fl_tready,
         rst_n          => rst_n,
         s_tdata        => s_tx_fl_tdata,
         s_tlast        => s_tx_fl_tlast,
         s_tvalid       => s_tx_fl_tvalid,
         enable         => eth_tx_fl_enable,
         encryp_bypass  => encryp_fl_bypass,
         encryp_enable  => encryp_fl_enable,
         fl_ch_rdata    => ch_fl_rdata,
         m_tdata        => m_tx_fl_tdata,
         m_tvalid       => m_tx_fl_tvalid,
         s_tready       => s_tx_fl_tready,
         sel_eth        => eth_tx_fl_sel
      );
   i_rl_rx : fsi_gdt_rl
      port map (
         clk             => clk,
         m_tready        => m_rx_rl_tready,
         rl_nav_rd       => nav_rd,
         rl_nav_start    => nav_start,
         rl_nav_stop     => nav_stop,
         rl_profile_cfg  => profile_cfg_internal,
         rl_status_clear => rl_status_clear,
         rst_n           => rst_n,
         s_tdata         => s_rx_rl_tdata,
         s_tvalid        => s_rx_rl_tvalid,
         decryp_bypass   => decryp_rl_bypass,
         decryp_enable   => decryp_rl_enable,
         enable          => eth_rx_rl_enable,
         fl_pmec_sync    => fl_pmec_sync,
         m_tdata         => m_rx_rl_tdata,
         m_tlast         => m_rx_rl_tlast,
         m_tvalid        => m_rx_rl_tvalid,
         rl_nav_data     => nav_rdata,
         rl_nav_eop      => nav_eop,
         rl_status       => rl_status,
         s_tready        => s_rx_rl_tready,
         sel_eth         => eth_rx_rl_sel
      );
   i_tmtc : fsi_core_logic_tmtc
      generic map (
         g_add_size => g_add_size
      )
      port map (
         ProcAddr        => ProcAddr,
         ProcCs          => ProcCs,
         ProcDataIn      => ProcDatain,
         ProcRNW         => ProcRNW,
         ch_fl_rdata     => ch_fl_rdata,
         ch_rl_rdata     => ch_rl_rdata,
         clk             => clk,
         fl_status       => fl_status,
         nav_rdata       => nav_rdata,
         rl_status       => rl_status,
         rst_n           => rst_n,
         sel_adt_gdt     => sel_adt_gdt,
         ProcDataOut     => ProcDataout,
         ProcRdAck       => ProcRdAck,
         ProcWrAck       => ProcWrAck,
         adt_gdt         => adt_gdt,
         aes_newkey      => encryp_newkey,
         ch_clear        => ch_clear,
         ch_rd           => ch_rd,
         ch_sel          => ch_sel,
         ch_wdata        => ch_wdata,
         ch_wr           => ch_wr,
         fl_status_clear => fl_status_clear,
         nav_rd          => nav_rd,
         nav_start       => nav_start,
         nav_stop        => nav_stop,
         nav_wdata       => nav_wdata,
         nav_wr          => nav_wr,
         profile_cfg     => profile_cfg_internal,
         rl_status_clear => rl_status_clear
      );

   -- Implicit buffered output assignments
   profile_cfg <= profile_cfg_internal;

end architecture rtl;

-- ----------------------------------------------------------------------------