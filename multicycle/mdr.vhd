-- MDR: Memory Data Register (Registrador de Dados da Memoria)
-- Guarda o dado lido da memoria (LD) ate o estado WRITEBACK.
--
-- Portas:
--   clk      : in  1 bit   clock manual (borda de subida)
--   rst      : in  1 bit   reset assincrono, zera o registrador
--   data_in  : in  16 bits saida da memoria (MemData)
--   data_out : out 16 bits vai pro write_data do banco de registradores

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity mdr is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        data_in  : in  std_logic_vector(15 downto 0);
        data_out : out std_logic_vector(15 downto 0)
    );
end entity mdr;

architecture rtl of mdr is
begin
    process (clk, rst)
    begin
        if rst = '1' then
            data_out <= (others => '0');
        elsif rising_edge(clk) then
            data_out <= data_in;
        end if;
    end process;
end architecture rtl;