.data
vetor: .double 12345.678 , 23456.789 , 34567.891 , 45678.910 , 56789.101 , 67891.01
numero_10: .double 10.0
ytest: .asciiz "C:/Users/digog/OneDrive/Área de Trabalho/Ytest.txt"
buffer_escrita: .word 0

.text
	# Abrir o arquivo
	li $v0, 13
	la $a0, ytest
	li $a1, 9
	syscall # Descritor do arquivo está em v0
	
	move $s0, $v0	# Salvo o descritor do arquivo

	li $a0, 7
	jal escrever_ascii
	
	# Fechar o arquivo
	li $v0, 16
	move $a0, $s0
	syscall
	
	li $v0, 10
	syscall
	
############################## FUNÇÃO QUE CALCULA O ASCII PAR O INTEIRO E ESCREVE NO ARQUIVO
#Recebe: valor inteiro do numero que deve ser escrito em a0
escrever_ascii:
	move $t0, $a0		# Valor que deve ser escrito em t0
	addi $t0, $t0, 48 	# Encontra o codigo ascii do número
	
	sw $t0, buffer_escrita	# Salvo o valor do ascii no buffer
	
	li $v0, 15
	move $a0, $s0		# Passar o descritor do arquivo
	la $a1, buffer_escrita	# Passar o endereço do que deve ser escrito
	li $a2, 1		# Passar a quantidade de caracteres a serem escritos
	syscall
	
	jr $ra

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
#	# Escrever no arquivo
#	li $v0, 15
#	move $a0, $t0
#	la $a1, buffer_escrita
#	li $a2, 1
#	syscall
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
	