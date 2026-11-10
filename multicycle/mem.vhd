library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Mem is
        Port (
                clk             : in STD_LOGIC;
                memWrite       : in STD_LOGIC;
                memRead        : in STD_LOGIC;
                address         : in STD_LOGIC_VECTOR(15 downto 0);
                writeData      : in STD_LOGIC_VECTOR(15 downto 0);
                MemData       : out STD_LOGIC_VECTOR(15 downto 0)
             );
end entity Mem;

architecture Behaviour of Mem is
        type ram_type is array (0 to (2**8) - 1) of STD_LOGIC_VECTOR(15 downto 0);
        signal mem_array        : ram_type;

begin
        process(clk)
        begin
                if rising_edge(clk) then
                        if memWrite = '1' then
                                mem_array(to_integer(unsigned(address))) <= writeData;
                        end if;
                        if memRead = '1' then
                                memData <= mem_array(to_integer(unsigned(address)));
                        end if;
                end if;
        end process;
end architecture Behaviour;
