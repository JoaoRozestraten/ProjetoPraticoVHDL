library ieee;
use ieee.std_logic_1164.all;

entity mdr is
        port (
                clk      : in  std_logic;
                rst      : in  std_logic;
                enable   : in  std_logic;
                data_in  : in  std_logic_vector(15 downto 0);
                data_out : out std_logic_vector(15 downto 0)
        );
end entity;

architecture rtl of mdr is
        signal value : std_logic_vector(15 downto 0) := (others => '0');
begin
        data_out <= value;
        process (clk, rst)
        begin
                if rst = '1' then value <= (others => '0');
                elsif rising_edge(clk) and enable = '1' then value <= data_in;
                end if;
        end process;
end architecture;
