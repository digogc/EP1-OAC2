.data
vetor: .double 12345.678 , 23456.789 , 34567.891 , 45678.910 , 56789.101 , 67891.01
numero_10: .double 10.0
ytest: .asciiz "C:/Users/digog/OneDrive/Área de Trabalho/Ytest.txt"
buffer_escrita: .word 0
linhas_matriz: .word 6
numero_1: .double 1.0

.text
main:
	la $a0, vetor
	jal escrever_ytest
	
	li $v0, 10
	syscall

# Função escrever_ytest
# Função que recebe o endereço do vetor que armazena o ytest e escreve ele em um arquivo
# Parâmetros: endereço do vetor ytest em a0
escrever_ytest:
	# Salvar endereço base do ytest em s0
	move $s0, $a0
	
	# Carrega a constante 10 no registrador f10
	la $t0, numero_10
	l.d $f10, 0($t0)
	
	# Coloca quantidade de linhas em s3
	la $t0, linhas_matriz
	lw $s3, 0($t0)
	
	# Carrega quantidade de linhas -1 em $s7
	subi $s7, $s3, 1
	
	# Como haverá jal dentro dessa função, salvar $ra na pilha
	subi $sp, $sp, 4
	sw $ra, 0($sp)
	
	# Abrir o arquivo
	li $v0, 13
	la $a0, ytest
	li $a1, 9
	syscall # Descritor do arquivo está em v0
	
	move $s1, $v0 	# Descritor do arquivo está em s1
	
	li $s2, 0 	# Contador de linhas escritas em s2
	# Loop para acessar todas as linhas
	acessar_linha:
		beq $s2, $s3, fim_acessar_linhas
		# Inicializa N para quantidade de divisões por 10
		li $s4, 0
		# Encontrar endereço da linha
		mul $t0, $s2, 8
		add $t0, $t0, $s0
		# Carrega o valor que esta na linha em f0
		l.d $f0, 0($t0)
		# Começa calculo para encontrar quantas divisões devem ser feitas
		calcular_N:
			c.lt.d $f0, $f10		# Se o numero da linha for menor que 10
			bc1t fim_calcular_N	# Já posso começar o processo de escrita
			
			div.d $f0, $f0, $f10 	# Divido o valor por 10
			addi $s4, $s4, 1		# N = N + 1
			j calcular_N
		
		fim_calcular_N:
		li $s5, 0	# Inicializo o contador de multiplicações ja realizadas
		# Agora preciso salvar o primeiro digito do double para escrever no arquivo
		escreve_antes_do_ponto:
			beq $s5, $s4, fim_escreve_antes_do_ponto
			# tranformação do primeiro digito do double em int
			cvt.w.d $f2, $f0		# Salva a parte inteira do valor em um registrador de double
			mfc1 $s6, $f2		# Move a parte inteira do valor para um registrador int
			move $a0, $s6		# Passo a parte inteira como parametro
			jal escrever_ascii
			
			# Subtrai a parte inteira e multiplica por 10
			cvt.d.w $f4, $f2		# Transformando a parte inteira em double que pode ser usado
			sub.d $f0, $f0, $f4	# Agora é um valor entre 0 e 1
			
			# Multiplicar valor por 10
			mul.d $f0, $f0, $f10
			#incrementa o contador de multiplicações
			addi $s5, $s5, 1
			j escreve_antes_do_ponto
			
		fim_escreve_antes_do_ponto:
		# Colocar o ponto no lugar correto
		li $t1, 46	# Seleciono o ascii do ponto
		sw $t1, buffer_escrita	# Salvo o valor do ascii no buffer
	
		# Escrever no arquivo
		li $v0, 15
		move $a0, $s1
		la $a1, buffer_escrita
		li $a2, 1
		syscall
		
		li $s4, 2	# Total de casas depois da virgula
		li $s5, 0	# Número de casas depois da vírgula já escritas
		escreve_depois_do_ponto:
			beq $s5, $s4, fim_escreve_depois_do_ponto
			# tranformação do primeiro digito do double em int
			cvt.w.d $f2, $f0		# Salva a parte inteira do valor em um registrador de double
			mfc1 $s6, $f2		# Move a parte inteira do valor para um registrador int
			move $a0, $s6		# Passo a parte inteira como parametro
			jal escrever_ascii
			
			# Subtrai a parte inteira e multiplica por 10
			cvt.d.w $f4, $f2		# Transformando a parte inteira em double que pode ser usado
			sub.d $f0, $f0, $f4	# Agora é um valor entre 0 e 1
			
			# Multiplicar valor por 10
			mul.d $f0, $f0, $f10
			#incrementa o contador de multiplicações/casas ja escritas
			addi $s5, $s5, 1
			j escreve_depois_do_ponto
		fim_escreve_depois_do_ponto:
		
		colocar_enter:
			bge $s2, $s7, fim_colocar_enter
			# Colocar o ponto no lugar correto
			li $t1, 10	# Seleciono o ascii do enter
			sw $t1, buffer_escrita	# Salvo o valor do ascii no buffer
	
			# Escrever no arquivo
			li $v0, 15
			move $a0, $s1
			la $a1, buffer_escrita
			li $a2, 1
			syscall
			
		fim_colocar_enter:
		
		addi $s2, $s2,1		# Incrementa contador de linhas ja escritas
		j acessar_linha
	fim_acessar_linhas:
	# Restaura para o $ra da função chamadora
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	# Fechar o arquivo
	li $v0, 16
	move $a0, $s1	# passar como argumento o descritor
	syscall
	
	
############################## FUNÇÃO QUE CALCULA O ASCII PAR O INTEIRO E ESCREVE NO ARQUIVO
#Recebe: valor inteiro do numero que deve ser escrito em a0
escrever_ascii:
	move $t0, $a0		# Valor que deve ser escrito em t0
	addi $t0, $t0, 48 	# Encontra o codigo ascii do número
	
	sw $t0, buffer_escrita	# Salvo o valor do ascii no buffer
	
	li $v0, 15
	move $a0, $s1		# Passar o descritor do arquivo
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
	