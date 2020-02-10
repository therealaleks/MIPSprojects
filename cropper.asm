#name:
#studentID:

.data

#Must use accurate file path.
#file paths in MARS are relative to the mars.jar file.
# if you put mars.jar in the same folder as test2.txt and your.asm, input: should work.
input:	.asciiz "C:\\Users\\DobyDobd\\Desktop\\New folder\\test1.txt"
output:	.asciiz "C:\\Users\\DobyDobd\\Desktop\\New folder\\cropped.pgm"	#used as output
buffer:  .space 2048		# buffer for upto 2048 bytes
.align 2
newbuff: .space 2048
x1: .word 10
x2: .word 23
y1: .word 0
y2: .word 6
headerbuff: .space 2048  #stores header
#any extra .data you specify MUST be after this line 
.align 2
array: .space 672
out:	.space 2048
err: 	.asciiz "error opening file"


	.text
	.globl main

main:	la $a0,input		#readfile takes $a0 as input
	jal readfile


    #load the appropriate values into the appropriate registers/stack positions
    #appropriate stack positions outlined in function*
    	lw $a0, x1
    	lw $a1, x2
    	lw $a2, y1
    	lw $a3, y2
    	subi $sp, $sp, 24
    	la $t0, array
    	sw $t0, 16($sp)
    	la $t0, newbuff
    	sw $t0, 20($sp)
	jal crop
	addi $sp, $sp, 24

	la $a0, output		#writefile will take $a0 as file location
	la $a1,newbuff	#$a1 takes location of what we wish to write.
	move $a2, $v0
	move $a3, $v1
	#add what ever else you may need to make this work.
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
	addi $sp, $sp, -8
	sw $a0, 0($sp)
	sw $a1, 4($sp)
		
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
	
	lw $a0, 0($sp)
	lw $a1, 4($sp)
	addi $sp, $sp, 8
	
	jr $ra

crop:	
	addi $sp, $sp, -24	#although not necessary, we will still follow the convention of when modifying $S registers in a functio
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	
	sw $a0, 8($sp)		#for the sake of convention, storing input variables
	sw $a1, 12($sp)		#we wont be storing argument 5 and 6 again since they're already in the stack
	sw $a2, 16($sp)		
	sw $a3, 20($sp)

	sub $t0, $a1, $a0 	#we calculate the width
	addi $s0, $t0, 1	#store it to s0
	
	sub $t0, $a3, $a2	#we calculate the height
	addi $s1, $t0, 1	#store it to s1
	
	mul $t0, $a2, 24	#what well do is calculate the position of a smaller array inside the big array, delimited by the coordinates
	add $t0, $t0, $a0	#here we will calculate the position of the upper left corner. $a2 will be i and $a0 will be j and we do (i * width)+j
	mul $t0, $t0, 4		#we multiply by four because an array slot is a word
	
	lw $t1, 40($sp)		#here we obtain the array address
	add $t2, $t0, $t1	#we add to it the position of the upper corner of the resulting array after crop
	
	lw $t3, 44($sp)		#we get the newbuffer adress
	
	add $t0, $0, $0		#we will now use a loop with a nested inner loop. here we initaite the counter for the outer loop
loopn:
	add $t1, $0, $0		#we initiate the counter for the inner move
	move $t5, $t2		#we move into $t5 the adress of our corner
inern: 
	addi $t1, $t1, 1	#increment counter
	
	lw $t4, 0($t5)		#transfer an int from big array to small array (array to newbuffer)
	sw $t4, 0($t3)
	
	addi $t5, $t5, 4	#advance both pointers
	addi $t3, $t3, 4
	
	blt $t1, $s0, inern	#we loop until weve saved all approriate ints in the row. we then have an even smaller array (the resulting crop) to deal with
	
	addi $t2, $t2, 96	#the left corner of that array will then simply be the first corner + 24
	addi $t0, $t0, 1	#increment outer counter
	blt  $t0, $s1, loopn	#loop until all the appropriate rows are saved
	
	la $t2, headerbuff	#now it is time to create our new header for the cropped array. we load the address into $t2
	
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
	move $t5, $0	#t5 will be our loop counter

newheader:			#part of crop, we will now update the header (i chose to do this in crop rather than writefile for convenience)
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
	
		#although not necessary, we will still follow the convention of when modifying $S registers in a functio
	
	lw $a0, 8($sp)		#unloading input variables
	lw $a1, 12($sp)
	lw $a2, 16($sp)
	lw $a3, 20($sp)	
	
	lw $s0, 4($sp)		#restoring $s registers
	lw $s1, 0($sp)
	addi $sp, $sp, 24	#restoring pointer
	
	jr $ra



#a0=x1
#a1=x2
#a2=y1
#a3=y2
#16($sp)=buffer
#20($sp)=newbuffer that will be made
#Remember to store ALL variables to the stack as you normally would,
#before starting the routine.
#Try to understand the math before coding!
#There are more than 4 arguments, so use the stack accordingly.


writefile:			#we will first convert the cropped array in newbuff back to ascii
		
	addi $sp, $sp, -20
	sw $ra, 16($sp)
	sw $a0, 12($sp)
	sw $a1, 8($sp)
	sw $a2, 4($sp)
	sw $a3, 0($sp)
	
	la $a0, out
	la $a1, newbuff
	# $a2, and $a3 stay the same for converttostr
	jal converttostr
	
	lw $ra, 16($sp)
	lw $a0, 12($sp)
	lw $a1, 8($sp)
	lw $a2, 4($sp)
	lw $a3, 0($sp)
	addi $sp, $sp, 20
	
	#la $a0, out		
	#li $v0, 4
	#syscall

	li $v0, 13	#now its time to write to file.
	#la $a0, output	#we open the file in queston
	li $a1, 1
	li $a2, 0
	syscall
	blt $v0, $0, error	#checking errors
	move $t1, $v0
	
	li $v0, 15		#we first write the header to it
	move $a0, $t1
	la $a1, headerbuff
	li $a2, 12
	syscall
		
	li $v0, 15		#then we write the cropped array
	move $a0, $t1
	la $a1, out
	li $a2, 700
	syscall
	
	li $v0, 16		#we close the file
	move $a0, $t1
	syscall
	
	jr $ra 

converttostr:
	addi $sp, $sp, -8
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	
	move $t1, $a0		#we'll put the string in "out"
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
	mul $t0, $a2, $a3	#we get the total number of numbers in our cropped array
	blt $t2,$t0, loopl	#loop back unless we've done all the numbers
	
	
	lw $a0, 0($sp)
	lw $a1, 4($sp)
	addi $sp, $sp, 8
	
	jr $ra
error:
	la $a0, err		#prints out error message if there's an error
	li $v0, 4
	syscall
	
	jr $ra
	
#slightly different from Q1.
#use as many arguments as you would like to get this to work.
#make sure the header matches the new dimensions!
