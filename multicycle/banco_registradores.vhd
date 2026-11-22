library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BancoRegistradores is
        port (
                clk        : in  std_logic;
                rst        : in  std_logic;
                reg_write  : in  std_logic;
                rs         : in  std_logic_vector(2 downto 0);
                rt         : in  std_logic_vector(2 downto 0);
                rd         : in  std_logic_vector(2 downto 0);
                write_reg  : in  std_logic_vector(2 downto 0);
                write_data : in  std_logic_vector(15 downto 0);
                rs_data    : out std_logic_vector(15 downto 0);
                rt_data    : out std_logic_vector(15 downto 0);
                rd_data    : out std_logic_vector(15 downto 0)
        );
end entity;

architecture rtl of BancoRegistradores is
        type reg_array is array (0 to 7) of std_logic_vector(15 downto 0);
        signal regs : reg_array := (others => (others => '0'));
begin
        rs_data <= regs(to_integer(unsigned(rs))) when rs /= "000" else (others => '0');
        rt_data <= regs(to_integer(unsigned(rt))) when rt /= "000" else (others => '0');
        rd_data <= regs(to_integer(unsigned(rd))) when rd /= "000" else (others => '0');

        process (clk, rst)
        begin
                if rst = '1' then
                        regs <= (others => (others => '0'));
                elsif rising_edge(clk) then
                        if reg_write = '1' and write_reg /= "000" then
                                regs(to_integer(unsigned(write_reg))) <= write_data;
                        end if;
                end if;
        end process;
end architecture;
