-- ----------------------------------------------------------------------------
--! Library       : snrf031
--! Entity        : fsi_core
--! Lenguaje      : VHDL-2008
-- ---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsi_core is
   generic( 
      g_add_size       : integer                := 16;
      g_slave_bus_size : integer                := 4;
      g_fpga_mayor     : integer range 0 to 31  := 0;
      g_fpga_minor     : integer range 0 to 31  := 0;
      g_fpga_number    : integer range 0 to 255 := 31;
      g_fpga_rev       : integer range 0 to 255 := 1
   );
   port( 
      ProcAddr            : in     std_logic_vector (g_add_size+g_slave_bus_size-1 downto 0);  -- 63 adresse max.
      ProcCs              : in     std_logic;
      ProcDataIn          : in     std_logic_vector (31 downto 0);
      ProcRNW             : in     std_logic;
      RXN                 : in     std_logic;
      -- GTX Serial I/O
      RXP                 : in     std_logic;
      clk                 : in     std_logic;
      clk_aurora          : in     std_ulogic  := '0';
      clk_dly             : in     std_logic;
      clk_eth             : in     std_logic;
      dds_sdio_1          : in     std_logic;
      dds_sdio_2          : in     std_logic;
      mii_rx_clk          : in     std_logic   := '0';
      mii_rx_col          : in     std_logic;
      mii_rx_crs          : in     std_logic;
      mii_rx_data         : in     std_logic_vector (3 downto 0);
      mii_rx_dv           : in     std_logic;
      mii_rx_er           : in     std_logic;
      mii_tx_clk          : in     std_logic;
      rgmii_rx_clk        : in     std_logic   := '0';
      rgmii_rx_ctl        : in     std_logic;
      rgmii_rx_data       : in     std_logic_vector (3 downto 0);
      rst_n               : in     std_logic;
      ProcDataOut         : out    std_logic_vector (31 downto 0);
      ProcRdAck           : out    std_logic;
      ProcWrAck           : out    std_logic;
      TXN                 : out    std_logic;
      TXP                 : out    std_logic;
      dds_cs_n            : out    std_logic;
      dds_ioupdate        : out    std_logic;
      dds_pwr_dwn         : out    std_logic;                                                  -- Power down DDS
      dds_rst             : out    std_logic;                                                  -- Reset DDS
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

end entity fsi_core ;

-- ----------------------------------------------------------------------------
--! @class fsi_core
--! @image html symbol_sbfsi_core.png
--! @author Alicia Bermejo
--! @version 1.0
--! @date 20/06/2023
--!
--! @brief 
--!  This module implements the Ethernet interface, the Ethernet frame multiplexer,
--!  the telecommand/telemetry interface in the FSI FPGA, the encryption interface, the decryption
--!  interface and the Aurora communications interface.
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
--! 1.2. Ethernet Clock (tx_clk): 25 MHz
--! 1.3. Reference Clock (Clk_dly): 200 MHzz
--!
--! 2.   Resources: 
--!
--! @class fsi_core.rtl
--! @image html rtl_bdfsi_core.png
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library module_fsi_aurora;

library ip_flink;
library ip_temp_if;
library ip_dds;
library ip_encrypter;
library ip_decrypter;


architecture rtl of fsi_core is

   -- Architecture declarations
   constant c_number: std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(g_fpga_number, 8));
   constant c_mayor: std_logic_vector(3 downto 0) := std_logic_vector(to_unsigned(g_fpga_mayor, 4));
   constant c_minor: std_logic_vector(3 downto 0) := std_logic_vector(to_unsigned(g_fpga_minor, 4));
   constant c_rev: std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(g_fpga_rev, 8));
   
   constant c_version: std_logic_vector(31 downto 0) := X"00" & c_number & c_mayor & c_minor & c_rev;

   -- Internal signal declarations
   signal ProcAddr_mst           : std_logic_vector(g_add_size-1 downto 0);    -- !! adresse mot et non octet
   signal ProcCs_aurora          : std_logic;
   signal ProcCs_core            : std_logic;
   signal ProcCs_dds             : std_logic;
   signal ProcCs_decryp          : std_logic;
   signal ProcCs_encryp          : std_logic;
   signal ProcCs_flink           : std_logic;
   signal ProcCs_mii             : std_logic;
   signal ProcCs_mst             : std_logic;
   signal ProcCs_rgmii           : std_logic;
   signal ProcCs_srv             : std_logic;
   signal ProcCs_temp            : std_logic;
   signal ProcDataIn_mst         : std_logic_vector(31 downto 0);
   signal ProcDataOut_aurora     : std_logic_vector(31 downto 0);
   signal ProcDataOut_core       : std_logic_vector(31 downto 0);
   signal ProcDataOut_dds        : std_logic_vector(31 downto 0);
   signal ProcDataOut_decryp     : std_logic_vector(31 downto 0);
   signal ProcDataOut_encryp     : std_logic_vector(31 downto 0);
   signal ProcDataOut_flink      : std_logic_vector(31 downto 0);
   signal ProcDataOut_mii        : std_logic_vector(31 downto 0);
   signal ProcDataOut_rgmii      : std_logic_vector(31 downto 0);
   signal ProcDataOut_srv        : std_logic_vector(31 downto 0);
   signal ProcDataOut_temp       : std_logic_vector(31 downto 0);
   signal ProcRNW_mst            : std_logic;                                  -- read/not write
   signal ProcRNW_rgmii          : std_logic;
   signal ProcRdAck_aurora       : std_logic;
   signal ProcRdAck_core         : std_logic;
   signal ProcRdAck_dds          : std_logic;
   signal ProcRdAck_decryp       : std_logic;
   signal ProcRdAck_encryp       : std_logic;
   signal ProcRdAck_flink        : std_logic;
   signal ProcRdAck_mii          : std_logic;
   signal ProcRdAck_rgmii        : std_logic;
   signal ProcRdAck_srv          : std_logic;
   signal ProcRdAck_temp         : std_logic;
   signal ProcWrAck_aurora       : std_logic;
   signal ProcWrAck_core         : std_logic;
   signal ProcWrAck_dds          : std_logic;
   signal ProcWrAck_decryp       : std_logic;
   signal ProcWrAck_encryp       : std_logic;
   signal ProcWrAck_flink        : std_logic;
   signal ProcWrAck_mii          : std_logic;
   signal ProcWrAck_rgmii        : std_logic;
   signal ProcWrAck_srv          : std_logic;
   signal ProcWrAck_temp         : std_logic;
   signal dds_phase_err          : std_logic_vector(5 downto 0);
   signal decryp_bypass          : std_logic;
   signal decryp_enable          : std_logic;
   signal decrypt_tdata          : std_logic_vector(31 downto 0);
   signal decrypt_tready         : std_logic;
   signal decrypt_tvalid         : std_logic;
   signal demux_tdata            : std_logic_vector(31 downto 0);
   signal demux_tready           : std_logic;
   signal demux_tvalid           : std_logic;
   signal enable_fsi_rx          : std_logic;
   signal enable_fsi_tx          : std_logic;
   signal encryp_bypass          : std_logic;
   signal encryp_enable          : std_logic;
   signal encryp_newkey          : std_logic;
   signal encrypt_tdata          : std_logic_vector(31 downto 0);
   signal encrypt_tready         : std_logic;
   signal encrypt_tvalid         : std_logic;                                  -- data valid
   signal eth_rx_enable          : std_logic;
   signal eth_rx_sel             : std_logic;
   signal eth_rx_tdata           : std_logic_vector(7 downto 0);               --! Word read from memory
   signal eth_rx_tlast           : std_logic;
   signal eth_rx_tready          : std_logic;
   signal eth_rx_tvalid          : std_logic;                                  --! AXI-S master interface, valid
   signal eth_tx_enable          : std_logic;
   signal eth_tx_sel             : std_logic;
   signal eth_tx_tdata           : std_logic_vector(7 downto 0);               --! Word read from memory
   signal eth_tx_tlast           : std_logic;
   signal eth_tx_tready          : std_logic;
   signal eth_tx_tvalid          : std_logic;                                  --! AXI-S master interface, valid
   signal fl_pmec_sync_in        : std_logic;
   signal fl_pmec_sync_out       : std_logic;
   signal mux_tdata              : std_logic_vector(31 downto 0);
   signal mux_tready             : std_logic;
   signal mux_tvalid             : std_logic;
   signal pn_code_gen_trck_st_in : std_logic_vector(1 downto 0);
   signal profile_cfg            : std_logic_vector(5 downto 0);
   signal sel_adt_gdt            : std_logic;


   -- Component Declarations
   component ip_dds
   generic (
      g_addr_len : natural := 16
   );
   port (
      ProcAddr            : in     std_logic_vector (g_addr_len -1 downto 0);
      ProcCs              : in     std_logic ;
      ProcDataIn          : in     std_logic_vector (31 downto 0);
      ProcRNW             : in     std_logic ;
      clk                 : in     std_logic ;
      dds_phase_err       : in     std_logic_vector (5 downto 0);
      dds_sdio_1          : in     std_logic ;
      dds_sdio_2          : in     std_logic ;
      reset_n             : in     std_logic ;
      ProcDataOut         : out    std_logic_vector (31 downto 0);
      ProcRdAck           : out    std_logic ;
      ProcWrAck           : out    std_logic ;
      dds_cs_n            : out    std_logic ;
      dds_ioupdate        : out    std_logic ;
      dds_pwr_dwn         : out    std_logic ;
      dds_rst             : out    std_logic ;
      dds_sclk            : out    std_logic ;
      dds_sdio_0          : out    std_logic ;
      dds_sdio_3          : out    std_logic ;
      pw_dw_clk_adc_bot_n : out    std_logic ;
      pw_dw_clk_adc_top_n : out    std_logic ;
      pw_dw_clk_dac_bot_n : out    std_logic ;
      pw_dw_clk_dac_top_n : out    std_logic ;
      pw_dw_ref_fre_rx_n  : out    std_logic ;
      pw_dw_ref_fre_tx_n  : out    std_logic 
   );
   end component ip_dds;
   component ip_decrypter
   generic (
      g_add_size : integer := 16
   );
   port (
      ProcAddr    : in     std_logic_vector (g_add_size-1 downto 0); -- !! adresse mot et non octet
      ProcCs      : in     std_logic ;
      ProcDataIn  : in     std_logic_vector (31 downto 0);
      ProcRNW     : in     std_logic ;                               -- read/not write
      bypass      : in     std_logic ;
      clk         : in     std_logic ;
      enable      : in     std_logic ;
      m_tready    : in     std_logic ;
      reset_n     : in     std_logic ;
      s_tdata     : in     std_logic_vector (31 downto 0);
      s_tvalid    : in     std_logic ;                               --! Write enable, port A
      ProcDataOut : out    std_logic_vector (31 downto 0);
      ProcRdAck   : out    std_logic ;
      ProcWrAck   : out    std_logic ;
      m_tdata     : out    std_logic_vector (31 downto 0);
      m_tvalid    : out    std_logic ;
      s_tready    : out    std_logic                                 --! AXI-S Slave interface, ready
   );
   end component ip_decrypter;
   component ip_encrypter
   generic (
      g_add_size : integer := 16
   );
   port (
      ProcAddr    : in     std_logic_vector (g_add_size-1 downto 0); -- !! adresse mot et non octet
      ProcCs      : in     std_logic ;
      ProcDataIn  : in     std_logic_vector (31 downto 0);
      ProcRNW     : in     std_logic ;                               -- read/not write
      bypass      : in     std_logic ;
      clk         : in     std_logic ;
      enable      : in     std_logic ;
      m_tready    : in     std_logic ;
      newkey      : in     std_logic ;
      reset_n     : in     std_logic ;
      s_tdata     : in     std_logic_vector (31 downto 0);
      s_tvalid    : in     std_logic ;                               --! Write enable, port A
      ProcDataOut : out    std_logic_vector (31 downto 0);
      ProcRdAck   : out    std_logic ;
      ProcWrAck   : out    std_logic ;
      m_tdata     : out    std_logic_vector (31 downto 0);
      m_tvalid    : out    std_logic ;
      s_tready    : out    std_logic                                 --! AXI-S Slave interface, ready
   );
   end component ip_encrypter;
   component ip_flink_master
   generic (
      g_addr_len : natural := 12;      -- bit len of address from proc interface
      g_data_len : natural := 32
   );
   port (
      ProcAddr    : in     std_logic_vector (g_addr_len -1 downto 0);
      ProcCs      : in     std_logic ;
      ProcDataIn  : in     std_logic_vector (g_data_len-1 downto 0);
      ProcRNW     : in     std_logic ;
      clk         : in     std_logic ;
      clk_dly     : in     std_logic ;
      reset_n     : in     std_logic ;
      ProcDataOut : out    std_logic_vector (g_data_len-1 downto 0);
      ProcRdAck   : out    std_logic ;
      ProcWrAck   : out    std_logic ;
      data_n      : inout  std_logic ;
      data_p      : inout  std_logic ;
      strobe_n    : inout  std_logic ;
      strobe_p    : inout  std_logic 
   );
   end component ip_flink_master;
   component ip_temp_if
   generic (
      g_add_size : integer := 12
   );
   port (
      ProcAddr    : in     std_logic_vector (g_add_size-1 downto 0);
      ProcCs      : in     std_logic ;
      ProcDataIn  : in     std_logic_vector (31 downto 0);
      ProcRNW     : in     std_logic ;
      clk         : in     std_logic ;
      reset_n     : in     std_logic ;
      ProcDataOut : out    std_logic_vector (31 downto 0);
      ProcRdAck   : out    std_logic ;
      ProcWrAck   : out    std_logic ;
      scl         : inout  std_logic ;
      sda         : inout  std_logic 
   );
   end component ip_temp_if;
   component fsi_aurora
   generic (
      g_frame_size : integer := 128;      --! Size in number of data beats, not in Bytes
      g_add_size   : integer := 16
   );
   port (
      ProcAddr               : in     std_logic_vector (g_add_size-1 downto 0); -- 63 adresse max.
      ProcCs                 : in     std_logic ;
      ProcDataIn             : in     std_logic_vector (31 downto 0);
      ProcRNW                : in     std_logic ;
      RXN                    : in     std_logic ;
      -- GTX Serial I/O
      RXP                    : in     std_logic ;
      clk                    : in     std_logic ;
      -- GTX Reference Clock Interface
      clk_aurora             : in     std_logic ;
      enable_fsi_rx          : in     std_logic ;
      enable_fsi_tx          : in     std_logic ;
      fl_pmec_sync_out       : in     std_logic ;
      profile_cfg            : in     std_logic_vector (5 downto 0);
      --           INIT_CLK_P             : in std_logic;
      --           INIT_CLK_N             : in std_logic;
      rst_n                  : in     std_logic ;
      rx_tready              : in     std_logic ;
      tx_tdata               : in     std_logic_vector (31 downto 0);
      tx_tvalid              : in     std_logic ;
      ProcDataOut            : out    std_logic_vector (31 downto 0);
      ProcRdAck              : out    std_logic ;
      ProcWrAck              : out    std_logic ;
      TXN                    : out    std_logic ;
      TXP                    : out    std_logic ;
      dds_phase_err          : out    std_logic_vector (5 downto 0);
      fl_pmec_sync_in        : out    std_logic ;
      pn_code_gen_trck_st_in : out    std_logic_vector (1 downto 0);
      rx_tdata               : out    std_logic_vector (31 downto 0);
      rx_tvalid              : out    std_logic ;
      sel_adt_gdt            : out    std_logic ;
      tx_tready              : out    std_logic 
   );
   end component fsi_aurora;
   component fsi_core_bus
   generic (
      g_add_size       : integer := 16;
      g_slave_bus_size : integer := 4
   );
   port (
      ProcAddr           : in     std_logic_vector (g_add_size+g_slave_bus_size-1 downto 0); -- 63 adresse max.
      ProcCs             : in     std_logic ;
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
      ProcRNW            : in     std_logic ;
      ProcRdAck_aurora   : in     std_logic ;
      ProcRdAck_core     : in     std_logic ;
      ProcRdAck_dds      : in     std_logic ;
      ProcRdAck_decryp   : in     std_logic ;
      ProcRdAck_encryp   : in     std_logic ;
      ProcRdAck_flink    : in     std_logic ;
      ProcRdAck_mii      : in     std_logic ;
      ProcRdAck_rgmii    : in     std_logic ;
      ProcRdAck_srv      : in     std_logic ;
      ProcRdAck_temp     : in     std_logic ;
      ProcWrAck_aurora   : in     std_logic ;
      ProcWrAck_core     : in     std_logic ;
      ProcWrAck_dds      : in     std_logic ;
      ProcWrAck_decryp   : in     std_logic ;
      ProcWrAck_encryp   : in     std_logic ;
      ProcWrAck_flink    : in     std_logic ;
      ProcWrAck_mii      : in     std_logic ;
      ProcWrAck_rgmii    : in     std_logic ;
      ProcWrAck_srv      : in     std_logic ;
      ProcWrAck_temp     : in     std_logic ;
      clk                : in     std_logic ;
      rst_n              : in     std_logic ;
      ProcAddr_mst       : out    std_logic_vector (g_add_size-1 downto 0);                  -- !! adresse mot et non octet
      ProcCs_aurora      : out    std_logic ;
      ProcCs_core        : out    std_logic ;
      ProcCs_dds         : out    std_logic ;
      ProcCs_decryp      : out    std_logic ;
      ProcCs_encryp      : out    std_logic ;
      ProcCs_flink       : out    std_logic ;
      ProcCs_mii         : out    std_logic ;
      ProcCs_rgmii       : out    std_logic ;
      ProcCs_srv         : out    std_logic ;
      ProcCs_temp        : out    std_logic ;
      ProcDataIn_mst     : out    std_logic_vector (31 downto 0);
      ProcDataOut        : out    std_logic_vector (31 downto 0);
      ProcRNW_mst        : out    std_logic ;                                                -- read/not write
      ProcRdAck          : out    std_logic ;
      ProcWrAck          : out    std_logic 
   );
   end component fsi_core_bus;
   component fsi_core_eth
   generic (
      g_add_size : integer := 13
   );
   port (
      MiiCol            : in     std_logic ;
      MiiCrs            : in     std_logic ;
      MiiDv             : in     std_logic ;
      MiiEr             : in     std_logic ;
      MiiRxc            : in     std_logic ;
      MiiRxd            : in     STD_LOGIC_VECTOR (3 downto 0);
      MiiTxc            : in     std_logic ;
      ProcAddr_mii      : in     std_logic_vector (g_add_size-1 downto 0); -- 63 adresse max.
      ProcAddr_rgmii    : in     std_logic_vector (g_add_size-1 downto 0); -- 63 adresse max.
      ProcCs_mii        : in     std_logic ;
      ProcCs_rgmii      : in     std_logic ;
      ProcDataIn_mii    : in     std_logic_vector (31 downto 0);
      ProcDataIn_rgmii  : in     std_logic_vector (31 downto 0);
      ProcRNW_mii       : in     std_logic ;
      ProcRNW_rgmii     : in     std_logic ;
      RgmiiRxCtl        : in     std_logic ;
      RgmiiRxc          : in     std_logic ;
      RgmiiRxd          : in     std_logic_vector (3 downto 0);
      clk               : in     std_logic ;
      clk_dly           : in     std_logic ;
      eth_rx_enable     : in     std_logic ;
      eth_rx_sel        : in     std_logic ;
      eth_tx_enable     : in     std_logic ;
      eth_tx_sel        : in     std_logic ;
      m_tx_tready       : in     std_logic ;
      rst_n             : in     std_logic ;
      s_rx_tdata        : in     std_logic_vector (7 downto 0);            --! Word read from memory
      s_rx_tlast        : in     std_logic ;
      s_rx_tvalid       : in     std_logic ;                               --! AXI-S master interface, valid
      tx_clk            : in     std_logic ;
      MiiTxEn           : out    std_logic ;
      MiiTxd            : out    std_logic_vector (3 downto 0);
      ------------------------------
      -- Interface Ethernet SMI	--
      ------------------------------
      Mii_Mdc           : out    std_logic ;
      ProcDataOut_mii   : out    std_logic_vector (31 downto 0);
      ProcDataOut_rgmii : out    std_logic_vector (31 downto 0);
      ProcRdAcq_mii     : out    std_logic ;
      ProcRdAcq_rgmii   : out    std_logic ;
      ProcWrAcq_mii     : out    std_logic ;
      ProcWrAcq_rgmii   : out    std_logic ;
      ------------------------------
      -- Interface Ethernet SMI	--
      ------------------------------
      RGMii_Mdc         : out    std_logic ;
      RgmiiTxCtl        : out    std_logic ;
      RgmiiTxc          : out    std_logic ;
      RgmiiTxd          : out    std_logic_vector (3 downto 0);
      m_tx_tdata        : out    std_logic_vector (7 downto 0);            --! Word read from memory
      m_tx_tlast        : out    std_logic ;
      m_tx_tvalid       : out    std_logic ;                               --! AXI-S master interface, valid
      mii_rst_n         : out    std_logic ;
      rgmii_cfg         : out    std_logic ;
      rgmii_rst_n       : out    std_logic ;
      s_rx_tready       : out    std_logic ;
      Mii_Md            : inout  std_logic ;
      RGMii_Md          : inout  std_logic 
   );
   end component fsi_core_eth;
   component fsi_core_logic
   generic (
      g_add_size : integer := 16
   );
   port (
      ProcAddr               : in     std_logic_vector (g_add_size-1 downto 0); -- 63 adresse max.
      ProcCs                 : in     std_logic ;
      ProcDatain             : in     std_logic_vector (31 downto 0);
      ProcRNW                : in     std_logic ;
      clk                    : in     std_logic ;                               --! Clock signal
      fl_pmec_sync_in        : in     std_logic ;
      m_rx_tready            : in     std_logic ;
      m_tx_tready            : in     std_logic ;
      pn_code_gen_trck_st_in : in     std_logic_vector (1 downto 0);
      rst_n                  : in     std_logic ;
      s_rx_tdata             : in     std_logic_vector (31 downto 0);           --! AXI-S Slave interface, data
      s_rx_tvalid            : in     std_logic ;                               --! AXI-S Slave interface, valid
      s_tx_tdata             : in     std_logic_vector (7 downto 0);            --! Word read from memory
      s_tx_tlast             : in     std_logic ;
      s_tx_tvalid            : in     std_logic ;                               --! AXI-S master interface, valid
      sel_adt_gdt            : in     std_logic ;
      ProcDataout            : out    std_logic_vector (31 downto 0);
      ProcRdAck              : out    std_logic ;
      ProcWrAck              : out    std_logic ;
      decryp_bypass          : out    std_logic ;
      decryp_enable          : out    std_logic ;
      enable_fsi_rx          : out    std_logic ;
      enable_fsi_tx          : out    std_logic ;
      encryp_bypass          : out    std_logic ;
      encryp_enable          : out    std_logic ;
      encryp_newkey          : out    std_logic ;
      eth_rx_enable          : out    std_logic ;
      eth_rx_sel             : out    std_logic ;
      eth_tx_enable          : out    std_logic ;
      eth_tx_sel             : out    std_logic ;
      fl_pmec_sync_out       : out    std_logic ;
      m_rx_tdata             : out    std_logic_vector (7 downto 0);
      m_rx_tlast             : out    std_logic ;
      m_rx_tvalid            : out    std_logic ;
      m_tx_tdata             : out    std_logic_vector (31 downto 0);
      m_tx_tvalid            : out    std_logic ;
      profile_cfg            : out    std_logic_vector (5 downto 0);
      s_rx_tready            : out    std_logic  := '0';                        --! AXI-S Slave interface, ready
      s_tx_tready            : out    std_logic 
   );
   end component fsi_core_logic;
   component fsi_core_srv
   generic (
      g_version  : std_logic_vector(31 downto 0);
      g_add_size : integer := 16
   );
   port (
      ProcAddr    : in     std_logic_vector (g_add_size-1 downto 0); -- !! adresse mot et non octet
      ProcCs      : in     std_logic ;
      ProcDataIn  : in     std_logic_vector (31 downto 0);
      ProcRNW     : in     std_logic ;                               -- read/not write
      clk         : in     std_logic ;
      rst_n       : in     std_logic ;                               -- System reset
      ProcDataOut : out    std_logic_vector (31 downto 0);
      ProcRdAck   : out    std_logic ;
      ProcWrAck   : out    std_logic 
   );
   end component fsi_core_srv;


begin

   -- Instance port mappings.
   i_dds : ip_dds
      generic map (
         g_addr_len => 16
      )
      port map (
         ProcAddr            => ProcAddr_mst,
         ProcCs              => ProcCs_dds,
         ProcDataIn          => ProcDataIn_mst,
         ProcRNW             => ProcRNW_mst,
         clk                 => clk,
         dds_phase_err       => dds_phase_err,
         dds_sdio_1          => dds_sdio_1,
         dds_sdio_2          => dds_sdio_2,
         reset_n             => rst_n,
         ProcDataOut         => ProcDataOut_dds,
         ProcRdAck           => ProcRdAck_dds,
         ProcWrAck           => ProcWrAck_dds,
         dds_cs_n            => dds_cs_n,
         dds_ioupdate        => dds_ioupdate,
         dds_pwr_dwn         => dds_pwr_dwn,
         dds_rst             => dds_rst,
         dds_sclk            => dds_sclk,
         dds_sdio_0          => dds_sdio_0,
         dds_sdio_3          => dds_sdio_3,
         pw_dw_clk_adc_bot_n => pw_dw_clk_adc_bot_n,
         pw_dw_clk_adc_top_n => pw_dw_clk_adc_top_n,
         pw_dw_clk_dac_bot_n => pw_dw_clk_dac_bot_n,
         pw_dw_clk_dac_top_n => pw_dw_clk_dac_top_n,
         pw_dw_ref_fre_rx_n  => pw_dw_ref_fre_rx_n,
         pw_dw_ref_fre_tx_n  => pw_dw_ref_fre_tx_n
      );
   i_decrypt : ip_decrypter
      generic map (
         g_add_size => g_add_size
      )
      port map (
         ProcAddr    => ProcAddr_mst,
         ProcCs      => ProcCs_decryp,
         ProcDataIn  => ProcDataIn_mst,
         ProcRNW     => ProcRNW_mst,
         bypass      => decryp_bypass,
         clk         => clk,
         enable      => decryp_enable,
         m_tready    => demux_tready,
         reset_n     => rst_n,
         s_tdata     => decrypt_tdata,
         s_tvalid    => decrypt_tvalid,
         ProcDataOut => ProcDataOut_decryp,
         ProcRdAck   => ProcRdAck_decryp,
         ProcWrAck   => ProcWrAck_decryp,
         m_tdata     => demux_tdata,
         m_tvalid    => demux_tvalid,
         s_tready    => decrypt_tready
      );
   i_encrypt : ip_encrypter
      generic map (
         g_add_size => g_add_size
      )
      port map (
         ProcAddr    => ProcAddr_mst,
         ProcCs      => ProcCs_encryp,
         ProcDataIn  => ProcDataIn_mst,
         ProcRNW     => ProcRNW_mst,
         bypass      => encryp_bypass,
         clk         => clk,
         enable      => encryp_enable,
         m_tready    => encrypt_tready,
         newkey      => encryp_newkey,
         reset_n     => rst_n,
         s_tdata     => mux_tdata,
         s_tvalid    => mux_tvalid,
         ProcDataOut => ProcDataOut_encryp,
         ProcRdAck   => ProcRdAck_encryp,
         ProcWrAck   => ProcWrAck_encryp,
         m_tdata     => encrypt_tdata,
         m_tvalid    => encrypt_tvalid,
         s_tready    => mux_tready
      );
   i_flink : ip_flink_master
      generic map (
         g_addr_len => g_add_size,         -- bit len of address from proc interface
         g_data_len => 32
      )
      port map (
         ProcAddr    => ProcAddr_mst,
         ProcCs      => ProcCs_flink,
         ProcDataIn  => ProcDataIn_mst,
         ProcRNW     => ProcRNW_mst,
         clk         => clk,
         clk_dly     => clk_dly,
         reset_n     => rst_n,
         ProcDataOut => ProcDataOut_flink,
         ProcRdAck   => ProcRdAck_flink,
         ProcWrAck   => ProcWrAck_flink,
         data_n      => data_n,
         data_p      => data_p,
         strobe_n    => strobe_n,
         strobe_p    => strobe_p
      );
   i_temp : ip_temp_if
      generic map (
         g_add_size => g_add_size
      )
      port map (
         ProcAddr    => ProcAddr_mst,
         ProcCs      => ProcCs_temp,
         ProcDataIn  => ProcDataIn_mst,
         ProcRNW     => ProcRNW_mst,
         clk         => clk,
         reset_n     => rst_n,
         ProcDataOut => ProcDataOut_temp,
         ProcRdAck   => ProcRdAck_temp,
         ProcWrAck   => ProcWrAck_temp,
         scl         => temp_scl,
         sda         => temp_sda
      );
   i_aurora : fsi_aurora
      generic map (
         g_frame_size => 128,                                         --! Size in number of data beats, not in Bytes
         g_add_size   => g_add_size
      )
      port map (
         ProcAddr               => ProcAddr_mst,
         ProcCs                 => ProcCs_aurora,
         ProcDataIn             => ProcDataIn_mst,
         ProcRNW                => ProcRNW_mst,
         RXN                    => RXN,
         RXP                    => RXP,
         clk                    => clk,
         clk_aurora             => clk_aurora,
         enable_fsi_rx          => enable_fsi_rx,
         enable_fsi_tx          => enable_fsi_tx,
         fl_pmec_sync_out       => fl_pmec_sync_out,
         profile_cfg            => profile_cfg,
         rst_n                  => rst_n,
         rx_tready              => decrypt_tready,
         tx_tdata               => encrypt_tdata,
         tx_tvalid              => encrypt_tvalid,
         ProcDataOut            => ProcDataOut_aurora,
         ProcRdAck              => ProcRdAck_aurora,
         ProcWrAck              => ProcWrAck_aurora,
         TXN                    => TXN,
         TXP                    => TXP,
         dds_phase_err          => dds_phase_err,
         fl_pmec_sync_in        => fl_pmec_sync_in,
         pn_code_gen_trck_st_in => pn_code_gen_trck_st_in,
         rx_tdata               => decrypt_tdata,
         rx_tvalid              => decrypt_tvalid,
         sel_adt_gdt            => sel_adt_gdt,
         tx_tready              => encrypt_tready
      );
   i_bus : fsi_core_bus
      generic map (
         g_add_size       => g_add_size,
         g_slave_bus_size => g_slave_bus_size
      )
      port map (
         ProcAddr           => ProcAddr,
         ProcCs             => ProcCs,
         ProcDataIn         => ProcDataIn,
         ProcDataOut_aurora => ProcDataOut_aurora,
         ProcDataOut_core   => ProcDataOut_core,
         ProcDataOut_dds    => ProcDataOut_dds,
         ProcDataOut_decryp => ProcDataOut_decryp,
         ProcDataOut_encryp => ProcDataOut_encryp,
         ProcDataOut_flink  => ProcDataOut_flink,
         ProcDataOut_mii    => ProcDataOut_mii,
         ProcDataOut_rgmii  => ProcDataOut_rgmii,
         ProcDataOut_srv    => ProcDataOut_srv,
         ProcDataOut_temp   => ProcDataOut_temp,
         ProcRNW            => ProcRNW,
         ProcRdAck_aurora   => ProcRdAck_aurora,
         ProcRdAck_core     => ProcRdAck_core,
         ProcRdAck_dds      => ProcRdAck_dds,
         ProcRdAck_decryp   => ProcRdAck_decryp,
         ProcRdAck_encryp   => ProcRdAck_encryp,
         ProcRdAck_flink    => ProcRdAck_flink,
         ProcRdAck_mii      => ProcRdAck_mii,
         ProcRdAck_rgmii    => ProcRdAck_rgmii,
         ProcRdAck_srv      => ProcRdAck_srv,
         ProcRdAck_temp     => ProcRdAck_temp,
         ProcWrAck_aurora   => ProcWrAck_aurora,
         ProcWrAck_core     => ProcWrAck_core,
         ProcWrAck_dds      => ProcWrAck_dds,
         ProcWrAck_decryp   => ProcWrAck_decryp,
         ProcWrAck_encryp   => ProcWrAck_encryp,
         ProcWrAck_flink    => ProcWrAck_flink,
         ProcWrAck_mii      => ProcWrAck_mii,
         ProcWrAck_rgmii    => ProcWrAck_rgmii,
         ProcWrAck_srv      => ProcWrAck_srv,
         ProcWrAck_temp     => ProcWrAck_temp,
         clk                => clk,
         rst_n              => rst_n,
         ProcAddr_mst       => ProcAddr_mst,
         ProcCs_aurora      => ProcCs_aurora,
         ProcCs_core        => ProcCs_core,
         ProcCs_dds         => ProcCs_dds,
         ProcCs_decryp      => ProcCs_decryp,
         ProcCs_encryp      => ProcCs_encryp,
         ProcCs_flink       => ProcCs_flink,
         ProcCs_mii         => ProcCs_mii,
         ProcCs_rgmii       => ProcCs_rgmii,
         ProcCs_srv         => ProcCs_srv,
         ProcCs_temp        => ProcCs_temp,
         ProcDataIn_mst     => ProcDataIn_mst,
         ProcDataOut        => ProcDataOut,
         ProcRNW_mst        => ProcRNW_mst,
         ProcRdAck          => ProcRdAck,
         ProcWrAck          => ProcWrAck
      );
   i_eth : fsi_core_eth
      generic map (
         g_add_size => g_add_size
      )
      port map (
         MiiCol            => mii_rx_col,
         MiiCrs            => mii_rx_crs,
         MiiDv             => mii_rx_dv,
         MiiEr             => mii_rx_er,
         MiiRxc            => mii_rx_clk,
         MiiRxd            => mii_rx_data,
         MiiTxc            => mii_tx_clk,
         ProcAddr_mii      => ProcAddr_mst,
         ProcAddr_rgmii    => ProcAddr_mst,
         ProcCs_mii        => ProcCs_mii,
         ProcCs_rgmii      => ProcCs_rgmii,
         ProcDataIn_mii    => ProcDataIn_mst,
         ProcDataIn_rgmii  => ProcDataIn_mst,
         ProcRNW_mii       => ProcRNW_mst,
         ProcRNW_rgmii     => ProcRNW_mst,
         RgmiiRxCtl        => rgmii_rx_ctl,
         RgmiiRxc          => rgmii_rx_clk,
         RgmiiRxd          => rgmii_rx_data,
         clk               => clk,
         clk_dly           => clk_dly,
         eth_rx_enable     => eth_rx_enable,
         eth_rx_sel        => eth_rx_sel,
         eth_tx_enable     => eth_tx_enable,
         eth_tx_sel        => eth_tx_sel,
         m_tx_tready       => eth_tx_tready,
         rst_n             => rst_n,
         s_rx_tdata        => eth_rx_tdata,
         s_rx_tlast        => eth_rx_tlast,
         s_rx_tvalid       => eth_rx_tvalid,
         tx_clk            => clk_eth,
         MiiTxEn           => mii_tx_en,
         MiiTxd            => mii_tx_data,
         Mii_Mdc           => mii_mdc,
         ProcDataOut_mii   => ProcDataOut_mii,
         ProcDataOut_rgmii => ProcDataOut_rgmii,
         ProcRdAcq_mii     => ProcRdAck_mii,
         ProcRdAcq_rgmii   => ProcRdAck_rgmii,
         ProcWrAcq_mii     => ProcWrAck_mii,
         ProcWrAcq_rgmii   => ProcWrAck_rgmii,
         RGMii_Mdc         => rgmii_mdc,
         RgmiiTxCtl        => rgmii_tx_ctl,
         RgmiiTxc          => rgmii_tx_clk,
         RgmiiTxd          => rgmii_tx_data,
         m_tx_tdata        => eth_tx_tdata,
         m_tx_tlast        => eth_tx_tlast,
         m_tx_tvalid       => eth_tx_tvalid,
         mii_rst_n         => mii_rst_n,
         rgmii_cfg         => rgmii_cfg,
         rgmii_rst_n       => rgmii_rst_n,
         s_rx_tready       => eth_rx_tready,
         Mii_Md            => mii_md,
         RGMii_Md          => rgmii_md
      );
   i_logic : fsi_core_logic
      generic map (
         g_add_size => g_add_size
      )
      port map (
         ProcAddr               => ProcAddr_mst,
         ProcCs                 => ProcCs_core,
         ProcDatain             => ProcDataIn_mst,
         ProcRNW                => ProcRNW_mst,
         clk                    => clk,
         fl_pmec_sync_in        => fl_pmec_sync_in,
         m_rx_tready            => eth_rx_tready,
         m_tx_tready            => mux_tready,
         pn_code_gen_trck_st_in => pn_code_gen_trck_st_in,
         rst_n                  => rst_n,
         s_rx_tdata             => demux_tdata,
         s_rx_tvalid            => demux_tvalid,
         s_tx_tdata             => eth_tx_tdata,
         s_tx_tlast             => eth_tx_tlast,
         s_tx_tvalid            => eth_tx_tvalid,
         sel_adt_gdt            => sel_adt_gdt,
         ProcDataout            => ProcDataOut_core,
         ProcRdAck              => ProcRdAck_core,
         ProcWrAck              => ProcWrAck_core,
         decryp_bypass          => decryp_bypass,
         decryp_enable          => decryp_enable,
         enable_fsi_rx          => enable_fsi_rx,
         enable_fsi_tx          => enable_fsi_tx,
         encryp_bypass          => encryp_bypass,
         encryp_enable          => encryp_enable,
         encryp_newkey          => encryp_newkey,
         eth_rx_enable          => eth_rx_enable,
         eth_rx_sel             => eth_rx_sel,
         eth_tx_enable          => eth_tx_enable,
         eth_tx_sel             => eth_tx_sel,
         fl_pmec_sync_out       => fl_pmec_sync_out,
         m_rx_tdata             => eth_rx_tdata,
         m_rx_tlast             => eth_rx_tlast,
         m_rx_tvalid            => eth_rx_tvalid,
         m_tx_tdata             => mux_tdata,
         m_tx_tvalid            => mux_tvalid,
         profile_cfg            => profile_cfg,
         s_rx_tready            => demux_tready,
         s_tx_tready            => eth_tx_tready
      );
   i_srv : fsi_core_srv
      generic map (
         g_version  => c_version,
         g_add_size => g_add_size
      )
      port map (
         ProcAddr    => ProcAddr_mst,
         ProcCs      => ProcCs_srv,
         ProcDataIn  => ProcDataIn_mst,
         ProcRNW     => ProcRNW_mst,
         clk         => clk,
         rst_n       => rst_n,
         ProcDataOut => ProcDataOut_srv,
         ProcRdAck   => ProcRdAck_srv,
         ProcWrAck   => ProcWrAck_srv
      );

end architecture rtl;

-- ----------------------------------------------------------------------------