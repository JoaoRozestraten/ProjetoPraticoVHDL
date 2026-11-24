library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Mem is
        Port (
                clk       : in  STD_LOGIC;
                memWrite  : in  STD_LOGIC;
                memRead   : in  STD_LOGIC;
                address   : in  STD_LOGIC_VECTOR(15 downto 0);
                writeData : in  STD_LOGIC_VECTOR(15 downto 0);
                MemData   : out STD_LOGIC_VECTOR(15 downto 0)
        );
end entity Mem;

architecture Behaviour of Mem is
        type ram_type is array (0 to 4095) of std_logic_vector(15 downto 0);
        signal mem_array : ram_type;

        attribute ram_init_file : string;
        attribute ram_init_file of mem_array : signal is "program.mif";
begin
        -- Single-clock synchronous RAM so Quartus maps it to M9K blocks and
        -- loads program.mif. On the FPGA, clk is CLOCK_50 (much faster than
        -- the CPU's manual clock), so read data is ready within one CPU state.
        -- Only the low 12 address bits are used (4096 words).
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
