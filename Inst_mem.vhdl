library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity Inst_Mem is 
	port (
		clk, rst, Pause_IF, Branch_Exec, Branch_ID: in std_logic;
		Branch_Addr_Exec, Branch_Addr_ID: in std_logic_vector(15 downto 0);
		Inst_out, Inst_address, Inc_Address: out std_logic_vector(15 downto 0)
	); 
end entity Inst_Mem;

architecture bhv of Inst_Mem is

	type mem is array(63 downto 0) of std_logic_vector(15 downto 0);
	signal Instruction_memory: mem := (others => "0000000000000000");
	signal PC, Inc_PC, next_PC: std_logic_vector(15 downto 0);

	component PC_Inc is
	port(
		PC: in std_logic_vector(15 downto 0);
		Output: out std_logic_vector(15 downto 0)
	);
	end component;

	file file_Instructs: text;

begin

	process(clk)
		variable v_ILINE: line;
		variable Instruct: std_logic_vector(15 downto 0);
	begin
		if(rst = '1') then
			Instruction_memory(0) <= "0011010000000000";
			Instruction_memory(1) <= "0011011000000000";
			Instruction_memory(2) <= "0011100000000000";
			Instruction_memory(3) <= "0011111000000100";
			Instruction_memory(4) <= "0011110000000111";
			Instruction_memory(5) <= "0011001000000000";
			Instruction_memory(6) <= "0010110111101000";
			Instruction_memory(7) <= "0001010010010000";
			Instruction_memory(8) <= "0011110000001100";
			Instruction_memory(9) <= "0001111110110001";
			Instruction_memory(10)<= "0111001011111111";
			Instruction_memory(11)<= "1110000000000000";
		elsif(rising_edge(clk) and (Pause_IF = '0' or Branch_ID = '1' or Branch_Exec = '1')) then
			PC <= next_PC;
		end if;
	end process;

	Inc_instance: PC_Inc port map(
		PC => PC , Output => Inc_PC
	);

	next_PC <=	Branch_Addr_Exec when Branch_Exec = '1' else
				Branch_Addr_ID when Branch_ID = '1' else
				Inc_PC;

	Inst_out <= Instruction_memory(to_integer(unsigned(PC(6 downto 1))));
	Inst_address <= PC;
	Inc_Address <= Inc_PC;
end bhv;