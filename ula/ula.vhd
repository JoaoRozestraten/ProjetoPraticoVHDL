library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Portas:
--   A           : Entrada de 16 bits (primeiro operando (PC ou RS))
--   B           : Entrada de 16 bits (segundo operando (RT ou 4 ou Imediato ou Imediato Shift))
--   ula_control : Entrada de controle de 3 bits (código da operação)
--   saida       : Saída de 16 bits (resultado da operação)
--   zero        : Flag de 1 bit ('1' quando saida = x"0000", senão '0')

--  Tabela de Operações
--   ula_control = "000" -> AND (A and B)
--   ula_control = "001" -> OR (A or B)
--   ula_control = "010" -> SOMA -> ADD, ADDI, LD, ST
--   ula_control = "100" -> SUBTRAÇÃO -> SUB, BEQ, BNE
--   ula_control = "110" -> (A < B)  -> SLT
--   ula_control = "111" -> NOR (not (A or B))


entity ula is
    Port (
        A           : in  STD_LOGIC_VECTOR(15 downto 0);
        B           : in  STD_LOGIC_VECTOR(15 downto 0);
        ula_control : in  STD_LOGIC_VECTOR(2 downto 0);
        saida       : out STD_LOGIC_VECTOR(15 downto 0);
        zero        : out STD_LOGIC
    );
end ula;

architecture Behavioral of ula is
begin

    process(A, B, ula_control)
        variable res_var : std_logic_vector(15 downto 0);
    begin
        case ula_control is

            -- 000 : Operação lógica AND 
            when "000" =>
                res_var := A and B;

            -- 001 : Operação lógica OR 
            when "001" =>
                res_var := A or B;

            -- 010 : Soma 
            when "010" =>
                res_var := std_logic_vector(signed(A) + signed(B));

            -- 100 : Subtração (BNE)
            when "100" =>
                res_var := std_logic_vector(signed(A) - signed(B));

            -- 110 : SLT 
            when "110" =>
                if signed(A) < signed(B) then
                    res_var := x"0001";
                else
                    res_var := x"0000";
                end if;

            -- 111 : Operação lógica NOR
            when "111" =>
                res_var := not (A or B);

            -- outros 
            when others =>
                res_var := (others => '0');

        end case;

        -- Atribuição dos resultados da operação
        saida <= res_var;

        if res_var = x"0000" then
            zero <= '1';
        else
            zero <= '0';
        end if;

    end process;

end Behavioral;
