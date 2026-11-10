library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Mem_tb is
end entity Mem_tb;

architecture sim of Mem_tb is
        component Mem is
                Port (
                        clk             : in STD_LOGIC;
                        memWrite       : in STD_LOGIC;
                        memRead        : in STD_LOGIC;
                        address         : in STD_LOGIC_VECTOR(15 downto 0);
                        writeData      : in STD_LOGIC_VECTOR(15 downto 0);
                        MemData       : out STD_LOGIC_VECTOR(15 downto 0)
                );
        end component;

        signal clk      : STD_LOGIC := '0';
        signal memWrite : STD_LOGIC := '0';
        signal memRead  : STD_LOGIC := '0';
        signal address  : STD_LOGIC_VECTOR(15 downto 0);
        signal writeData: STD_LOGIC_VECTOR(15 downto 0);
        signal MemData  : STD_LOGIC_VECTOR(15 downto 0);

        constant CLK_PERIOD : time := 20 ns;

        signal sim_done : boolean := false;
begin
        uut: Mem
                port map(
                        clk             => clk,
                        memWrite        => memWrite,
                        memRead         => memRead,
                        address         => address,
                        writeData       => writeData,
                        MemData         => MemData
                );

        clk_process : process
        begin
                while not sim_done loop
                clk <= '0';
                wait for CLK_PERIOD / 2;
                clk <= '1';
                wait for CLK_PERIOD / 2;
                end loop;
                wait; -- Stops the process completely when done
        end process;

        stim_process : process
        begin

                wait for 40 ns;

                address         <= x"0004";
                writeData       <= x"ABCD";
                memWrite        <= '1';
                memRead         <= '0';
                wait for CLK_PERIOD;

                address         <= x"0004";
                writeData       <= x"ABCD";
                memWrite        <= '1';
                memRead         <= '0';
                wait for CLK_PERIOD;

                memWrite        <= '0';
                wait for CLK_PERIOD;

                address         <= x"0004";
                memRead         <= '1';
                wait for CLK_PERIOD;

                memRead         <= '0';
                wait for CLK_PERIOD;

                wait for CLK_PERIOD * 2;
                sim_done <= true;
                wait;
        end process;
end architecture sim;


