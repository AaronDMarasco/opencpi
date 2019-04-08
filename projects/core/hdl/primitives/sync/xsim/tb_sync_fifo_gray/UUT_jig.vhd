-- This file is protected by Copyright. Please refer to the COPYRIGHT file
-- distributed with this source distribution.
--
-- This file is part of OpenCPI <http://www.opencpi.org>
--
-- OpenCPI is free software: you can redistribute it and/or modify it under the
-- terms of the GNU Lesser General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option) any
-- later version.
--
-- OpenCPI is distributed in the hope that it will be useful, but WITHOUT ANY
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
-- A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
-- details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.

-------------------------------------------------------------------------------
-- Test Jig for Synchronizers
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity UUT_jig is

  generic (
    SRC_FNAME     : string;
    VER_CHK_FNAME : string;
    UUT_NAME      : string;
    TEST_NUM      : integer;
    DATA_WIDTH    : positive;
    CLK_PER_1     : time;
    CLK_PER_2     : time);

end UUT_jig;

architecture rtl of UUT_jig is

  constant VER_ACT_FNAME : string := UUT_NAME & "_tb" & integer'image(TEST_NUM) & "_act.txt";
  constant VER_LOG_FNAME : string := UUT_NAME & "_tb" & integer'image(TEST_NUM) & "_log.txt";
  constant VER_TAG       : string := UUT_NAME & " Test # " & integer'image(TEST_NUM);
  --------------------------------------------------------------------------------
  -- UUT component declaration
  --------------------------------------------------------------------------------

  component SyncFIFO
    generic (
      DATAWIDTH : natural := 1;
      DEPTH     : natural := 2;         --minimum 2
      INDXWIDTH : natural := 1);        --minimum 1
    port (
      sCLK     : in  std_logic;
      sRST     : in  std_logic;
      sENQ     : in  std_logic;
      sD_IN    : in  std_logic_vector(DATAWIDTH-1 downto 0);
      sFULL_N  : out std_logic;
      dCLK     : in  std_logic;
      dDEQ     : in  std_logic;
      dD_OUT   : out std_logic_vector(DATAWIDTH-1 downto 0);
      dEMPTY_N : out std_logic);
  end component;

  --------------------------------------------------------------------------------
  -- Test Jig declarations
  --------------------------------------------------------------------------------

  component sim_source
    generic (
      FILE_NAME  : string;
      DATA_WIDTH : positive);
    port (
      CLK        : in  std_logic;
      RST        : in  std_logic;
      EN         : in  std_logic;
      DOUT_TDATA : out std_logic_vector(DATA_WIDTH-1 downto 0);
      DOUT_TRDY  : in  std_logic);
  end component;

  component sim_verify
    generic (
      CHK_FNAME  : string;
      ACT_FNAME  : string;
      LOG_FNAME  : string;
      TAG        : string;
      TOLERANCE  : integer;
      DATA_WIDTH : positive);
    port (
      CLK       : in  std_logic;
      RST       : in  std_logic;
      EN        : in  std_logic;
      DONE      : out std_logic;
      DIN_TDATA : in  std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;

  signal clk1                   : std_logic;
  signal clk2                   : std_logic;
  signal rst                    : std_logic;
  signal din                    : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal din_trdy               : std_logic                               := '1';
  signal dout                   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal test_en                : std_logic;
  signal test_done              : std_logic;
  signal s_enq_vhdl, s_enq_vlog : std_logic                               := '0';
  signal s_deq_vhdl, s_deq_vlog : std_logic                               := '0';
  signal FFn_vhdl, EFn_vhdl     : std_logic                               := '0';
  signal FFn_vlog, EFn_vlog     : std_logic                               := '0';
  signal FFn_error, EFn_error   : std_logic;
  signal dout_vhdl, dout_vlog   : std_logic_vector(7 downto 0);
  signal DOUT_error             : std_logic_vector(7 downto 0);
  --------------------------------------------------------------------------------

begin

  ----------------------------------------------------------------------------
  -- Clockgen 1
  ----------------------------------------------------------------------------

  clkgen1 : process
  begin
    clk1 <= '0';
    wait for CLK_PER_1/2;
    clk1 <= '1';
    wait for CLK_PER_1/2;
  end process;

  ----------------------------------------------------------------------------
  -- Clockgen 2
  ----------------------------------------------------------------------------

  clkgen2 : process
  begin
    clk2 <= '0';
    wait for CLK_PER_2/2;
    clk2 <= '1';
    wait for CLK_PER_2/2;
  end process;

  ----------------------------------------------------------------------------
  -- Data Source
  ----------------------------------------------------------------------------

  src : sim_source
    generic map (
      FILE_NAME  => SRC_FNAME,
      DATA_WIDTH => DATA_WIDTH)
    port map (
      CLK        => clk1,               --in
      RST        => rst,                --in
      EN         => test_en,            --in
      DOUT_TDATA => din,                --out
      DOUT_TRDY  => din_trdy);          --in

  ----------------------------------------------------------------------------
  -- UUT
  ----------------------------------------------------------------------------

  uut : entity work.sync_fifo_gray
    generic map (
      DATAWIDTH => 8,
      DEPTH     => 8,
      INDXWIDTH => 3)
    port map (
      sRST     => rst,                  --in
      sCLK     => clk1,                 --in
      sENQ     => s_enq_vhdl,           --in
      sD_IN    => din(7 downto 0),      --in
      sFULL_N  => FFn_vhdl,             --out
      dCLK     => clk2,                 --in
      dDEQ     => s_deq_vhdl,           --in
      dD_OUT   => dout_vhdl,            --out
      dEMPTY_N => EFn_vhdl);            --out

  dout(15)         <= din(15);
  dout(9)          <= EFn_vhdl;
  dout(8)          <= not FFn_vhdl;
  dout(7 downto 0) <= dout_vhdl;

  -- TODO:
  -- BSV VERILOG INSTANTIATED FOR INITIAL TEST/VERIFICATION OF VHDL IMPLEMENTATION
  -- THIS MODULE IS TO BE REMOVED PRIOR TO THE 1.5 RELEASE
  uut_verilog : SyncFIFO
    generic map (
      DATAWIDTH => 8,
      DEPTH     => 8,
      INDXWIDTH => 3)
    port map (
      sRST     => not rst,              --in
      sCLK     => clk1,                 --in
      sENQ     => s_enq_vlog,           --in
      sD_IN    => din(7 downto 0),      --in
      sFULL_N  => FFn_vlog,             --out
      dCLK     => clk2,                 --in
      dDEQ     => s_deq_vlog,           --in
      dD_OUT   => dout_vlog,            --out
      dEMPTY_N => EFn_vlog);            --out

  s_enq_vhdl <= test_en and din(15) and FFn_vhdl;
  s_enq_vlog <= test_en and din(15) and FFn_vlog;

  process (clk2)
  begin
    if rising_edge(clk2) then
      s_deq_vhdl <= EFn_vhdl;
      s_deq_vlog <= EFn_vlog;
    end if;
  end process;

  FFn_error  <= FFn_vhdl xor FFn_vlog;
  EFn_error  <= EFn_vhdl xor EFn_vlog;
  DOUT_error <= dout_vhdl xor dout_vlog;

  ----------------------------------------------------------------------------
  -- Data Verify
  ----------------------------------------------------------------------------

  verify : sim_verify
    generic map (
      CHK_FNAME  => VER_CHK_FNAME,
      ACT_FNAME  => VER_ACT_FNAME,
      LOG_FNAME  => VER_LOG_FNAME,
      TAG        => VER_TAG,
      TOLERANCE  => 0,  -- 0 because using 'Golden' files for verification
      DATA_WIDTH => DATA_WIDTH)
    port map (
      CLK       => clk2,
      RST       => rst,
      EN        => test_en,
      DONE      => test_done,
      DIN_TDATA => dout);

  ----------------------------------------------------------------------------
  -- Stimulus
  ----------------------------------------------------------------------------

  stimulus : process
  begin
    test_en <= '0';
    rst     <= '1';
    wait for 100 ns; wait until rising_edge(clk1);
    rst     <= '0';
    wait for 100 ns; wait until rising_edge(clk1);
    test_en <= '1';
    wait until test_done = '1';
    wait for 100 ns; wait until rising_edge(clk1);
    test_en <= '0';
    wait;
  end process;

end rtl;
