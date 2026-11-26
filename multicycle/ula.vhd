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
-- Arquivo   : ula.vhd
-- Descricao : Unidade logica e aritmetica de 16 bits, em complemento de dois.
--             A codificacao de ula_control e a mesma usada pela ControlUnit:
--             000 ADD, 001 SUB, 010 AND, 011 OR, 100 SLT, 110 NOR.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ula is
        port (
                A           : in  std_logic_vector(15 downto 0);  -- Operando A (PC ou registrador A)
                B           : in  std_logic_vector(15 downto 0);  -- Operando B (B, constante 1 ou imediato)
                ula_control : in  std_logic_vector(2 downto 0);   -- Operacao (ALUControl da UC)
                saida       : out std_logic_vector(15 downto 0);  -- Resultado
                zero        : out std_logic                       -- '1' quando o resultado e zero
        );
end entity;

architecture rtl of ula is
begin
        process (A, B, ula_control)
                variable result : std_logic_vector(15 downto 0);  -- Resultado da operacao
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
