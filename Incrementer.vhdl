library ieee;
use ieee.std_logic_1164.all;
--Purely the combinational circuit that is the ALU.

entity Increment is
	port(
		Input: in std_logic_vector(15 downto 0);
		Output: out std_logic_vector(15 downto 0)
	);
end entity Increment;

architecture arch of Increment is
	signal Carry : std_logic_vector(14 downto 0):= (others =>'0');
begin

	Output(0) <= not Input(0);
	Carry(0) <= Input(0);

	L1: for i in 1 to 14 generate
		Output(i) <= Input(i) xor Carry(i-1);
		Carry(i) <= Input(i) and Carry(i-1);
	end generate;

	Output(15) <= Input(15) xor Carry(14);

end arch;