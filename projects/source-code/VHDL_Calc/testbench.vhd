library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb is
end tb;

architecture behavior of tb is

    component calc
        port (
            A        : in  std_logic_vector(3 downto 0);
            B        : in  std_logic_vector(3 downto 0);
            reg_out  : out std_logic_vector(7 downto 0);
            Add      : in  std_logic;
            reset    : in  std_logic;
            AC       : in  std_logic;
            clock    : in  std_logic
        );
    end component;

    -- Signal declarations
    signal A        : std_logic_vector(3 downto 0) := (others => '0');
    signal B        : std_logic_vector(3 downto 0) := (others => '0');
    signal Add      : std_logic := '0';
    signal reset    : std_logic := '0';
    signal AC       : std_logic := '0';
    signal clock    : std_logic := '0';
    signal reg_out  : std_logic_vector(7 downto 0);

    constant clock_period : time := 20 ns;

begin

    -- Instantiate Unit Under Test (UUT)
    uut: calc
        port map (
            A        => A,
            B        => B,
            reg_out  => reg_out,
            Add      => Add,
            reset    => reset,
            AC       => AC,
            clock    => clock
        );

    -- Clock generation process
    clock_process: process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        A <= "0001";
        B <= "0010";

        reset <= '1';
        wait for 20 ns;

        reset <= '0';
        wait for 40 ns;

        AC <= '1';
        wait for 40 ns;

        AC <= '0';
        wait for 40 ns;

        Add <= '1';
        wait for 40 ns;

        Add <= '0';
        wait for 40 ns;

        Add <= '1';
        wait for 40 ns;

        AC <= '1';
        wait for 40 ns;

        AC <= '0';

        wait;
    end process;

end behavior;
