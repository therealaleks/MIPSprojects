#name:
#studentID:

.data
#Must use accurate file path.
#file paths in MARS are relative to the mars.jar file.
# if you put mars.jar in the same folder as test2.txt and your.asm, input: should work.
input:	.asciiz "C:\\Users\\DobyDobd\\Desktop\\New folder\\test1.txt"
output:	.asciiz "C:\\Users\\DobyDobd\\Desktop\\New folder\\flipped.pgm"	#used as output
axis: .word 1 # 0=flip around x-axis....1=flip around y-axis
buffer:  .space 2048	
.align 2	# buffer for upto 2048 bytes
newbuff: .space 2048

#any extra data you specify MUST be after this line 
.align 2
array:	.space 672  #168 integer array
out:	.space 2048
err: 	.asciiz "error opening file"
header: .asciiz "P2\n24 7\n15\n"
	.text
	.globl main

main:
	la $a0,input	#readfile takes $a0 as input
	jal readfile

	la $a0,array		#$a0 will specify the "2D array" we will be flipping
	la $a1,newbuff		#$a1 will specify the buffer that will hold the flipped array.
	la $a2,axis        #either 0 or 1, specifying x or y axis flip accordingly
	jal flip


	la $a0, output		#writefile will take $a0 as file location we wish to write to.
	la $a1, newbuff		#$a1 takes location of what data we wish to write.
	jal writefile

	li $v0,10		# exit
	syscall

readfile:
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

flip:
	move $t8, $a1		#obtaining adress of new buff
	addi $sp, $sp, -8	#although not necessary, we will still follow the convention of when modifying $S registers in a functio
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	
	addi $s0, $0, 24	#well be using these values a ot
	addi $s1, $0, 7
	lw $t0, 0($a2)		#we check if we doing x or y
	bne $t0, 0, yaxis	#react accordingly
	
	addi $t0, $0, 6		#this is x , well use a nested loop. here we initialize the outer loop counter
loop1:
	addi $t1, $0, 0		#inner loop counter
inloop1:	 		#the general idea here is we will take the i-th row and put it in our flipped array in the 6-i position, starting from i=6
	mul $t2, $t0, $s0	#here we're figuring out the position of the number we want to transfer
	add $t2, $t2, $t1	#by doing i(width) + j
	mul $t2, $t2, 4		#and making it appropriate for usage in an address
	add $t2, $t2, $a0	#we add it to the array's address and we have the location of the number we want to take
	lw $t3, 0($t2)		#we transfer it ere
	sw $t3, 0($t8)
	addi $t8, $t8, 4	#we advance the pointer of the newbuff
	
	addi $t1, $t1, 1	#we loop until all the numbers in the row have been transfored
	blt $t1, $s0, inloop1
	
	subi $t0, $t0, 1	#here we decrement so that we go from down to up, therefore flipping the array around x
	bge $t0, $0, loop1	#we loop until all the rows have been transfered
	jr $ra
yaxis:
	addi $t0, $0, 0		#very similar for y
loop2:				#the only difference is that we are now moving through rows from up to bottom, but transfering the numbers of each row from right to left instead. this flips around y
	addi $t1, $0, 23	#all this changes are the initial values of the counters and how we change them at each loop
inloop2:	 		#the rest is the same
	mul $t2, $t0, $s0
	add $t2, $t2, $t1
	mul $t2, $t2, 4
	add $t2, $t2, $a0
	lw $t3, 0($t2)
	sw $t3, 0($t8)
	
	addi $t8, $t8, 4
	
	subi $t1, $t1, 1
	bge $t1, $0, inloop2
	
	addi $t0, $t0, 1
	blt $t0, $s1, loop2
	
		#although not necessary, we will still follow the convention of when modifying $S registers in a functio
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	addi $sp, $sp, 88
	jr $ra

writefile:

	addi $sp, $sp, -12	#here we call the function converttostr to convert to string
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
	
converttostr:			#fully commented in cropper.asm (virtually same function)
	add $t1, $0, $a0
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
	
	ble $t7, 23, loopback
	addi $t0, $0, 10
	sb $t0, 0($t1)
	addi $t1, $t1, 1
	
	add $t7, $0, $0	
loopback:	
	ble $t2,167, loopl
	
	jr $ra

error:
	la $a0, err
	li $v0, 4
	syscall
	
	jr $ra
	
#slightly different from Q1.
#use as many arguments as you would like to get this to work.
#make sure the header matches the new dimensions!
