library ieee;
use ieee.std_logic_1164.all;

entity pc is
        port (
                clk     : in  std_logic;
                rst     : in  std_logic;
                PCWrite : in  std_logic;
                PC_next : in  std_logic_vector(15 downto 0);
                PC_out  : out std_logic_vector(15 downto 0)
        );
end entity;

architecture rtl of pc is
        signal value : std_logic_vector(15 downto 0) := (others => '0');
begin
        PC_out <= value;
        process (clk, rst)
        begin
                if rst = '1' then value <= (others => '0');
                elsif rising_edge(clk) and PCWrite = '1' then value <= PC_next;
                end if;
        end process;
end architecture;
