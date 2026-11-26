-- ============================================================================
-- Projeto Pratico VHDL - CPU multiciclo de 16 bits
-- Laboratorio de Arquitetura de Sistemas Computacionais (218040P)
--
-- Integrantes:
--   Daniel Picconi Alquete           RA 24015408
--   Gabriel Lippi Angelini           RA 24005453
--   Joao Guadagnucci Rozestraten     RA 24005941
--   Nathan Gonzalez Jurcevic         RA 21008388
--   Rodrigo Seiji Yugoshi Ushizawa   RA 24009811
--
-- Arquivo   : mdr_tb.vhd
-- Descricao : Testbench do MDR. Escreve 0xABCD e 0x1234, confere a saida,
--             aplica reset e confere que o valor volta a zero.
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity mdr_tb is
end entity mdr_tb;

architecture sim of mdr_tb is
    -- Sinais ligados as portas do MDR (ver mdr.vhd)
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
        signal enable   : std_logic := '1';
        signal data_in  : std_logic_vector(15 downto 0) := (others => '0');
        signal data_out : std_logic_vector(15 downto 0);
        signal fim      : boolean := false;  -- Para o clock no fim do teste
begin
    uut : entity work.mdr
                port map (
                        clk      => clk,
                        rst      => rst,
                        enable   => enable,
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
