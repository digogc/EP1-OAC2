.data
vetor: .double 12345.678 , 23456.789 , 34567.891 , 45678.910 , 56789.101 , 67891.01
numero_10: .double 10.0

.text

######################## COMO CONVERTER A PARTE INTEIRA DE UM DOUBLE PARA INT
#
#	la $t0, vetor
#	l.d $f0, 0($t0)		# Carrega o valor em f0
#	
#	cvt.w.d $f2, $f0		# Salva a parte inteira do valor em um registrador de double
#	mfc1 $t1, $f2		# Move a parte inteira do valor para um registrador int
#	
#	# teste
#	move $a0, $t1
#	li $v0, 1
#	syscall
#
	