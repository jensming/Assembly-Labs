.data
	prompt: .asciiz "Enter the height of the pattern (must be greater than 0):\t"
	errorMessage: .asciiz "Invalid Entry!\n"
	tab1: .asciiz "*\t"
	tab2: .asciiz "\t*"
	newLine: .asciiz "\n"
.text
	main:	
		li $v0, 4
		la $a0, prompt
		syscall		# Print prompt
	
		li $v0, 5
		syscall		# Get user input
	
		move $t0, $v0	# Store user input in $t0
		
		NOP	
		ble $t0, $zero, printError	# Prints errorMessage if user input is less than or equal to zero
		NOP
		
		addi $t1, $zero, 1			# int i = 1
		loop:
			NOP
			bgt $t1, $t0, endProgram	# while (i < user input)
			NOP
			jal printPattern
			
			increment:
				addi $t1, $t1, 1		# i++
				j loop
	
	printPattern:
		addi $t2, $zero, 1		#int j = 1
		printTabs_loop1:
			NOP
			bge $t2, $t1, printInteger
			NOP
			li $v0, 4
			la $a0, tab1
			syscall			# Prints asterisk followed by tab
			addi $t2, $t2, 1	# j++
			j printTabs_loop1
			
		printInteger:
			li $v0, 1
			move $a0, $t1
			syscall			# Prints integer
			addi $t3, $zero, 1	#int k = 1
			b printTabs_loop2
			
		printTabs_loop2:
			NOP
			bge $t3, $t1, endPattern
			NOP
			li $v0, 4
			la $a0, tab2
			syscall			# Prints tab followed by asterisk
			addi $t3, $t3, 1	# k++
			j printTabs_loop2
		
		endPattern:
			li $v0, 4
			la $a0, newLine
			syscall			# Prints newLine
			j increment
			
	printError:
		li $v0, 4
		la $a0, errorMessage
		syscall			# Print errorMessage
		j main

	endProgram:
		li $v0, 10
		syscall			# Exits program
