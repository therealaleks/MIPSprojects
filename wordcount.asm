#studentName: Alex X. Liu
#studentID: 260867551

# This MIPS program should count the occurence of a word in a text block using MMIO

.data
#any any data you need be after this line 
text: .space 601
word: .space 601
count: .space 4

title: .asciiz "Word count\n"

prompt: .asciiz "Enter the text segment:\n"
prompt2: .asciiz "Enter the search word:\n"
prompt3: .asciiz "press 'e' to enter another segment of text or 'q' to quit.\n"

output1: .asciiz "The word '"
output2: .asciiz "' occured "
output3: .asciiz " time(s).\n"

tab: .asciiz "	"

	.text
	.globl main

main:	# all subroutines you create must come below "main"
	la $a0, title
	jal stdout
bido:			#this is the point we go back to when we need to repeat the process
	
	jal input	#first we get the input
	
	jal getword	#then we get the word
	
	jal getcount	#then we get the number of words
	
	jal output	#then we output that number
	
	jal redo	#then we give the option to do another search or quit

input:			#input function
	
	addi $sp, $sp, -4	#we save $ra into the stack as we are about to call a couple of functions
	sw $ra, 0($sp)
	
	la $a0, prompt		#we print out prompt 
	jal stdout
	
	
	la $a0, text		#then we get the inputed text and store it in text
	jal stdin

	
	la $a0, tab		#we print out a tab to echo what was inputed
	jal stdout

	
	la $a0, text		#we print out the input
	jal stdout
	
	
	lw $ra, 0($sp)		#restore $ra and jump back
	addi $sp, $sp, 4
	
	jr $ra
	
	
getword:			#function to obtain the search word
	addi $sp, $sp, -4	#save $ra
	sw $ra, 0($sp)
	
	la $a0, prompt2		#print out prompt2
	jal stdout

	la $a0, word		#get input for the search word and store it in word
	jal stdin

	la $a0, tab		#print out tab before echoing the input
	jal stdout

	la $a0, word		#print out the input
	jal stdout
	
	lw $ra, 0($sp)		#restore $ra and jump back
	addi $sp, $sp, 4

	jr $ra

getcount:
	move $t0, $0	#init counter for number of words
	la $t2, text
boi:
	la $t4, word		#get word adress
loop:
	lb $t3, 0($t2)		#we take a letter from text
	addi $t2, $t2, 1
	beq $t3, 10, end	#if its "\n" then we are done
	
	blt $t3, 48, boi	#we check if its a letter
	bgt $t3, 122, boi	#basically, we work our way up the ascii table by process of elimination
	
	blt $t3, 58, checkem	#if its a valid letter, then we check if its part of our word in "checkem"
	blt $t3, 65, boi	#if its not a valid letter then boi why tf are you wasting my time so we go back to looping through the tet
	
	ble $t3, 90, checkem
	blt $t3, 97, boi
checkem:
	lb $t5, 0($t4)		#we obtain a letter from our word
	lb $t6, 1($t4)
	addi $t4, $t4, 1	#advance word counter
	
	bne $t3, $t5, skip	#otherwise if its not equal, we skip to the next word
	beq $t6, 10, next	#if the next char is newline of our word, then we just check if the next letter of our current word being checked is valid. if it is, then it does not match
	j loop
next:				#here we check if the next letter (of our text block) is valid. 
	lb $t5, 0($t2)
	
	blt $t5, 48, addem	#if the next letter is invalid, then that means we've found an occurence of our word, so we add 1 to our counter in "addem"
	bgt $t5, 122, addem
	
	blt $t3, 58, boi	#if the next letter is valid, then that means that this word we're looking at is longer than our search word so boi, we go back to looping through our text block
	blt $t3, 65, addem
	
	ble $t5, 90, boi	#if it is, then thats not the word were looking for, we refresh the word adress
	blt $t5, 97, addem	#otherwise we add 1 to our counter
	j boi			#if we reach this line, then that means the next letter is valid, we go to boi
addem:
	addi $t0, $t0, 1	#here we add 1 to our word counter
	j boi
	
skip:			#basically, here, we loop through the letters until we reach a non alphanumerical char signifying that the word to be skipped has ended
	lb $t3, 0($t2)		#then we go back to our procedure
	addi $t2, $t2, 1
	beq $t3, 10, end	#if its "\n" then we are done
	
	blt $t3, 48, boi	#we check if its a valid letter
	bgt $t3, 122, boi
	
	blt $t3, 58, skip
	blt $t3, 65, addem
	
	ble $t3, 90, skip	
	blt $t3, 97, boi
	j skip
end:				#this is where we arrive once were done
	#li $v0, 1
	#move $a0, $t0
	#syscall 
	
	move $v0, $t0		#return value is the number of occurences, although as it turned out, i ended up not using it
	
	la $t2, count		#instead, we'll just convert that number to a string and save it into "count"
	blt $t0, 100, twodig	#to convert, we account for three cases: 3 digits, 2 digits and 1 digits. For a text of max 600 characters, its impossible to have a 4 digit number of any word
	addi $t3, $0, 100	#here, we're processing three digits
	div $t0, $t3		#we just take count(int) mod 100
	mflo $t3		#mflo is the first digit
	mfhi $t0		#mfhi is the two digit int remainder after we remove the first digit
	
	addi $t3, $t3, 48	#we convert the first digit into a char and add it to "count"
	sb $t3, 0($t2)
	addi $t2, $t2, 1	#increment pointer of "count"
	
	bgt $t0, 9, twodig	#here we account for the edge case of if the three digit number is of the form X0X
	addi $t3, $0, 48	#ie the remainder is only 1 digit (or 0 digit)
	sb $t3, 0($t2)		#so if its only 1 digit, then we add a 0 as our second digit and move on
	addi $t2, $t2, 1	#increment pointer
twodig:				
	blt $t0, 10, onedig	#we check if the count is one digit or two digit. if 1, we go straight to "onedig" if 2, we proceed
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
	
	jr $ra

output:				#basically we print out in succession the pieces of our message indicating the word count
	addi $sp, $sp, -8	#we save into the stack $ra, also $a0, because originally i needed to do that. not anymore, but i dont want to change it just in case
	sw $a0, 4($sp)
	sw $ra, 0($sp)
	
	la $a0, output1		#we print out output1
	jal stdout
	
	la $a0, word		#we print out content of word, but without the newline
	jal stdout2
	
	la $a0, output2		#we print out output2
	jal stdout
	
	#li $v0, 1
	#lw $a0, 4($sp)
	#syscall 
	
	la $a0, count		#we print out count
	jal stdout
	
	la $a0, output3		#print output3
	jal stdout

	lw $ra, 0($sp)		#restore $ra
	lw $a0, 4($sp)
	addi $sp, $sp, 8
	
	jr $ra			#jump back
	

stdout:				#this is our print function
	move $t5, $a0		#we print out the content pointed to by $a0
	lui $t0, 0xffff 
wait1:	lw $t1, 8($t0)		#poll waiting to load words into output
	lb $t2, 0($t5) 		#load byte to be printed
	andi $t1, $t1, 0x0001
	beq $t1, $0, wait1
	sw $t2, 12($t0)		#load byte into output
	addi $t5, $t5, 1	#increment pointer
	bne $t2, $0, wait1	#if we havent reached null, we continue polling
	
	jr $ra			#jump back
	
stdout2:			#this is our second version of the print function. basically, this one doesnt print the newline at the end of the search word
	move $t5, $a0		#so same thing as stdout
	lui $t0, 0xffff 
wait11:	lw $t1, 8($t0)
	lb $t2, 0($t5) 
	beq $t2, 10, nope	#but once we reach the newline, we end the funciton emediately
	andi $t1, $t1, 0x0001
	beq $t1, $0, wait11
	sw $t2, 12($t0)
	addi $t5, $t5, 1
	bne $t2, $0, wait11
nope:	
	jr $ra

stdin:				#here is our input funciton
	move $t5, $a0		#we store the input into what $a0 points to
	lui $t0, 0xffff 
wait2:	lw $t1, 0($t0) 		#poll waiting for inputs
	andi $t1, $t1, 0x0001
	beq $t1, $0, wait2
	lw $t2, 4($t0)		#obtain input
	sb $t2, 0($t5)		#save it in the desired location
	addi $t5, $t5, 1	#increment pointer
	bne $t2, 10, wait2	#if we dont detect a newline (or enter) we continue polling
	sb $0, 0($t5)		#otherwise we save an extra null to mark the end of a string
	
	jr $ra			#and we jump back

redo:				#here is the function that offers to either quit or do another search
	la $a0, prompt3		#we print out the appropriate prompt
	jal stdout
	
	lui $t0, 0xffff 
wait3:	lw $t1, 0($t0) 		#poll waiting for input
	andi $t1, $t1, 0x0001
	beq $t1, $0, wait3
	lw $t2, 4($t0)		#obtain input
	
	beq $t2, 101, bido	#if its e, we go back to main, more specifically to bido, and repeat the whole process
	bne $t2, 113, wait3	#if its not q, and not e, then we continue polling
	
	li $v0, 10		#if its q, then we quit
	syscall
