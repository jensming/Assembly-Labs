##########################################################################
# Created by:  Ensminger, James
#              1725314
#              25 February 2021
#
# Assignment:  Lab 4: Syntax Checker
#              CSE 12, Computer Systems and Assembly Language
#              UC Santa Cruz, Winter 2021
# 
# Description: This program prints messages that programs often face when
#	       syntax error is present upon compiling them.
# 
# Notes:       This program is intended to be run from the MARS IDE.
##########################################################################
# Psuedocode
#
# main:
#	prints "You entered the file:\n"
#	takes filename input from program arguments
#	prints filename and new line
#	jumps to firstIndex, isValidFile, and lenCheck (spec check filename)
#	jump to openFile then jumps to readFile
#	jump to exitProgram
#	
# firstIndex:
#	checks if first char of filename is in between 'a' and 'z' or 'A' and 'Z'
#	if neither, branch to invalidArg
#	else return
#
# isValidFile:
#	checks if current char in filename is in between 'a' and 'z' or 'A' and 'Z' or '0' and '9' or is an '_' or '.'
#	if false, branch to invalidArg
#	else loop until char is null
#	
# lenChecker:
#	checks if length of filename is 20 chars or greater
#	if true, branch to invalidArg
#	else loop until char is null
#
# return:
#	jump register to return address
#
# openFile:
#	opens file using syscall 13
#	stores address of open file in registers
#
# readFile:
#	reads file using syscall 14
#	stores the first 128 bytes to buffer
#	if num of chars equals zero, jump to multBraces
#	else jump to stack
#
# pop:
#	sub 4 bytes from $sp
#	load char to register
#	decrement size of stack
#	return
#
# push:
#	add 4 bytes to $sp
#	save char to register
#	increment size of stack
#	increment brace pairs
#	jump to increment
#
# increment:
#	increment counter and index
#	jump to stack
#	
# stack:
#	if all chars checked in file, return to readFile
#	else if char is either '(', '[', or '{', jump to push
#	else jump to popChecker
#
# popChecker:
#	if char is either ')', ']', or '}', jump to popBrace
#	else jump to increment
#
# popBrace:
#	if stack size equals zero, jump to braceMismatch
#	else jump and link to pop
#	jump to increment
#
# success:
#	prints success message and number of matched brace pairs
#	jump to exitProgram
#
# multBraces:
#	if stack size equals zero, jump to success
#	else print multiple brace error message
#	jump to printBraces
#
# printBraces:
#	if stack size equals zero, jump to success
#	else load char of brace from buffer and print until stack is empty
#	jump to exitProgram when stack is empty
#
# braceMismatch:
#	prints brace mismatch error message along with the brace and index of it in the file
#	jump to exitProgram
#
# invalidArg:
#	prints invalid program arguments message
#	jump to exitProgram
#
# exitProgram:
#	prints new line
#	closes file
#	terminates program using syscall 10
##########################################################################
.data
	buffer: .space 128
	index: .word 0
	stackSize: .word 0
	bracePairs: .word 0

	prompt: .asciiz "You entered the file:\n"
	
	impropFile: .asciiz "\nERROR: Invalid program argument."		# Improper filename error message
	
	braceMismatch1: .asciiz "\nERROR - There is a brace mismatch: "		# Brace follows
	braceMismatch2: .asciiz " at index "					# Index where brace mismatch is follows
	
	bracesOnStack: .asciiz "\nERROR - Brace(s) still on stack: "		# Remaining braces on stack in reverse order follows
	
	mSuccess1: .asciiz "\nSUCCESS: There are " 				# Number of pairs of braces follows
	mSuccess2: .asciiz " pairs of braces."
	
	newLine: .asciiz "\n"
	
.text
	main:
		li $v0, 4
		la $a0, prompt
		syscall				# Prints file name entry message
		
		lw $s0, ($a1)			# Takes the filename input from program arguments
		
		move $t0, $s0
		jal firstIndex
		jal isValidFile
		move $t0, $s0
		jal lenCheck
		
		la $a0, ($s0)
		li $v0, 4
		syscall				# Prints file name entered
		
		li $v0, 4
		la $a0, newLine
		syscall				# Prints new line
		
		jal openFile
		j readFile
		
		j exitProgram
	
	#REGISTER USAGE
	# $t0: address of filename
	# $t1: first byte (char) of filename
	firstIndex:
		lb $t1, 0($t0)
		
		sgeu $t2, $t1, 97
		sleu $t3, $t1, 122
		and $t4, $t2, $t3		# Checks if first index of the filename is an ascii letter between 'a' and 'z'
		
		sgeu $t2, $t1, 65
		sleu $t3, $t1, 90
		and $t5, $t2, $t3		# Checks if first index of the filename is an ascii letter between 'A' and 'Z'
		
		or $t2, $t4, $t5
		NOP
		beq $t2, $0, invalidArg
		NOP
		
		jr $ra
	
	#REGISTER USAGE
	# $t0: address of filename
	# $t1: current byte (char) of filename
	isValidFile:
		lb $t1, 0($t0)
		
		NOP
		beq $t1, $0, return		# if $t1 = null, return to main
		NOP
		
		sgeu $t2, $t1, 97
		sleu $t3, $t1, 122
		and $t4, $t2, $t3		# Checks if current index of the filename is an ascii letter between 'a' and 'z'
		
		sgeu $t2, $t1, 65
		sleu $t3, $t1, 90
		and $t5, $t2, $t3		# Checks if current index of the filename is an ascii letter between 'A' and 'Z'
		
		sgeu $t2, $t1, 48
		sleu $t3, $t1, 57
		and $t6, $t2, $t3		# Checks if current index of the filename is an ascii integer between '0' and '9'
		
		seq $t7, $t1, 46		# Checks if current index of the filename is an ascii period '.'
		seq $t8, $t1, 95		# Checks if current index of the filename is an ascii underscore '_'
		
		or $t2, $t4, $t5
		or $t3, $t2, $t6
		or $t4, $t3, $t7
		or $t5, $t4, $t8
		
		NOP
		beq $t5, $0, invalidArg
		NOP
		
		addi $t0, $t0, 1		# Increments $t0 by 1 byte
		
		j isValidFile
		
	#REGISTER USAGE
	# $t0: address of filename
	# $t1: current byte (char) of filename
	# $t2: filename length counter
	lenCheck:
		li $t2, 0			# Filename length counter
		
	lenChecker:
		lb $t1, 0($t0)
		
		NOP
		beq $t1, $0, return		# if $t1 = null, return to main
		NOP
		
		NOP
		beq $t2, 20, invalidArg		# If the lenCheck counter reaches an index of 20, then the filename is invalid
		NOP
		
		addi $t0, $t0, 1		# Increments $t0 by 1 byte
		addi $t2, $t2, 1		# Increments $t2 by 1 integer (ex. i++)
		
		j lenChecker
		
	return:
		jr $ra				# Returns to last spot left off in main
				
	#REGISTER USAGE
	# $s0: address of filename
	openFile:
		li $v0, 13
		la $a0, ($s0)
		la $a1, 0
		la $a2, 0
		syscall				# Opens the file entered in program arguments
		
		move $s1, $v0			# Stores the address of the open file in registers
		
		jr $ra
	
	#REGISTER USAGE
	# $s1: address of opened file
	# $s2: size of opened file contents
	readFile:
		li $v0, 14
		la $a0, ($s1)
		la $a1, buffer
		li $a2, 128
		syscall				# Reads the open file entered in program arguments
		
		move $t0, $0			# Counter for buffer
		move $t9, $0			# Index initialized
		la $s2, ($v0)			# Sets size of file contents to $s2
		
		NOP
		beq $s2, $t0, multBraces
		NOP
		
		j stack
		
	#REGISTER USAGE
	# $t8: brace to pop off of stack
	# $s4: stackSize
	pop:	
		lw $t8, ($sp)			# $t8 is brace that pops off of stack
		addi $sp $sp 4
		
		lw $s4, stackSize
		addi $s4, $s4, -1		# Decrements the size of stack since stack since it doesn't grow upward
		sw $s4, stackSize
		
		jr $ra
	
	#REGISTER USAGE
	# $t8: brace to pop off of stack
	# $s4: stackSize
	push:
		addi $sp $sp -4
		sw $t8, ($sp)			# $t8 is brace to push onto stack
		
		lw $s4, stackSize
		addi $s4, $s4, 1		# Increments the size of stack by 1 since it grows downard
		sw $s4, stackSize
		
		lw $s5, bracePairs
		addi $s5, $s5, 1		# Increments brace pair counter by 1
		sw $s5, bracePairs
		
		j increment
	
	#REGISTER USAGE
	# $t9: index
	# $t0: counter
	increment:
		addi $t9, $t9, 1		# Increments the index by 1
		addi $t0, $t0, 1		# Increments the counter by 1
		
		j stack
	
	#REGISTER USAGE
	# $t0: counter
	# $t1: current byte (char) of buffer
	# $s2: size of opened file contents
	stack:
		NOP
		beq $s2, $t0, readFile
		NOP
		
		lb $t1, buffer($t0)
		
		seq $t2, $t1, 40		# Checks if current element of buffer is an ascii brace '('
		seq $t3, $t1, 91		# Checks if current element of buffer is an ascii brace '['
		seq $t4, $t1, 123		# Checks if current element of buffer is an ascii brace '{'
		
		or $t5, $t2, $t3
		or $t2, $t4, $t5
		
		NOP
		beq $t2, $0, popChecker
		NOP
		
		j push
	
	#REGISTER USAGE
	# $t1: current byte (char) of buffer
	popChecker:
		lb $t1, buffer($t0)
		
		seq $t2, $t1, 41		# Checks if current element of buffer is an ascii brace ')'
		seq $t3, $t1, 93		# Checks if current element of buffer is an ascii brace ']'
		seq $t4, $t1, 125		# Checks if current element of buffer is an ascii brace '}'
		
		or $t5, $t2, $t3
		or $t2, $t4, $t5
		
		NOP
		bnez $t2, popBrace
		NOP
		
		j increment
	
	#REGISTER USAGE
	# $t1: current byte (char) of buffer
	# $s4: size of stack
	popBrace:
		lw $s4, stackSize
		jal pop
		NOP
		beq $s4, $0, braceMismatch
		NOP
	
		#jal pop

		j increment
		
	success:
		li $v0, 4
		la $a0, mSuccess1
		syscall				# Prints first part of the success message
		
		li $v0, 1
		lw $a0, bracePairs
		syscall				# Prints number of pairs of braces
		
		li $v0, 4
		la $a0, mSuccess2
		syscall				# Prints last part of the success message
		
		j exitProgram
	
	multBraces:
		lw $s4, stackSize

		NOP
		beq $s4, $0, success
		NOP
		
		li $v0, 4
		la $a0, bracesOnStack
		syscall				# Prints the multBraces error message
		
		j printBraces
	
	printBraces:
		lw $s4, stackSize
	
		NOP
		beq $s4, $0, exitProgram
		NOP
		
		jal pop
		
		li $v0, 11
		lb $t8, buffer($s4)
		la $a0, ($t8)
		syscall				# Prints braces leftover on the stack
		
		j printBraces
		
	braceMismatch:
		li $v0, 4
		la $a0, braceMismatch1
		syscall				# Prints braceMismatch1 error message
		
		li $v0, 11
		addi $t9, $t9, -2
		lb $t8, buffer($t9)
		la $a0, ($t8)
		syscall				# Prints the mismatched brace found on the stack
		
		li $v0, 4
		la $a0, braceMismatch2
		syscall				# Prints braceMismatch2 error message
		
		li $v0, 1
		la $a0, ($t9)
		syscall				# Prints the index of the mismatched brace
		
		j exitProgram
		
	invalidArg:
		li $v0, 4
		la $a0, impropFile
		syscall				# Prints improper filename error message
		
		j exitProgram
	
	exitProgram:
		li $v0, 4
		la $a0, newLine
		syscall				# Prints a new line
		
		li $v0, 16			
		la $a0, ($s2)
		syscall				# Closes file
		
		li $v0, 10
		syscall				# Exits program
