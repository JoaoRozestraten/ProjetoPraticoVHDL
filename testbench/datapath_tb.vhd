library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity datapath_tb is
end entity datapath_tb;

architecture sim of datapath_tb is
                type memory_type is array (0 to 4095) of std_logic_vector(15 downto 0);

                constant test_program : memory_type := (
                                0  => x"5205", -- ADDI R1, R0, 5
                                1  => x"5407", -- ADDI R2, R0, 7
                                2  => x"0650", -- ADD  R3, R1, R2 = 12
                                3  => x"1888", -- SUB  R4, R2, R1 = 2
                                4  => x"2A50", -- AND  R5, R1, R2 = 5
                                5  => x"3C50", -- OR   R6, R1, R2 = 7
                                6  => x"4E50", -- SLT  R7, R1, R2 = 1
                                7  => x"7614", -- SW   R3, 20(R0)
                                8  => x"7815", -- SW   R4, 21(R0)
                                9  => x"7A16", -- SW   R5, 22(R0)
                                10 => x"7C17", -- SW   R6, 23(R0)
                                11 => x"7E18", -- SW   R7, 24(R0)
                                12 => x"6214", -- LW   R1, 20(R0)
                                13 => x"7219", -- SW   R1, 25(R0)
                                14 => x"8002", -- BEQ  R0, R0, +2: skip 15 and 16
                                15 => x"761A", -- skipped SW R3, 26(R0)
                                16 => x"761B", -- skipped SW R3, 27(R0)
                                17 => x"9002", -- BNE  R0, R0, +2: not taken
                                18 => x"A01E", -- JMP  30: skip 19..29
                                19 => x"761C", -- skipped SW R3, 28(R0)
                                30 => x"761F", -- SW   R3, 31(R0)
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
                                wait for 740 ns;

                assert test_memory(20) = x"000C"
                        report "ERRO: ADD/SW nao gravou 0x000C em memoria[20]"
                        severity error;
                assert test_memory(21) = x"0002"
                        report "ERRO: SUB/SW nao gravou 0x0002 em memoria[21]"
                        severity error;
                assert test_memory(22) = x"0005"
                        report "ERRO: AND/SW nao gravou 0x0005 em memoria[22]"
                        severity error;
                assert test_memory(23) = x"0007"
                        report "ERRO: OR/SW nao gravou 0x0007 em memoria[23]"
                        severity error;
                assert test_memory(24) = x"0001"
                        report "ERRO: SLT/SW nao gravou 0x0001 em memoria[24]"
                        severity error;
                assert test_memory(25) = x"000C"
                        report "ERRO: LW/SW nao gravou 0x000C em memoria[25]"
                        severity error;
                assert test_memory(26) = x"0000"
                        report "ERRO: BEQ nao pulou a instrucao em memoria[26]"
                        severity error;
                assert test_memory(27) = x"0000"
                        report "ERRO: BEQ nao pulou a instrucao em memoria[27]"
                        severity error;
                assert test_memory(28) = x"0000"
                        report "ERRO: JMP nao pulou a instrucao em memoria[28]"
                        severity error;
                assert test_memory(31) = x"000C"
                        report "ERRO: JMP nao chegou a instrucao final"
                        severity error;

                report "Todos os testes do caminho de dados foram aprovados"
                                                severity note;
                                finish;
                end process;
end architecture sim;
