library ieee;
use ieee.std_logic_1164.all;

entity IR is
        port (
                clk       : in  std_logic;
                rst       : in  std_logic;
                IRWrite   : in  std_logic;
                MemData   : in  std_logic_vector(15 downto 0);
                opcode    : out std_logic_vector(3 downto 0);
                rd        : out std_logic_vector(2 downto 0);
                rs        : out std_logic_vector(2 downto 0);
                rt        : out std_logic_vector(2 downto 0);
                imediato  : out std_logic_vector(5 downto 0);
                endereco  : out std_logic_vector(11 downto 0)
        );
end entity IR;

architecture rtl of IR is
        signal instruction : std_logic_vector(15 downto 0) := (others => '0');
begin
        process (clk, rst)
        begin
                        if rst = '1' then
                                        instruction <= (others => '0');
                        elsif rising_edge(clk) and IRWrite = '1' then
                                        instruction <= MemData;
                        end if;
        end process;

        opcode   <= instruction(15 downto 12);
        rd       <= instruction(11 downto 9);
        rs       <= instruction(8 downto 6);
        rt       <= instruction(5 downto 3);
        imediato <= instruction(5 downto 0);
        endereco <= instruction(11 downto 0);
end architecture rtl;
