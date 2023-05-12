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
	signal PC, Inc_PC, next_PC, Inc_input, Inc_output, Pc_Inst, Inc_Inst: std_logic_vector(15 downto 0);

	component Increment is
	port(
		Input: in std_logic_vector(15 downto 0);
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
			Instruction_memory(0) <= "1110000000000000";
		elsif(rising_edge(clk) and (Pause_IF = '0' or Branch_ID = '1' or Branch_Exec = '1')) then
			PC <= next_PC;
		end if;
	end process;
	
	Inc_input(14 downto 0) <= PC(15 downto 1);
	Inc_input(15) <= '0';
	Inc_instance: Increment port map(
		Input => Inc_input , Output => Inc_output
	);
	Inc_PC(15 downto 1) <= Inc_output(14 downto 0);
	Inc_PC(0) <= PC(0);

	next_PC <=	Branch_Addr_Exec when Branch_Exec = '1' else
				Branch_Addr_ID when Branch_ID = '1' else
				Inc_PC;

	Pc_Inst <= Instruction_memory(to_integer(unsigned(PC(6 downto 1))));
	Inc_Inst <= Instruction_memory(to_integer(unsigned(Inc_output(5 downto 0))));

	Inst_out(15 downto 8) <=Pc_Inst(15 downto 8) when PC(0) = '0' else
							Pc_Inst(7 downto 0);
	Inst_out(7 downto 0) <= Pc_Inst(7 downto 0) when PC(0) = '0' else
							Inc_Inst(15 downto 8);

	Inst_address <= PC;
	Inc_Address <= Inc_PC;
end bhv;