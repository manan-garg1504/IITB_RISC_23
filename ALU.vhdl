library ieee;
use ieee.std_logic_1164.all;
--Purely the combinational circuit that is the ALU.
--Not carry during subtraction implies that A is less than B(unsigned)
--Try eventually to do signed comparison, which is what programmer prolly expects

entity ALU is
	port(
		Input_1, Input_2: in std_logic_vector(15 downto 0);
		Nand_ins, Extra_bit: in std_logic; 
		--Extra bit adds 1 to Input_2 in addition path
		Output: out std_logic_vector(15 downto 0);
		C,Z: out std_logic
	);
end entity ALU;

architecture arch of ALU is
	signal carry : std_logic_vector(16 downto 0);
	signal sum_buf : std_logic_vector(15 downto 0);
	signal nand_buf : std_logic_vector(15 downto 0);
	signal Or_Gates : std_logic_vector(11 downto 0);
	signal ALU_out: std_logic_vector(15 downto 0);
begin
	carry(0) <= Extra_bit;

	L1: for i in 0 to 15 generate
		sum_buf(i) <= Input_1(i) xor Input_2(i) xor carry(i);
		carry(i+1) <= (Input_1(i) and Input_2(i)) or (Input_2(i) and carry(i)) or (Input_1(i) and carry(i));
	end generate;

	L2: for i in 0 to 15 generate
		nand_buf(i) <= Input_1(i) nand Input_2(i);
	end generate;

	ALU_out <= nand_buf when Nand_ins = '1' else
			sum_buf;

	Or_Level1: for i in 0 to 7 generate
		Or_Gates(i) <= ALU_out(2*i) or ALU_out(2*i + 1);
	end generate Or_Level1;
	Or_Level2: for i in 8 to 11 generate
		Or_Gates(i) <= Or_Gates(2*i - 16) or Or_Gates(2*i - 15);
	end generate Or_Level2;
	Z <= not((Or_Gates(8) or Or_Gates(9))or(Or_Gates(10) or Or_Gates(11)));

	C <= carry(16);
	Output <= ALU_out;
end arch;