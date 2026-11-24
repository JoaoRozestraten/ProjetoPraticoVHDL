library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ALU control encoding is shared with ControlUnit:
-- 000 ADD, 001 SUB, 010 AND, 011 OR, 100 SLT, 110 NOR.
entity ula is
        port (
                A           : in  std_logic_vector(15 downto 0);
                B           : in  std_logic_vector(15 downto 0);
                ula_control : in  std_logic_vector(2 downto 0);
                saida       : out std_logic_vector(15 downto 0);
                zero        : out std_logic
        );
end entity;

architecture rtl of ula is
begin
        process (A, B, ula_control)
                variable result : std_logic_vector(15 downto 0);
        begin
                case ula_control is
                        when "000" => result := std_logic_vector(signed(A) + signed(B));
                        when "001" => result := std_logic_vector(signed(A) - signed(B));
                        when "010" => result := A and B;
                        when "011" => result := A or B;
                        when "100" =>
                                if signed(A) < signed(B) then result := x"0001";
                                else result := x"0000";
                                end if;
                        when "110" => result := not (A or B);
                        when others => result := (others => '0');
                end case;
                saida <= result;
                if result = x"0000" then zero <= '1'; else zero <= '0'; end if;
        end process;
end architecture;
