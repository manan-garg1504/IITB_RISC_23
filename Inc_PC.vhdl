library ieee;
use ieee.std_logic_1164.all;
--Purely the combinational circuit that is the ALU.

entity PC_Inc is
	port(
		PC: in std_logic_vector(15 downto 0);
		Output: out std_logic_vector(15 downto 0)
	);
end entity PC_Inc;

architecture arch of PC_Inc is
	signal Carry : std_logic_vector(14 downto 1):= (others =>'0');
begin

	Output(0) <= PC(0);

	Output(1) <= not PC(1);
	Carry(1) <= PC(1);

	L1: for i in 2 to 14 generate
		Output(i) <= PC(i) xor Carry(i-1);
		Carry(i) <= PC(i) and Carry(i-1);
	end generate;

	Output(15) <= PC(15) xor Carry(14);

end arch;