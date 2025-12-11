-- ----------------------------------------------------------------------------
-- Project Name  : snrf031
-- Library       : snrf031
-- Package Header: fsi_adt_registers_pkg
-- File          : si_adt_registers_pkg.vhd
-- Lenguaje      : VHDL 93
-- --------------------------------------------------------------------------
-- Author        : alicia.bermejo
-- Time          : 10:02:55 
-- Date          : 10-10-2023
-- --------------------------------------------------------------------------
-- Description   : RTL code
--
-- Notes         : None
-- 
-- Limitations   : None
-- --------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package fsi_core_logic_registers_pkg is

   -- --------------------------------------------------------------------------
   -- Write/Read Register address
   -- --------------------------------------------------------------------------
   constant c_profile_add         : integer := 0;  -- 
   constant c_channel_sel_add     : integer := 4;  -- 
   constant c_channel_filter_add  : integer := 8;  -- 
   constant c_nav_sel_add         : integer := 12; -- 
   constant c_nav_data_add        : integer := 16; -- 
   constant c_rl_status_add       : integer := 20; -- 
   constant c_fl_status_add       : integer := 24; --
   constant c_aes_newkey_add      : integer := 28; --
   constant c_sel_mode_add        : integer := 32; --

end fsi_core_logic_registers_pkg;
-- -----------------------------------------------------------------------------