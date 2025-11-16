-- Simple accumulator register used by calc.vhd.

library ieee;
use ieee.std_logic_1164.all;

entity acc_reg islibrary IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg is
    Port (
        clear     : in  STD_LOGIC;
        load      : in  STD_LOGIC;
        clock     : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        data_in   : in  STD_LOGIC_VECTOR (7 downto 0);
        data_out  : out STD_LOGIC_VECTOR (7 downto 0)
    );
end reg;

architecture Behavioral of reg is
begin
    process (clock, reset)
    begin
        if reset = '1' then
            data_out <= (others => '0');
        elsif rising_edge(clock) then
            if clear = '1' then
                data_out <= (others => '0');
            elsif load = '1' then
                data_out <= data_in;
            end if;
        end if;
    end process;
end Behavioral;

  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    d       : in  std_logic_vector(3 downto 0);
    q       : out std_logic_vector(3 downto 0)
  );
end entity acc_reg;

architecture rtl of acc_reg is
  signal reg_q : std_logic_vector(3 downto 0) := (others => '0');
begin
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      reg_q <= (others => '0');
    elsif rising_edge(clk) then
      reg_q <= d;
    end if;
  end process;

  q <= reg_q;
end architecture rtl;
