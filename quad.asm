	.data


nosolution: 	.asciiz "No solution"
space:		.asciiz " "

	.text
	.globl main

main:	

	#la $t0, outputstring	#for output
	la $t1, nosolution
	la $t2, space
	lb $s3, 0($t2)
	
	li $v0, 5		#getting input for a
	syscall
	add $t0, $t0, $v0
	
	li $v0, 5		#getting input for b
	syscall
	add $s1, $s1, $v0
	
	move $a0, $t0
	move $a1, $s1
	div $a0, $a1
	mfhi $s0 		#we compute a mod b. 
	
	li $v0, 5		#getting input for c
	syscall
	add $s2, $s2, $v0

	add $t0, $0, $0		#this will be our iterator for values of x
	add $t2, $0, $0		#this will be our counter for the number of solutions
	
loop:	
	move $a0, $t0		#here we square x
	mult $a0, $a0		
	mflo $t1		#put the square into t1
	
	move $a0, $t1		#now we compute x^2 mod b
	move $a1, $s1
	div $a0, $a1
	mfhi $t1 		
		
	bne $t1, $s0, skip	#if x^2 mod b isnt equal to a mod b, then we skip the solution printing step
	
	li $v0, 1		#else we then print out x + a space for the next solution
	move $a0, $t0
	syscall
	
	li $v0, 4
	la $a0, space
	syscall
	
	addi $t2, $t2, 1
skip:	
	beq $t0, $s2, exit	#we check if we'd reached c. if so, we go to the exit step
	addi $t0, $t0, 1	#if not, we get our next x value

	j loop			#and loop back

exit:	
	bne $t2, $0, end	#once were done with all values of x, we check if we had any solutions, if we did, the program ends
	li $v0, 4		#if not, we print our "no solution"
	la $a0, nosolution
	syscall
end: 	nop

