import struct
import sys

# Read the program and input from the command line
program = ""
inputText = ""
if len(sys.argv) < 2:
	print("Error: Please specify a program to load")
else:
	program = open(sys.argv[1], "r").read()

if len(sys.argv) >= 3:
	inputText = sys.argv[2]

# Make sure the number and placement of loop commands is valid
depth = 0
for c in program:
	if c == '[':
		depth += 1
	elif c == ']':
		depth -= 1

	if depth < 0:
		print("Error: Unmatched ]")
		exit()
	elif depth > 255:
		print("Error: Exceeding max loop depth of 255")
		exit()

if depth > 0:
	print("Error: Unmatched [")
	exit()

# Remove the previously loaded program
romFile = open("armfuck.gba", "r+b")
romFile.truncate(0x82843C + 8)
romFile.close()

# Extract important addresses
romFile = open("armfuck.gba", "r+b")
romFile.seek((-12 * 4) - 8, 2)
inputStart = struct.unpack('<I', romFile.read(4))[0]
numberTable = struct.unpack('<I', romFile.read(4))[0]
numberSize = struct.unpack('<I', romFile.read(4))[0]
commandRight = struct.unpack('<I', romFile.read(4))[0]
commandLeft = struct.unpack('<I', romFile.read(4))[0]
commandInc = struct.unpack('<I', romFile.read(4))[0]
commandDec = struct.unpack('<I', romFile.read(4))[0]
commandOut = struct.unpack('<I', romFile.read(4))[0]
commandIn = struct.unpack('<I', romFile.read(4))[0]
commandOpen = struct.unpack('<I', romFile.read(4))[0]
commandClose = struct.unpack('<I', romFile.read(4))[0]
commandHalt = struct.unpack('<I', romFile.read(4))[0]

print("Program:\n" + program)
print("\nInput:\n" + inputText)
print("\nInput Buffer: " + hex(inputStart))
print("Number Table: " + hex(numberTable))
print("Number Size: " + str(numberSize))
print("> Handler: " + hex(commandRight))
print("< Handler: " + hex(commandLeft))
print("+ Handler: " + hex(commandInc))
print("- Handler: " + hex(commandDec))
print(". Handler: " + hex(commandOut))
print(", Handler: " + hex(commandIn))
print("[ Handler: " + hex(commandOpen))
print("] Handler: " + hex(commandClose))
print("Halt Handler: " + hex(commandHalt))

# Convert the input into a form the ROM can use
romFile.seek(inputStart - 0x8000000)
for c in inputText:
	romFile.write(struct.pack('<I', (ord(c) * numberSize) + numberTable + 4))
romFile.write(struct.pack('<I', numberTable + 4)) # Null terminator. Should this be EOF?

# Convert the brainfuck code into a form the ROM can use
romFile.seek(0, 2) # Go to end of file
for c in program:
	if c == '>':
		romFile.write(struct.pack('<I', commandRight))
	elif c == '<':
		romFile.write(struct.pack('<I', commandLeft))
	elif c == '+':
		romFile.write(struct.pack('<I', commandInc))
	elif c == '-':
		romFile.write(struct.pack('<I', commandDec))
	elif c == '.':
		romFile.write(struct.pack('<I', commandOut))
	elif c == ',':
		romFile.write(struct.pack('<I', commandIn))
	elif c == '[':
		depth += 1
		romFile.write(struct.pack('<I', commandOpen))
	elif c == ']':
		depth -= 1
		romFile.write(struct.pack('<I', commandClose))

# Mark the end of the program
romFile.write(struct.pack('<I', commandHalt))

romFile.close()
