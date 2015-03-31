-- The ipbus slaves live in this entity - modify according to requirements
--
-- Ports can be added to give ipbus slaves access to the chip top level.
--
-- Dave Newbold, February 2011
--
-- edit 4/16/2014 JTO adding in 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ipbus.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mezz_slaves is
port(
	ipb_clk: in std_logic;
	ipb_rst: in std_logic;
	ipb_in: in ipb_wbus;
	ipb_out: out ipb_rbus;
	rst_out: out std_logic;
	eth_err_ctrl: out std_logic_vector(35 downto 0);
	eth_err_stat: in std_logic_vector(47 downto 0) := X"000000000000";
	pkt_rx: in std_logic := '0';
	pkt_tx: in std_logic := '0';
	LED0: out std_logic ;
	LED1: out std_logic ;
	LED2: out std_logic ;
	LED3: out std_logic ;

    --sysclk_p, sysclk_n: in std_logic;
    --mc_a, mc_b: out std_logic;
    --vipq: out std_logic_vector(83 downto 0);
    --vipd: in std_logic_vector(31 downto 0);

    --vpwr_en : out std_logic;
    --sda     : inout std_logic_vector(2 downto 0);
    --scl     : inout std_logic_vector(2 downto 0)

    vpram_sysclk: in std_logic
	);
end mezz_slaves;

architecture rtl of mezz_slaves is

	constant NSLV: positive := 7;
	signal ipbw: ipb_wbus_array(NSLV-1 downto 0);
	signal ipbr, ipbr_d: ipb_rbus_array(NSLV-1 downto 0);
	signal ctrl_reg: std_logic_vector(31 downto 0);
	signal inj_ctrl, inj_stat: std_logic_vector(63 downto 0);
	signal blinker_iter: std_logic_vector(31 downto 0);

begin

  fabric: entity work.ipbus_fabric
    generic map(NSLV => NSLV)
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- Slave 0: id / rst reg

	slave0: entity work.ipbus_ctrlreg
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(0),
			ipbus_out => ipbr(0),
			d => X"abcdfedc",
			q => ctrl_reg
		);
		
		rst_out <= ctrl_reg(0);

-- Slave 1: register

	slave1: entity work.ipbus_reg
		generic map(addr_width => 0)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(1),
			ipbus_out => ipbr(1),
			q => open
		);
			
-- Slave 2: ethernet error injection

	slave3: entity work.ipbus_ctrlreg
		generic map(
			ctrl_addr_width => 1,
			stat_addr_width => 1
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(2),
			ipbus_out => ipbr(2),
			d => inj_stat,
			q => inj_ctrl
		);
		
	eth_err_ctrl <= inj_ctrl(49 downto 32) & inj_ctrl(17 downto 0);
	inj_stat <= X"00" & eth_err_stat(47 downto 24) & X"00" & eth_err_stat(23 downto 0);
	
-- Slave 3: packet counters

	slave5: entity work.ipbus_pkt_ctr
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(3),
			ipbus_out => ipbr(3),
			pkt_rx => pkt_rx,
			pkt_tx => pkt_tx
		);

-- Slave 4: 1kword RAM

	slave2: entity work.ipbus_ram
		generic map(addr_width => 10)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(4),
			ipbus_out => ipbr(4)
		);
	
-- Slave 5: peephole RAM

	slave4: entity work.ipbus_peephole_ram
		generic map(addr_width => 10)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(5),
			ipbus_out => ipbr(5)
		);

---- Slave 6: VIPRAM
--
--	slave6: entity work.ipbus_fpgavpram
--		port map(
--			clock => ipb_clk,
--			reset => ipb_rst,
--			ipbus_in => ipbw(6),
--			ipbus_out => ipbr(6),
--
--    --        mc_a => mc_a,
--    --        mc_b => mc_b,
--            --vipq => vipq,
--            --vipd => vipd,
--
--    --        vpwr_en  => vpwr_en,
--    --        sda      => sda,
--    --        scl      => scl
--			LED0=>LED0,
--			LED1=>LED1,
--			LED2=>LED2,
--			LED3=>LED3,
--            sysclk => vpram_sysclk 
--		);
	--LEDs_blinking_proc: process( vpram_sysclk)
	--begin
	--	if rising_edge(vpram_sysclk) then
	--	--if (sysclk'event and sysclk='1') then
	--		LED0<='1';
	--		blinker_iter<= blinker_iter+1;
	--	end if;
	--end process LEDs_blinking_proc;

	--LED1<= blinker_iter(26);
	--LED2<= blinker_iter(27);
	--LED3<= blinker_iter(28);
end rtl;
