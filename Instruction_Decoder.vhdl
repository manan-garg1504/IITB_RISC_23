library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--Just the entire stopping and conitinuing part once

entity Ins_decode is
	port(
		clk, rst, Branch_Exec: in std_logic;
		next_Instruction, next_Address, nextInc_Address: in std_logic_vector(15 downto 0);
		RF_Write_Addr, OprA_addr, OprB_addr: out std_logic_vector(2 downto 0);
		Ins_type_out: out std_logic_vector(3 downto 0);
		R0_Val, Branch_Address, Extra_Operand: out std_logic_vector(15 downto 0);
		Complement_OprB, Use_Extra, Pause_IF, Pause_RF, end_proc, Branch_out, Mult_out: out std_logic
	);
end Ins_decode;

architecture arch of Ins_decode is

	component Dec_Mult is
	port(
		clk, Mult: std_logic;
		Input_Imm: in std_logic_vector(7 downto 0);
		Bin_Imm : out std_logic_vector(2 downto 0);
		Reg_addr_mult: out std_logic_vector (2 downto 0);
		Next_Imm: out std_logic_vector(7 downto 0)
	);
	end component;

	component Branch_Calc is
	port(
		PC: in std_logic_vector(15 downto 0);
		Immediate: in std_logic_vector(15 downto 1);
		Result: out std_logic_vector(15 downto 0)
	);
	end component;

	signal Mult_addr, Mult_Reg_Addr, OprA, OprB, OprC, prev_OprC: std_logic_vector(2 downto 0);
	signal Ins_type: std_logic_vector(3 downto 0);
	signal Instruction, Address, Inc_Address, Branch_Addr, Extra_Opr, Imm_6, Imm_9: std_logic_vector(15 downto 0);
	signal Branch_Imm: std_logic_vector(14 downto 0);
	signal Load_Store, Bees, ALU_Ins, Jays, ADI, JAL, LLI, JRI, Starter, Multiple, Lower_Zero, Lower_One, Nines_extend, Load, Branch_cont: std_logic;
	signal stopped, Stop_next, Mult_done, Pause_Pipe, prev_Load, Store, Branch_Exec2, Pause_Pipe_Load, Pause_Pipe_Mult, prevLoadPause: std_logic;
	signal Next_Imm: std_logic_vector(7 downto 0);
	signal Mult_Imm: std_logic_vector(15 downto 1);

begin

	process(clk)
	begin
		if(rst = '1') then
			Instruction <= "0000000000000000";
		elsif(rising_edge(clk)) then
			if(Pause_Pipe = '0' and Stop_next = '0') then
				Instruction <= next_Instruction;
				Address <= next_Address;
				Inc_Address <= nextInc_Address;
			elsif(Pause_Pipe_Mult = '1') then
				Instruction(7 downto 0) <= Next_Imm;
				Address <= Address;
				Inc_Address <= nextInc_Address;
				Instruction(15 downto 8) <= Instruction(15 downto 8);
			end if;
			Branch_Exec2 <= Branch_Exec;
			stopped <= Stop_next;
			prev_Load <= Load;
			prev_OprC <= OprC;
			prevLoadPause <= Pause_Pipe_Load;
		end if;
	end process;

	Bees <= Instruction(15) and not Instruction(14);
	Load_Store <= not Instruction(15) and Instruction(14);
	Multiple <= Load_Store and Instruction(13);
	Starter <= (Instruction(15) nor Instruction(14));
	Lower_Zero <= (Instruction(13) nor Instruction(12));
	Lower_One <= Instruction(13) and Instruction(12);
	ADI <= Starter and Lower_Zero;
	ALU_Ins <= Starter and (Instruction(13) xor Instruction(12));
	LLI <= Starter and Lower_One;
	Jays <= Instruction(15) and Instruction(14);
	JRI <= Jays and Instruction(13);
	JAL <= Jays and Lower_Zero;
	Store <= Load_Store and Instruction(12);
	Load <= Load_Store and not Instruction(12);
	Branch_cont <= Branch_Exec or Branch_Exec2;

	Mult_instance: Dec_Mult port map(
		clk => clk, Mult => Multiple,
		Input_Imm => Instruction(7 downto 0),
		Bin_Imm => Mult_addr,
		Reg_addr_mult => Mult_Reg_Addr,
		Next_Imm => Next_Imm
	);

	Mult_done <= '1' when Next_Imm = "00000000" else '0';

	Imm_6(4 downto 0)<=	Instruction(4 downto 0);
	Extend_6: for i in 5 to 15 generate
		Imm_6(i) <= Instruction(5);
	end generate;

	Imm_9(8 downto 0) <= Instruction(8 downto 0);
	Nines_extend <= not LLI and Instruction(8);
	Extend_9: for i in 9 to 15 generate
		Imm_9(i) <= Nines_extend;
	end generate;

	Branch_Imm<=Imm_6(14 downto 0) when Bees = '1' else
				Imm_9(14 downto 0);
	Branch_Instance: Branch_Calc port map(
		PC => Address, Immediate => Branch_Imm, 
		Result => Branch_Addr
	);

	Mult_Imm(3 downto 1) <= Mult_addr;
	Mult_Imm(15 downto 4) <= "000000000000";

	Stop_next<='0' when stopped = '1' else
				JAL;

	OprC <= Mult_Reg_Addr when (Multiple = '1') else
			Instruction(5 downto 3) when ALU_Ins = '1' else
			Instruction(8 downto 6) when ADI = '1' else
			Instruction(11 downto 9);

	OprA <= Instruction(8 downto 6) when Load_Store = '1' and Instruction(13) = '0'  else
			Instruction(11 downto 9);
	OprB <= Mult_Reg_Addr when Load_Store = '1' and Lower_One = '1' else
			Instruction(11 downto 9) when Load_Store = '1' else
			Instruction(8 downto 6);

	Ins_type(3) <=	not Starter or Lower_One;
	Ins_type(2) <=	'1' when ADI = '1' or LLI = '1' else
					'0' when JRI = '1' else
					Instruction(12) when ALU_Ins = '1' else
					Instruction(14);

	Ins_type(1) <=	Instruction(1) when ALU_Ins = '1' else
					'1' when Jays = '1' else
					'0' when Multiple = '1' else
					Instruction(13);

	Ins_type(0) <=	Instruction(0) when ALU_Ins ='1' else
					'0' when LLI = '1' else
					Instruction(12);

	Complement_OprB <= (ALU_Ins and Instruction(2)) or (Bees);

	Pause_Pipe_Mult <= Multiple and (Mult_done nor Branch_cont);
	Pause_Pipe_Load <= '1' when ((Branch_cont = '0') and (prevLoadPause = '0') and (prev_Load = '1') and ((OprA = prev_OprC) or (OprB = prev_OprC) or (prev_OprC = "000"))) else '0';
	Pause_Pipe <= Pause_Pipe_Load or Pause_Pipe_Mult;

	R0_Val <= Address;
	Use_Extra <= ALU_Ins nor Bees;

	--Branch Address calculation could be only 15 bit
	--See if these Muxes can be optimized
	Extra_Operand(0) <=	Imm_9(0) when LLI = '1' else
						'0' when Multiple = '1' or JRI = '1' else
						Branch_Addr(0) when Bees = '1' else
						Inc_Address(0) when Jays = '1' else
						Imm_6(0);

	Extra_Operand(15 downto 1)<=Imm_9(15 downto 1) when LLI = '1' else
								Mult_Imm(15 downto 1) when Multiple = '1' else
								Branch_Addr(15 downto 1) when Bees = '1' else
								Imm_9(14 downto 0) when JRI = '1' else
								Inc_Address(15 downto 1) when Jays = '1' else
								Imm_6(15 downto 1);

	Branch_Address <= Branch_Addr;
	Branch_out <= Stop_next;

	Ins_type_out <= Ins_type;
	Pause_IF <= Pause_Pipe;
	Pause_RF <= Pause_Pipe_Load;

	end_proc <= '1' when Instruction(15 downto 12) = "1110" else '0';
	Mult_out <= Pause_Pipe_Mult;

	OprA_addr <= OprA;
	OprB_addr <= OprB;
	RF_Write_Addr <= OprC;
end arch;