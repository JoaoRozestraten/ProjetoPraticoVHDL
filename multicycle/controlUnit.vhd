library ieee;
use ieee.std_logic_1164.all;

-- Multicycle control unit for the 16-bit CPU.
-- Memory is word-addressed: PC increments by 1.
-- Opcodes: ADD=0 SUB=1 AND=2 OR=3 SLT=4 ADDI=5
--          LD=6 ST=7 BEQ=8 BNE=9 JMP=A.
entity ControlUnit is
        port (
                clk         : in  std_logic;
                reset       : in  std_logic; -- synchronous, active high
                opcode      : in  std_logic_vector(3 downto 0);

                -- PC and memory control
                PCWrite     : out std_logic;
                PCWriteCond : out std_logic;
                BranchNE    : out std_logic;
                PCSource    : out std_logic_vector(1 downto 0);
                IorD        : out std_logic;
                MemRead     : out std_logic;
                MemWrite    : out std_logic;
                IRWrite     : out std_logic;
                MDRWrite    : out std_logic;

                -- Register file and internal pipeline registers
                AWrite      : out std_logic;
                BWrite      : out std_logic;
                ALUOutWrite : out std_logic;
                RegWrite    : out std_logic;
                MemtoReg    : out std_logic;

                -- ALU multiplexers and operation
                ALUSrcA     : out std_logic;
                ALUSrcB     : out std_logic_vector(1 downto 0);
                ALUControl  : out std_logic_vector(2 downto 0);

                -- FPGA state display
                StateCode   : out std_logic_vector(3 downto 0)
        );
end entity;

architecture rtl of ControlUnit is
        type state_type is (
                S_FETCH, S_DECODE, S_EXEC_R, S_WB_R,
                S_EXEC_ADDI, S_WB_ADDI, S_MEM_ADDR,
                S_MEM_READ, S_MEM_LATCH, S_MEM_WB,
                S_MEM_STORE, S_BRANCH, S_JUMP
        );
        signal state, next_state : state_type;

        constant OP_ADD  : std_logic_vector(3 downto 0) := "0000";
        constant OP_SUB  : std_logic_vector(3 downto 0) := "0001";
        constant OP_AND  : std_logic_vector(3 downto 0) := "0010";
        constant OP_OR   : std_logic_vector(3 downto 0) := "0011";
        constant OP_SLT  : std_logic_vector(3 downto 0) := "0100";
        constant OP_ADDI : std_logic_vector(3 downto 0) := "0101";
        constant OP_LD   : std_logic_vector(3 downto 0) := "0110";
        constant OP_ST   : std_logic_vector(3 downto 0) := "0111";
        constant OP_BEQ  : std_logic_vector(3 downto 0) := "1000";
        constant OP_BNE  : std_logic_vector(3 downto 0) := "1001";
        constant OP_JMP  : std_logic_vector(3 downto 0) := "1010";

        -- ALUControl: ADD=000, SUB=001, AND=010, OR=011, SLT=100
        constant ALU_ADD : std_logic_vector(2 downto 0) := "000";
        constant ALU_SUB : std_logic_vector(2 downto 0) := "001";
        constant ALU_AND : std_logic_vector(2 downto 0) := "010";
        constant ALU_OR  : std_logic_vector(2 downto 0) := "011";
        constant ALU_SLT : std_logic_vector(2 downto 0) := "100";
begin
        -- State register
        process(clk)
        begin
                if rising_edge(clk) then
                if reset = '1' then
                        state <= S_FETCH;
                else
                        state <= next_state;
                end if;
                end if;
        end process;

        process(state, opcode)
        begin
                next_state <= S_FETCH;
                case state is
                when S_FETCH =>
                        next_state <= S_DECODE;
                when S_DECODE =>
                        if opcode = OP_ADD or opcode = OP_SUB or
                        opcode = OP_AND or opcode = OP_OR or opcode = OP_SLT then
                        next_state <= S_EXEC_R;
                        elsif opcode = OP_ADDI then
                        next_state <= S_EXEC_ADDI;
                        elsif opcode = OP_LD or opcode = OP_ST then
                        next_state <= S_MEM_ADDR;
                        elsif opcode = OP_BEQ or opcode = OP_BNE then
                        next_state <= S_BRANCH;
                        elsif opcode = OP_JMP then
                        next_state <= S_JUMP;
                        end if;
                when S_EXEC_R     => next_state <= S_WB_R;
                when S_WB_R       => next_state <= S_FETCH;
                when S_EXEC_ADDI  => next_state <= S_WB_ADDI;
                when S_WB_ADDI    => next_state <= S_FETCH;
                when S_MEM_ADDR   =>
                        if opcode = OP_LD then
                        next_state <= S_MEM_READ;
                        else
                        next_state <= S_MEM_STORE;
                        end if;
                when S_MEM_READ   => next_state <= S_MEM_LATCH;
                when S_MEM_LATCH  => next_state <= S_MEM_WB;
                when S_MEM_WB     => next_state <= S_FETCH;
                when S_MEM_STORE  => next_state <= S_FETCH;
                when S_BRANCH     => next_state <= S_FETCH;
                when S_JUMP       => next_state <= S_FETCH;
                end case;
        end process;

        process(state, opcode)
        begin
                PCWrite     <= '0';
                PCWriteCond <= '0';
                BranchNE    <= '0';
                PCSource    <= "00";
                IorD        <= '0';
                MemRead     <= '0';
                MemWrite    <= '0';
                IRWrite     <= '0';
                MDRWrite    <= '0';
                AWrite      <= '0';
                BWrite      <= '0';
                ALUOutWrite <= '0';
                RegWrite    <= '0';
                MemtoReg    <= '0';
                ALUSrcA     <= '0';
                ALUSrcB     <= "00";
                ALUControl  <= ALU_ADD;
                StateCode   <= "0000";

                case state is
                when S_FETCH =>
                        StateCode   <= "0000";
                        MemRead     <= '1';
                        IRWrite     <= '1';
                        IorD        <= '0';       -- PC is memory address
                        ALUSrcA     <= '0';       -- PC
                        ALUSrcB     <= "01";    -- constant 1
                        ALUControl  <= ALU_ADD;
                        PCSource    <= "00";    -- direct ALU result
                        PCWrite     <= '1';

                when S_DECODE =>
                        StateCode   <= "0001";
                        AWrite      <= '1';
                        BWrite      <= '1';
                        ALUSrcA     <= '0';       -- current PC (= old PC + 1)
                        ALUSrcB     <= "10";    -- sign-extended immediate
                        ALUControl  <= ALU_ADD;
                        ALUOutWrite <= '1';       -- save branch target

                when S_EXEC_R =>
                        StateCode   <= "0010";
                        ALUSrcA     <= '1';       -- A register
                        ALUSrcB     <= "00";    -- B register
                        ALUOutWrite <= '1';
                        if opcode = OP_SUB then
                        ALUControl <= ALU_SUB;
                        elsif opcode = OP_AND then
                        ALUControl <= ALU_AND;
                        elsif opcode = OP_OR then
                        ALUControl <= ALU_OR;
                        elsif opcode = OP_SLT then
                        ALUControl <= ALU_SLT;
                        end if;

                when S_WB_R =>
                        StateCode   <= "0011";
                        RegWrite    <= '1';
                        MemtoReg    <= '0';       -- write ALUOut to Ri

                when S_EXEC_ADDI =>
                        StateCode   <= "0100";
                        ALUSrcA     <= '1';
                        ALUSrcB     <= "10";
                        ALUControl  <= ALU_ADD;
                        ALUOutWrite <= '1';

                when S_WB_ADDI =>
                        StateCode   <= "0101";
                        RegWrite    <= '1';
                        MemtoReg    <= '0';

                when S_MEM_ADDR =>
                        StateCode   <= "0110";
                        ALUSrcA     <= '1';
                        ALUSrcB     <= "10";
                        ALUControl  <= ALU_ADD;
                        ALUOutWrite <= '1';

                when S_MEM_READ =>
                        StateCode   <= "0111";
                        IorD        <= '1';       -- ALUOut is memory address
                        MemRead     <= '1';

                when S_MEM_LATCH =>
                        StateCode   <= "1000";
                        IorD        <= '1';
                        MemRead     <= '1';       -- hold RAM output valid
                        MDRWrite    <= '1';

                when S_MEM_WB =>
                        StateCode   <= "1001";
                        RegWrite    <= '1';
                        MemtoReg    <= '1';       -- write MDR to Ri

                when S_MEM_STORE =>
                        StateCode   <= "1010";
                        IorD        <= '1';
                        MemWrite    <= '1';       -- write Ri to memory

                when S_BRANCH =>
                        StateCode   <= "1011";
                        ALUSrcA     <= '1';
                        ALUSrcB     <= "00";
                        ALUControl  <= ALU_SUB;  -- compare Ri - Rj
                        PCSource    <= "01";    -- branch target in ALUOut
                        PCWriteCond <= '1';
                        if opcode = OP_BNE then
                        BranchNE <= '1';
                        end if;

                when S_JUMP =>
                        StateCode   <= "1100";
                        PCWrite     <= '1';
                        PCSource    <= "10";    -- zero-extended instruction[11:0]
                end case;
        end process;
end architecture;
