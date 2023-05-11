import sys
import numpy as np

def to_bin(n, len):
	ans = ""
#	print(n)
	if(n < 0):
		N = 1
		for j in range(len):
			N*=2
		
		n += N

	for i in range(len):
		ans = ('1' if (n%2) else '0') + ans
		n //= 2

#	print(ans)
	return ans

def Input_and_Store(Instructions):

	code = open("code.txt", 'r')
	StarterFile = open("Ins_begin.txt", 'r')
	TestFiles = open("..\Inst_mem.vhdl", 'w')

	for line in StarterFile:
		TestFiles.write(line)
	StarterFile.close()

	opcode =""
	output_string =""
	imm = 0
	k = 0

	for R in code:
		if (R == ""):
			continue

		Instructions.append(R)
		Ins = R.split()
		#print (Ins)
		opcode = Ins[0]

		if (opcode == "ADA" or opcode == "ADC" or opcode == "ADZ" or
			opcode == "AWC" or opcode == "ACA" or opcode == "ACC" or 
			opcode == "ACZ" or opcode == "ACW" or opcode == "NDU" or
			opcode == "NDC" or opcode == "NDZ" or opcode == "NCU" or
			opcode == "NCC" or opcode == "NCZ"):

			output_string = "0001" if (opcode[0] == 'A') else "0010"

			for i in range(3):
				Ins[i+1] = int(Ins[i+1][1])
				imm = Ins[i + 1]
				output_string += to_bin(imm, 3)

			output_string += "1" if (opcode[1] == 'C') else "0"

			if(opcode[2] == 'Z'):
				output_string += "01"
			elif(opcode[1] == 'W' or opcode[2] == 'W'):
				output_string += "11"
			elif(opcode[2] == 'A' or opcode[2] == 'U'):
				output_string += "00"
			else:
				output_string += "10"

		elif (opcode == "ADI" or opcode == "LW" or opcode == "BLE" or opcode == "SW" or opcode == "BEQ" or opcode == "BLT" or opcode == "JLR"):

			if(opcode[0] == 'A'):
				output_string = "0000"
			elif(opcode[0] == 'B'):
				output_string = "10"
				if(opcode[2] == 'Q'):
					output_string += "10"
				elif(opcode[2] == 'T'):
					output_string += "01"
				else:
					output_string += "00"
			elif(opcode[1] == 'W'):
				output_string = "010"
				output_string += '0' if (opcode[0]=='L') else '1'
			else:
				output_string = "1101"

			for i in range(2):
				Ins[i+1] = int(Ins[i+1][1])
				imm = Ins[i + 1]
				output_string += to_bin(imm, 3)

			if(opcode[0] == 'J'):
				output_string += "000000"
			else:
				Ins[3] = imm = int(Ins[3])
				output_string += to_bin(imm,6)

		elif (opcode == "LLI" or opcode == "SM" or
		opcode == "LM" or opcode == "JAL" or opcode == "JRI"):
		
			if(opcode[1] == 'M'):
				output_string = "011"
				output_string += '0' if (opcode[0]=='L') else '1'

			elif(opcode[0] == 'J'):
				output_string = "11"
				output_string += "11" if (opcode[1]=='R') else "00"
			
			else:
				output_string = "0011"

			imm = int(Ins[1][1])
			Ins[1] = imm
			output_string += to_bin(imm, 3)

			if(opcode[1] == 'M'):
				R = Ins[2]
				output_string += "0" + R
			
			else:
				Ins[2] = imm = int(Ins[2])
				output_string += to_bin(imm, 9)

		else:
			return opcode

		TestFiles.write("\t\t\tInstruction_memory(" + str(k) + ") <= \"" + output_string + "\";\n")
		k = k + 1
		Instructions.pop()
		Instructions.append(Ins)

	Instructions.append("END")
	TestFiles.write("\t\t\tInstruction_memory(" + str(k) + ") <= " + "\"1110000000000000\";\n")

	StarterFile = open("Ins_end.txt", 'r')
	for line in StarterFile:
		TestFiles.write(line)
	StarterFile.close()

	TestFiles.close()
	code.close()

	return "ADC"

Instructions = []
out = Input_and_Store(Instructions)

if(out != "ADC"):

	print("The following symbol is not recognized: " + out)
	sys.exit(1)

Curr_Ins = 0
registers = np.zeros(8, dtype = np.int16)
Data_mem = np.zeros(64, dtype = np.int16)

#Dirty bits for Data Mem
Data_mem_mod = np.zeros(64, dtype = bool)

C = 0
Z = 0
#ideally these start with not known values

FLAG = 0
#programmer's model
while(Instructions[Curr_Ins][0] != "END"):
	Ins = Instructions[Curr_Ins]
	opcode = Ins[0]
	FLAG = 0

	if (opcode == "ADA"):
		registers[Ins[3]] = registers[Ins[2]] + registers[Ins[1]]
		res = registers[Ins[3]]
		Opr1 = registers[Ins[2]]
		Opr2 = registers[Ins[1]]
		
		C = 1 if((Opr1 > 0 and Opr2 > 0 and res < 0) or (Opr1 < 0 and Opr2 < 0) or (((Opr1 <0) ^ (Opr2 <0)) and res>0)) else 0
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if (opcode == "ADC" and C == 1):
		registers[Ins[3]] = registers[Ins[2]] + registers[Ins[1]]
		res = registers[Ins[3]]
		Opr1 = registers[Ins[2]]
		Opr2 = registers[Ins[1]]
		
		C = 1 if((Opr1 > 0 and Opr2 > 0 and res < 0) or (Opr1 < 0 and Opr2 < 0) or (((Opr1 <0) ^ (Opr2 <0)) and res>0)) else 0
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if (opcode == "ADZ" and Z == 1):
		registers[Ins[3]] = registers[Ins[2]] + registers[Ins[1]]
		res = registers[Ins[3]]
		Opr1 = registers[Ins[2]]
		Opr2 = registers[Ins[1]]
		
		C = 1 if((Opr1 > 0 and Opr2 > 0 and res < 0) or (Opr1 < 0 and Opr2 < 0) or (((Opr1 <0) ^ (Opr2 <0)) and res>0)) else 0
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if (opcode == "AWC"):
		registers[Ins[3]] = registers[Ins[2]] + registers[Ins[1]] + C
		res = registers[Ins[3]]
		Opr1 = registers[Ins[2]]
		Opr2 = registers[Ins[1]]
		
		C = 1 if((Opr1 > 0 and Opr2 > 0 and res < 0) or (Opr1 < 0 and Opr2 < 0) or (((Opr1 <0) ^ (Opr2 <0)) and res>0)) else 0
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if (opcode == "ACA"):
		registers[Ins[3]] = (~registers[Ins[2]]) + registers[Ins[1]]
		res = registers[Ins[3]]
		Opr1 = (~registers[Ins[2]])
		Opr2 = registers[Ins[1]]
		
		C = 1 if((Opr1 > 0 and Opr2 > 0 and res < 0) or (Opr1 < 0 and Opr2 < 0) or (((Opr1 <0) ^ (Opr2 <0)) and res>0)) else 0
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if (opcode == "ACC" and C == 1):
		registers[Ins[3]] = (~registers[Ins[2]]) + registers[Ins[1]]
		res = registers[Ins[3]]
		Opr1 = (~registers[Ins[2]])
		Opr2 = registers[Ins[1]]
		
		C = 1 if((Opr1 > 0 and Opr2 > 0 and res < 0) or (Opr1 < 0 and Opr2 < 0) or (((Opr1 <0) ^ (Opr2 <0)) and res>0)) else 0
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if (opcode == "ACZ" and Z == 1):
		registers[Ins[3]] = (~registers[Ins[2]]) + registers[Ins[1]]
		res = registers[Ins[3]]
		Opr1 = (~registers[Ins[2]])
		Opr2 = registers[Ins[1]]
		
		C = 1 if((Opr1 > 0 and Opr2 > 0 and res < 0) or (Opr1 < 0 and Opr2 < 0) or (((Opr1 <0) ^ (Opr2 <0)) and res>0)) else 0
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if (opcode == "ACW"):
		registers[Ins[3]] = (~registers[Ins[2]]) + registers[Ins[1]] + C
		res = registers[Ins[3]]
		Opr1 = (~registers[Ins[2]])
		Opr2 = registers[Ins[1]]
		
		C = 1 if((Opr1 > 0 and Opr2 > 0 and res < 0) or (Opr1 < 0 and Opr2 < 0) or (((Opr1 <0) ^ (Opr2 <0)) and res>0)) else 0
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1
	
	if (opcode == "ADI"):
		registers[Ins[2]] = registers[Ins[1]] + Ins[3]
		res = registers[Ins[3]]
		Opr1 = registers[Ins[2]]
		Opr2 = Ins[3]
		
		C = 1 if((Opr1 > 0 and Opr2 > 0 and res < 0) or (Opr1 < 0 and Opr2 < 0) or (((Opr1 <0) ^ (Opr2 <0)) and res>0)) else 0
		if(registers[Ins[2]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[2] == 0):
			FLAG = 1

	if (opcode == "NDU"):
		registers[Ins[3]] = ~(registers[Ins[2]] & registers[Ins[1]])
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if (opcode == "NDC" and C == 1):
		registers[Ins[3]] = ~(registers[Ins[2]] & registers[Ins[1]])
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if (opcode == "NDZ" and Z == 1):
		registers[Ins[3]] = ~(registers[Ins[2]] & registers[Ins[1]])
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if (opcode == "NCU"):
		registers[Ins[3]] = ~((~registers[Ins[2]]) & registers[Ins[1]])
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if (opcode == "NCC" and C == 1):
		registers[Ins[3]] = ~((~registers[Ins[2]]) & registers[Ins[1]])
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if (opcode == "NCZ" and Z == 1):
		registers[Ins[3]] = ~((~registers[Ins[2]]) & registers[Ins[1]])
		if(registers[Ins[3]] == 0):
			Z = 1
		else:
			Z = 0
		if(Ins[3] == 0):
			FLAG = 1

	if(opcode == "LLI"):
		Ins[2] = Ins[2] & ((1 << 9) - 1)
		registers[Ins[1]] = Ins[2]
		if(Ins[1] == 0):
			FLAG = 1
	
	if(opcode == "LW"):
		address = ((registers[Ins[2]] + Ins[3])//2) & ((1<<6) - 1)
		registers[Ins[1]] = Data_mem[address]
		if(Ins[1] == 0):
			FLAG = 1

	if(opcode == "SW"):
		address = ((registers[Ins[2]] + Ins[3])//2) & ((1<<6) - 1)
		Data_mem[address] = registers[Ins[1]]
		Data_mem_mod[address] = True

	if(opcode == "LM"):
		address = (registers[Ins[1]]//2) & ((1<<6) - 1)
		for i in range(8):
			if(Ins[2][7-i] == '1'):
				registers[7-i] = Data_mem[address]
				address += 1
				address %= 64
		FLAG = 1 if(Ins[2][0] == '1') else 0

	if(opcode == "SM"):
		address = (registers[Ins[1]]//2) & ((1<<6) - 1)
		
		for i in range(8):
			if(Ins[2][7-i] == '1'):
				Data_mem[address] = registers[7-i]
				Data_mem_mod[address] = True
				address += 1
				address %= 64
	
	if(opcode == "BEQ"):
		if(registers[Ins[1]] == registers[Ins[2]]):
			FLAG = 1
			registers[0] += Ins[3]*2
	
	if(opcode == "BLT"):
		if(registers[Ins[1]] < registers[Ins[2]]):
			FLAG = 1
			registers[0] += Ins[3]*2

	if(opcode == "BLE"):
		if(registers[Ins[1]] <= registers[Ins[2]]):
			FLAG = 1
			registers[0] += Ins[3]*2

	if(opcode == "JAL"):
		registers[Ins[1]] = 2*Curr_Ins + 2
		registers[0] += Ins[2]*2
		FLAG = 1

	if(opcode == "JLR"):
		registers[0] = registers[Ins[2]]
		registers[Ins[1]] = 2*Curr_Ins + 2
		FLAG = 1

	if(opcode == "JRI"):
		registers[0] = registers[Ins[1]] + Ins[2]*2
		FLAG = 1

	if(opcode == 'E'):
		break

	if(FLAG == 0):
		registers[0] += 2

	Curr_Ins = (registers[0]//2) & ((1<<6) - 1)

TestFiles = open("Expected_out.txt", 'w')
for i in range(64):
	if(Data_mem_mod[i] == False):
		TestFiles.write("----------------\n")
	else:
		TestFiles.write(to_bin(Data_mem[i], 16) + '\n')

TestFiles.close()