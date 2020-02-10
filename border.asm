#name:
#studentID:

.data

#Must use accurate file path.
#file paths in MARS are relative to the mars.jar file.
# if you put mars.jar in the same folder as test2.txt and your.asm, input: should work.
input:	.asciiz "C:\\Users\\DobyDobd\\Desktop\\New folder\\test1.txt"
output:	.asciiz "C:\\Users\\DobyDobd\\Desktop\\New folder\\borded.pgm"	#used as output

borderwidth: .word 4    #specifies border width
buffer:  .space 2048		# buffer for upto 2048 bytes
.align 2
newbuff: .space 2048
headerbuff: .space 2048  #stores header

#any extra data you specify MUST be after this line 
.align 2
array: 	.space 672
out:	.space 2048
err: 	.asciiz "error opening file"

	.text
	.globl main

main:	la $a0,input		#readfile takes $a0 as input
	jal readfile


	la $a0,array		#$a1 will specify the "2D array" we will be flipping
	la $a1,newbuff		#$a2 will specify the buffer that will hold the flipped array.
	la $a2,borderwidth
	jal bord


	la $a0, output		#writefile will take $a0 as file location
	la $a1,newbuff		#$a1 takes location of what we wish to write.
	move $a2, $v0
	move $a3, $v1
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

bord:	
	addi $sp, $sp, -8	#although not necessary, we will still follow the convention of when modifying $S registers in a functio
	sw $s0, 4($sp)
	sw $s1, 0($sp)

	lw $s3, 0($a2)		#obtain border size, put it in $s3
	addi $t0, $s3, 24	#we will calculate the size of the array after adding borders
	add $s0, $t0, $s3	#24+2*borderwidth = new width = $s0 , 7+2*borderwidth = new height = $s1
	
	addi $t0, $s3, 7
	add $s1, $t0, $s3
	
	mul $t0, $s1, $s0	#calculate total entries in new array
	move $t1, $0		#initialize loop counter for blankloop
	addi $t2, $0, 15	#15 is white
	move $t3, $a1		#obtain adress of newbuff
blankloop:			#what we will now do is make a white array of the appropriate size and then we'll place the old array inside it, offset from the borders by distance = borderwidth
	sw $t2, 0($t3)		#here we just loop until a white array of the appropriate size is made
	addi $t3, $t3, 4
	addi $t1, $t1 1
	blt $t1, $t0, blankloop
	
	mul $t1, $s0, $s3	#now we will calculate the location inside the new array where the first entry of the old array (upper right corner) will be placed
	add $t1, $t1, $s3	#that location will be borderwidth*(new width) + borderwidth
	mul $t1, $t1, 4		#we make it into a multiple of four 
	
	add $t2, $t1, $a1	#we add it to the adress of the newbuff. $t2 is now the location where the first entry of the first row of the old array will be placed
	move $t3, $a0 
		
	add $t0, $0, $0		#initialize counter
loopn:
	add $t1, $0, $0		#initialize iner loop counter
	move $t5, $t2		#obtain the starting point for the current row of the old array
inern: 
	addi $t1, $t1, 1	#increment counter
	
	lw $t4, 0($t3)		#obtain int from old array and replace the corresponding in the new array with it
	sw $t4, 0($t5)
	
	addi $t5, $t5, 4	#advance both pointers
	addi $t3, $t3, 4
	
	blt $t1, 24, inern	#we loop until we've transfered the whole row of the old array
	
	mul $t6, $s0, 4		#then we obtain the location where the first entry of the next row will be put. we first calculate the offset
	
	add $t2, $t2, $t6	#add it to our old starting point
	addi $t0, $t0, 1	#increment outer loop counter
	blt  $t0, 7, loopn	#loop until we've done all the rows
	
	la $t2, headerbuff	#we must now create a new header
	
	addi $t0, $0, 80	#P
	sb $t0, 0($t2)
	addi $t2, $t2, 1
	
	addi $t0, $0, 50	#2
	sb $t0, 0($t2)
	addi $t2, $t2, 1
	
	addi $t0, $0, 10	#/n
	sb $t0, 0($t2)
	addi $t2, $t2, 1
	
	move $t0, $s0
	move $t5, $0
	
newheader:
	blt $t0, 10, onedig	#we check if the first value out of the two for dimensions is one digit or two digit. if 1, we go straight to "onedig" if 2, we proceed
	addi $t1, $0, 10	
	div $t0, $t1		#we do mod 10 to get the 2nd digit
	mfhi $t1	
	addi $t3, $t1, 48	#add 48 to convert to ascii

	sub $t0, $t0, $t1	#substract the remainder, leaving a multiple of 10
	div $t0, $t0, 10	#divide by 10 to obtain first digit

	sb $t3, 1($t2)		#save the 2nd digit into the headerbuff
	
onedig:
	addi $t0, $t0, 48	#convert digit (or first digit) to ascii
	sb $t0, 0($t2)		#save into headerbuff 
	addi $t2, $t2, 2	#increment by 2 always. it might create a null if single digit, but this wont affect annything
	
	addi $t5, $t5, 1	#increment counter
	
	beq $t5, 2, done	#counter=2 means that we've done both height and width. so we break out of the loop
	
	addi $t0, $0, 32	#if weve only done width, then we add a space and loop back but this time $t0 is $s1 (the height)
	sb $t0, 0($t2)
	addi $t2, $t2, 1
	
	move $t0, $s1
	
	j newheader
done:				#after adding the dynamic parts of our header, we do the static parts
	addi $t0, $0, 10	#newline
	sb $t0, 0($t2)
	addi $t2, $t2, 1
	
	addi $t0, $0, 49	#1
	sb $t0, 0($t2)
	addi $t2, $t2, 1
	
	addi $t0, $0, 53	#5
	sb $t0, 0($t2)
	addi $t2, $t2, 1
	
	addi $t0, $0, 10	#newline
	sb $t0, 0($t2)
	addi $t2, $t2, 1
	
	move $v0, $s0		#for convenience, this function will return $s0 and $s1 since we'll be using these values in following operations
	move $v1, $s1
	
	lw $s0, 4($sp)
	lw $s1, 0($sp)
	addi $sp, $sp, 8	#although not necessary, we will still follow the convention of when modifying $S registers in a functio
	
	jr $ra

	
	
#a0=buffer
#a1=newbuff
#a2=borderwidth
#Can assume 24 by 7 as input
#Try to understand the math before coding!
#EXAMPLE: if borderwidth=2, 24 by 7 becomes 28 by 11.

writefile:
	addi $sp, $sp, -20	#fully commented in cropper.asm (virtually same function)
	sw $ra, 16($sp)
	sw $a0, 12($sp)
	sw $a1, 8($sp)
	sw $a2, 4($sp)
	sw $a3, 0($sp)
	
	la $a0, out
	la $a1, newbuff
				# $a2, and $a3 stay the same
	jal converttostr	#we call converttostr to convert to ascii
	
	lw $ra, 16($sp)
	lw $a0, 12($sp)
	lw $a1, 8($sp)
	lw $a2, 4($sp)
	lw $a3, 0($sp)
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
	la $a1, headerbuff
	li $a2, 12
	syscall
	
	li $v0, 15
	move $a0, $t1
	la $a1, out
	li $a2, 2048
	syscall
	
	li $v0, 16
	move $a0, $t1
	syscall
	
	jr $ra 


converttostr:
	add $t1, $0, $a0	#we'll put the string in "out"
	add $t2, $0, $0		#initiating counters
	add $t7, $0, $0
	addi $t3, $0, 10	#10, well use the number enough times
	move $t8, $a1		#obtain adress of newbuff
loopl:
	lw $t0, 0($t8)		#we load an int from newbuff
	addi $t8, $t8, 4	#increment pointer
	blt $t0, 10, savel	#check if its 1 digit or two digit. 1 digit, we can save emmediately
	
	div $t0,$t3		#if 2 digits. we do mod 10 to get the second digit
	mfhi $t4
	
	sub $t0, $t0, $t4	#to get the first digit, we substact the second digit from the number, leaving us with a multiple of 10
	div $t0, $t0, 10	#we divide by 10 to get the first digit
	addi $t0, $t0, 48	#convert first digit to ascii
	sb $t0, 0($t1)		#store first digit in out
	addi $t1, $t1, 1	#increment pointer
	
	move $t0, $t4		#now we can just save our second digit right after the first, in save1
	
savel:	
	addi $t0, $t0, 48	#convert digit to ascii
	sb $t0, 0($t1)		#save it
	addi $t1, $t1, 1	#increment pointer

	addi $t0, $0, 32	#add a space before the next number
	sb $t0, 0($t1)
	addi $t1, $t1, 1
	
	addi $t2, $t2, 1	#increment counter (for how many numbers we've done)
	addi $t7, $t7, 1	#increment counter (for how many numbers we've done in the row)
	
	blt $t7, $a2, loopback	#if we havent reached the end of a row, then we go to loopback to loop back and get the next number
	addi $t0, $0, 10	#if we have reached the end of a row, we add a newline
	sb $t0, 0($t1)
	addi $t1, $t1, 1	#increment pointer
	
	add $t7, $0, $0		#reset counter for new row
loopback:
	mul $t0, $a2, $a3
	blt $t2,$t0, loopl 	#loop back unless we've done all the numbers
	
	jr $ra


error:
	la $a0, err
	li $v0, 4
	syscall
	
	jr $ra
	
#slightly different from Q1.
#use as many arguments as you would like to get this to work.
#make sure the header matches the new dimensions!
