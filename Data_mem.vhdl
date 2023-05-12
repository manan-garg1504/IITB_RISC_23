library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity Data_Mem is
	port(
		clk, Next_mem_store_en, Next_RF_store_en, end_proc, Cin, Zin: in std_logic; 
		Next_Addr_in, Next_Data_in, PC_in: in std_logic_vector(15 downto 0);
		Next_Reg_addr: in std_logic_vector(2 downto 0);
		RF_Data_out, WB_PC, Port1: out std_logic_vector(15 downto 0);
		Reg_addr_out: out std_logic_vector (2 downto 0);
		RF_store_en, Load_Branch, Cout, Zout: out std_logic
	); 
end entity Data_Mem;

architecture bhv of Data_Mem is

	type mem_arr is array(127 downto 0) of std_logic_vector(7 downto 0);
	signal Reg_addr: std_logic_vector (2 downto 0);
	signal memory_data: mem_arr;
	signal mem_en, RF_en, C, Z: std_logic;
	signal end_done, end_proc_use: std_logic:= '0';
	signal Data_in, mem_data_out, Mem_adr, Data_out, Inc_Mem_Adr: std_logic_vector(15 downto 0);

	function bin (lvec: in std_logic_vector) return string is
		variable text: string(8 downto 1) := (others => '9');
	begin
		for k in 8 downto 1 loop
			case lvec(k-1) is
				when '0' => text(k) := '0';
				when '1' => text(k) := '1';
				when others => text(k) := '-';
			end case;
		end loop;
		return text;
	end function;

	component Increment is
	port(
		Input: in std_logic_vector(15 downto 0);
		Output: out std_logic_vector(15 downto 0)
	);
	end component;

	file file_RESULTS : text; 
begin

	process(clk)
	begin
		if(rising_edge(clk)) then
			Data_in <= Next_Data_in;
			Mem_adr <= Next_Addr_in;
			mem_en <= Next_mem_store_en;
			end_proc_use <= end_proc;
			Cout <= C;
			C <= Cin;
			Zout <= Z;
			Z <= Zin;

			WB_PC <= PC_in;
			RF_en <= Next_RF_store_en;
			Reg_addr <= Next_Reg_addr;
		end if;
	end process;

	Inc_instance: Increment port map(
		Input => Mem_Adr , Output => Inc_Mem_Adr
	);

	mem_data_out(15 downto 8) <= memory_data(to_integer(unsigned(Mem_Adr(6 downto 0))));
	mem_data_out(7 downto 0) <= memory_data(to_integer(unsigned(Inc_Mem_Adr(6 downto 0))));

	RF_Data_out <=	mem_data_out when mem_en = '1' else
					Data_in;
	RF_store_en <= RF_en;
	
	Load_Branch <=	'1' when Reg_addr = "000" and RF_en = '1' and mem_en = '1' else
					'0';

	Reg_addr_out(0) <= Reg_addr(0) and RF_en;
	Reg_addr_out(1) <= Reg_addr(1) and RF_en;
	Reg_addr_out(2) <= Reg_addr(2) and RF_en;

	Port1(15 downto 8) <= memory_data(0);
	Port1(7 downto 0) <= memory_data(1);

	--Write Back
	process(clk)
	begin
		if(rising_edge(clk) and mem_en = '1' and RF_en = '0') then
			memory_data(to_integer(unsigned(Mem_adr(6 downto 0)))) <= Data_in(15 downto 8);
			memory_data(to_integer(unsigned(Inc_Mem_adr(6 downto 0)))) <= Data_in(7 downto 0);
		end if;
	end process;

	--tester
	file_open(file_RESULTS, "..\..\Testing\output.txt", write_mode);
	test_proc: process(end_proc_use)
		variable message: string(1 to 16);
		variable v_OLINE: line;
	begin
		if (rising_edge(end_proc_use) and end_done = '0') then
			repLoop: for i in 0 to 63 loop
				message(1 to 8) := bin(memory_data(2*i));
				message(9 to 16) := bin(memory_data(2*i + 1));
				write(v_OLINE, message);
				writeline(file_RESULTS, v_OLINE);
			end loop;

			end_done <= '1';
		end if;
	end process;
end bhv;
