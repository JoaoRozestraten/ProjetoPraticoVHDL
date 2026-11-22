library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity datapath_tb is
end entity datapath_tb;

architecture sim of datapath_tb is
                type memory_type is array (0 to 4095) of std_logic_vector(15 downto 0);

                constant test_program : memory_type := (
                                0 => x"5205", -- ADDI R1, R0, 5
                                1 => x"5407", -- ADDI R2, R0, 7
                                2 => x"0650", -- ADD  R3, R1, R2
                                3 => x"7614", -- ST   R3, 20(R0)
                                4 => x"6814", -- LD   R4, 20(R0)
                                5 => x"7815", -- ST   R4, 21(R0)
                                others => x"0000"
                );

                signal clk             : std_logic := '0';
                signal reset           : std_logic := '1';
                signal memory_data_in  : std_logic_vector(15 downto 0);
                signal memory_address  : std_logic_vector(15 downto 0);
                signal memory_data_out : std_logic_vector(15 downto 0);
                signal memory_read     : std_logic;
                signal memory_write    : std_logic;
                signal state_code      : std_logic_vector(3 downto 0);
                signal test_memory     : memory_type := test_program;
begin
                clk <= not clk after 5 ns;

                process (memory_address, test_memory)
                begin
                                memory_data_in <= test_memory(to_integer(unsigned(memory_address)));
                end process;

                process (clk)
                begin
                                if rising_edge(clk) and memory_write = '1' then
                                                test_memory(to_integer(unsigned(memory_address))) <= memory_data_out;
                                end if;
                end process;

                dut : entity work.Datapath
                                port map (
                                                clk             => clk,
                                                reset           => reset,
                                                memory_data_in  => memory_data_in,
                                                memory_address  => memory_address,
                                                memory_data_out => memory_data_out,
                                                memory_read     => memory_read,
                                                memory_write    => memory_write,
                                                state_code      => state_code
                                );

                process
                begin
                                wait for 12 ns;
                                reset <= '0';
                                wait for 340 ns;

                report "Simulacao do caminho de dados finalizada com programa interno"
                                                severity note;
                                finish;
                end process;
end architecture sim;
