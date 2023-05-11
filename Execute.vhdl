library ieee;
use ieee.std_logic_1164.all;
--BEQ: 1010
--BLT: 1001
--BLE: 1000

entity Execute_stage is
	port(
		rst, clk, Load_Branch, end_proc_in: in std_logic;
		next_Ins_type: in std_logic_vector(3 downto 0);
		next_Reg_addr_in: in std_logic_vector(2 downto 0);
		next_Opr_A, next_Opr_B, next_Extra_Opr, Mem_out, PC_in: in std_logic_vector(15 downto 0);
		Data_out, Branch_PC, Mem_Addr, PC_out: out std_logic_vector(15 downto 0);
		Reg_addr_out, Reg_addr_Forward: out std_logic_vector (2 downto 0);
		mem_store_en_out, RF_Write_en_out, Branch_out, end_proc_out: out std_logic
	);
end entity Execute_stage;

architecture bhv of Execute_stage is

	component ALU is
	port(
		Input_1, Input_2: in std_logic_vector(15 downto 0);
		Nand_ins, Extra_bit: in std_logic;
		--Extra bit adds 1 to Input_2 in addition path
		Output: out std_logic_vector(15 downto 0);
		C,Z: out std_logic
	);
	end component;

	component Comparator is
		port(
			Input_1, Input_2: in std_logic_vector(15 downto 0);
			Input2_IsLess, Equal: out std_logic
		);
	end component;

	signal C_out, Z_out, C, Z, Allow_Branch, Branch, Branch_Ins, Write_condition, RF_Write_en, Write_result: std_logic;
	signal Nand_ins, Carry_ALU, Ones, R0_write, A_IsLess, Compare_success, Extra_Ins, mem_store_en: std_logic;
	signal Final_Data, ALU_Out, Operand_A, Operand_B, Extra_Opr: std_logic_vector(15 downto 0);
	signal out_reg_addr: std_logic_vector(2 downto 0);
	signal Ins_type: std_logic_vector(3 downto 0);
	signal Branch_counter: std_logic_vector(1 downto 0);

begin

	process(clk)
	begin
	if(rst = '1') then
		Ins_type <= "1110";
		Branch_counter (1) <= '0';
		Extra_Opr <= "0000000000000000";
		out_reg_addr <= "000";
		end_proc_out <= '0';
		C <= '0';
		Z <= '0';
	else
		if(rising_edge(clk) and ((Branch = '0') or (Branch_counter = "10"))) then
			Ins_type <= next_Ins_type;
			Operand_A <= next_Opr_A;
			Operand_B <= next_Opr_B;
			Extra_Opr <= next_Extra_Opr;
			out_reg_addr <= next_Reg_addr_in;
			end_proc_out <= end_proc_in;
			PC_out <= PC_in;
		end if;

		if(rising_edge(clk) and Ins_type(3) = '0' and Write_condition = '1') then
			Z <= Z_out;
		end if;

		if(rising_edge(clk) and Ins_type(3 downto 2) = "01" and Write_condition = '1') then
			C <= C_out;
		end if;

		if(rising_edge(clk) and Branch = '1') then
			Branch_counter(1) <= not Branch_counter(1);
		end if;
	end if;
	end process;

	process(Branch_counter(1), rst)
	begin
		if(rst = '1') then
			Branch_counter(0) <= '0';
		elsif(rising_edge(Branch_counter(1))) then
			Branch_counter(0) <= not Branch_counter(0);
		end if;
	end process;

	Nand_ins <= Ins_type(3) nor Ins_type(2);
	Ones <= Ins_type(1) and Ins_type(0);
	Branch_Ins <= Ins_type(3) and not Ins_type(2);
	Allow_Branch <= Branch_counter(1) nor Branch_counter(0);
	Extra_Ins <= Ins_type(3) and Ins_type(2);

	Carry_ALU<=	'1' when ((Ins_type(3 downto 2) = "01" and Ones = '1' and C = '1') or (Branch_Ins='1' and Ones = '0')) else
				'0';

	ALU_instance: ALU port map(
		Input_1 => Operand_A, Input_2 => Operand_B,
		Nand_ins => Nand_ins, Extra_bit => Carry_ALU,
		Output => ALU_Out, C => C_out, Z => Z_out
	);

	mem_store_en <=	Extra_Ins and not Ins_type(1);

	Write_condition <= (Ins_type(1) xnor Ins_type(0)) or ((Ins_type(0) and Z) or (Ins_type(1) and C));

	RF_Write_en <=	not Ins_type(0) when mem_store_en = '1' else
					'1' when Extra_Ins = '1' and Ins_type(1) ='1' else
					not Ins_type(3) and Write_condition;

	Write_result <= not mem_store_en and RF_Write_en;
	A_IsLess <= ((Operand_A(15) xor Operand_B(15)) and not C_out) or (Operand_A(15) and Operand_B(15));

	Final_Data<=Extra_Opr when Ins_type(3) = '1' else
				ALU_Out;

	R0_write <=	'1' when out_reg_addr = "000" and RF_Write_en = '1' else
				'0';
	Compare_success <= (A_IsLess and not Ins_type(1) and not Z_out) or (Z_out and not Ins_type(0));
	Branch <= (R0_write and not mem_store_en) or (Load_Branch) or (Ins_type(3) and (Ones or (not Ins_type(2) and Compare_success)));

	Branch_out <= Allow_Branch and Branch;

	Branch_PC<=	Mem_out when Load_Branch = '1' else
				ALU_Out when (Branch_Ins = '1' and Ones = '1') else
				Final_Data;

	Data_out <= Final_Data;
	Mem_Addr <= ALU_Out;
	Reg_addr_out <= out_reg_addr;

	mem_store_en_out <= mem_store_en;
	RF_Write_en_out <= RF_Write_en;

	Reg_addr_Forward(0) <= Write_result and out_reg_addr(0);
	Reg_addr_Forward(1) <= Write_result and out_reg_addr(1);
	Reg_addr_Forward(2) <= Write_result and out_reg_addr(2);
end bhv;