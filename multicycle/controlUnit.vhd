-- ============================================================================
-- Projeto Pratico VHDL - CPU multiciclo de 16 bits
-- Laboratorio de Arquitetura de Sistemas Computacionais (218040P)
--
-- Integrantes:
--   Daniel Picconi Alquete           RA 24015408
--   Gabriel Lippi Angelini           RA 24005453
--   Joao Guadagnucci Rozestraten     RA 24005941
--   Nathan Gonzalez Jurcevic         RA 21008388
--   Rodrigo Seiji Yugoshi Ushizawa   RA 24009811
--
-- Arquivo   : controlUnit.vhd
-- Descricao : Unidade de controle (UC) multiciclo. Maquina de estados que,
--             a partir do opcode, gera os sinais de controle do caminho de
--             dados. Codigos de estado (StateCode, mostrados nos LEDs verdes):
--             0000 FETCH     0001 DECODE    0010 EXEC_R    0011 WB_R
--             0100 EXEC_ADDI 0101 WB_ADDI   0110 MEM_ADDR  0111 MEM_READ
--             1001 MEM_WB    1010 MEM_STORE 1011 BRANCH    1100 JUMP
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity ControlUnit is
        port (
                clk          : in  std_logic;                     -- Clock da CPU
                reset        : in  std_logic;                     -- Reset assincrono (volta para FETCH)
                opcode       : in  std_logic_vector(3 downto 0);  -- Opcode vindo do IR
                PCWrite      : out std_logic;                     -- Escreve o PC incondicionalmente
                PCWriteCond  : out std_logic;                     -- Escreve o PC se o desvio for tomado
                BranchNE     : out std_logic;                     -- '1' no BNE (desvia quando zero = '0')
                PCSource     : out std_logic_vector(1 downto 0);  -- Proximo PC: 00 ULA, 01 ALUOut, 10 endereco do JMP
                IorD         : out std_logic;                     -- Endereco da memoria: 0 PC, 1 ALUOut
                MemRead      : out std_logic;                     -- Habilita leitura da memoria
                MemWrite     : out std_logic;                     -- Habilita escrita na memoria
                IRWrite      : out std_logic;                     -- Habilita escrita no IR
                MDRWrite     : out std_logic;                     -- Habilita escrita no MDR
                AWrite       : out std_logic;                     -- Habilita escrita no registrador A
                BWrite       : out std_logic;                     -- Habilita escrita no registrador B
                ALUOutWrite  : out std_logic;                     -- Habilita escrita no ALUOut
                RegWrite     : out std_logic;                     -- Habilita escrita no banco de registradores
                MemtoReg     : out std_logic;                     -- Dado escrito no banco: 0 ALUOut, 1 MDR
                ALUSrcA      : out std_logic;                     -- Operando A da ULA: 0 PC, 1 registrador A
                ALUSrcB      : out std_logic_vector(1 downto 0);  -- Operando B da ULA: 00 B, 01 constante 1, 10 imediato estendido
                ALUControl   : out std_logic_vector(2 downto 0);  -- Operacao da ULA (ver ula.vhd)
                StateCode    : out std_logic_vector(3 downto 0)   -- Codigo do estado atual (LEDs)
        );
end entity ControlUnit;

architecture rtl of ControlUnit is
        -- Estados da maquina de estados
        type state_t is (
                FETCH,
                DECODE,
                EXEC_R,
                WB_R,
                EXEC_ADDI,
                WB_ADDI,
                MEM_ADDR,
                MEM_READ,
                MEM_WB,
                MEM_STORE,
                BRANCH,
                JUMP
        );

        signal state      : state_t := FETCH;  -- Estado atual
        signal next_state : state_t := FETCH;  -- Proximo estado

        -- Opcodes das 11 instrucoes
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
        -- Registrador de estado
        -- Reset assincrono, como no PC, no IR e no banco de registradores.
        state_register : process (clk, reset)
        begin
                if reset = '1' then
                        state <= FETCH;
                elsif rising_edge(clk) then
                        state <= next_state;
                end if;
        end process state_register;

        -- Logica de proximo estado. No DECODE a ULA ja calcula PC + imediato
        -- (alvo do desvio), que fica guardado no ALUOut.
        next_state_logic : process (state, opcode)
        begin
                next_state <= FETCH;

                case state is
                        when FETCH =>
                                next_state <= DECODE;

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

                        when EXEC_R =>
                                next_state <= WB_R;
                        when WB_R =>
                                next_state <= FETCH;
                        when EXEC_ADDI =>
                                next_state <= WB_ADDI;
                        when WB_ADDI =>
                                next_state <= FETCH;
                        when MEM_ADDR =>
                                if opcode = OP_LD then
                                        next_state <= MEM_READ;
                                else
                                        next_state <= MEM_STORE;
                                end if;
                        when MEM_READ =>
                                next_state <= MEM_WB;
                        when MEM_WB =>
                                next_state <= FETCH;
                        when MEM_STORE =>
                                next_state <= FETCH;
                        when BRANCH =>
                                next_state <= FETCH;
                        when JUMP =>
                                next_state <= FETCH;
                end case;
        end process next_state_logic;

        -- Logica de saida
        output_logic : process (state, opcode)
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
                ALUControl  <= "000";
                StateCode   <= "0000";

                case state is
                        when FETCH =>
                                MemRead   <= '1';
                                IRWrite   <= '1';
                                PCWrite   <= '1';
                                ALUSrcA   <= '0'; -- PC
                                ALUSrcB   <= "01"; -- constante 1

                        when DECODE =>
                                AWrite      <= '1';
                                BWrite      <= '1';
                                ALUSrcB     <= "10"; -- imediato estendido
                                ALUOutWrite <= '1';
                                StateCode   <= "0001";


                        when EXEC_R =>
                                ALUSrcA     <= '1'; -- A
                                ALUSrcB     <= "00"; -- B
                                ALUOutWrite <= '1';
                                StateCode   <= "0010";

                        when WB_R =>
                                RegWrite  <= '1';
                                StateCode <= "0011";

                        when EXEC_ADDI =>
                                ALUSrcA     <= '1'; -- A
                                ALUSrcB     <= "10"; -- imediato estendido
                                ALUOutWrite <= '1';
                                StateCode   <= "0100";

                        when WB_ADDI =>
                                RegWrite  <= '1';
                                StateCode <= "0101";

                        when MEM_ADDR =>
                                ALUSrcA     <= '1'; -- A
                                ALUSrcB     <= "10"; -- imediato estendido
                                ALUOutWrite <= '1';
                                StateCode   <= "0110";

                        when MEM_READ =>
                                IorD      <= '1';
                                MemRead   <= '1';
                                MDRWrite  <= '1';
                                StateCode <= "0111";

                        when MEM_WB =>
                                RegWrite  <= '1';
                                MemtoReg  <= '1';
                                StateCode <= "1001";

                        when MEM_STORE =>
                                IorD      <= '1';
                                MemWrite  <= '1';
                                StateCode <= "1010";

                        when BRANCH =>
                                ALUSrcA     <= '1'; -- A
                                ALUSrcB     <= "00"; -- B
                                ALUControl  <= "001"; -- SUB
                                PCSource    <= "01"; -- ALUOut
                                PCWriteCond <= '1';
                                StateCode   <= "1011";

                                if opcode = OP_BNE then
                                        BranchNE <= '1';
                                end if;

                        when JUMP =>
                                PCWrite   <= '1';
                                PCSource  <= "10"; -- endereco do JMP
                                StateCode <= "1100";
                end case;

                -- No EXEC_R a operacao da ULA depende do opcode
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
