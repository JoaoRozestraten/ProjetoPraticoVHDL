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
-- Arquivo   : datapath.vhd
-- Descricao : Caminho de dados da CPU multiciclo. Liga a unidade de controle,
--             o PC, o IR, o banco de registradores, a ULA, o MDR e os
--             registradores internos A, B e ALUOut. A memoria fica fora
--             (em cpu_top.vhd ou no testbench).
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Datapath is
        port (
                clk            : in  std_logic;                      -- Clock da CPU
                reset          : in  std_logic;                      -- Reset assincrono
                memory_data_in : in  std_logic_vector(15 downto 0);  -- Palavra lida da memoria
                memory_address : out std_logic_vector(15 downto 0);  -- Endereco da memoria (PC ou ALUOut)
                memory_data_out: out std_logic_vector(15 downto 0);  -- Dado a escrever na memoria (B)
                memory_read    : out std_logic;                      -- Habilita leitura da memoria
                memory_write   : out std_logic;                      -- Habilita escrita na memoria
                state_code     : out std_logic_vector(3 downto 0);   -- Codigo do estado da UC
                -- Valores mostrados nos displays da FPGA
                pc_out         : out std_logic_vector(15 downto 0);  -- PC atual
                mdr_out        : out std_logic_vector(15 downto 0);  -- Conteudo do MDR (RDM)
                alu_result_out : out std_logic_vector(15 downto 0)   -- Saida da ULA
        );
end entity Datapath;

architecture rtl of Datapath is
        -- Valores principais do caminho de dados
        signal pc            : std_logic_vector(15 downto 0);
        signal pc_next       : std_logic_vector(15 downto 0);
        signal alu_result    : std_logic_vector(15 downto 0);
        signal alu_out       : std_logic_vector(15 downto 0);
        signal mdr_data      : std_logic_vector(15 downto 0);

        -- Entradas da ULA e dados do banco de registradores
        signal alu_input_a   : std_logic_vector(15 downto 0);
        signal alu_input_b   : std_logic_vector(15 downto 0);
        signal a_reg         : std_logic_vector(15 downto 0);
        signal b_reg         : std_logic_vector(15 downto 0);
        signal rs_data       : std_logic_vector(15 downto 0);
        signal rt_data       : std_logic_vector(15 downto 0);
        signal rd_data       : std_logic_vector(15 downto 0);
        signal write_data    : std_logic_vector(15 downto 0);

        -- Campos da instrucao
        signal opcode        : std_logic_vector(3 downto 0);
        signal rd            : std_logic_vector(2 downto 0);
        signal rs            : std_logic_vector(2 downto 0);
        signal rt            : std_logic_vector(2 downto 0);
        signal immediate     : std_logic_vector(5 downto 0);
        signal address       : std_logic_vector(11 downto 0);
        signal Extend        : std_logic_vector(15 downto 0);  -- Imediato com extensao de sinal
        signal Extshift      : std_logic_vector(15 downto 0);  -- Imediato estendido deslocado 1 bit

        -- Sinais de controle
        signal pc_write      : std_logic;
        signal pc_write_cond : std_logic;
        signal branch_ne     : std_logic;
        signal iord          : std_logic;
        signal ir_write      : std_logic;
        signal mdr_write     : std_logic;
        signal a_write       : std_logic;
        signal b_write       : std_logic;
        signal alu_out_write : std_logic;
        signal reg_write     : std_logic;
        signal mem_to_reg    : std_logic;
        signal alu_src_a     : std_logic;
        signal alu_src_b     : std_logic_vector(1 downto 0);
        signal pc_source     : std_logic_vector(1 downto 0);
        signal alu_control   : std_logic_vector(2 downto 0);

        signal zero          : std_logic;  -- Flag de zero da ULA
        signal branch_taken  : std_logic;  -- '1' quando o desvio e tomado
        signal pc_enable     : std_logic;  -- Habilita escrita no PC
begin
        -- Selecao do imediato e do endereco da memoria
        Extend <= std_logic_vector(resize(signed(immediate), 16));
        Extshift <= std_logic_vector(shift_left(signed(Extend), 1));
        memory_address <= pc when iord = '0' else alu_out;
        memory_data_out <= b_reg;
        write_data <= mdr_data when mem_to_reg = '1' else alu_out;
        branch_taken <= pc_write_cond and (zero xor branch_ne);
        pc_enable <= pc_write or branch_taken;

        pc_out <= pc;
        mdr_out <= mdr_data;
        alu_result_out <= alu_result;

        -- Seleciona a origem do proximo PC: resultado da ULA, alvo do desvio
        -- guardado no ALUOut ou o endereco do salto estendido com zeros.
        process (pc_source, alu_result, alu_out, address)
        begin
                case pc_source is
                when "01" =>
                                pc_next <= alu_out;
                when "10" =>
                                pc_next <= x"0" & address;
                when others =>
                                pc_next <= alu_result;
                end case;
        end process;

                -- Seleciona os dois operandos apresentados a ULA.
        process (alu_src_a, alu_src_b, pc, a_reg, b_reg, Extend)
                variable left_operand  : std_logic_vector(15 downto 0);
                variable right_operand : std_logic_vector(15 downto 0);
                begin
                        if alu_src_a = '1' then
                                left_operand := a_reg;
                        else
                                left_operand := pc;
                        end if;

                        case alu_src_b is
                        when "01" => right_operand := x"0001";
                        when "10" => right_operand := Extend;  
                        when others => right_operand := b_reg;
                        end case;

                        alu_input_a <= left_operand;
                        alu_input_b <= right_operand;
                end process;

                -- Unidade de controle
                u_control : entity work.ControlUnit
                        port map (
                                clk          => clk,
                                reset        => reset,
                                opcode       => opcode,
                                PCWrite      => pc_write,
                                PCWriteCond  => pc_write_cond,
                                BranchNE     => branch_ne,
                                PCSource     => pc_source,
                                IorD         => iord,
                                MemRead      => memory_read,
                                MemWrite     => memory_write,
                                IRWrite      => ir_write,
                                MDRWrite     => mdr_write,
                                AWrite       => a_write,
                                BWrite       => b_write,
                                ALUOutWrite  => alu_out_write,
                                RegWrite     => reg_write,
                                MemtoReg     => mem_to_reg,
                                ALUSrcA      => alu_src_a,
                                ALUSrcB      => alu_src_b,
                                ALUControl   => alu_control,
                                StateCode    => state_code
                        );

                -- Contador de programa
                u_pc : entity work.pc
                        port map (
                                clk     => clk,
                                rst     => reset,
                                PCWrite => pc_enable,
                                PC_next => pc_next,
                                PC_out  => pc
                        );

                -- Registrador de instrucao e separacao dos campos
                u_ir : entity work.IR
                        port map (
                                clk       => clk,
                                rst       => reset,
                                IRWrite   => ir_write,
                                MemData   => memory_data_in,
                                opcode    => opcode,
                                rd        => rd,
                                rs        => rs,
                                rt        => rt,
                                imediato  => immediate,
                                endereco  => address
                        );

                -- Banco de registradores. A terceira porta de leitura fornece o dado do ST (Ri).
                u_regs : entity work.BancoRegistradores
                        port map (
                                clk        => clk,
                                rst        => reset,
                                reg_write  => reg_write,
                                rs         => rs,
                                rt         => rt,
                                rd         => rd,
                                write_reg  => rd,
                                write_data => write_data,
                                rs_data    => rs_data,
                                rt_data    => rt_data,
                                rd_data    => rd_data
                        );

                -- Unidade logica e aritmetica
                u_ula : entity work.ula
                        port map (
                                A           => alu_input_a,
                                B           => alu_input_b,
                                ula_control => alu_control,
                                saida       => alu_result,
                                zero        => zero
                        );

                -- Registrador de dados da memoria
                u_mdr : entity work.mdr
                        port map (
                                clk      => clk,
                                rst      => reset,
                                enable   => mdr_write,
                                data_in  => memory_data_in,
                                data_out => mdr_data
                        );

                -- Registradores internos do multiciclo: A, B e ALUOut.
                process (clk, reset)
                begin
                        if reset = '1' then
                                a_reg   <= (others => '0');
                                b_reg   <= (others => '0');
                                alu_out <= (others => '0');
                        elsif rising_edge(clk) then
                                if a_write = '1' then
                                        a_reg <= rs_data;
                                end if;

                                if b_write = '1' then
                                        -- ST grava Ri; BEQ/BNE comparam Ri com Rj.
                                        if opcode = "0111" or opcode = "1000" or opcode = "1001" then
                                                b_reg <= rd_data;
                                        else
                                                b_reg <= rt_data;
                                        end if;
                                end if;

                                if alu_out_write = '1' then
                                        alu_out <= alu_result;
                                end if;
                        end if;
                end process;

end architecture rtl;
