library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
use STD.textio.all;
use ieee.std_logic_textio.all;

--Invariance of LM operand?
--Current output doesn't seem to have forwarded operand

entity RegisterFile is
	port(
		next_Ins_type: in std_logic_vector(3 downto 0);
		next_OprA_Addr, next_OprB_Addr, next_WB_Addr, next_OprC_Addr, Execute_addr: in std_logic_vector(2 downto 0);
		next_PC, WB_Data_next, Extra_Operand_next, Execute_out: in std_logic_vector(15 downto 0);
		clk, end_proc_in, WB_en_next, next_Complement_OprB, Use_Extra_next, Mult_next, Pause_RF: in std_logic;
		Operand_A, Operand_B, Extra_Opr: out std_logic_vector(15 downto 0);
		OprC_addr: out std_logic_vector(2 downto 0);
		Ins_type_out: out std_logic_vector(3 downto 0);
		end_proc_out: out std_logic
	);
end entity;

architecture behave of RegisterFile is

	type RF is array(1 to 7) of std_logic_vector(15 downto 0);
	signal registers: RF;
	signal OprA_Addr, OprB_Addr: std_logic_vector(2 downto 0);
	signal Ins_type: std_logic_vector(3 downto 0);
	signal OprA, OprB, Extra_Operand, PC, temp_reg: std_logic_vector(15 downto 0);
	signal Complement_OprB, Use_Extra, Store, Mult, Prev_Mult: std_logic;
	signal Reg_BufA, Reg_BufB: RF;

begin
	process(clk)
	begin
		if(rising_edge(clk) and Pause_RF = '0') then
			OprA_Addr <= next_OprA_Addr;
			OprB_Addr <= next_OprB_Addr;
			OprC_Addr <= next_OprC_Addr;
			Extra_Operand <= Extra_Operand_next;
			PC <= next_PC;
			Use_Extra <= Use_Extra_next;
			Ins_type <= next_Ins_type;
			Complement_OprB <= next_Complement_OprB;
			end_proc_out <= end_proc_in;
			Mult <= Mult_next;
			Prev_Mult <= Mult;

			if(Prev_Mult = '0' and Mult = '1') then
				temp_reg <= OprA;
			end if;

		end if;
	end process;

	Reg_BufA(1) <= registers(1);
	Reg_BufA(2) <= registers(2) when OprA_Addr(0) = '0' else registers(3);
	Reg_BufA(3) <= registers(4) when OprA_Addr(0) = '0' else registers(5);
	Reg_BufA(4) <= registers(6) when OprA_Addr(0) = '0' else registers(7);
	Reg_BufA(5) <= Reg_BufA(1) when OprA_Addr(1) = '0' else Reg_BufA(2);
	Reg_BufA(6) <= Reg_BufA(3) when OprA_Addr(1) = '0' else Reg_BufA(4);
	Reg_BufA(7) <= Reg_BufA(5) when OprA_Addr(2) = '0' else Reg_BufA(6);

	OprA<=	PC when OprA_Addr = "000" else
			Execute_out when (Execute_addr = OprA_Addr) else
			WB_Data_next when (next_WB_Addr = OprA_Addr) else
			Reg_BufA(7);

	Reg_BufB(1) <= registers(1);
	Reg_BufB(2) <= registers(2) when OprB_Addr(0) = '0' else registers(3);
	Reg_BufB(3) <= registers(4) when OprB_Addr(0) = '0' else registers(5);
	Reg_BufB(4) <= registers(6) when OprB_Addr(0) = '0' else registers(7);
	Reg_BufB(5) <= Reg_BufB(1) when OprB_Addr(1) = '0' else Reg_BufB(2);
	Reg_BufB(6) <= Reg_BufB(3) when OprB_Addr(1) = '0' else Reg_BufB(4);
	Reg_BufB(7) <= Reg_BufB(5) when OprB_Addr(2) = '0' else Reg_BufB(6);

	OprB<=	PC when OprB_Addr = "000" else
			Execute_out when (Execute_addr = OprB_Addr) else
			WB_Data_next when (next_WB_Addr = OprB_Addr) else
			Reg_BufB(7);

	Operand_B<=	Extra_Operand when Use_Extra = '1' else
				not(OprB) when Complement_OprB = '1' else
				OprB;

	Operand_A <=temp_reg when Prev_Mult = '1' else
				OprA;

	Extra_Opr<= OprB when Ins_type = "1101" else
				Extra_Operand;

	Ins_type_out <= Ins_type;

	--Write Back Stage
	process(clk)
	begin
		if(rising_edge(clk) and WB_en_next='1' and (next_WB_Addr /= "000")) then
			registers(to_integer(unsigned(next_WB_Addr))) <= WB_Data_next;
		end if;
	end process;
end behave;