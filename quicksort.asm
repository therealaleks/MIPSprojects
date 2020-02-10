#studentName:
#studentID:

# This MIPS program should sort a set of numbers using the quicksort algorithm
# The program should use MMIO

.data
#any any data you need be after this line 
.align 2
array:	.space 40
buffer: .space 2
output: .space 200

prompt1: .asciiz "Welcome to QuickSort\n"
prompt2: .asciiz "\nThe sorted array is: "
prompt3: .asciiz "The array is re-initialized\n"

newline: .asciiz "\n"
	.text
	.globl main

main:	# all subroutines you create must come below "main"
	#move $t5, $a0
	la $a0, prompt1		#print welcome message
	jal stdout
	la $t9, buffer		#get adress for the buffer, where we temporarily store entered digits of a number
	la $t8, array		#get adress of the array
	move $t7, $0		#initialize the counter for number of elements in array
start:				#this is the point where we're just polling for inputs, its the point we always go back to after finishing anything
	lui $t0, 0xffff 	#we poll waiting for inputs
wait:	lw $t1, 0($t0) 
	andi $t1, $t1, 0x0001
	beq $t1, $0, wait
	
	lw $t2, 4($t0)		#get the input
	#sb $t2, 0($t5)
	
	beq $t2, 99, clear	#if its <c>, we go to clear
	
	beq $t2, 115, sort	#if its <s>, we go to sort
	
	beq $t2, 113, quit	#if its <q>, we go to quit
	
	beq $t2, 32, wait1	#if its space we move forward
	blt $t2, 48, wait	#if its not a number, we continue polling
	bgt $t2, 57, wait
				#otherwise we move forward
wait1:	lw $t1, 8($t0)		#here we poll waiting to echo what we entered
	andi $t1, $t1, 0x0001
	beq $t1, $0, wait1
	
	sw $t2, 12($t0)		#echo the entered char
	
	beq $t2, 32, addint	#if its a space, then that means we need to add whatever is in the buffer, into the array, as a space signifies the end of a number
	
	sb $t2, 0($t9)		#otherwise we add the digit to our buffer 
	addi $t9, $t9, 1	#and increment the pointer
	
	j start			#go back to start to acquire the next digit
	
addint:				#so here, we're transfering the number in the buffer to the array
	la $t0, buffer		#first we find out how many digits are in there. we do this by substracting the current buffer pointer from the original one. 
	sub $t0, $t9, $t0	#this equals 1 if theres 1 digit, 2 if theres two digit, as we increment it everytime a digit is added to the buffer
	la $t9, buffer		#here we reset the buffer pointer
	beq $t0, 1, onedigg	#if its one digit, we go to onedigg, otherwise its two digits and we just continue
	
	lb $t0, 0($t9)		#here is for two digit case
	subi $t0, $t0, 48	#we obtain the byte of the first digit, convert it to an int by substracting 48
	mul $t0, $t0, 10	#multiply it by 10
	lb $t1, 1($t9)		#obtain second digit
	subi $t1, $t1, 48	#convert it to int
	add $t0, $t0, $t1	#add it to the first digit multiplied by 10
	
	sw $t0, 0($t8) 		#and now we have converted the two digit number to an it, so we save it into the array
	addi $t8, $t8, 4	#increment array pointer
	
	addi $t7, $t7, 1	#increment counter of array elements
	
	j start			#go back to start to continue polling for inputs
onedigg:			#here we process the 1 digit case
	lb $t0, 0($t9)		#we just obtain the digit
	subi $t0, $t0, 48	#convert to int
		
	sw $t0, 0($t8)		#save into array
	addi $t8, $t8, 4	#increment pointer
	
	addi $t7, $t7, 1	#increment counter
	
	j start			#back to polling for inputs
	
clear:	
	move $t0, $0		#initialize a loop counter
	la $t1, array		#obtain adress of the array
loop:	
	sw $0, 0($t1)		#we essentially loop through the array and replace everything with 0
	addi $t1, $t1, 4
	addi $t0, $t0, 1
	blt $t0, 10, loop
	
	la $a0, prompt3		#print out the array has been reinited message
	jal stdout
	
	la $t8, array		#reset array pointer
	move $t7, $0		#reset array element counter
	
	move $t0, $0		#now we're also going to clear the ascii conversion of the array, so we init a loop counter again
	la $t1, output		#get adress of the buffer
pool:
	sb $0, 0($t1)		#loop through and replace everything with 0
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	blt $t0, 200, pool
	
	j start			#go back to polling for inputs
	
stdout:				#function to print stuff using mmIO
	move $t3, $a0		#$a0 is the adress of what we wish to print
	lui $t0, 0xffff 	#we poll waiting to load outputs
wait2:	lw $t1, 8($t0)		
	lb $t2, 0($t3) 		#get the output from the adress
	andi $t1, $t1, 0x0001
	beq $t1, $0, wait2	
	sw $t2, 12($t0)		#load the output
	addi $t3, $t3, 1	#increment  adress
	bne $t2, $0, wait2	#if we havent reached null, we continue polling
	
	jr $ra			#otherwise we jump back
	
sort:				#sort function
	la $a0, prompt2		#first we print out the message of your sorted array is:....
	jal stdout
	
	beq $t7, $0, null	#if there are no elements in our array, we go to null
	
	la $a0, array		#otherwise, we load $a0 as the adress of lo and $a1 as the adress of hi
	mul $t0, $t7, 4		#we get the adress of hi by adding the number of elements multiplied by 4 (since were dealing with words)
	add $a1, $a0, $t0	#to the adress of lo, which is just the adress of the array
	addi $a1, $a1, -4	#we take out 4 so that its pointing at the last element, rather than the free spot after it
	jal quicksort		#we call quicksort and dont save anything into the stack since we dont need to
	
	
	
	la $a0, output		#then once the array is sorted, we convert it to a string and put it in output
	la $a1, array
	jal converttostr
null:				#the null procedure is to skip all the sorting and conversion
	la $a0, output		#here we print out the string in output
	jal stdout
	
	la $a0, newline		#print a newline
	jal stdout
	
	j start			#go back to polling for inputs
	
quicksort:
	addi $sp, $sp, -4	#we save $v0 into the stack since its somethinbg we need to preserve but that gets changed everytime we 
	sw $v0, 0($sp)		#we recursively call this function
	ble $a1, $a0, return	#if hi <= lo, we just return
	
	addi $sp, $sp, -12	#we load everything into stack to call partition
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	sw $ra, 8($sp)
	
	move $a0, $a0		#$a0 = lo, $a1 = hi
	move $a1, $a1
	
	jal partition		#this returns the adress of the pivot
	
	lw $a0, 0($sp)
	lw $a1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	
	addi $sp, $sp, -12	#we load everything into the stack to call quicksort
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	sw $ra, 8($sp)
	
	move $a0, $a0		#we call quicksort
	addi $a1, $v0, -4	#$a0 = lo, $a1 = adress of pivot - 4 (-4 since we're dealing with words)
	
	jal quicksort
	
	lw $a0, 0($sp)
	lw $a1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	
	addi $sp, $sp, -12	#same thing for the other partition
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	sw $ra, 8($sp)
	
	move $a1, $a1		#$a1 = hi, $a0 = adress of pivot + 4
	addi $a0, $v0, 4
	
	jal quicksort
	
	lw $a0, 0($sp)
	lw $a1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	
return:
	lw $v0, 0($sp)		#as we return, we restore $v0
	addi $sp, $sp, 4	#we restore stack pointer
			
	jr $ra			#jump back
	
partition:				#partition function
					#$a0 = adress of lo , $a1 = adress of hi
	move $t0, $a0	#p_pos
	lw $t1, 0($a0)	#pivot
	move $t2, $0	#loop counter (i)
loop1: 
	add $t3, $a0, $t2		
	lw $t3, 0($t3)			#$t3 = a[i] (by adding i to lo)
	
	bge $t3, $t1, loopback		#if a[i] >= pivot, then we loop back without doing anything but incremeting i
	
	addi $t0, $t0, 4		#otherwise, we increment p_pos (by 4 since we're dealing with words)
	
	addi $sp, $sp, -20		#we save all the arguments, $ra and $t0, $t1 because we still need those values
	sw $a0, 0($sp)			#and we call swap on p_pos and a[i[
	sw $a1, 4($sp)
	sw $ra, 8($sp)
	sw $t0, 12($sp)
	sw $t1, 16($sp)
	
	add $a0, $a0, $t2		#$a0 = a[i}, obtained same as before
	move $a1, $t0 			#$a1 = p_pos
	jal swap
	
	lw $a0, 0($sp)			#load everything back
	lw $a1, 4($sp)
	lw $ra, 8($sp)
	lw $t0, 12($sp)
	lw $t1, 16($sp)
	addi $sp, $sp, 20
loopback:				#then here is the loopback sequence
	addi $t2, $t2, 4		#increment i (by 4 since were dealing with words)
	add $t3, $t2, $a0		#obtain a[i]
	ble $t3, $a1, loop1		#we loop as long as a[i]<hi
	
	addi $sp, $sp, -20		#after the loop, we save our needed values same as before and call swap
	sw $a0, 0($sp)			#on lo and p_pos
	sw $a1, 4($sp)
	sw $ra, 8($sp)
	sw $t0, 12($sp)
	sw $t1, 16($sp)
	
	move $a0, $a0
	move $a1, $t0
	jal swap
	
	lw $a0, 0($sp)
	lw $a1, 4($sp)
	lw $ra, 8($sp)
	lw $t0, 12($sp)
	lw $t1, 16($sp)
	addi $sp, $sp, 20
	
	move $v0, $t0			#we return p_pos
	jr $ra				#jump back

swap:			#swap function. we literally just load values from two adresses and save them back into switched adresses
	lw $t0, 0($a0)
	lw $t1, 0($a1)
	
	sw $t0, 0($a1)
	sw $t1, 0($a0)

	jr $ra

converttostr:			#here we convert the array to a string
	addi $sp, $sp, -8
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	
	move $t1, $a0		#we'll put the string in output
	add $t2, $0, $0		#initiating counters
	addi $t3, $0, 10	#10, well use the number enough times
	move $t6, $a1		#obtain adress of array
loopstr:
	lw $t0, 0($t6)		#we load an int from newbuff
	addi $t6, $t6, 4	#increment pointer
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
	
	blt $t2,$t7, loopstr	#loop back unless we've done all the numbers
	
	sb $0, 0($t1)		#add a null
		
	lw $a0, 0($sp)
	lw $a1, 4($sp)
	addi $sp, $sp, 8
	
	jr $ra

quit:
	li $v0, 10
	syscall
