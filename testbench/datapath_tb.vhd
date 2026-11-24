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
                                -- Addresses 20..32 hold data, so the rest of the code starts at 50.
                                14 => x"A032", -- JMP  50
                                -- Branch target = PC + 1 + imm (PC already incremented in FETCH).
                                50 => x"82C2", -- BEQ  R1, R3, +2: 12 = 12, taken, skip 51 and 52
                                51 => x"761A", -- skipped SW R3, 26(R0)
                                52 => x"761B", -- skipped SW R3, 27(R0)
                                53 => x"9541", -- BNE  R2, R5, +1: 7 /= 5, taken, skip 54
                                54 => x"761C", -- skipped SW R3, 28(R0)
                                55 => x"9C81", -- BNE  R6, R2, +1: 7 = 7, not taken
                                56 => x"741D", -- SW   R2, 29(R0) = 7
                                57 => x"8941", -- BEQ  R4, R5, +1: 2 /= 5, not taken
                                58 => x"781E", -- SW   R4, 30(R0) = 2
                                59 => x"A046", -- JMP  70: skip 60..69
                                60 => x"761C", -- skipped SW R3, 28(R0)
                                70 => x"761F", -- SW   R3, 31(R0)
                                -- Backward branch (negative immediate): count R2 from 0 to 3.
                                71 => x"5C03", -- ADDI R6, R0, 3
                                72 => x"5400", -- ADDI R2, R0, 0
                                73 => x"5481", -- ADDI R2, R2, 1
                                74 => x"95BE", -- BNE  R2, R6, -2: back to 73 while R2 /= 3
                                75 => x"7413", -- SW   R2, 19(R0) = 3 (imm range is -32..31)
                                76 => x"A04C", -- JMP  76: stop here
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
                                variable falhas : natural := 0;
                begin
                                wait for 12 ns;
                                reset <= '0';
                                wait for 1500 ns;

                if test_memory(20) /= x"000C" then
                        report "ERRO: ADD/SW nao gravou 0x000C em memoria[20]" severity error;
                        falhas := falhas + 1;
                end if;
                if test_memory(21) /= x"0002" then
                        report "ERRO: SUB/SW nao gravou 0x0002 em memoria[21]" severity error;
                        falhas := falhas + 1;
                end if;
                if test_memory(22) /= x"0005" then
                        report "ERRO: AND/SW nao gravou 0x0005 em memoria[22]" severity error;
                        falhas := falhas + 1;
                end if;
                if test_memory(23) /= x"0007" then
                        report "ERRO: OR/SW nao gravou 0x0007 em memoria[23]" severity error;
                        falhas := falhas + 1;
                end if;
                if test_memory(24) /= x"0001" then
                        report "ERRO: SLT/SW nao gravou 0x0001 em memoria[24]" severity error;
                        falhas := falhas + 1;
                end if;
                if test_memory(25) /= x"000C" then
                        report "ERRO: LW/SW nao gravou 0x000C em memoria[25]" severity error;
                        falhas := falhas + 1;
                end if;
                if test_memory(26) /= x"0000" then
                        report "ERRO: BEQ nao pulou a instrucao em memoria[26]" severity error;
                        falhas := falhas + 1;
                end if;
                if test_memory(27) /= x"0000" then
                        report "ERRO: BEQ nao pulou a instrucao em memoria[27]" severity error;
                        falhas := falhas + 1;
                end if;
                if test_memory(28) /= x"0000" then
                        report "ERRO: BNE tomado ou JMP nao pulou a instrucao em memoria[28]" severity error;
                        falhas := falhas + 1;
                end if;
                if test_memory(29) /= x"0007" then
                        report "ERRO: BNE com registradores iguais desviou (memoria[29])" severity error;
                        falhas := falhas + 1;
                end if;
                if test_memory(30) /= x"0002" then
                        report "ERRO: BEQ com registradores diferentes desviou (memoria[30])" severity error;
                        falhas := falhas + 1;
                end if;
                if test_memory(31) /= x"000C" then
                        report "ERRO: JMP nao chegou a instrucao final" severity error;
                        falhas := falhas + 1;
                end if;
                if test_memory(19) /= x"0003" then
                        report "ERRO: laco com BNE para tras nao contou ate 3 (memoria[19])" severity error;
                        falhas := falhas + 1;
                end if;

                if falhas = 0 then
                        report "Todos os testes do caminho de dados foram aprovados"
                                severity note;
                else
                        report integer'image(falhas) & " teste(s) do caminho de dados falharam"
                                severity error;
                end if;
                                finish;
                end process;
end architecture sim;
