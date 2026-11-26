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
-- Arquivo   : cpu_top.vhd
-- Descricao : Entidade de topo para a placa DE2-115. Os nomes das portas
--             seguem o arquivo de pinos da Terasic (DE2_115_pin_assignments.csv).
--               KEY0    : clock manual da CPU (cada aperto = um pulso, com debouncer)
--               KEY1    : reset (segurado = reset)
--               HEX0-3  : PC
--               HEX4-7  : saida da ULA com SW17 = '1', registrador de dados da
--                         memoria (RDM) com SW17 = '0'
--               LEDG3-0 : codigo do estado da UC (ver StateCode em controlUnit.vhd)
--               LEDG8   : aceso enquanto o botao de clock esta apertado
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity cpu_top is
        port (
                CLOCK_50 : in  std_logic;                      -- Clock de 50 MHz da placa
                KEY      : in  std_logic_vector(3 downto 0);   -- Botoes (ativos em '0')
                SW       : in  std_logic_vector(17 downto 0);  -- Chaves (so SW17 e usada)
                HEX0     : out std_logic_vector(6 downto 0);   -- PC, digito 0
                HEX1     : out std_logic_vector(6 downto 0);   -- PC, digito 1
                HEX2     : out std_logic_vector(6 downto 0);   -- PC, digito 2
                HEX3     : out std_logic_vector(6 downto 0);   -- PC, digito 3
                HEX4     : out std_logic_vector(6 downto 0);   -- ULA/RDM, digito 0
                HEX5     : out std_logic_vector(6 downto 0);   -- ULA/RDM, digito 1
                HEX6     : out std_logic_vector(6 downto 0);   -- ULA/RDM, digito 2
                HEX7     : out std_logic_vector(6 downto 0);   -- ULA/RDM, digito 3
                LEDG     : out std_logic_vector(8 downto 0)    -- LEDs verdes (estado e clock)
        );
end entity cpu_top;

architecture rtl of cpu_top is
        signal cpu_clk         : std_logic;                      -- Clock manual (saida do debouncer)
        signal reset           : std_logic;                      -- Reset ativo em '1'

        -- Ligacao entre a CPU e a memoria
        signal memory_data_in  : std_logic_vector(15 downto 0);
        signal memory_address  : std_logic_vector(15 downto 0);
        signal memory_data_out : std_logic_vector(15 downto 0);
        signal memory_read     : std_logic;
        signal memory_write    : std_logic;
        signal state_code      : std_logic_vector(3 downto 0);

        -- Valores mostrados nos displays
        signal pc              : std_logic_vector(15 downto 0);
        signal mdr             : std_logic_vector(15 downto 0);
        signal alu_result      : std_logic_vector(15 downto 0);
        signal upper_display   : std_logic_vector(15 downto 0);  -- ULA ou RDM, conforme SW17
begin
        reset <= not KEY(1);

        u_debouncer : entity work.debouncer
                port map (
                        clk      => CLOCK_50,
                        button_n => KEY(0),
                        pressed  => cpu_clk
                );

        u_cpu : entity work.Datapath
                port map (
                        clk             => cpu_clk,
                        reset           => reset,
                        memory_data_in  => memory_data_in,
                        memory_address  => memory_address,
                        memory_data_out => memory_data_out,
                        memory_read     => memory_read,
                        memory_write    => memory_write,
                        state_code      => state_code,
                        pc_out          => pc,
                        mdr_out         => mdr,
                        alu_result_out  => alu_result
                );

        -- A memoria roda no CLOCK_50, entao sua saida fica pronta bem antes
        -- do proximo pulso do clock manual (ver mem.vhd).
        u_mem : entity work.Mem
                port map (
                        clk       => CLOCK_50,
                        memWrite  => memory_write,
                        memRead   => memory_read,
                        address   => memory_address,
                        writeData => memory_data_out,
                        MemData   => memory_data_in
                );

        upper_display <= alu_result when SW(17) = '1' else mdr;

        u_hex0 : entity work.hex7seg port map (value => pc(3 downto 0),   segments => HEX0);
        u_hex1 : entity work.hex7seg port map (value => pc(7 downto 4),   segments => HEX1);
        u_hex2 : entity work.hex7seg port map (value => pc(11 downto 8),  segments => HEX2);
        u_hex3 : entity work.hex7seg port map (value => pc(15 downto 12), segments => HEX3);

        u_hex4 : entity work.hex7seg port map (value => upper_display(3 downto 0),   segments => HEX4);
        u_hex5 : entity work.hex7seg port map (value => upper_display(7 downto 4),   segments => HEX5);
        u_hex6 : entity work.hex7seg port map (value => upper_display(11 downto 8),  segments => HEX6);
        u_hex7 : entity work.hex7seg port map (value => upper_display(15 downto 12), segments => HEX7);

        LEDG(3 downto 0) <= state_code;
        LEDG(7 downto 4) <= (others => '0');
        LEDG(8)          <= cpu_clk;
end architecture rtl;
