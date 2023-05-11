library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Dec_Mult is
	port(
		clk, Mult: std_logic;
		Input_Imm: in std_logic_vector(7 downto 0);
		Bin_Imm : out std_logic_vector(2 downto 0);
		Reg_addr_mult: out std_logic_vector (2 downto 0);
		Next_Imm: out std_logic_vector(7 downto 0)
	);
end Dec_Mult;

architecture arch of Dec_Mult is

	signal Suppress : std_logic_vector(7 downto 1);
	signal counter: std_logic_vector(2 downto 0);

begin

	process(clk)
	begin
		if(rising_edge(clk)) then
			if (Mult = '0') then
				counter <= "000";
			else
				counter(0) <= not counter(0);
				if(counter(0) = '1') then
					counter(1) <= not counter(1);
				end if;
				if(counter(1 downto 0) = "11") then
					counter(2) <= not counter(2);
				end if;
			end if;
		end if;
	end process;
	Next_Imm(0) <= '0';

	Suppress(1) <= Input_Imm(0) or Input_Imm(1);
	Next_Imm(1) <= Input_Imm(0) and Input_Imm(1);

	Suppression: for i in 2 to 7 generate
		Suppress(i) <= Suppress(i-1) or Input_Imm(i);
		Next_Imm(i) <= Suppress(i-1) and Input_Imm(i);
	end generate;

	Bin_Imm <= counter;
	Reg_addr_mult(2) <= Suppress(3);
	Reg_addr_mult(1) <= (Suppress(1) and Suppress(3)) or (Suppress(5) and not Suppress(3));
	Reg_addr_mult(0) <= Input_Imm(0) or (Suppress(2) and not Suppress(1)) or (Suppress(4) and not Suppress(3)) or (Suppress(6) and not Suppress(5));

end arch;