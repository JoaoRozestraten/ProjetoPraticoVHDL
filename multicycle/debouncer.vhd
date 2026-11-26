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
-- Arquivo   : debouncer.vhd
-- Descricao : Transforma o sinal com trepidacao de um botao em um nivel limpo.
--             button_n e ativo em nivel baixo (as KEYs da DE2-115 leem '0'
--             quando apertadas); pressed fica em '1' enquanto o botao esta
--             apertado, depois de ficar estavel por STABLE_CYCLES ciclos de
--             clock (1_000_000 a 50 MHz = 20 ms).
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity debouncer is
        generic (
                STABLE_CYCLES : positive := 1_000_000  -- Ciclos de estabilidade exigidos
        );
        port (
                clk      : in  std_logic;  -- Clock da placa (CLOCK_50)
                button_n : in  std_logic;  -- Botao, ativo em '0'
                pressed  : out std_logic   -- '1' enquanto o botao esta apertado (sem trepidacao)
        );
end entity debouncer;

architecture rtl of debouncer is
        signal sync_0 : std_logic := '1';                                -- 1o flip-flop de sincronizacao
        signal sync_1 : std_logic := '1';                                -- 2o flip-flop de sincronizacao
        signal stable : std_logic := '1';                                -- Ultimo nivel estavel do botao
        signal count  : natural range 0 to STABLE_CYCLES - 1 := 0;       -- Ciclos desde a ultima mudanca
begin
        pressed <= not stable;

        process (clk)
        begin
                if rising_edge(clk) then
                        -- Dois flip-flops sincronizam o botao, que e assincrono.
                        sync_0 <= button_n;
                        sync_1 <= sync_0;

                        if sync_1 = stable then
                                count <= 0;
                        elsif count = STABLE_CYCLES - 1 then
                                stable <= sync_1;
                                count  <= 0;
                        else
                                count <= count + 1;
                        end if;
                end if;
        end process;
end architecture rtl;
