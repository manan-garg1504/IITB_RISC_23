library ieee;
use ieee.std_logic_1164.all;

--Load Immediate hag raha hai MC

entity CPU is
	port(rst, clk : in std_logic;
		 Port1, Port2 : out std_logic_vector(15 downto 0));
end entity CPU;

architecture bhv of CPU is

	--signal declaration
	signal Inst_address, Inst_out, Inc_Address: std_logic_vector(15 downto 0);
	signal R0_Val, Extra_Opr_Dec, WB_PC, RF_PC, Exec_PC: std_logic_vector(15 downto 0);
	signal Branch_Addr_Exec, Branch_Addr_ID: std_logic_vector(15 downto 0);
	signal Branch, Comp_B, Use_Extra, mem_store_en: std_logic;
	signal RF_Write_Addr_Dec, OprA_addr_Dec, OprB_addr_Dec: std_logic_vector(2 downto 0);
	signal Ins_type_Dec, Ins_type_RF: std_logic_vector(3 downto 0);
	signal WB_addr, RF_Write_Addr_Exec, RF_Write_Addr_RF, RF_Write_Addr_to_Mem: std_logic_vector(2 downto 0);
	signal OprA, OprB, Extra_Opr_RF: std_logic_vector(15 downto 0);
	signal Exec_DataOut, DataMemAddr, WB_Data: std_logic_vector(15 downto 0);
	signal RF_write_en_Exec, WB_en, Pause_IF, Pause_RF, Load_Branch: std_logic;

	signal Branch_Exec, Branch_ID, Mult: std_logic;
	signal end_proc_Dec, end_proc_RF, end_proc_Exec: std_logic;
	-- components declaration
	component Inst_Mem is
	port (
		clk, rst, Pause_IF, Branch_Exec, Branch_ID: in std_logic;
		Branch_Addr_Exec, Branch_Addr_ID: in std_logic_vector(15 downto 0);
		Inst_out, Inst_address, Inc_Address: out std_logic_vector(15 downto 0)
	); 
	end component;

	component Ins_decode is
	port(
		clk, rst, Branch_Exec: in std_logic;
		next_Instruction, next_Address, nextInc_Address: in std_logic_vector(15 downto 0);
		RF_Write_Addr, OprA_addr, OprB_addr: out std_logic_vector(2 downto 0);
		Ins_type_out: out std_logic_vector(3 downto 0);
		R0_Val, Branch_Address, Extra_Operand: out std_logic_vector(15 downto 0);
		Complement_OprB, Use_Extra, Pause_IF, Pause_RF, end_proc, Branch_out, Mult_out: out std_logic
	);
	end component;

	component RegisterFile is
	port(
		next_Ins_type: in std_logic_vector(3 downto 0);
		next_OprA_Addr, next_OprB_Addr, next_WB_Addr, next_OprC_Addr, Execute_addr: in std_logic_vector(2 downto 0);
		next_PC, WB_Data_next, Extra_Operand_next, Execute_out, WB_PC: in std_logic_vector(15 downto 0);
		clk, end_proc_in, WB_en_next, next_Complement_OprB, Use_Extra_next, Mult_next, Pause_RF: in std_logic;
		Operand_A, Operand_B, Extra_Opr, PC_out: out std_logic_vector(15 downto 0);
		OprC_addr: out std_logic_vector(2 downto 0);
		Ins_type_out: out std_logic_vector(3 downto 0);
		end_proc_out: out std_logic
	);
	end component;

	component Execute_stage is
	port(
		rst, clk, Load_Branch, end_proc_in: in std_logic;
		next_Ins_type: in std_logic_vector(3 downto 0);
		next_Reg_addr_in: in std_logic_vector(2 downto 0);
		next_Opr_A, next_Opr_B, next_Extra_Opr, Mem_out, PC_in: in std_logic_vector(15 downto 0);
		Data_out, Branch_PC, Mem_Addr, PC_out: out std_logic_vector(15 downto 0);
		Reg_addr_out, Reg_addr_Forward: out std_logic_vector (2 downto 0);
		mem_store_en_out, RF_Write_en_out, Branch_out, end_proc_out: out std_logic
	);
	end component;

	component Data_Mem is 
	port(
		clk, Next_mem_store_en, Next_RF_store_en, end_proc: in std_logic; 
		Next_Addr_in, Next_Data_in, PC_in: in std_logic_vector(15 downto 0);
		Next_Reg_addr: in std_logic_vector(2 downto 0);
		RF_Data_out, WB_PC, Port1: out std_logic_vector(15 downto 0);
		Reg_addr_out: out std_logic_vector (2 downto 0);
		RF_store_en, Load_Branch: out std_logic
	); 
	end component;
begin

	Instructions: Inst_Mem port map(
		clk => clk, rst => rst, Pause_IF => Pause_IF, Branch_Exec => Branch_Exec,
		Branch_ID => Branch_ID, Branch_Addr_Exec => Branch_Addr_Exec, Branch_Addr_ID => Branch_Addr_ID,
		Inst_out => Inst_out, Inst_address => Inst_address, Inc_Address => Inc_Address
	); 

	Decoder: Ins_decode port map(
		clk => clk, rst => rst, Branch_Exec => Branch_Exec, next_Instruction => Inst_out,
		next_Address => Inst_address, nextInc_Address => Inc_Address, RF_Write_Addr => RF_Write_Addr_Dec,
		OprA_addr => OprA_addr_Dec, OprB_addr => OprB_addr_Dec, Ins_type_out => Ins_type_Dec,
		R0_Val => R0_Val, Branch_Address => Branch_Addr_ID, Extra_Operand => Extra_Opr_Dec,
		Complement_OprB => Comp_B, Use_Extra => Use_Extra, Pause_IF => Pause_IF,
		Pause_RF => Pause_RF, end_proc => end_proc_Dec, Branch_out => Branch_ID, Mult_out => Mult
	);

	RF: RegisterFile port map(
		next_Ins_type => Ins_type_Dec, next_OprA_Addr => OprA_addr_Dec, next_OprB_Addr => OprB_addr_Dec,
		next_WB_Addr => WB_addr, next_OprC_Addr => RF_Write_Addr_Dec, Execute_addr => RF_Write_Addr_Exec,
		next_PC => R0_Val, WB_Data_next => WB_Data, Extra_Operand_next => Extra_Opr_Dec,
		Execute_out => Exec_DataOut, WB_PC => WB_PC, clk => clk, end_proc_in => end_proc_Dec,
		WB_en_next => WB_en, next_Complement_OprB => Comp_B, Use_Extra_next => Use_Extra,
		Mult_next => Mult, Pause_RF => Pause_RF, Operand_A => OprA, Operand_B => OprB,
		Extra_Opr => Extra_Opr_RF, PC_out => RF_PC, OprC_addr => RF_Write_Addr_RF,
		Ins_type_out => Ins_type_RF, end_proc_out => end_proc_RF
	);

	Exec: Execute_stage	port map(
		rst => rst, clk => clk, Load_Branch => Load_Branch, end_proc_in => end_proc_RF,
		next_Ins_type => Ins_type_RF, next_Reg_addr_in => RF_Write_Addr_RF,
		next_Opr_A => OprA, next_Opr_B => OprB, next_Extra_Opr => Extra_Opr_RF,
		Mem_out => WB_Data, PC_in => RF_PC, Data_out => Exec_DataOut, Branch_PC => Branch_Addr_Exec,
		Mem_Addr => DataMemAddr, PC_out => Exec_PC, Reg_addr_out => RF_Write_Addr_to_Mem,
		Reg_addr_Forward => RF_Write_Addr_Exec, mem_store_en_out => mem_store_en,
		RF_Write_en_out => RF_write_en_Exec, Branch_out => Branch_Exec, end_proc_out=> end_proc_Exec
	);

	Data: Data_Mem port map(
		clk => clk, Next_mem_store_en => mem_store_en, Next_RF_store_en => RF_write_en_Exec,
		end_proc => end_proc_Exec, Next_Addr_in => DataMemAddr, Next_Data_in => Exec_DataOut,
		PC_in => Exec_PC, Next_Reg_addr => RF_Write_Addr_to_Mem, WB_PC => WB_PC, Port1 => Port1,
		RF_Data_out => WB_Data, Reg_addr_out => WB_addr, RF_store_en => WB_en, Load_Branch => Load_Branch
	); 
end bhv;