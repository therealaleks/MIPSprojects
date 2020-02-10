# This program illustrates an exercise of capitalizing a string.
# The test string is hardcoded. The program should capitalize the input string
# Comment your work

	.data

inputstring: 	.asciiz "I am a student YOTUn at McGill University "
outputstring:	.space 100
newline:	.asciiz "\n"




	.text
	.globl main

main:	la $t0, inputstring	#we obtain the address for the input
	la $t1, outputstring	#for output
	
	li  $v0, 4		#we print a inputstring
	la  $a0, inputstring		
	syscall
	
	li  $v0, 4		#we print a newline
	la  $a0, newline	
	syscall
	
	lb $t2, 0($t0)		#we obtain the first character
	
loop1:	beq $t2, $0, exit	#check if we've reached the end of the string, if yea, we go to exit
	beq $t2, 32, skip	#else we check if character is a space, if it is, we skip the capitalize step
	blt $t2, 91, skip	#else, we check if the letter is already capitalized, if it is, we skip the capitalize step
capitalize:
	addi $t2, $t2, -32	#to capitalize, we take off 32 from the character
skip: 	sb $t2, 0($t1)		#store character in the output string
	addi $t1, $t1, 1	#advance the output pointer by 1
	addi $t0, $t0, 1	#do the same for the input pointer
	lb $t2, 0($t0)		#we take the new character
	
	j loop1			#loop back

exit:	li  $v0, 4		#we print the output
	la  $a0, outputstring
	syscall
