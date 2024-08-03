# fasmarm likes to convert LDMs and STMs to LDRs and STRs when it can and there's no way to disable it.
# This script looks for any LDR/STR opcode in the rom and replaces them with the equivalent LDM/STM instruction
import sys

def unoptimize(file):
	pos = 0
	data = file.read(4)
	while data:
		opcode = (data[3] << 24) | (data[2] << 16) | (data[1] << 8) | data[0]
		if (data[3] & 0xFC) == 0xE4: # LDR/STR found
			# Create a new LDM/STM opcode
			newop = bytearray(4)
			newop[3] = 0xE8

			old_p = (opcode >> 24) & 1
			old_u = (opcode >> 23) & 1
			old_w = (opcode >> 21) & 1
			old_l = (opcode >> 20) & 1
			old_rn = (opcode >> 16) & 0xF
			old_rd = (opcode >> 12) & 0xF
			old_offset = (opcode >> 2) & 1

			new_p = old_p & old_offset
			new_u = old_u
			new_w = old_w | (~old_p & old_offset)
			new_l = old_l
			new_rn = old_rn
			new_reglist = 1 << old_rd

			newop[3] |= new_p
			newop[2] = (new_u << 7) | (new_w << 5) | (new_l << 4) | new_rn
			newop[1] = (new_reglist >> 8) & 0xFF
			newop[0] = new_reglist & 0xFF

			# Write new opcode to file
			file.seek(pos)
			file.write(newop)

			#print(hex(opcode) + " at " + hex(pos) + " replaced with " + hex(int(newop[3] << 24) | (newop[2] << 16) | (newop[1] << 8) | newop[0]))

		pos += 4
		data = file.read(4)

if __name__ == "__main__":
	if len(sys.argv) >= 2:
		file = open(sys.argv[1], "r+b")
		unoptimize(file)
		file.close()
	else:
		print("Error: Not enough arguments")
