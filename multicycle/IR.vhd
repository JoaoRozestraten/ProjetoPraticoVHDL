library ieee;
use ieee.std_logic_1164.all;

entity IR is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        IRWrite  : in  std_logic;
        MemData  : in  std_logic_vector(15 downto 0);
        opcode   : out std_logic_vector(3 downto 0);
        Ri       : out std_logic_vector(2 downto 0);
        Rj       : out std_logic_vector(2 downto 0);
        Rk       : out std_logic_vector(2 downto 0);
        imediato : out std_logic_vector(5 downto 0);
        endereco : out std_logic_vector(11 downto 0)
    );
end entity IR;

architecture rtl of IR is
    signal leitura_pendente : std_logic;
    signal instrucao_guardada : std_logic_vector(15 downto 0);
    signal instrucao : std_logic_vector(15 downto 0);
begin
    process (clk, rst)
    begin
        if rst = '1' then
            leitura_pendente <= '0';
            instrucao_guardada <= (others => '0');
        elsif rising_edge(clk) then
            leitura_pendente <= IRWrite;
            if leitura_pendente = '1' then
                instrucao_guardada <= MemData;
            end if;
        end if;
    end process;

    -- Com DECODE, a saida registrada da RAM ja contem a instrucao.
    -- Ao finalizar DECODE, a copia interna mantem essa mesma palavra.
    instrucao <= MemData when leitura_pendente = '1' else instrucao_guardada;
    opcode   <= instrucao(15 downto 12);
    Ri       <= instrucao(11 downto 9);
    Rj       <= instrucao(8 downto 6);
    Rk       <= instrucao(5 downto 3);
    imediato <= instrucao(5 downto 0);
    endereco <= instrucao(11 downto 0);
end architecture rtl;
