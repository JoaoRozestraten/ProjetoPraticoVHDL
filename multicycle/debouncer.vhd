library ieee;
use ieee.std_logic_1164.all;

-- Turns a bouncing push button into a clean level.
-- button_n is active-low (DE2-115 KEYs read '0' while pressed);
-- pressed is '1' while the button is held, after it has been stable
-- for STABLE_CYCLES clock cycles (1_000_000 at 50 MHz = 20 ms).
entity debouncer is
        generic (
                STABLE_CYCLES : positive := 1_000_000
        );
        port (
                clk      : in  std_logic;
                button_n : in  std_logic;
                pressed  : out std_logic
        );
end entity debouncer;

architecture rtl of debouncer is
        signal sync_0 : std_logic := '1';
        signal sync_1 : std_logic := '1';
        signal stable : std_logic := '1';
        signal count  : natural range 0 to STABLE_CYCLES - 1 := 0;
begin
        pressed <= not stable;

        process (clk)
        begin
                if rising_edge(clk) then
                        -- Two flip-flops synchronize the asynchronous button.
                        sync_0 <= button_n;
                        sync_1 <= sync_0;

                        if sync_1 = stable then
                                count <= 0;
                        elsif count = STABLE_CYCLES - 1 then
                                stable <= sync_1;
                                count  <= 0;
                        else
                                count <= count + 1;
                        end if;
                end if;
        end process;
end architecture rtl;
