library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity ControlUnit_tb is
end entity;

architecture sim of ControlUnit_tb is
        constant CLK_PERIOD : time := 10 ns;
        signal clk         : std_logic := '0';
        signal reset       : std_logic := '0';
        signal opcode      : std_logic_vector(3 downto 0) := (others => '0');
        signal PCWrite     : std_logic;
        signal PCWriteCond : std_logic;
        signal BranchNE    : std_logic;
        signal PCSource    : std_logic_vector(1 downto 0);
        signal IorD        : std_logic;
        signal MemRead     : std_logic;
        signal MemWrite    : std_logic;
        signal IRWrite     : std_logic;
        signal MDRWrite    : std_logic;
        signal AWrite      : std_logic;
        signal BWrite      : std_logic;
        signal ALUOutWrite : std_logic;
        signal RegWrite    : std_logic;
        signal MemtoReg    : std_logic;
        signal ALUSrcA     : std_logic;
        signal ALUSrcB     : std_logic_vector(1 downto 0);
        signal ALUControl  : std_logic_vector(2 downto 0);
        signal StateCode   : std_logic_vector(3 downto 0);

        type state_sequence is array (natural range <>) of std_logic_vector(3 downto 0);
        -- States must match ControlUnit.vhd:
        constant FETCH     : std_logic_vector(3 downto 0) := "0000";
        constant DECODE    : std_logic_vector(3 downto 0) := "0001";
        constant EXEC_R    : std_logic_vector(3 downto 0) := "0010";
        constant WB_R      : std_logic_vector(3 downto 0) := "0011";
        constant EXEC_ADDI : std_logic_vector(3 downto 0) := "0100";
        constant WB_ADDI   : std_logic_vector(3 downto 0) := "0101";
        constant MEM_ADDR  : std_logic_vector(3 downto 0) := "0110";
        constant MEM_READ  : std_logic_vector(3 downto 0) := "0111";
        constant MEM_LATCH : std_logic_vector(3 downto 0) := "1000";
        constant MEM_WB    : std_logic_vector(3 downto 0) := "1001";
        constant MEM_STORE : std_logic_vector(3 downto 0) := "1010";
        constant BRANCH    : std_logic_vector(3 downto 0) := "1011";
        constant JUMP      : std_logic_vector(3 downto 0) := "1100";
begin
        dut : entity work.ControlUnit(rtl)
                port map (
                        clk => clk, reset => reset, opcode => opcode,
                        PCWrite => PCWrite, PCWriteCond => PCWriteCond,
                        BranchNE => BranchNE, PCSource => PCSource,
                        IorD => IorD, MemRead => MemRead, MemWrite => MemWrite,
                        IRWrite => IRWrite, MDRWrite => MDRWrite,
                        AWrite => AWrite, BWrite => BWrite, ALUOutWrite => ALUOutWrite,
                        RegWrite => RegWrite, MemtoReg => MemtoReg,
                        ALUSrcA => ALUSrcA, ALUSrcB => ALUSrcB,
                        ALUControl => ALUControl, StateCode => StateCode
                );

        clk <= not clk after CLK_PERIOD / 2;

        stimulus : process
                        procedure run_instruction(
                        constant op : in std_logic_vector(3 downto 0);
                        constant cycles : in positive
                ) is
                begin
                        -- Begin an instruction when the control unit is in FETCH.
                        wait until falling_edge(clk);
                        opcode <= op;
                        -- DECODE and all subsequent execution stages, returning to FETCH.
                        for i in 1 to cycles loop
                                wait until rising_edge(clk);
                        end loop;
                        wait for 1 ns;
                        report "Finished opcode " & to_hstring(op) severity note;
                end procedure;
        begin
                reset <= '1';
                wait until rising_edge(clk);
                wait for 1 ns;
                reset <= '0';

                -- cycles counts edges from FETCH until returning to FETCH.
                run_instruction("0000", 4); -- ADD
                run_instruction("0001", 4); -- SUB
                run_instruction("0010", 4); -- AND
                run_instruction("0011", 4); -- OR
                run_instruction("0100", 4); -- SLT
                run_instruction("0101", 4); -- ADDI
                run_instruction("0110", 6); -- LD
                run_instruction("0111", 4); -- ST
                run_instruction("1000", 3); -- BEQ
                run_instruction("1001", 3); -- BNE
                run_instruction("1010", 3); -- JMP

                -- Verify reset visually in the waveform from an execution state.
                wait until falling_edge(clk);
                opcode <= "0110";
                wait until rising_edge(clk); -- DECODE
                wait until rising_edge(clk); -- MEM_ADDR
                wait until falling_edge(clk);
                reset <= '1';
                wait until rising_edge(clk); -- FETCH
                wait for 1 ns;
                reset <= '0';

                report "Simulation finished" severity note;
                finish;
        end process;
end architecture;
