library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM_Block_4096x16 is
    port (
        Clk      : in  STD_LOGIC;
        Rst      : in  STD_LOGIC;
        WE       : in  STD_LOGIC;
        Address  : in  STD_LOGIC_VECTOR(11 downto 0);
        Data_In  : in  STD_LOGIC_VECTOR(15 downto 0);
        Data_Out : out STD_LOGIC_VECTOR(15 downto 0)
    );
end RAM_Block_4096x16;

architecture Behavioral of RAM_Block_4096x16 is

    type RAM_Type is array (0 to 4095) of
        STD_LOGIC_VECTOR(15 downto 0);

    signal RAM : RAM_Type :=
        (others => (others => '0'));

    signal Data_Reg : STD_LOGIC_VECTOR(15 downto 0) :=
        (others => '0');

    attribute ram_style : string;
    attribute ram_style of RAM : signal is "block";

begin

    process (Clk)
    begin
        if rising_edge(Clk) then

            if WE = '1' then
                RAM(to_integer(unsigned(Address))) <= Data_In;
            end if;

            if Rst = '1' then
                Data_Reg <= (others => '0');
            else
                Data_Reg <=
                    RAM(to_integer(unsigned(Address)));
            end if;

        end if;
    end process;

    Data_Out <= Data_Reg;

end Behavioral;