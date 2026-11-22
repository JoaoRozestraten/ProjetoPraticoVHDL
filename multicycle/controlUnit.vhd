library ieee;
use ieee.std_logic_1164.all;

entity ControlUnit is
        port (
                clk          : in  std_logic;
                reset        : in  std_logic;
                opcode       : in  std_logic_vector(3 downto 0);

                -- PC and memory controls
                PCWrite      : out std_logic;
                PCWriteCond  : out std_logic;
                BranchNE     : out std_logic;
                PCSource     : out std_logic_vector(1 downto 0);
                IorD         : out std_logic;
                MemRead      : out std_logic;
                MemWrite     : out std_logic;
                IRWrite      : out std_logic;
                MDRWrite     : out std_logic;

                -- Internal datapath register controls
                AWrite       : out std_logic;
                BWrite       : out std_logic;
                ALUOutWrite  : out std_logic;
                RegWrite     : out std_logic;
                MemtoReg     : out std_logic;

                -- ALU input and operation controls
                ALUSrcA      : out std_logic;
                ALUSrcB      : out std_logic_vector(1 downto 0);
                ALUControl   : out std_logic_vector(2 downto 0);

                -- Encoded current state
                StateCode    : out std_logic_vector(3 downto 0)
        );
end entity ControlUnit;

architecture rtl of ControlUnit is
        -- Multicycle FSM states
        type state_t is (
                FETCH,
                DECODE,
                EXEC_R,
                WB_R,
                EXEC_ADDI,
                WB_ADDI,
                MEM_ADDR,
                MEM_READ,
                MEM_LATCH,
                MEM_WB,
                MEM_STORE,
                BRANCH,
                JUMP
        );

        signal state      : state_t := FETCH;
        signal next_state : state_t := FETCH;

        -- Instruction opcodes
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
begin
        -- State register: advance once per clock cycle.
        state_register : process (clk)
        begin
                if rising_edge(clk) then
                        if reset = '1' then
                                 state <= FETCH;
                        else
                                 state <= next_state;
                        end if;
                end if;
        end process state_register;

        -- Next-state logic: choose the instruction sequence.
        next_state_logic : process (state, opcode)
        begin
                next_state <= FETCH;

                case state is
                        when FETCH => next_state <= DECODE;
                        when DECODE =>
                                if opcode <= OP_SLT then
                                                next_state <= EXEC_R;
                                elsif opcode = OP_ADDI then
                                                next_state <= EXEC_ADDI;
                                elsif opcode = OP_LD or opcode = OP_ST then
                                                next_state <= MEM_ADDR;
                                elsif opcode = OP_BEQ or opcode = OP_BNE then
                                                next_state <= BRANCH;
                                elsif opcode = OP_JMP then
                                                next_state <= JUMP;
                                end if;

                        when EXEC_R => next_state <= WB_R;
                        when WB_R => next_state <= FETCH;
                        when EXEC_ADDI => next_state <= WB_ADDI;
                        when WB_ADDI => next_state <= FETCH;
                        when MEM_ADDR =>
                                if opcode = OP_LD then
                                                next_state <= MEM_READ;
                                else
                                                next_state <= MEM_STORE;
                                end if;
                        when MEM_READ => next_state <= MEM_LATCH;
                        when MEM_LATCH => next_state <= MEM_WB;
                        when MEM_WB => next_state <= FETCH;
                        when MEM_STORE =>next_state <= FETCH;
                        when BRANCH => next_state <= FETCH;
                        when JUMP => next_state <= FETCH;
                end case;
        end process next_state_logic;

        -- Output logic: generate the datapath controls for the current state.
        output_logic : process (state, opcode)
        begin
                -- Safe defaults: no writes, no memory operation, ALU add.
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
                ALUControl  <= "000";
                StateCode   <= "0000";

                case state is
                        when FETCH =>
                                MemRead    <= '1';
                                IRWrite    <= '1';
                                PCWrite    <= '1';
                                ALUSrcB    <= "01";

                        when DECODE =>
                                AWrite      <= '1';
                                BWrite      <= '1';
                                ALUSrcB     <= "10";
                                ALUOutWrite <= '1';
                                StateCode   <= "0001";

                        when EXEC_R =>
                                ALUSrcA     <= '1';
                                ALUOutWrite <= '1';
                                StateCode   <= "0010";

                        when WB_R =>
                                RegWrite  <= '1';
                                StateCode <= "0011";

                        when EXEC_ADDI =>
                                ALUSrcA     <= '1';
                                ALUSrcB     <= "10";
                                ALUOutWrite <= '1';
                                StateCode   <= "0100";

                        when WB_ADDI =>
                                RegWrite  <= '1';
                                StateCode <= "0101";

                        when MEM_ADDR =>
                                ALUSrcA     <= '1';
                                ALUSrcB     <= "10";
                                ALUOutWrite <= '1';
                                StateCode   <= "0110";

                        when MEM_READ =>
                                IorD      <= '1';
                                MemRead   <= '1';
                                StateCode <= "0111";

                        when MEM_LATCH =>
                                IorD      <= '1';
                                MemRead   <= '1';
                                MDRWrite  <= '1';
                                StateCode <= "1000";

                        when MEM_WB =>
                                RegWrite  <= '1';
                                MemtoReg  <= '1';
                                StateCode <= "1001";

                        when MEM_STORE =>
                                IorD      <= '1';
                                MemWrite  <= '1';
                                StateCode <= "1010";

                        when BRANCH =>
                                ALUSrcA     <= '1';
                                ALUControl  <= "001";
                                PCSource    <= "01";
                                PCWriteCond <= '1';
                                StateCode   <= "1011";

                                if opcode = OP_BNE then
                                                BranchNE <= '1';
                                end if;

                        when JUMP =>
                                PCWrite   <= '1';
                                PCSource  <= "10";
                                StateCode <= "1100";
                end case;

                -- R-type instructions choose their ALU operation from opcode.
                if state = EXEC_R then
                        case opcode is
                                when OP_SUB =>
                                        ALUControl <= "001";
                                when OP_AND =>
                                        ALUControl <= "010";
                                when OP_OR =>
                                        ALUControl <= "011";
                                when OP_SLT =>
                                        ALUControl <= "100";
                                when others =>
                                        ALUControl <= "000";
                        end case;
                end if;
        end process output_logic;
end architecture rtl;
