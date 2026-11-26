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
-- Arquivo   : mem.vhd
-- Descricao : Memoria unificada (instrucoes e dados) de 4096 palavras de
--             16 bits, inicializada pelo arquivo program.mif.
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Mem is
        Port (
                clk       : in  STD_LOGIC;                      -- Clock da memoria (CLOCK_50 na FPGA)
                memWrite  : in  STD_LOGIC;                      -- Sinal da UC (habilita escrita)
                memRead   : in  STD_LOGIC;                      -- Sinal da UC (habilita leitura)
                address   : in  STD_LOGIC_VECTOR(15 downto 0);  -- Endereco (PC ou ALUOut, via IorD)
                writeData : in  STD_LOGIC_VECTOR(15 downto 0);  -- Dado a escrever (registrador B)
                MemData   : out STD_LOGIC_VECTOR(15 downto 0)   -- Palavra lida
        );
end entity Mem;

architecture Behaviour of Mem is
        type ram_type is array (0 to 4095) of std_logic_vector(15 downto 0);
        signal mem_array : ram_type;  -- Conteudo da memoria

        attribute ram_init_file : string;
        attribute ram_init_file of mem_array : signal is "program.mif";
begin
        -- RAM sincrona de clock unico, para o Quartus mapear em blocos M9K e
        -- carregar o program.mif. Na FPGA, clk e o CLOCK_50 (muito mais rapido
        -- que o clock manual da CPU), entao o dado lido fica pronto dentro de
        -- um estado da CPU. So os 12 bits baixos do endereco sao usados (4096 palavras).
        process (clk)
        begin
                if rising_edge(clk) then
                        if memWrite = '1' then
                                mem_array(to_integer(unsigned(address(11 downto 0)))) <= writeData;
                        end if;
                        if memRead = '1' then
                                MemData <= mem_array(to_integer(unsigned(address(11 downto 0))));
                        end if;
                end if;
        end process;
end architecture Behaviour;
