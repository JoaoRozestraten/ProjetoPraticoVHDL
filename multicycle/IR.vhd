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
-- Arquivo   : IR.vhd
-- Descricao : Registrador de instrucao (IR). Guarda a palavra lida da memoria
--             quando IRWrite = '1' e separa os campos da instrucao:
--             opcode(15-12) | rd(11-9) | rs(8-6) | rt(5-3)
--             imediato(5-0) e endereco(11-0) usam os mesmos bits.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity IR is
        port (
                clk       : in  std_logic;                      -- Clock da CPU
                rst       : in  std_logic;                      -- Reset assincrono (zera a instrucao)
                IRWrite   : in  std_logic;                      -- Sinal da UC (habilita escrita)
                MemData   : in  std_logic_vector(15 downto 0);  -- Palavra lida da memoria
                opcode    : out std_logic_vector(3 downto 0);   -- Bits 15-12: codigo da operacao
                rd        : out std_logic_vector(2 downto 0);   -- Bits 11-9: registrador destino (Ri)
                rs        : out std_logic_vector(2 downto 0);   -- Bits 8-6: registrador fonte (Rj)
                rt        : out std_logic_vector(2 downto 0);   -- Bits 5-3: registrador fonte (Rk)
                imediato  : out std_logic_vector(5 downto 0);   -- Bits 5-0: imediato com sinal
                endereco  : out std_logic_vector(11 downto 0)   -- Bits 11-0: endereco do JMP
        );
end entity IR;

architecture rtl of IR is
        signal instruction : std_logic_vector(15 downto 0) := (others => '0');  -- Instrucao armazenada
begin
        process (clk, rst)
        begin
                        if rst = '1' then
                                        instruction <= (others => '0');
                        elsif rising_edge(clk) and IRWrite = '1' then
                                        instruction <= MemData;
                        end if;
        end process;

        -- Separacao dos campos da instrucao
        opcode   <= instruction(15 downto 12);
        rd       <= instruction(11 downto 9);
        rs       <= instruction(8 downto 6);
        rt       <= instruction(5 downto 3);
        imediato <= instruction(5 downto 0);
        endereco <= instruction(11 downto 0);
end architecture rtl;
