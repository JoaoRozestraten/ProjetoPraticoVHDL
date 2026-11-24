library ieee;
use ieee.std_logic_1164.all;

-- Top-level entity for the DE2-115 board.
-- Port names follow the Terasic pin assignment file (DE2_115_pin_assignments.csv).
--   KEY0     : manual CPU clock (one press = one clock pulse, debounced)
--   KEY1     : reset (held = reset)
--   HEX0-3   : PC
--   HEX4-7   : ALU output when SW17 = '1', memory data register (RDM) when SW17 = '0'
--   LEDG3-0  : control unit state code (see StateCode in controlUnit.vhd)
--   LEDG8    : on while the clock button is pressed
entity cpu_top is
        port (
                CLOCK_50 : in  std_logic;
                KEY      : in  std_logic_vector(3 downto 0);
                SW       : in  std_logic_vector(17 downto 0);
                HEX0     : out std_logic_vector(6 downto 0);
                HEX1     : out std_logic_vector(6 downto 0);
                HEX2     : out std_logic_vector(6 downto 0);
                HEX3     : out std_logic_vector(6 downto 0);
                HEX4     : out std_logic_vector(6 downto 0);
                HEX5     : out std_logic_vector(6 downto 0);
                HEX6     : out std_logic_vector(6 downto 0);
                HEX7     : out std_logic_vector(6 downto 0);
                LEDG     : out std_logic_vector(8 downto 0)
        );
end entity cpu_top;

architecture rtl of cpu_top is
        signal cpu_clk         : std_logic;
        signal reset           : std_logic;

        signal memory_data_in  : std_logic_vector(15 downto 0);
        signal memory_address  : std_logic_vector(15 downto 0);
        signal memory_data_out : std_logic_vector(15 downto 0);
        signal memory_read     : std_logic;
        signal memory_write    : std_logic;
        signal state_code      : std_logic_vector(3 downto 0);

        signal pc              : std_logic_vector(15 downto 0);
        signal mdr             : std_logic_vector(15 downto 0);
        signal alu_result      : std_logic_vector(15 downto 0);
        signal upper_display   : std_logic_vector(15 downto 0);
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

        -- The memory runs on CLOCK_50 so its output is ready long before
        -- the next manual clock pulse (see mem.vhd).
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
