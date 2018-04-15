### Gabriel Rebacz 4I1
### ARKO projekt MIPS
### filtr srednia
######################################
.data

ask_input_msg:			.asciiz	"Input file name:\n"
header: 			.space   54 	
input_file:			.space	128 	
ask_mask:   		 	.asciiz "Insert mask size:\n"
ask_output_msg:			.asciiz	"Output file name:\n"
filter_prompt:			.asciiz "\nChoose filter:\n1. lowpass\n2. highpass\n"
input_err:			.asciiz "\nInput image not found! Restarting...\n\n"
output_err: 			.asciiz "\nOutput file error! Restarting...\n"
output_file: 			.space  128	
buff:				.space	900
buff_out:			.space  900
.align 2
endinbuf: .space 4
endoutbuf: .space 4
maskpow: .space 4
outdesc: .space 4

.text
main:

	#print ask_input_msg string
	li $v0, 4	# syscall 4, print string
	la $a0, ask_input_msg # load ask_input_msg string
	syscall
	
	#read filename
	li $v0, 8	# syscall 8, read string
	la $a0, input_file # store string in input_file
	li $a1, 128		
	syscall
	
	#print ask_output_string
	li $v0, 4	# syscall 4, print string
	la $a0, ask_output_msg# load ask_input_msg string
	syscall
	
	#read output name
	li $v0, 8	# syscall 8, read string
	la $a0, output_file# store string in output_file
	li $a1, 128		
	syscall
	
	# remove trailing newline
	li  $t0, '\n'		
	li  $t1, 128# length of the output_file
	li  $t2, 0	

	#print ask_output_string
	li $v0, 4	# syscall 4, print string
	la $a0, ask_mask# load ask_input_msg string
	syscall

	li $v0, 5 #read int
	syscall
	move $s5, $v0
		
		
out_remove_newline:
	beqz	$t1, newline_loop_init		# if end of string, jump to remove newline from input string
	subu	$t1, $t1, 1			# decrement the index
	lb	$t2, output_file($t1)		# load the character at current index position
	bne	$t2, $t0, out_remove_newline	# if current character != '\n', jump to loop beginning
	li	$t0, 0			
	sb	$t0, output_file($t1) 
	
newline_loop_init:
	li	$t0, '\n'	
	li	$t1, 128# length of the input_file
	li	$t2, 0		
	
newline_loop:
	beqz	$t1, newline_loop_end	# if end of string, jump to loop end
	subu	$t1, $t1, 1			# decrement the index
	lb	$t2, input_file($t1)	# load the character at current index position
	bne	$t2, $t0, newline_loop	# if current character != '\n', jump to loop beginning
	li	$t0, 0			# else store null character
	sb	$t0, input_file($t1) # and overwrite newline character with null
	
newline_loop_end:
	
	#open input file
	li	$v0, 13		# syscall 13, open file
	la	$a0, input_file	# load filename address
	li 	$a1, 0		# read flag
	li	$a2, 0		# mode 0
	syscall
	bltz	$v0, inputFileErrorHandler	#if $v0=-1, there was a descriptor error; go to handler. 
	move	$s0, $v0	# save file descriptor
	
	#read header
	li	$v0, 14		# syscall 14, read from file
	move	$a0, $s0	# load file descriptor
	la	$a1, header	# load address to store data
	li	$a2, 54		# read 54 bytes
	syscall
	
	
	#save the width
	lw $s7, header+18
	mul $s7, $s7, 3
	li $t8, 4
	div $s7, $t8
	mfhi $t5
	sub $t5, $t8, $t5
	beq $t5, 4, zero_padding

	
not_zero_padding:
	addu $s7, $s7, $t5
	
zero_padding:

	lw $s4, header+22  #save height
	
	lw $s1, header+34	# store the size of the data section of the image
	
########################################HER
	
	
	#read image data	
	li $v0, 14		# read from file
	move $a0, $s0	# load file descriptor
	la $a1, buff	# load base address of array
	li $a2, 900	# load size of data section
	syscall
	la $s2, buff
	#close file NO!!

	la $s3, buff
	la  $s4, buff_out  #load the address of the buff into $s3
	
	addi $s4, $s4, 899 #calculate end adresses of buffers, after last bit #@!
	addi $s3, $s3, 899 #@!
	
	sw $s4, endoutbuf
	sw $s3 endinbuf

	mul $t7, $s5, $s5
	sw $t7, maskpow

	la $s3, buff
	la  $s4, buff_out  #load the address of the buff into $s3
	
	#open output file
	li $v0, 13
	la $a0, output_file
	li $a1, 1		
	li $a2, 0
	syscall
	sw $v0, outdesc	# store out file descriptor in memory
	move $t1, $v0	# copy file descriptor
	
	#confirm that file exists 
	bltz $t1, outputFileErrorHandler

	li $v0, 15	
	move $a0, $t1
	la $a1, header
	addi $a2, $zero,54
	syscall
	

	
#############################################################################

init_loop:
	move $s6,$zero #init loop count
	la $t1, buff

	addi $s2, $s5, -1 #calculate margin
	div $s2, $s2, 2

	addi $s4, $s4, 1 #calculate last line of margin
	sub $s4, $s4, $s2
	
	addi $s6, $s7, 1 #calculate right margin
	sub $s6, $s6, $s2
	
	addiu $s6, $s2, -1

###############
	lw $t1, outdesc
	addi $t2, $s2, -1
	li $v0, 15	
	move  $a0, $t1
	la $a1, header
	addu   $a2, $zero,$t2
	syscall
################
loop:

check_pixel:
	move $t8, $s2 
	move $t5, $s3
	la $t2, buff


	mul $t8, $s7, $s2 #moving to left up
	sub $t5, $t5, $t8
	mul $t8, $s2, 3
	sub $t5, $t5, $t8 
	
	blt $t5, $t2, ignore_pixel	
	
	move $t5, $s3 
	
	
	mul $t8, $s7, $s2 #how many i have to add width }moving right down
	addu $t5, $t5, $t8 #adding width
	mul $t8, $s2, 3 #how many i have to move right
	addu $t5, $t5, $t8
	
	
	addu $t2, $t2, 899
	bgt $t5, $t3, ignore_pixel
	
###################CALCULATE PIXEL@#!@#!@#!@#
calculate_pixel:
	li $t7, 0 #pixel value
	li $t6, 0
	li $t3, 0

	move $t8, $s2
	move $t5, $s3
	
	mul $t8, $s7, $s2 #moving left up
	sub $t5, $t5, $t8
	mul $t8, $s2, 3
	sub $t5, $t5, $t8 
	
column_loop_init:

	li $t6, 0
	
column_loop:
	lb $t4, ($t5)
	sll $t4, $t4, 24##
	srl $t4, $t4, 24##
	add $t7, $t7, $t4 #add up to sum
	addi $t6, $t6, 1
	addi $t5, $t5, 3 #move to next pixel in that row
	bne $t6, $s5, column_loop #check if we ended that row
	
row_loop:
	addi $t3, $t3, 1 #we'll move to next row and start on left side of it
	beq $t3, $s5, last_pixel

	add $t5, $t5, $s7
	move $t8, $s5
	
	mul $t8, $s5, 3
	sub $t5, $t5, $t8
	j column_loop_init

last_pixel:
	lw $t3, maskpow #load maskpow
	div $t7, $t7, $t3 #divide by mask n^2
	
j normalize

####################CALCULATE PIXEL!@#!@#!@#!@#!@#


	
ignore_pixel:
	lb $t7, ($s3) #load directly that pixel
	j store_pixel

normalize:
	bge $t7, 0, continue1
	li  $t7, 0
continue1:
	ble  $t7, 255, continue2
	li  $t7, 255
continue2:


store_pixel:
	sb $t7, ($s4)
	addi $s3, $s3, 1 #+1 all adresses and loop count
	addi $s4, $s4, 1
	addi $s6, $s6, 1
	
	beq $s6, $s1, end_of_input
	
##########BUFFS
check_in_buf:

	move $t8, $s2 #getting to right down pixel
	move $t5, $s3 
	
	
	mul $t8, $s7, $s2 #how many i have to add width }moving right down
	addu $t5, $t5, $t8 #adding width
	mul $t8, $s2, 3 #how many i have to move right
	addu $t5, $t5, $t8


	lw $t3, endinbuf #checking if we can calculate next pixel
	#addi $t5, $t5, -2 #if i'm sure we're 3 pixels behind last mask boundary so we go back by 2 to calculate next furthest adress
	blt $t5, $t3, check_out_buf
	
#INBUF
reload_inbuf:
	
	move $t5, $s3 #since when we have to preserve buffer

			
	mul $t8, $s7, $s2 #moving to left up
	sub $t5, $t5, $t8
	mul $t8, $s2, 3
	sub $t5, $t5, $t8 
	
	sub $t6, $s3, $t5 #calculating difference between first saved pixel and actual pixel
	la $s3, buff
	addu $s3, $s3, $t6 #calculating new adress of actual pixel after reloading buffer[i move important data to the beggining and then load rest]
	la $t2, buff
	lw $t4, endinbuf
	shift_data:
		bgt $t5, $t4, shift_end #end shifting when read position exceed buffer
		lb $t3, ($t5)
		sb $t3, ($t2)
		addi $t2, $t2, 1
		addi $t5, $t5 ,1
	j shift_data
		
	shift_end:
		
	sub $t7, $t4, $t2 #calculating how many pixels i can load to free space of buffer
	addi $t7, $t7, 1#@!
	#read image data	
	li		$v0, 14		# read from file
	move		$a0, $s0	# load file descriptor
	move		$a1, $t2	# load base address of array
	move		$a2, $t7	# load size of data section
	syscall
	
	
#INBUF

check_out_buf:
	
	lw $t3, endoutbuf#checking if we're not on the end of out buffer
	ble $s4, $t3, loop

store_and_reload_outbuf:

	#write to output file
	li $v0, 15	
	lw $t3, outdesc	
	move  $a0, $t3
	la $a1, buff_out
	li $a2, 900
	syscall
	la $s4, buff_out
	j loop

##############BUFFS	

end_of_input:
	la $t2, buff_out
	sub $t3, $s4, $t2 #how many pixels are information pixels
	##nie zapisuje prawdopodobnie
	
	#write to output file
	li $v0, 15	
	lw $t5, outdesc	
	move  $a0, $t5
	la $a1, buff_out
	move $a2, $t3
	syscall
	
	la $t8, buff_out
	sub $t3, $t3, $s7
	addu $t8, $t8, $t3
	
	li $v0, 15	
	lw $t5, outdesc	
	move  $a0, $t5
	move $a1, $t8
	move $a2, $s7
	syscall
	
	
	#close files
	move $a0, $s0		# move the file descriptor into argument register
	li $v0, 16			# syscall 16, close file
	syscall

	lw $s0, outdesc
	move $a0, $s0		# move the file descriptor into argument register
	li $v0, 16			# syscall 16, close file
	syscall
	la  $s3, buff  #load the address of the buff into $s3


leave:
	li  $v0, 10
	syscall
	
	
inputFileErrorHandler:
	#print file input error message
	li $v0, 4			# syscall 4, print string
	la $a0, input_err		# print the message
	syscall
	j		main

outputFileErrorHandler:
	#print file output error message
	li $v0, 4			# syscall 4, print string
	la $a0, output_err	# print the message
	syscall
	j main
