library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pc is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;                      -- Reset global
        PCWrite   : in  std_logic;                      -- Sinal da UC (habilita escrita)
        PC_next   : in  std_logic_vector(15 downto 0);  -- Vindo do Mux (PCSource)
        PC_out    : out std_logic_vector(15 downto 0)   -- Vai para a Memória (Address)
    );
end entity pc;

architecture rtl of pc is
    signal pc_reg : unsigned(15 downto 0) := (others => '0');
begin
    
    PC_out <= std_logic_vector(pc_reg);

    process(clk, rst)
    begin
        if rst = '1' then
            pc_reg <= (others => '0');
        elsif rising_edge(clk) then
            if PCWrite = '1' then
                pc_reg <= unsigned(PC_next);
            end if;
        end if;
    end process;

end architecture rtl;