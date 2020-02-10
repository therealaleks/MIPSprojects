#name:
#studentID:

.data

#Must use accurate file path.
#file paths in MARS are relative to the mars.jar file.
# if you put mars.jar in the same folder as test2.txt and your.asm, input: should work.
input:	.asciiz "C:\\Users\\DobyDobd\\Desktop\\New folder\\test1.txt"
output:	.asciiz "C:\\Users\\DobyDobd\\Desktop\\New folder\\transposed.pgm"	#used as output
buffer:  .space 2048	# buffer for upto 2048 bytes
	.align 2	
newbuff: .space 2048


#any extra data you specify MUST be after this line 
err: 	.asciiz "error opening file"
header: .asciiz "P2\n7 24\n15\n"
.align 2
array: .space 672

out:	.space 2048

	.text
	.globl main

main:	la $a0,input 		#readfile takes $a0 as input
	jal readfile


	la $a0,array		#$a0 will specify the "2D array" we will be flipping
	la $a1,newbuff		#$a1 will specify the buffer that will hold the flipped array.
	jal transpose


	la $a0, output		#writefile will take $a0 as file location
	la $a1,newbuff		#$a1 takes location of what we wish to write.
	jal writefile

	li $v0,10		# exit
	syscall

readfile:
#done in Q1
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	sw $a0, 0($sp)

	li $v0, 13		#open file
	li $a1, 0		
	li $a2, 0
	syscall			
	blt $v0, $0, error	#check for error
	move $t1, $v0		#obtain file descriptor
	
	li $v0, 14		#read from file into the buffer
	move $a0, $t1
	la $a1, buffer
	li $a2, 2048
	syscall

	la $a0, buffer		#prints out content of buffer
	li $v0, 4
	syscall
	
	li $v0, 16		#close file
	move $a0, $t1
	syscall
	
	la $a0, array
	la $a1, buffer
	jal converttoint
	
	lw $a0, 0($sp)
	lw $ra, 4($sp)
	addi $sp, $sp, 8
	jr $ra

converttoint:	
	add $t0, $0, $a0		#we will now convert the buffer to an array of ints, and we'll store it in "array"
	add $t1, $0, $a1		#thus we obtain the appropriate addresses
loop:	
	lb $t2, 0($t1)		#we load two bites at a time
	lb $t3, 1($t1)
	
	beq $t2, 32, skip	#we check if the first bite is a space or newline. if so, we proceed to skip
	beq $t2, 10, skip
	beq $t2, $0, end	#if null, end of string, we proceed to end
	
	subi $t2, $t2, 48	#if not, then according to mycourses announcments, it can only be a number. we substract 48 
				#to convert to int
	add $t4, $t4, $t2	#we add it to t4 (this is because t4 holds a first power digit if there is one)
	
	beq $t3, 32, save	#now to know what we do with this number, we must first know if its the first power in the base 10 representation of a number
	beq $t3, 10, save	#t3 is the next bite. if that bite is a space or newline or null, we know that it the sole digit in the base 10 number
	beq $t3, $0, save	#so we proceed to save it in our array in the process "save"
	
	addi $t5, $0, 10	
	mult $t4, $t5		#if it is the first power in base 10, then we multiply it by 10
	mflo $t4		#we add it to $t4 and loop back 
				#the final number will accumulate inside t4 until the last digit is reached and we go to save
	addi $t1, $t1, 1	#here we advance the buffer counter for each loop
	
	j loop
save:				#in save, we simply store the number in the array
	sw $t4, 0($t0)
	addi $t0, $t0, 4	
	add $t4, $0, $0
skip:				#here we advance buffer pointer
	addi $t1, $t1, 1	
	j loop			#loop back for the next number
end:	
	jr $ra


transpose:
	move $t4, $a0
	move $t5, $a1
	add $t0, $0, $0		#we initiate the outer loop counter
loop1:
	add $t1, $0, $0		#we initiate the inner loop counter
	move $t2, $t4		#obtain adress of the array (or as well see shortly, the address of the first element of the current column)
inloop:
	lw $t3, 0($t2)		#we take an int from the array
	sw $t3, 0($t5)		#and put it in newbuff
	
	addi $t5, $t5, 4	#increment by 4 for newbuff for the next int
	addi $t2, $t2, 96	#as for the array, we'll add 96 or 24*4 to obtain the int right under the previous one. essentially, we're iterating through the colums
	
	addi $t1, $t1, 1	#increment inner loop counter
	blt $t1, 7, inloop	#we loop until we've stored the whole column
	
	addi $t0, $t0, 1	#then we increment the outer loop counter
	addi $t4, $t4, 4	#we increment to the next column
	blt $t0, 24, loop1	#and we loop until every column is done
	jr $ra
#Can assume 24 by 7 again for the input.txt file
#Try to understand the math before coding!

writefile:		
	
	addi $sp, $sp, -12	#fully commented in cropper.asm (virtually same function)
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	sw $a1, 0($sp)
	
	la $a0, out
	la $a1, newbuff
	jal converttostr
	
	lw $ra, 8($sp)
	lw $a0, 4($sp)
	lw $a1, 0($sp)
	addi $sp, $sp, 12
	
	#la $a0, out
	#li $v0, 4
	#syscall
	
	move $t0, $a1

	li $v0, 13
	#la $a0, output
	li $a1, 1
	li $a2, 0
	syscall
	blt $v0, $0, error
	move $t1, $v0
	
	li $v0, 15
	move $a0, $t1
	la $a1, header
	li $a2, 16
	syscall
	
	li $v0, 15
	move $a0, $t1
	la $a1, out
	li $a2, 700
	syscall
	
	li $v0, 16
	move $a0, $t1
	syscall
	
	jr $ra 
	
converttostr:		#fully commented in cropper.asm (virtually same function)
	move $t1, $a0
	add $t2, $0, $0
	add $t7, $0, $0
	addi $t3, $0, 10
	move $t8, $a1
loopl:
	lw $t0, 0($t8)
	addi $t8, $t8, 4
	blt $t0, 10, savel
	
	div $t0,$t3
	
	mfhi $t4
	
	sub $t0, $t0, $t4
	div $t0, $t0, 10
	addi $t0, $t0, 48
	sb $t0, 0($t1)
	addi $t1, $t1, 1
	
	move $t0, $t4
	
savel:	
	addi $t0, $t0, 48
	sb $t0, 0($t1)
	addi $t1, $t1, 1

	addi $t0, $0, 32
	sb $t0, 0($t1)
	addi $t1, $t1, 1
	
	addi $t2, $t2, 1
	addi $t7, $t7, 1
	
	ble $t7, 6, loopback
	addi $t0, $0, 10
	sb $t0, 0($t1)
	addi $t1, $t1, 1
	
	add $t7, $0, $0
loopback:	
	blt $t2,168, loopl
	
	jr $ra

error:
	la $a0, err
	li $v0, 4
	syscall
	
	jr $ra
	
#slightly different from Q1.
#use as many arguments as you would like to get this to work.
#make sure the header matches the new dimensions!
