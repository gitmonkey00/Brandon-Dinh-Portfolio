library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all; 
 
entity calc is 
    Port ( 
        A : in STD_LOGIC_VECTOR (3 downto 0); 
        B : in STD_LOGIC_VECTOR (3 downto 0); 
        reg_out : out STD_LOGIC_VECTOR (7 downto 0); 
        Add : in STD_LOGIC; 
        reset : in STD_LOGIC; 
        AC : in STD_LOGIC; 
        clock : in STD_LOGIC 
    ); 
end calc; 
 
architecture Behavioral of calc is 
    type state_type is (s1, s2, s3); 
    signal y : state_type; 
    signal A_8bit, B_8bit, sum : std_logic_vector (7 downto 0); 
    signal clear, load : std_logic; 
     
    component reg 
        Port ( 
            clear : in STD_LOGIC; 
            load : in STD_LOGIC; 
            clock : in STD_LOGIC; 
            reset : in STD_LOGIC; 
            data_in : in STD_LOGIC_VECTOR (7 downto 0);  
            data_out : out STD_LOGIC_VECTOR (7 downto 0) 
        ); 
    end component; 
begin 
 
FSM_transitions: process (reset, clock) 
begin 
    if reset = '1' then 
        y <= s1; 
    elsif clock'event and clock = '1' then 
        case y is 
            when s1 => 
                if AC = '1' then 
                    y <= s1; 
                elsif AC = '0' and Add = '1' then 
                    y <= s2; 
                else 
                    y <= s3; 
                end if; 
            when s2 => 
                if AC = '1' then 
                    y <= s1; 
                else 
                    y <= s3; 
                end if; 
            when s3 => 
                if AC = '1' then 
                    y <= s1; 
                elsif AC = '0' and Add = '1' then 
                    y <= s2; 
                else 
                    y <= s3;  
                end if; 
        end case; 
    end if; 
end process; 
 
FSM_actions: process(y) 
begin 
    case y is 
        when s1 => 
            clear <= '1'; 
            load <= '1'; 
        when s2 => 
            clear <= '0'; 
            load <= '1'; 
        when s3 => 
            clear <= '0'; 
            load <= '0'; 
    end case; 
end process; 
 
A_8bit <= "0000" & A; 
B_8bit <= "0000" & B; 
 -- Adder 
sum <= A_8bit + B_8bit; 
 -- Register 
register1: reg port map( clear, load, clock, reset, sum, reg_out); 
 
end Behavioral;
