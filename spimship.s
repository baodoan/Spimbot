# syscall constants
SBRK = 9

.data


words:
	.word 0

words_end:
	.word words


.align 2
planet_info: .space 32
dust_max: .space 4 
dust_max_sector: .space 4	
scan_sector: .space 256
scan_complete: .space 4

#data for euclidean.s
three:	.float	3.0
five:	.float	5.0
PI:	.float	3.141592
F180:	.float  180.0

# movement memory-mapped I/O
VELOCITY            = 0xffff0010
ANGLE               = 0xffff0014
ANGLE_CONTROL       = 0xffff0018

# coordinates memory-mapped I/O
BOT_X               = 0xffff0020
BOT_Y               = 0xffff0024

# planet memory-mapped I/O
PLANETS_REQUEST     = 0xffff1014

# scanning memory-mapped I/O
SCAN_REQUEST        = 0xffff1010
SCAN_SECTOR         = 0xffff101c

# gravity memory-mapped I/O
FIELD_STRENGTH      = 0xffff1100

# bot info memory-mapped I/O
SCORES_REQUEST      = 0xffff1018
ENERGY              = 0xffff1104

# debugging memory-mapped I/O
PRINT_INT           = 0xffff0080

# interrupt constants
SCAN_MASK           = 0x2000
SCAN_ACKNOWLEDGE    = 0xffff1204
ENERGY_MASK         = 0x4000
ENERGY_ACKNOWLEDGE  = 0xffff1208

# puzzle interface locations 
SPIMBOT_PUZZLE_REQUEST 		= 0xffff1000 
SPIMBOT_SOLVE_REQUEST 		= 0xffff1004 
SPIMBOT_LEXICON_REQUEST 	= 0xffff1008 

# I/O used in competitive scenario 
INTERFERENCE_MASK 	= 0x8000 
INTERFERENCE_ACK 	= 0xffff13048 
SPACESHIP_FIELD_CNT  	= 0xffff110c 


# global variables

scan_done:
	.word 0

dust:
	.space 256

planets:
	.space 32

lexicon:
	.space 1000

puzzle_struct:
	.space 4112

puzzle_solution:
	.space 1024

num_rows:
	.space 4

num_columns:
	.space 4

current_position:
	.space 4


.text

# PUZZLE  #####################################################
#
# 1) request the lexicon (the set of words) used in the puzzles
# 2) request a puzzle
# 3) submit a solution to a puzzle
#
##  struct lexicon {
#	int lexicon_size;
#	char* lexical_items[lexicon_size];
#	}

## struct puzzle {
#   	int rows;
#   	int columns;
#	char puzzle[rows * columns];
#	}

## struct solution {
#	int num_words;
#	int position[2* num_words];
#

##################
requesting_puzzle:
	li 	$t0 0
	sw 	$t0 VELOCITY
	sub	$sp, $sp, 36
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)		# s4 = puzzle_rows
	sw	$s5, 24($sp)		# s5 = puzzle_columns
	sw	$s6, 28($sp)		# s6 = puzzle size 
	sw	$s7, 32($sp)		# i
	
	la 	$t3, puzzle_solution
	
	la 	$s0, lexicon				# struct lexicon 
	sw 	$s0, SPIMBOT_LEXICON_REQUEST 		# $s0
	
	la 	$s1, puzzle_struct			# $s1
	sw 	$s1, SPIMBOT_PUZZLE_REQUEST
		

	la	$t0, puzzle_solution
	add	$t1, $t0, 4
	sw	$t1, current_position			# initial current solution = 4 offset from puzzle_solution


	##sw	$s1, PRINT_INT		
	
	#lw 	$t1, 8($s1)
	#sw 	$t1, PRINT_INT
	#lbu 	$t1, 0($t1)

	#sw 	$t1, PRINT_INT
	

	
solving_puzzle:
		

	lw	$s2, 0($s0)			# lexicon_size		
	li	$s7, 0				# i
	
	lw	$s4, 0($s1)			# rows
	lw	$s5, 4($s1)			# columns
	mul	$s6, $s4, $s5			# puzzle_size = rows * columns	


	sw	$s4, num_rows
	sw	$s5, num_columns


puzzle_loop:
	##bge	$s7, $s2, done_solving		# i <= lexicon_size
	##mul	$t0, $s7 ,4 			# i*4

	add	$t1, $s0, 4			# &char*lexicon[0]
		

	### add	$s3, $t1, $t0			# &char*lexicon[i]


	move 	$a0, $t1		# $a0 = &char* lexicon[]
	move 	$a1, $s2		# $a1 = lexicon_size

	jal	find_words		# find_words(const char** dictionary, int dictionary_size)
	
	
done_solving:
	
	
	la  $a0, puzzle_solution
	sw  $a0, SPIMBOT_SOLVE_REQUEST	 # if the solution Right, ENERGY should gain here
	la  $a0, puzzle_solution
	lw  $a0, 0($a0)			# numwords
	sw  $a0  PRINT_INT 	
    	lw  $t0, ENERGY         	 # current ENERGY
    	sw  $t0, PRINT_INT($zero)	 
	##j  continue
li $t1, 5
sw $t1, VELOCITY
j back_to_planet





## void
## find_words(const char** dictionary, int dictionary_size) {
##     for (int i = 0; i < num_rows; i++) {
##         for (int j = 0; j < num_columns; j++) {
##             int start = i * num_columns + j;
##             int end = (i + 1) * num_columns - 1;
## 
##             for (int k = 0; k < dictionary_size; k++) {
##                 const char* word = dictionary[k];
##                 int word_end = horiz_strncmp(word, start, end);
##                 if (word_end > 0) {
##                     record_word(word, start, word_end);
##                 }
## 
##                 word_end = vert_strncmp(word, i, j);
##                 if (word_end > 0) {
##                     record_word(word, start, word_end);
##                 }
## 
##             }
##         }
##     }
## }



######################### FIND_WORDS ##################
find_words:
	sub	$sp, $sp, 40
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)
	sw	$s6, 28($sp)
	sw	$s7, 32($sp)
	sw	$s8, 36($sp)
findwordsp2:

	move	$s0, $a0		# dictionary
	move	$s1, $a1		# dictionary_size
	lw	$s2, num_columns
	li	$s3, 0			# i = 0

fw_i:
	lw	$t0, num_rows
	bge	$s3, $t0, fw_done	# !(i < num_rows)
	li	$s4, 0			# j = 0

fw_j:
	bge	$s4, $s2, fw_i_next	# !(j < num_columns)
	mul	$t0, $s3, $s2		# i * num_columns
	add	$s5, $t0, $s4		# start = i * num_columns + j
	add	$t0, $t0, $s2		# equivalent to (i + 1) * num_columns
	sub	$s6, $t0, 1		# end = (i + 1) * num_columns - 1
	li	$s7, 0			# k = 0

fw_k:
	bge	$s7, $s1, fw_j_next	# !(k < dictionary_size)
	mul	$t0, $s7, 4		# k * 4
	add	$t0, $s0, $t0		# &dictionary[k]
	#sw	$t0, PRINT_INT
	lw	$s8, 0($t0)		# word = dictionary[k]
	
	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $s6		# end
	jal	horiz_strncmp
	ble	$v0, 0, fw_vert		# !(word_end > 0)
	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $v0		# word_end
	jal	record_word

fw_vert:
	move	$a0, $s8		# word
	move	$a1, $s3		# i
	move	$a2, $s4		# j
	jal	vert_strncmp
	ble	$v0, 0, fw_k_next	# !(word_end > 0)
	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $v0		# word_end
	jal	record_word

fw_k_next:
	add	$s7, $s7, 1		# k++
	j	fw_k

fw_j_next:
	add	$s4, $s4, 1		# j++
	j	fw_j

fw_i_next:
	add	$s3, $s3, 1		# i++
	j	fw_i

fw_done:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	lw	$s6, 28($sp)
	lw	$s7, 32($sp)
	lw	$s8, 36($sp)
	add	$sp, $sp, 40
	jr	$ra

######################### GET_CHARACTER ##################
## char
## get_character(int i, int j) {
##     return puzzle[i * num_columns + j];
## }

get_character:
	lw	$t0, num_columns
	mul	$t0, $a0, $t0		# i * num_columns
	add	$t0, $t0, $a1		# i * num_columns + j
	
	##lw	$t1, puzzle
	la	$t1, puzzle_struct
	add	$t1, 8

	add	$t1, $t1, $t0		# &puzzle[i * num_columns + j]
	lbu	$v0, 0($t1)		# puzzle[i * num_columns + j]
	jr	$ra


######################### HORIZ_STRNCMP ##################
## int
## horiz_strncmp(const char* word, int start, int end) {
##     int word_iter = 0;
## 
##     while (start <= end) {
##         if (puzzle[start] != word[word_iter]) {
##             return 0;
##         }
## 
##         if (word[word_iter + 1] == '\0') {
##             return start;
##         }
## 
##         start++;
##         word_iter++;
##     }
##     
##     return 0;
## }

horiz_strncmp:
	li	$t0, 0			# word_iter = 0
	
	##lw	$t1, puzzle

	la	$t1, puzzle_struct
	##sw	$t1, PRINT_INT
	add	$t1, $t1, 8	

	##lw	$t1, 8($t1)
	##sw	$a0, PRINT_INT

hs_while:
	bgt	$a1, $a2, hs_end	# !(start <= end)

	add	$t2, $t1, $a1		# &puzzle[start]
	lbu	$t2, 0($t2)		# puzzle[start]
	add	$t3, $a0, $t0		# &word[word_iter]

	lbu	$t4, 0($t3)		# word[word_iter]

	beq	$t2, $t4, hs_same	# !(puzzle[start] != word[word_iter])
	li	$v0, 0			# return 0
	jr	$ra

hs_same:
	lbu	$t4, 1($t3)		# word[word_iter + 1]
	bne	$t4, 0, hs_next		# !(word[word_iter + 1] == '\0')
	move	$v0, $a1		# return start
	jr	$ra

hs_next:
	add	$a1, $a1, 1		# start++
	add	$t0, $t0, 1		# word_iter++
	j	hs_while

hs_end:
	li	$v0, 0			# return 0
	jr	$ra


######################### VERT_STRNCMP ##################
## int
## vert_strncmp(const char* word, int start_i, int j) {
##     int word_iter = 0;
## 
##     for (int i = start_i; i < num_rows; i++, word_iter++) {
##         if (get_character(i, j) != word[word_iter]) {
##             return 0;
##         }
## 
##         if (word[word_iter + 1] == '\0') {
##             // return ending address within array
##             return i * num_columns + j;
##         }
##     }
## 
##     return 0;
## }

vert_strncmp:
	sub	$sp, $sp, 24
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)

	move	$s0, $a0		# word
	move	$s1, $a1		# i = start_i
	move	$s2, $a2		# j
	li	$s3, 0			# word_iter
	lw	$s4, num_rows

vs_for:
	bge	$s1, $s4, vs_nope	# !(i < num_rows)

	move	$a0, $s1
	move	$a1, $s2
	jal	get_character		# get_character(i, j)
	add	$t0, $s0, $s3		# &word[word_iter]
	lbu	$t1, 0($t0)		# word[word_iter]
	bne	$v0, $t1, vs_nope

	lbu	$t1, 1($t0)		# word[word_iter + 1]
	bne	$t1, 0, vs_next
	lw	$v0, num_columns
	mul	$v0, $s1, $v0		# i * num_columns
	add	$v0, $v0, $s2		# i * num_columns + j
	j	vs_return

vs_next:
	add	$s1, $s1, 1		# i++
	add	$s3, $s3, 1		# word_iter++
	j	vs_for

vs_nope:
	li	$v0, 0			# return 0 (data flow)

vs_return:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	add	$sp, $sp, 24

	jr	$ra




## // assumes the word is at least 4 characters
## int
## horiz_strncmp_fast(const char* word) {
##     // treat first 4 chars as an int
##     unsigned x = *(unsigned*)word;
##     unsigned cmp_w[4];
##     // compute different offsets to search
##     cmp_w[0] = x;
##     cmp_w[1] = (x & 0x00ffffff); 
##     cmp_w[2] = (x & 0x0000ffff);
##     cmp_w[3] = (x & 0x000000ff);
## 
##     for (int i = 0; i < num_rows; i++) {
##         // treat the row of chars as a row of ints
##         unsigned* array = (unsigned*)(puzzle + i * num_columns);
##         for (int j = 0; j < num_columns / 4; j++) {
##             unsigned cur_word = array[j];
##             int start = i * num_columns + j * 4;
##             int end = (i + 1) * num_columns - 1;
## 
##             // check each offset of the word
##             for (int k = 0; k < 4; k++) {
##                 // check with the shift of current word
##                 if (cur_word == cmp_w[k]) {
##                     // finish check with regular horiz_strncmp
##                     int ret = horiz_strncmp(word, start + k, end);
##                     if (ret != 0) {
##                         return ret;
##                     }
##                 }
##                 cur_word >>= 8;
##             }
##         }
##     }
##     
##     return 0;
## }

######################### HORIZ_STRNCMP_FAST ##################
horiz_strncmp_fast:
	sub	$sp, $sp, 56
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)
	sw	$s6, 28($sp)
	sw	$s7, 32($sp)
	sw	$s8, 36($sp)
	# cmp_w is on offsets 40 through 55

	move	$s0, $a0			# word
	lw	$s1, num_columns

	lw	$t0, 0($s0)			# x
	sw	$t0, 40($sp)			# cmp_w[0]
	and	$t1, $t0, 0x00ffffff		# x & 0x00ffffff
	sw	$t1, 44($sp)			# cmp_w[1]
	and	$t1, $t0, 0x0000ffff		# x & 0x0000ffff
	sw	$t1, 48($sp)			# cmp_w[2]
	and	$t1, $t0, 0x000000ff		# x & 0x000000ff
	sw	$t1, 52($sp)			# cmp_w[3]

	li	$s2, 0				# i = 0

hsf_for_i:
	lw	$t0, num_rows
	bge	$s2, $t0, hsf_return_0		# !(i < num_rows)

	##lw	$t0, puzzle

	la	$t0, puzzle_struct
	add	$t0, 8


	mul	$t1, $s2, $s1			# i * num_columns
	add	$s3, $t0, $t1			# array = puzzle + i * num_columns

	li	$s4, 0				# j = 0

hsf_for_j:
	div	$t0, $s1, 4			# num_columns / 4
	bge	$s4, $t0, hsf_for_i_next	# !(j < num_columns / 4)

	mul	$t0, $s4, 4			# j * 4
	add	$t1, $s3, $t0			# &array[j]
	lw	$s5, 0($t1)			# cur_word = array[j]
	mul	$t1, $s2, $s1			# i * num_columns
	add	$s6, $t1, $t0			# start = i * num_columns + j * 4
	add	$t1, $t1, $s1			# equivalent to (i + 1) * num_columns
	sub	$s7, $t1, 1			# end = (i + 1) * num_columns - 1

	li	$s8, 0				# k = 0

hsf_for_k:
	mul	$t0, $s8, 4			# k * 4
	add	$t0, $sp, $t0			# &cmp_w[k] - 40
	lw	$t0, 40($t0)			# cmp_w[k]
	bne	$s5, $t0, hsf_for_k_next	# !(cur_word == cmp_w[k])

	move	$a0, $s0			# word
	add	$a1, $s6, $s8			# start + k
	move	$a2, $s7			# end
	jal	horiz_strncmp
	bne	$v0, 0, hsf_return		# ret != 0

hsf_for_k_next:
	srl	$s5, $s5, 8			# cur_word >>= 8
	add	$s8, $s8, 1			# k++
	blt	$s8, 4, hsf_for_k		# k < 4

	add	$s4, $s4, 1			# j++
	j	hsf_for_j

hsf_for_i_next:
	add	$s2, $s2, 1			# i++
	j	hsf_for_i

hsf_return_0:
	li	$v0, 0				# return 0 (data flow)

hsf_return:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	lw	$s6, 28($sp)
	lw	$s7, 32($sp)
	lw	$s8, 36($sp)
	add	$sp, $sp, 56
	jr	$ra





######################### RECORD_WORD ##################
record_word:

	la 	$t3, puzzle_solution
	lw 	$t4, 0($t3)			# numwords
	add 	$t3 $t3 4
	mul 	$t4, $t4, 8
	add	$t3, $t3, $t4
	sw 	$a1 0($t3)
	sw 	$a2 4($t3)
	la 	$t3 puzzle_solution
	lw 	$t4 0($t3)
	add 	$t4, $t4, 1			# numwords +1
	sw 	$t4, 0($t3)			# update numwords
	li 	$t5 1000 
	sw 	$t5 PRINT_INT
	
	jr	$ra





main:
	# your code goes here
	# for the interrupt-related portions, you'll want to
	# refer closely to example.s - it's probably easiest
	# to copy-paste the relevant portions and then modify them
	# keep in mind that example.s has bugs, as discussed in section
	
	la 	$t2, scan_complete
	la	$t3, dust_max
	la	$t4, dust_max_sector
	li	$t2, 0

	# ENABLE INTERRUPTS
	li	$t7, SCAN_MASK		# scan interrup enable bit
	or	$t7, $t7, ENERGY_MASK	# energy interrupt bit
	or  	$t7, $t7, INTERFERENCE_MASK
	or	$t7, $t7, 1		# global interrupt enable
	mtc0	$t7, $12	

locating:
 ############# ---LOCATING DUST PARTICLES--- #####################
	la 	$t0, scan_sector		# alocate array of integers to hold the scan results
	li 	$t1, 0
	

	
scanning:
	bge 	$t1, 64, done_scanning		
	sw  	$t1, SCAN_SECTOR($zero)
	sw  	$t0, SCAN_REQUEST($zero)
	
wait_scan:
	#REQUEST SCAN INTERRUPT
	bne 	$t2, $0 , done_scan 				
	j   	wait_scan		
			
done_scan:
	li  	$t2, 0			# scan_complete = 0
	add 	$t1, $t1, 1		# $t1++
	j   	scanning	
	 	
done_scanning:
	# Find the sector having the most dust
	li 	$t3, 0
	li 	$t1, 0
	j  	find_max_dust

find_max_dust:
	bge 	$t1, 64, activate_gravity
	mul 	$t5, $t1, 4
	add 	$t5, $t0, $t5
	lw  	$t6, 0($t5)
	bge 	$t6, $t3, update_max_dust
	add 	$t1, $t1, 1		# $t1++
	j   	find_max_dust

update_max_dust:
	move 	$t3, $t6		# update the max_dust value
	move 	$t4, $t1		# update the max_dust_sector
	add 	$t1, $t1, 1		# $t1++
	j 	find_max_dust

	############# ---ACTIVATE GRAVITY FIELD--- #####################

activate_gravity:
	# DETERMINE THE APPROPRIATE COORDINATE X, Y of Dust_Sector

	#sw	$t4, PRINT_INT	

	li	 $t1, 8
	div	 $t4, $t1		# t4/row_index				
	mfhi  	 $t5
	mflo	 $t6

	mul	$t5, $t5, 37
	mul	$t6, $t6, 37

	add	$t5, $t5, 15		# Now x_dust = $t5
	add	$t6, $t6, 15		# Now y_dust = $t6

	#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV

	li $t2, 8
	sw $t2, VELOCITY 		# move 

	lw $t3, BOT_X			# box x
	lw $t4, BOT_Y 			# bot y

	sub $a0, $t5, $t3 		# delta x
	sub $a1, $t6, $t4 		# delta y

	jal sb_arctan			# **************************
	sw $v0, ANGLE 			# set angle

	li $t0, 1
	sw $t0, ANGLE_CONTROL 	# relative angle, bot set 

travel: 
	lw $t7, BOT_X			# box x
	lw $t8, BOT_Y 			# bot y
	
	sub $a0, $t5, $t7 		# delta x
	sub $a1, $t6, $t8 		# delta y

	jal euclidean_dist 		# how far away is the sector             ***********
	ble $v0, 14, attract_dust



##------->>>############ FOR TESTING Puzzle --- remove after finishing

		##li	$t2, 10
		##sw	$t2, FIELD_STRENGTH




	j travel 				# if not close enough, keep looping 

attract_dust:


###########/////////**********************CHECK ENERGY AND SOLVE PUZZLE ******
	lw  $t0, ENERGY
	sw  $t0, PRINT_INT($zero)
	blt $t0, 15, requesting_puzzle

    	
continue:
	###########


	li $t1, 0		## Stop the Bot to collect dust
	sw $t1, VELOCITY	
	li $v1 13000
	li $t1, 6
	sw $t1, FIELD_STRENGTH

	j	back_to_planet



back_to_planet:
	ble $v1, $0, dustwait
duststart:
	sub $v1, $v1, 1
	li $t1, 0
	sw $t1, VELOCITY
	bge $v1 $0 duststart
	li $t1, 4
	sw $t1, FIELD_STRENGTH
	j dustwait
	#li 	$a0 0
	#sw 	$a0 FIELD_STRENGTH
	j back_to_planet
	
	
dustwait:
	li $t1, 10		## Make bot move again
	sw $t1, VELOCITY

chaser:
	la $t9, planet_info		# address where planets should be
	sw $t9, PLANETS_REQUEST	# requesting planets

	lw $t1, BOT_X			# box x
	lw $t2, BOT_Y 			# bot y

	lw $t3, 0($t9)			# x val allied
	lw $t4, 4($t9)			# y val allied	

	sub $a0, $t1, $t3 		# delta x
	sub $a1, $t2, $t4 		# delta y
	add $t9, $a0, 0
	add $t8, $a1, 0
	bge $t9 $0 abs9end
	sub $t9 $0 $t9
abs9end:
	bge $t8 $0 abs8end
	sub $t8 $0 $t8
abs8end:
	add $t9 $t8 $t9
	bge $t9 15 dend
	li $t9, 4		
	sw $t9, VELOCITY
dend:
	beq $a0, $0, release 	# skip so 0 divide does not occur
	jal sb_arctan

	sub $v0, $v0, 180
	sw $v0, ANGLE 			# set initial angle to 0

	li $t0, 1
	sw $t0, ANGLE_CONTROL 	# relative angle

	j chaser
release:
	li $t1, 0
	sw $t1, FIELD_STRENGTH
	li $v1 7000
	li $t1 0
	sw $t1, VELOCITY
v1loop:
	ble $v1 $0 v1loopend
	sub $v1 $v1 1;
	j v1loop
v1loopend:
	li $t1, 10
	sw $t1, VELOCITY
	
	j  locating

#========================================================================
#------------------------------euclidean.s-------------------------------
#========================================================================

# -----------------------------------------------------------------------
# sb_arctan - computes the arctangent of y / x
# $a0 - x
# $a1 - y
# returns the arctangent
# -----------------------------------------------------------------------

sb_arctan:
	li	$v0, 0		# angle = 0;

	abs	$t0, $a0	# get absolute values
	abs	$t1, $a1
	ble	$t1, $t0, no_TURN_90	  

	## if (abs(y) > abs(x)) { rotate 90 degrees }
	move	$t0, $a1	# int temp = y;
	neg	$a1, $a0	# y = -x;      
	move	$a0, $t0	# x = temp;    
	li	$v0, 90		# angle = 90;  

no_TURN_90:
	bgez	$a0, pos_x 	# skip if (x >= 0)

	## if (x < 0) 
	add	$v0, $v0, 180	# angle += 180;

pos_x:
	mtc1	$a0, $f0
	mtc1	$a1, $f1
	cvt.s.w $f0, $f0	# convert from ints to floats
	cvt.s.w $f1, $f1
	
	div.s	$f0, $f1, $f0	# float v = (float) y / (float) x;

	mul.s	$f1, $f0, $f0	# v^^2
	mul.s	$f2, $f1, $f0	# v^^3
	l.s	$f3, three	# load 5.0
	div.s 	$f3, $f2, $f3	# v^^3/3
	sub.s	$f6, $f0, $f3	# v - v^^3/3

	mul.s	$f4, $f1, $f2	# v^^5
	l.s	$f5, five	# load 3.0
	div.s 	$f5, $f4, $f5	# v^^5/5
	add.s	$f6, $f6, $f5	# value = v - v^^3/3 + v^^5/5

	l.s	$f8, PI		# load PI
	div.s	$f6, $f6, $f8	# value / PI
	l.s	$f7, F180	# load 180.0
	mul.s	$f6, $f6, $f7	# 180.0 * value / PI

	cvt.w.s $f6, $f6	# convert "delta" back to integer
	mfc1	$t0, $f6
	add	$v0, $v0, $t0	# angle += delta

	jr 	$ra
	

# -----------------------------------------------------------------------
# euclidean_dist - computes sqrt(x^2 + y^2)
# $a0 - x
# $a1 - y
# returns the distance
# -----------------------------------------------------------------------

euclidean_dist:
	mul	$a0, $a0, $a0	# x^2
	mul	$a1, $a1, $a1	# y^2
	add	$v0, $a0, $a1	# x^2 + y^2
	mtc1	$v0, $f0
	cvt.s.w	$f0, $f0	# float(x^2 + y^2)
	sqrt.s	$f0, $f0	# sqrt(x^2 + y^2)
	cvt.w.s	$f0, $f0	# int(sqrt(...))
	mfc1	$v0, $f0
	jr	$ra



#===========================interrupts======================



.kdata				# interrupt handler data (separated just for readability)
chunkIH:	.space 16	# space for four registers
non_intrpt_str:	.asciiz "Non-interrupt exception\n"
unhandled_str:	.asciiz "Unhandled interrupt type\n"

.ktext 0x80000180
interrupt_handler:
.set noat
	move	$k1, $at		# Save $at                               
.set at
	la	$k0, chunkIH
	sw	$a0, 0($k0)		# Get some free registers                  
	sw	$a1, 4($k0)		# by storing them to a global variable     

	sw	$t0, 8($k0)
	sw	$v0, 12($k0)

	mfc0	$k0, $13		# Get Cause register                       
	srl	$a0, $k0, 2                
	and	$a0, $a0, 0xf		# ExcCode field                            
	bne	$a0, 0, non_intrpt         

interrupt_dispatch:			# Interrupt:                             
	mfc0	$k0, $13		# Get Cause register, again                 
	beq	$k0, 0, done		# handled all outstanding interrupts     

	and	$a0, $k0, SCAN_MASK				# is there a scan interrupt?                
	bne	$a0, 0, scan_interrupt   

	and	$a0, $k0, ENERGY_MASK			# is there a energy interrupt?
	bne	$a0, 0, energy_interrupt

	and $a0, $k0, INTERFERENCE_MASK 	# is there an interference interrupt
	bne $a0, 0, interference_interrupt
	# add dispatch for other interrupt types here.

	li	$a1, 4			# Unhandled interrupt types
	la	$a0, unhandled_str
	syscall 
	j	done

scan_interrupt:
###############
	sw	$zero, VELOCITY		# Spimbot not moving
	sw	$a1, SCAN_ACKNOWLEDGE	# acknowledge interrupt
	
	li	$t2, 1
	j	interrupt_dispatch	# see if other interrupts are waiting

###############

energy_interrupt:
#########
	sw	$a1, ENERGY_ACKNOWLEDGE	# acknowledge interrupt

	j	interrupt_dispatch	# see if other interrupts are waiting
############

interference_interrupt:
	sw $a1, INTERFERENCE_ACK 	#acknowledge interrupts

	j interrupt_dispatch

non_intrpt:				# was some non-interrupt
	li	$v0, 4
	la	$a0, non_intrpt_str
	syscall				# print out an error message
	# fall through to done

done:
	la	$k0, chunkIH
	lw	$a0, 0($k0)		# Restore saved registers
	lw	$a1, 4($k0)

	lw	$t0, 8($k0)
	lw	$v0, 12($k0)


.set noat
	move	$at, $k1		# Restore $at
.set at 
	eret


