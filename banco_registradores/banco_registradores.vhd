library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- LEITURA E ESCRITA SÍNCRONAS:
-- Ambos os processos (leitura e escrita) foram implementados de forma
-- SÍNCRONA, disparados na borda de subida do clock (rising_edge(clk)):

-- Portas:
--   clk        : Sinal de clock do processador
--   rst        : Reset ativo em '1' (zera todos os registradores e saídas)
--   reg_write  : Habilitação de escrita síncrona (1 = grava no registrador)
--   read_reg1  : Endereço do registrador para a saída 1 (3 bits: 0 a 7)
--   read_reg2  : Endereço do registrador para a saída 2 (3 bits: 0 a 7)
--   write_reg  : Endereço do registrador de destino (3 bits: 0 a 7)
--   write_data : Dado de 16 bits a ser gravado em write_reg
--   read_data1 : Saída síncrona de 16 bits do registrador read_reg1
--   read_data2 : Saída síncrona de 16 bits do registrador read_reg2


entity BancoRegistradores is
    Port (
        clk        : in  STD_LOGIC;
        rst        : in  STD_LOGIC;
        reg_write  : in  STD_LOGIC;
        read_reg1  : in  STD_LOGIC_VECTOR(2 downto 0);
        read_reg2  : in  STD_LOGIC_VECTOR(2 downto 0);
        write_reg  : in  STD_LOGIC_VECTOR(2 downto 0);
        write_data : in  STD_LOGIC_VECTOR(15 downto 0);
        read_data1 : out STD_LOGIC_VECTOR(15 downto 0);
        read_data2 : out STD_LOGIC_VECTOR(15 downto 0)
    );
end BancoRegistradores;

architecture Behavioral of BancoRegistradores is

    -- 8 registradores (R0 a R7) de 16 bits cada
    type reg_array is array (0 to 7) of STD_LOGIC_VECTOR(15 downto 0);
    signal regs : reg_array := (others => (others => '0'));

begin

    -- Processo síncrono para Escrita e Leitura
    process(clk, rst)
    begin
        if rst = '1' then
            regs       <= (others => (others => '0'));
            read_data1 <= (others => '0');
            read_data2 <= (others => '0');
        elsif rising_edge(clk) then
            -- 1. Escrita síncrona
            if reg_write = '1' then
                regs(to_integer(unsigned(write_reg))) <= write_data;
            end if;

            -- 2. Leitura síncrona (as saídas só atualizam na borda do clock)
            read_data1 <= regs(to_integer(unsigned(read_reg1)));
            read_data2 <= regs(to_integer(unsigned(read_reg2)));
        end if;
    end process;

end Behavioral;
