#name:
#studentID:

.data

#Must use accurate file path.
#file paths in MARS are relative to the mars.jar file.
# if you put mars.jar in the same folder as test2.txt and your.asm, input: should work.
input:	.asciiz "C:\\Users\\DobyDobd\\Desktop\\New folder\\test1.txt" #used as input
output:	.asciiz "C:\\Users\\DobyDobd\\Desktop\\New folder\\copy.pgm"	#used as output

buffer:  .space 2048		# buffer for upto 2048 bytes

header: .asciiz "P2\n24 7\n15\n"
err: 	.asciiz "error opening file"

	.text
	.globl main

main:	la $a0,input		#readfile takes $a0 as input
	jal readfile

	la $a0, output		#writefile will take $a0 as file location
	la $a1,buffer		#$a1 takes location of what we wish to write.
	jal writefile

	li $v0,10		# exit
	syscall

readfile:
	li $v0, 13	#open file
	li $a1, 0
	li $a2, 0
	syscall
	blt $v0, $0, error	#check for errors
	move $t1, $v0
	
	li $v0, 14		#read the file into the buffer
	move $a0, $t1
	la $a1, buffer
	li $a2, 2048
	syscall
	blt $v0, $0, error	#check for errors
	
	la $a0, buffer		#print buffer
	li $v0, 4
	syscall
	
	li $v0, 16		#close file
	move $a0, $t1
	syscall
	
	blt $v0, $0, error	#check for errors
	jr $ra
	
writefile: 
	move $t0, $a1		#save adress of buffer

	li $v0, 13		#open file in read/write
	li $a1, 1
	li $a2, 0
	syscall
	blt $v0, $0, error	#check for erros
	move $t1, $v0		#save file descriptor
	
	li $v0, 15		#write the header first
	move $a0, $t1
	la $a1, header
	li $a2, 11
	syscall
	
	li $v0, 15		#then the buffer
	move $a0, $t1
	move $a1, $t0
	li $a2, 2048
	syscall
	
	li $v0, 16		#close file
	move $a0, $t1
	syscall
	
	jr $ra	
	
error:				#prints error message if called upon
	la $a0, err		
	li $v0, 4
	syscall
	
	jr $ra
	

	
#Open the file to be read,using $a0
#Conduct error check, to see if file exists

# You will want to keep track of the file descriptor*

# read from file
# use correct file descriptor, and point to buffer
# hardcode maximum number of chars to read
# read from file

# address of the ascii string you just read is returned in $v1.
# the text of the string is in buffer
# close the file (make sure to check for errors)



#open file to be written to, using $a0.
#write the specified characters as seen on assignment PDF:
#P2
#24 7
#15
#write the content stored at the address in $a1.
#close the file (make sure to check for errors)
