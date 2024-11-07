.data
vetor: .double 12345.678 , 23456.789 , 34567.891 , 45678.910 , 56789.101 , 67891.01
numero_10: .double 10.0
ytest: .asciiz "C:/Users/digog/OneDrive/Área de Trabalho/Ytest.txt"
buffer_escrita: .word 0

.text

#################################### COMO CRIAR O ARQUIVO E ESCREVER O ASCII NELE
#
#	# Abrir o arquivo
#	li $v0, 13
#	la $a0, ytest
#	li $a1, 9
#	syscall # Descritor do arquivo está em v0
#	
#	move $s0, $v0	# Salvo o descritor do arquivo
#	
#	li $t1, 53	# Seleciono o ascii desejado
#	sw $t1, buffer_escrita	# Salvo o valor do ascii no buffer
#	
#	# Fechar o arquivo
#	li $v0, 16
#	move $a0, $s0
#	syscall
#

# Sub-rotina para converter para ascii e escrever esse caractere no arquivo

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
	