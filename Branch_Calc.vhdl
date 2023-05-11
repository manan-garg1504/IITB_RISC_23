library ieee;
use ieee.std_logic_1164.all;

entity Branch_Calc is
	port(
		PC: in std_logic_vector(15 downto 0);
		Immediate: in std_logic_vector(15 downto 1);
		Result: out std_logic_vector(15 downto 0)
	);
end entity Branch_Calc;

architecture arch of Branch_Calc is

	signal Carry : std_logic_vector(14 downto 1):= (others =>'0');

begin

	Result(0) <= PC(0);

	Result(1) <= PC(1) xor Immediate(1);
	Carry(1) <= (PC(1) and Immediate(1));
	L1: for i in 2 to 14 generate
		Result(i) <= PC(i) xor Immediate(i) xor Carry(i-1);
		Carry(i) <= (PC(i) and Immediate(i)) or (Immediate(i) and Carry(i-1)) or (PC(i) and Carry(i-1));
	end generate;

	Result(15) <= PC(15) xor Immediate(15) xor Carry(14);
end arch;