##########################################################################
# Created by:  Ensminger, James
#              1725314
#              25 February 2021
#
# Assignment:  Lab 5: Functions and Graphics
#              CSE 12, Computer Systems and Assembly Language
#              UC Santa Cruz, Winter 2021
# 
# Description: This program uses the bitmap display tool in MARS to draw
#	       various lines and pixel points as well as a crosshair.
# 
# Notes:       This program is intended to be run from the MARS IDE.
##########################################################################
# Pseudocode
#
# clear_bitmap:
# 	loops through each 32-bit pixel address on the bitmap one at a time, does this by looping through memory
#	starts at originAddress (0xFFFF0000) and loops until last pixel is colored at end address (0xFFFFFFFC)
#
# draw_pixel:
# 	gets x and y coordinates from input coordinate 0x00XX00YY
#	gets the memory address of the coordinate using getPixelAddress macro
#	stores the input color at this memory address to color the pixel on the bitmap display
#
# get_pixel:
#	gets x and y coordinates from input coordinate 0x00XX00YY
#	gets the memory address of the coordinate using getPixelAddress macro
#	returns the color stored at this memory address
#
# draw_horizontal_line:
#	manipulates x coordinate value to only get the first and last memory address in row 0x000000YY from the input coordinate 0x00XX00YY
#	loops through each pixel address until the last pixel is colored at the end address in row 0x000000YY
#
# draw_vertical_line:
#	manipulates y coordinate value to only get the first and last memory address in column 0x000000XX from the input coordinate 0x00XX00YY
#	loops through each pixel address until the last pixel is colored at the end address in column 0x000000XX
#
# draw_crosshair:
#	gets current color of pixel at the input coordinate using the get_pixel function and stores it in a saved temorary register
#	draws a horizontal line in the input color by using the draw_horizontal_line function
#	draws a vertical line in the input color by using the draw_horizontal_line function
#	restores the color of pixel at the input coordinate using the draw_pixel function with the color stored in the saved temorary register
######################################################
# Macros for instructor use (you shouldn't need these)
######################################################

# Macro that stores the value in %reg on the stack 
#	and moves the stack pointer.
.macro push(%reg)
	subi $sp $sp 4
	sw %reg 0($sp)
.end_macro 

# Macro takes the value on the top of the stack and 
#	loads it into %reg then moves the stack pointer.
.macro pop(%reg)
	lw %reg 0($sp)
	addi $sp $sp 4	
.end_macro

#################################################
# Macros for you to fill in (you will need these)
#################################################

# Macro that takes as input coordinates in the format
#	(0x00XX00YY) and returns x and y separately.
# args: 
#	%input: register containing 0x00XX00YY
#	%x: register to store 0x000000XX in
#	%y: register to store 0x000000YY in
.macro getCoordinates(%input %x %y)
	and %y, %input, 0x000000FF
	srl %x, %input, 16
.end_macro

# Macro that takes Coordinates in (%x,%y) where
#	%x = 0x000000XX and %y= 0x000000YY and
#	returns %output = (0x00XX00YY)
# args: 
#	%x: register containing 0x000000XX
#	%y: register containing 0x000000YY
#	%output: register to store 0x00XX00YY in
.macro formatCoordinates(%output %x %y)
	sll %output, %x, 16
	or %output, %output, %y
.end_macro 

# Macro that converts pixel coordinate to address
# 	output = origin + 4 * (x + 128 * y)
# args: 
#	%x: register containing 0x000000XX
#	%y: register containing 0x000000YY
#	%origin: register containing address of (0, 0)
#	%output: register to store memory address in
.macro getPixelAddress(%output %x %y %origin)
	mul %output, %y, 128
	add %output, %x, %output
	mul %output, %output, 4
	add %output, %output, %origin
.end_macro


.data
originAddress: .word 0xFFFF0000

.text
# prevent this file from being run as main
li $v0 10 
syscall

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Subroutines defined below
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#*****************************************************
# Clear_bitmap: Given a color, will fill the bitmap 
#	display with that color.
# -----------------------------------------------------
# Inputs:
#	$a0 = Color in format (0x00RRGGBB) 
# Outputs:
#	No register outputs
# -----------------------------------------------------
# Register Usage:
# $t0 = coordinates of address in loop
# $t1 = coordinates of end address of memory map
# $a0 = color of pixel
#*****************************************************
clear_bitmap: nop
	lw $t0, originAddress
	lw $t1, 0xFFFFFFFC				# End address of memory map
	
	clearLoop:					# Loops through each address of memory map and saves it at $a0 until the last address of memory map is reached
		nop
		beq $t0, $t1, endClearLoop
		nop
		sw $a0, ($t0)
		addi $t0, $t0, 4
		j clearLoop
		
	endClearLoop:
 		jr $ra

#*****************************************************
# draw_pixel: Given a coordinate in $a0, sets corresponding 
#	value in memory to the color given by $a1
# -----------------------------------------------------
#	Inputs:
#		$a0 = coordinates of pixel in format (0x00XX00YY)
#		$a1 = color of pixel in format (0x00RRGGBB)
#	Outputs:
#		No register outputs
# -----------------------------------------------------
#Register Usage:
# $t0 = contains 0x000000XX
# $t1 = contains 0x000000YY
# $t2 = coordinates of originAddress
# $t8 = pixel address
#*****************************************************
draw_pixel: nop
	lw $t2, originAddress
	
	getCoordinates($a0, $t0, $t1)			# Separates the x and y coordinates from $a0 of the memory map
	getPixelAddress($t8, $t0, $t1, $t2)		# Gets the pixel address at (x, y)
	sw $a1, ($t8)					# Saves the pixel address to $a1
	
	jr $ra
	
#*****************************************************
# get_pixel:
#  Given a coordinate, returns the color of that pixel	
#-----------------------------------------------------
#	Inputs:
#		$a0 = coordinates of pixel in format (0x00XX00YY)
#	Outputs:
#		Returns pixel color in $v0 in format (0x00RRGGBB)
# -----------------------------------------------------
#Register Usage:
# $t0 = contains 0x000000XX
# $t1 = contains 0x000000YY
# $t2 = coordinates of originAddress
# $t8 = pixel address
#*****************************************************
get_pixel: nop
	lw $t2, originAddress
	
	getCoordinates($a0, $t0, $t1)			# Separates the x and y coordinates from $a0 of the memory map
	getPixelAddress($t8, $t0, $t1, $t2)		# Gets the pixel address at (x, y)
	lw $v0, ($t8)					# Loads the contents of the pixel address to $v0 which is the RGB color of the pixel
	
	jr $ra

#*****************************************************
# draw_horizontal_line: Draws a horizontal line
# ----------------------------------------------------
# Inputs:
#	$a0 = y-coordinate in format (0x000000YY)
#	$a1 = color in format (0x00RRGGBB) 
# Outputs:
#	No register outputs
# -----------------------------------------------------
#Register Usage:
# $t0 = contains 0x000000XX
# $t1 = contains 0x000000YY
# $t2 = coordinates of originAddress
# $t3 = last pixel address in row 0x000000YY
# $t8 = initial pixel address in row 0x000000YY, contains current address in loops
#*****************************************************
draw_horizontal_line: nop
	getCoordinates($a0, $t0, $t1)
	li $t0, 0x00000080				# End of row 0x000000YY
	getPixelAddress($t3, $t0, $t1, $t2)

	getCoordinates($a0, $t0, $t1)
	li $t0, 0x00000000				# Beginning of row 0x000000YY
	getPixelAddress($t8, $t0, $t1, $t2)
	
	HorizLoop:					# Loops through each address on the memory map row of 0x000000YY until the last address of that row is reached
		nop
		beq $t8, $t3, HorizLoopEnd
		nop
		sw $a1, ($t8)
		addi $t8, $t8, 4
		j HorizLoop
		
	HorizLoopEnd:
 		jr $ra

#*****************************************************
# draw_vertical_line: Draws a vertical line
# ----------------------------------------------------
# Inputs:
#	$a0 = x-coordinate in format (0x000000XX)
#	$a1 = color in format (0x00RRGGBB) 
# Outputs:
#	No register outputs
# -----------------------------------------------------
#Register Usage:
# $t0 = contains 0x000000XX
# $t1 = contains 0x000000YY
# $t2 = coordinates of originAddress
# $t4 = last pixel address in column 0x000000XX
# $t8 = initial pixel address in row 0x000000XX, contains current address in loops
#*****************************************************
draw_vertical_line: nop
	columnEnd:					
		getCoordinates($a0, $t0, $t1)
		nop
		beq $t0, $0, coordinateShift		# Checks if input coordinate only has an x coordinate
		nop
		li $t1, 0x00000080			# End of column 0x000000XX
		getPixelAddress($t4, $t0, $t1, $t2)
		
	getCoordinates($a0, $t0, $t1)
	li $t1, 0x00000000				# Beginning of column 0x000000XX
	getPixelAddress($t8, $t0, $t1, $t2)
	
	vertLoop:					# Loops through each address, from the current to the last, on the memory map column of 0x000000XX
		nop
		beq $t8, $t4, endVertLoop
		nop
		sw $a1, ($t8)
		addi $t8, $t8, 512
		j vertLoop
		
	coordinateShift:
		sll $a0, $a0, 16
		j columnEnd
	
	endVertLoop:
 		jr $ra

#*****************************************************
# draw_crosshair: Draws a horizontal and a vertical 
#	line of given color which intersect at given (x, y).
#	The pixel at (x, y) should be the same color before 
#	and after running this function.
# -----------------------------------------------------
# Inputs:
#	$a0 = (x, y) coords of intersection in format (0x00XX00YY)
#	$a1 = color in format (0x00RRGGBB) 
# Outputs:
#	No register outputs
# -----------------------------------------------------
#Register Usage:
# $s4 = stores original pixel color of the pixel address
#*****************************************************
draw_crosshair: nop
	push($ra)
	push($s0)
	push($s1)
	push($s2)
	push($s3)
	push($s4)
	push($s5)
	move $s5 $sp

	move $s0 $a0  # store 0x00XX00YY in s0
	move $s1 $a1  # store 0x00RRGGBB in s1
	getCoordinates($a0 $s2 $s3)  # store x and y in s2 and s3 respectively
	
	# get current color of pixel at the intersection, store it in s4
	push($ra)
	jal get_pixel
	pop($ra)
	move $s4, $v0

	# draw horizontal line (by calling your `draw_horizontal_line`) function
	push($ra)
	jal draw_horizontal_line
	pop($ra)
	
	# draw vertical line (by calling your `draw_vertical_line`) function
	push($ra)
	jal draw_vertical_line
	pop($ra)
	
	# restore pixel at the intersection to its previous color
	move $a1, $s4
	push($ra)
	jal draw_pixel
	pop($ra)

	move $sp $s5
	pop($s5)
	pop($s4)
	pop($s3)
	pop($s2)
	pop($s1)
	pop($s0)
	pop($ra)
	jr $ra
