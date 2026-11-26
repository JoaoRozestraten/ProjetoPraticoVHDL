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
-- Arquivo   : banco_registradores.vhd
-- Descricao : Banco com 8 registradores de 16 bits (R0 a R7), enderecados
--             por 3 bits. Tres leituras combinacionais (rs, rt e rd) e uma
--             escrita sincrona. R0 vale sempre zero e nao pode ser escrito.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BancoRegistradores is
        port (
                clk        : in  std_logic;                      -- Clock da CPU
                rst        : in  std_logic;                      -- Reset assincrono (zera todos os registradores)
                reg_write  : in  std_logic;                      -- Sinal da UC (habilita escrita)
                rs         : in  std_logic_vector(2 downto 0);   -- Endereco da 1a leitura
                rt         : in  std_logic_vector(2 downto 0);   -- Endereco da 2a leitura
                rd         : in  std_logic_vector(2 downto 0);   -- Endereco da 3a leitura (Ri do ST/BEQ/BNE)
                write_reg  : in  std_logic_vector(2 downto 0);   -- Endereco do registrador escrito
                write_data : in  std_logic_vector(15 downto 0);  -- Dado a escrever
                rs_data    : out std_logic_vector(15 downto 0);  -- Conteudo do registrador rs
                rt_data    : out std_logic_vector(15 downto 0);  -- Conteudo do registrador rt
                rd_data    : out std_logic_vector(15 downto 0)   -- Conteudo do registrador rd
        );
end entity;

architecture rtl of BancoRegistradores is
        type reg_array is array (0 to 7) of std_logic_vector(15 downto 0);
        signal regs : reg_array := (others => (others => '0'));  -- Os 8 registradores
begin
        -- Leituras combinacionais; R0 sempre devolve zero
        rs_data <= regs(to_integer(unsigned(rs))) when rs /= "000" else (others => '0');
        rt_data <= regs(to_integer(unsigned(rt))) when rt /= "000" else (others => '0');
        rd_data <= regs(to_integer(unsigned(rd))) when rd /= "000" else (others => '0');

        -- Escrita sincrona; escrita em R0 e ignorada
        process (clk, rst)
        begin
                if rst = '1' then
                        regs <= (others => (others => '0'));
                elsif rising_edge(clk) then
                        if reg_write = '1' and write_reg /= "000" then
                                regs(to_integer(unsigned(write_reg))) <= write_data;
                        end if;
                end if;
        end process;
end architecture;
