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
-- Arquivo   : mdr.vhd
-- Descricao : Registrador de dados da memoria (MDR/RDM). Guarda a palavra
--             lida da memoria no LD para ser escrita no banco no ciclo seguinte.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity mdr is
        port (
                clk      : in  std_logic;                      -- Clock da CPU
                rst      : in  std_logic;                      -- Reset assincrono (zera o MDR)
                enable   : in  std_logic;                      -- Sinal da UC (MDRWrite)
                data_in  : in  std_logic_vector(15 downto 0);  -- Palavra lida da memoria
                data_out : out std_logic_vector(15 downto 0)   -- Valor guardado
        );
end entity;

architecture rtl of mdr is
        signal value : std_logic_vector(15 downto 0) := (others => '0');  -- Valor guardado no MDR
begin
        data_out <= value;
        process (clk, rst)
        begin
                if rst = '1' then value <= (others => '0');
                elsif rising_edge(clk) and enable = '1' then value <= data_in;
                end if;
        end process;
end architecture;
