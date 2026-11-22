library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Datapath is
        port (
                clk            : in  std_logic;
                reset          : in  std_logic;
                memory_data_in : in  std_logic_vector(15 downto 0);
                memory_address : out std_logic_vector(15 downto 0);
                memory_data_out: out std_logic_vector(15 downto 0);
                memory_read    : out std_logic;
                memory_write   : out std_logic;
                state_code     : out std_logic_vector(3 downto 0)
        );
end entity Datapath;

architecture rtl of Datapath is
        -- Main datapath values
        signal pc            : std_logic_vector(15 downto 0);
        signal pc_next       : std_logic_vector(15 downto 0);
        signal alu_result    : std_logic_vector(15 downto 0);
        signal alu_out       : std_logic_vector(15 downto 0);
        signal mdr_data      : std_logic_vector(15 downto 0);

        -- ALU inputs and register-bank data
        signal alu_input_a   : std_logic_vector(15 downto 0);
        signal alu_input_b   : std_logic_vector(15 downto 0);
        signal a_reg         : std_logic_vector(15 downto 0);
        signal b_reg         : std_logic_vector(15 downto 0);
        signal rs_data       : std_logic_vector(15 downto 0);
        signal rt_data       : std_logic_vector(15 downto 0);
        signal rd_data       : std_logic_vector(15 downto 0);
        signal write_data    : std_logic_vector(15 downto 0);

        -- Instruction fields
        signal opcode        : std_logic_vector(3 downto 0);
        signal rd            : std_logic_vector(2 downto 0);
        signal rs            : std_logic_vector(2 downto 0);
        signal rt            : std_logic_vector(2 downto 0);
        signal immediate     : std_logic_vector(5 downto 0);
        signal address       : std_logic_vector(11 downto 0);
        signal Extend        : std_logic_vector(15 downto 0);
        signal Extshift      : std_logic_vector(15 downto 0);

        -- Control signals
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

        signal zero          : std_logic;
        signal branch_taken  : std_logic;
begin
        -- Immediate and memory-address selection
        Extend <= std_logic_vector(resize(signed(immediate), 16));
        Extshift <= std_logic_vector(shift_left(signed(Extend), 1));
        memory_address <= pc when iord = '0' else alu_out;
        memory_data_out <= b_reg;
        write_data <= mdr_data when mem_to_reg = '1' else alu_out;
        branch_taken <= pc_write_cond and (zero xor branch_ne);

        -- Select the next PC source: ALU result, saved branch target,
        -- or the zero-extended jump address.
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

                -- Select the two operands presented to the ULA.
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

                -- Control unit
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

                -- Program counter
                u_pc : entity work.pc
                        port map (
                                clk     => clk,
                                rst     => reset,
                                PCWrite => pc_write or branch_taken,
                                PC_next => pc_next,
                                PC_out  => pc
                        );

                -- Instruction register and field decoder
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

                -- Register bank. The third read port supplies store data (Ri).
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

                -- Arithmetic and logic unit
                u_ula : entity work.ula
                        port map (
                                A           => alu_input_a,
                                B           => alu_input_b,
                                ula_control => alu_control,
                                saida       => alu_result,
                                zero        => zero
                        );

                -- Memory data register
                u_mdr : entity work.mdr
                        port map (
                                clk      => clk,
                                rst      => reset,
                                enable   => mdr_write,
                                data_in  => memory_data_in,
                                data_out => mdr_data
                        );

                -- Internal multicycle registers: A, B, and ALUOut.
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
                                        if opcode = "0111" then
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
