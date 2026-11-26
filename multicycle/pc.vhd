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
-- Arquivo   : pc.vhd
-- Descricao : Contador de programa (PC) de 16 bits. So muda na borda de
--             subida do clock quando PCWrite = '1'; o reset e assincrono.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity pc is
        port (
                clk     : in  std_logic;                      -- Clock da CPU
                rst     : in  std_logic;                      -- Reset assincrono (PC volta para 0)
                PCWrite : in  std_logic;                      -- Habilita escrita (PCWrite ou desvio tomado)
                PC_next : in  std_logic_vector(15 downto 0);  -- Vindo do mux (PCSource)
                PC_out  : out std_logic_vector(15 downto 0)   -- Vai para a memoria (endereco)
        );
end entity;

architecture rtl of pc is
        signal value : std_logic_vector(15 downto 0) := (others => '0');  -- Valor atual do PC
begin
        PC_out <= value;
        process (clk, rst)
        begin
                if rst = '1' then value <= (others => '0');
                elsif rising_edge(clk) and PCWrite = '1' then value <= PC_next;
                end if;
        end process;
end architecture;
