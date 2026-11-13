-- Testbench do MDR
-- Escreve 0xABCD, confere a saida, aplica reset e confere zero.

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity mdr_tb is
end entity mdr_tb;

architecture sim of mdr_tb is
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal data_in  : std_logic_vector(15 downto 0) := (others => '0');
    signal data_out : std_logic_vector(15 downto 0);
    signal fim      : boolean := false;
begin
    uut : entity work.mdr
        port map (
            clk      => clk,
            rst      => rst,
            data_in  => data_in,
            data_out => data_out
        );

    clk <= not clk after 5 ns when not fim else clk;

    process
    begin
        wait for 12 ns;
        rst <= '0';

        data_in <= x"ABCD";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert data_out = x"ABCD" report "ERRO: MDR nao capturou 0xABCD" severity error;

        data_in <= x"1234";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert data_out = x"1234" report "ERRO: MDR nao capturou 0x1234" severity error;

        rst <= '1';
        wait for 1 ns;
        assert data_out = x"0000" report "ERRO: reset nao zerou o MDR" severity error;

        report "Testbench do MDR terminou";
        fim <= true;
        wait;
    end process;
end architecture sim;