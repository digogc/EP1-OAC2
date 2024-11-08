.data
xtrain: .asciiz "C:/Users/digog/OneDrive/Área de Trabalho/Xtrain.txt"
xtest: .asciiz "C:/Users/digog/OneDrive/Área de Trabalho/Xtest.txt"
buffer: .space 1
buffer_cont: .space 1
numero_0: .double 0.0
numero_1: .double 1.0
numero_10: .double 10.0
numero_100: .double 100.0
end_aux: .space 8
tamanho: .space 4
w: .word 3
h: .word 1
k: .word 2
k_double: .double 2.0
maior_valor: .double 1.79769E+308
linhas_matriz: .space 4
ytest: .asciiz "C:/Users/digog/OneDrive/Área de Trabalho/Ytest.txt"
buffer_escrita: .word 0

.text
.globl main
main:
	# Ler os arquivos.
	jal ler_todos_arquivos
	# Início dos valores de Xtrain: $s0.
	move $s0, $v0
	# Início dos valores de Xtest: $s1.
	move $s1, $v1

	# Calcular o número de linhas e salvar na memória
	jal calcula_linhas

	# Montar Ytrain.
	# Tem como parâmetro: endereço base da Matriz de Xtrain.
	move $a0, $s0
	jal montar_ytrain
	# Início do Arranjo de YTrain: $s2
	move $s2, $v0

	# Montar matriz Xtrain.
	# Tem como parâmetros: endereço de início dos dados
	move $a0, $s0
	jal montar_matriz
	# Início da Matriz de Xtrain: $s0
	move $s0, $v0

	# Montar matriz Xtest.
	# Tem como parâmetros: endereço de início dos dados
	move $a0, $s1
	jal montar_matriz
	# Início da Matriz de Xtest: $s1
	move $s1, $v0
	
	move $a0, $s0		# endereço de Xtrain em a0
	move $a1, $s1		# endereço de Xtest em a1
	move $a2, $s2		# endereço de Ytrain em a2
	jal knn
	
	move $a0, $v0		# passa o retorno de knn como argumento para escrever_ytest
	jal escrever_ytest
	
	# Finalizar programa.
	li $v0, 10
	syscall

#################################################### SUB-ROTINAS (FUNÇÕES)

#                 FUNÇÃO PARA LEITURA DE TODOS OS ARQUIVOS NECESSÁRIOS
ler_todos_arquivos:
	# Obter descritor do arquivo "xtrain.txt" → ficará em $s0.
	la $a0, xtrain
	li $a1, 0
	li $v0, 13
	syscall
	move $s0, $v0

	# Obter descritor do arquivo "xtest.txt" → ficará em $s1.
	la $a0, xtest
	li $a1, 0
	li $v0, 13
	syscall
	move $s1, $v0

	# Inspecionar número de elementos que serão guardados na memória.
	li $t0, 0

	inspecionar_num_elementos_xtrain:
		move $a0, $s0
		la $a1, buffer_cont
		li $a2, 1
		li $v0, 14
		syscall
		lb $t1, 0($a1)
		li $t2, 10 # ASCII de \n.
		beq $t1, $t2, contar_xtrain
		beq $v0, $a2, inspecionar_num_elementos_xtrain

	inspecionar_num_elementos_xtest:
		move $a0, $s1
		la $a1, buffer_cont
		li $a2, 1
		li $v0, 14
		syscall
		lb $t1, 0($a1)
		li $t2, 10 # ASCII de \n.
		beq $t1, $t2, contar_xtest
		beq $v0, $a2, inspecionar_num_elementos_xtest

	j alocar_espaco

contar_xtrain:
addi $t0, $t0, 8
j inspecionar_num_elementos_xtrain

contar_xtest:
addi $t0, $t0, 8
j inspecionar_num_elementos_xtest

	# Abrir espaço para os elementos.
	alocar_espaco:
	addi $t0, $t0, 16

	# Aqui, $t0 tem o número de elementos dos arquivos.
	# Guardar esse valor na memória.
	la $t6, tamanho
	div $t7, $t0, 16
	sw $t7, 0($t6)

	move $a0, $t0
	li $v0, 9
	syscall
	# Endereço de início do espaço alocado vai para $t6.
	move $t6, $v0

	# Fechar o arquivo xtrain.txt.
	move $a0, $s0 # Mover o descritor do arquivo para $a0
	li $v0, 16 # Syscall para fechar o arquivo
	syscall

	# Fechar o arquivo xtest.txt.
	move $a0, $s1 # Mover o descritor do arquivo para $a0
	li $v0, 16 # Syscall para fechar o arquivo
	syscall

# Espaço para os elementos dos dois arquivos está alocado.

# Guardar valores de xtrain.txt.

	# Abrir o arquivo xtrain.txt.
	la $a0, xtrain
	li $a1, 0
	li $v0, 13
	syscall
	move $s0, $v0

	# Posição onde guardar.
	addi $t7, $0, 0

	# Ler um caractere do arquivo xtrain.txt por vez.
	ler_novo_num_xtrain:
	# Resetar $f0.
	la $t0, numero_0
	l.d $f0, 0($t0)
	ler_caractere_xtrain:
	move $a0, $s0
	la $a1, buffer
	li $a2, 1
	li $v0, 14
	syscall
	# Guarda o número de bytes efetivamente lidos.
	move $t1, $v0

	# Obter o caractere → vai para $t2.
	lb $t2, 0($a1)
	
	# Descobrir se é "." ou "\n".
	li $t3, 46 # .
	li $t4, 10 # \n
	li $t5, 13 # \r
	beq $t2, $t5, ler_caractere_xtrain # Se o caractere for '\r', segue para o próximo caractere, que será \n.
	beq $t2, $t3, eh_ponto_xtrain  # Se o caractere for '.', pula para eh_ponto
	beq $t2, $t4, eh_barra_xtrain  # Se o caractere for '\', pula para eh_barra
	
	# Se chega aqui, é número.
	li $t3, 48 # Código ASCII de "0"
	sub $t2, $t2, $t3  # $t2 passa a ter o NÚMERO lido.
	# Converter o número inteiro em $t2 para um float, em $f2.
	mtc1 $t2, $f2
	cvt.d.w $f2, $f2
	# la $t3, end_aux
	# sw $t2, 0($t3)
	# l.d $f2, 0($t3)
	
	# Atualizar o registrador que guarda o número que está sendo trabalhado.
	la $t3, numero_10
	l.d $f4, 0($t3)
	mul.d $f0, $f0, $f4
	add.d $f0, $f0, $f2
	
	# Verificar se chegou ao final do arquivo
	beq $t1, $a2, ler_caractere_xtrain  # Se leu menos bytes que o solicitado, chegou ao fim
	
	# Arquivo acabou → fechá-lo.
	move $a0, $s0 # Mover o descritor do arquivo para $a0
	li $v0, 16 # Syscall para fechar o arquivo
	syscall
	
	eh_ponto_xtrain:
	# Contador de casas decimais.
	la $t3, numero_1
	l.d $f6, 0($t3)
	# Lê as casas decimais.
	casas_decimais_xtrain:
	move $a0, $s0
	la $a1, buffer
	li $a2, 1
	li $v0, 14
	syscall
	# Se o arquivo acabou.
	bne $v0, $a2, fim_arquivo_xtrain
	# Obter o caractere → vai para $t2.
	lb $t2, 0($a1)
	# Descobrir se é "\n" ou "\r".
	li $t3, 10 # \n
	li $t5, 13 # \r
	beq $t2, $t5, casas_decimais_xtrain # Se o caractere for '\r', segue para o próxima casa decimal, que será \n.
	beq $t2, $t3, eh_barra_xtrain  # Se o caractere for '\n', pula para eh_barra
	# Incrementar contador de casas decimais.
	mul.d $f6, $f6, $f4
	# $t2 tem número.
	li $t3, '0' # Código ASCII de "0"
	sub $t2, $t2, $t3  # $t2 passa a ter o NÚMERO lido.
	# Converter o número inteiro em $t2 para um float, em $f2.
	mtc1 $t2, $f2
	cvt.d.w $f2, $f2
	#la $t3, end_aux
	#sw $t2, 0($t3)
	#l.d $f2, 0($t3)
	# Atualizar o registrador que guarda o número que está sendo trabalhado.
	div.d $f2, $f2, $f6
	add.d $f0, $f0, $f2
	j casas_decimais_xtrain

eh_barra_xtrain:
# Terminei de ler esse número. Vou guardá-lo e resetar o registrador intermediário.
# Guardar na posição certa do espaço já alocado.
add $t8, $t6, $t7
s.d $f0, 0($t8)
# Atualizar a posição a guardar.
addi $t7, $t7, 8
j ler_novo_num_xtrain

fim_arquivo_xtrain:
# Guadar o último número do arquivo.
add $t8, $t6, $t7
s.d $f0, 0($t8)
# Fechar o arquivo.
move $a0, $s0 # Mover o descritor do arquivo para $a0
li $v0, 16 # Syscall para fechar o arquivo
syscall
# Atualizar a posição a guardar.
addi $t7, $t7, 8

# Guardar valores de xtest.txt.

	# Abrir o arquivo xtest.txt.
	la $a0, xtest
	li $a1, 0
	li $v0, 13
	syscall
	move $s0, $v0
	
	# Ler um caractere do arquivo xtrain.txt por vez.
	ler_novo_num_xtest:
		# Resetar $f0.
		la $t0, numero_0
		l.d $f0, 0($t0)
		ler_caractere_xtest:
			move $a0, $s0
			la $a1, buffer
			li $a2, 1
			li $v0, 14
			syscall
			# Guarda o número de bytes efetivamente lidos.
			move $t1, $v0

	# Obter o caractere → vai para $t2.
	lb $t2, 0($a1)
	
	# Descobrir se é "." ou "\n".
	li $t3, 46 # .
	li $t4, 10 # \n
	li $t5, 13 # \r
	beq $t2, $t5, ler_caractere_xtest # Se o caractere for '\r', segue para o próximo caractere, que será \n.
	beq $t2, $t3, eh_ponto_xtest  # Se o caractere for '.', pula para eh_ponto
	beq $t2, $t4, eh_barra_xtest  # Se o caractere for '\', pula para eh_barra
	
	# Se chega aqui, é número.
	li $t3, 48 # Código ASCII de "0"
	sub $t2, $t2, $t3  # $t2 passa a ter o NÚMERO lido.
	# Converter o número inteiro em $t2 para um float, em $f2.
	mtc1 $t2, $f2
	cvt.d.w $f2, $f2
	# la $t3, end_aux
	# sw $t2, 0($t3)
	# l.d $f2, 0($t3)
	
	# Atualizar o registrador que guarda o número que está sendo trabalhado.
	la $t3, numero_10
	l.d $f4, 0($t3)
	mul.d $f0, $f0, $f4
	add.d $f0, $f0, $f2
	
	# Verificar se chegou ao final do arquivo
	beq $t1, $a2, ler_caractere_xtest  # Se leu menos bytes que o solicitado, chegou ao fim
	
	# Arquivo acabou → fechá-lo.
	move $a0, $s0 # Mover o descritor do arquivo para $a0
	li $v0, 16 # Syscall para fechar o arquivo
	syscall
	
eh_ponto_xtest:
# Contador de casas decimais.
la $t3, numero_1
l.d $f6, 0($t3)
	# Lê as casas decimais.
	casas_decimais_xtest:
	move $a0, $s0
	la $a1, buffer
	li $a2, 1
	li $v0, 14
	syscall
	# Se o arquivo acabou.
	bne $v0, $a2, fim_arquivo_xtest
	# Obter o caractere → vai para $t2.
	lb $t2, 0($a1)
	# Descobrir se é "\n" ou "\r".
	li $t3, 10 # \n
	li $t5, 13 # \r
	beq $t2, $t5, casas_decimais_xtest # Se o caractere for '\r', segue para o próxima casa decimal, que será \n.
	beq $t2, $t3, eh_barra_xtest  # Se o caractere for '\n', pula para eh_barra
	# Incrementar contador de casas decimais.
	mul.d $f6, $f6, $f4
	# $t2 tem número.
	li $t3, '0' # Código ASCII de "0"
	sub $t2, $t2, $t3  # $t2 passa a ter o NÚMERO lido.
	# Converter o número inteiro em $t2 para um float, em $f2.
	mtc1 $t2, $f2
	cvt.d.w $f2, $f2
	#la $t3, end_aux
	#sw $t2, 0($t3)
	#l.d $f2, 0($t3)
	# Atualizar o registrador que guarda o número que está sendo trabalhado.
	div.d $f2, $f2, $f6
	add.d $f0, $f0, $f2
	j casas_decimais_xtest

eh_barra_xtest:
# Terminei de ler esse número. Vou guardá-lo e resetar o registrador intermediário.
# Guardar na posição certa do espaço já alocado.
add $t8, $t6, $t7
s.d $f0, 0($t8)
# Atualizar a posição a guardar.
addi $t7, $t7, 8
j ler_novo_num_xtest

fim_arquivo_xtest:
# Guadar o último número do arquivo.
add $t8, $t6, $t7
s.d $f0, 0($t8)
# Fechar o arquivo.
move $a0, $s0 # Mover o descritor do arquivo para $a0
li $v0, 16 # Syscall para fechar o arquivo
syscall

# Guardar endereço de início do dados de xtest.
la $t7, 3832($t6)

# Montar retornos da função.
# $v0: endereço base dos dados de Xtrain.
# $v1: endereço base dos dados de Xtest.
move $v0, $t6
move $v1, $t7

# Retornar.
jr $ra

#                      FUNÇÃO PARA CRIAR MATRIX
# Função para alocar e preencher a matriz (Xtest ou Xtrain)
# Tem como parâmetros: endereço de início dos dados
# Retorna o endereço de início da matriz já preenchida.
montar_matriz:
	# Valor de w em $t1.
	la $t1, w
	lw $t1, 0($t1)
	# Valor de h em $t2.
	la $t2, h
	lw $t2, 0($t2)
	# Endereço base dos dados em $t3.
	move $t3, $a0

	# Calcular a quantidade de linhas → tamanho + 1 - (w + h), em $t0.
	la $t0, tamanho
	lw $t0, 0($t0)
	addi $t0, $t0, 1    # tamanho + 1
	add $t4, $t1, $t2   # w + h
	sub $t0, $t0, $t4
	
	# Espaço total ocupado pela matriz, em $t5.
	mul $t5, $t0, $t1   # Calcula o total de elementos da matriz, em $t5
	mul $t5, $t5, 8   # Calculo do total de bytes necessários, em $t5.
	
	# Aloca o espaço necessário para a matriz.
	move $a0, $t5       # Carrega o total de bytes necessários para syscall
	li $v0, 9           # Syscall para alocar espaço
	syscall
	# Endereço inicial da matriz em $t9.
	move $t9, $v0
	
	# Preencher a matriz.
	# Linhas já preenchidas.
	li $t4, 0
	preenche_linha:
		# Deslocamento do início dos dados que quero pegar em relação ao início dos dados.
		mul $t5, $t4, 8
		# Endereço inicial do conjunto que quero pegar.
		add $t5, $t3, $t5
		# Elementos já preenchidos na linha.
		li $t7, 0
		preenche_elemento:
			# Deslocamento do dado que quero pegar em relação ao início da "linha"
			mul $t8, $t7, 8
			# Endereço do dado que quero pegar.
			add $t8, $t5, $t8
			# Carrega o dado.
			l.d $f0, 0($t8)
			# Guarda na matriz.
			s.d $f0, 0($t9)
			# Avança para o próximo elemento da matriz.
			addi $t9, $t9, 8
			# Incrementa o contador de elementos da linha.
			addi $t7, $t7, 1
			# Se não chegou ao final da linha, preenche o próximo elemento.
			blt $t7, $t1, preenche_elemento
		# Incrementa contador de linhas
		addi $t4, $t4, 1
	# Se não chegou ao final da matriz, preenche a próxima linha
	blt $t4, $t0, preenche_linha
	
	# Retornar.
	jr $ra

#                      FUNÇÃO PARA CRIAR YTRAIN

# Parâmetros:
# Endereço base da matriz de Xtrain ($a0)

montar_ytrain:
	# Número de elementos do Xtrain em $t0.
	la $t0, tamanho
	lw $t0, 0($t0)

	# Calcular número de linhas da matriz do YTrain, em $t1.
	# Valor de w em $t1 e de h em $t2.
	la $t9, w
	lw $t9, 0($t9)
	la $t8, h
	lw $t8, 0($t8)
	addi $t1, $t0, 1
	add $t2, $t9, $t8
	sub $t1, $t1, $t2
	
	# Calcular espaço necessário para matriz do Ytrain, em $t2.
	mul $t2, $t1, 8
	
	# Guardar endereço base da matriz de Xtrain em $t3.
	move $t3, $a0
	
	# Alocar o espaço necessário para a matriz YTrain. Posso sobescrever $t2.
	move $a0, $t2
	li $v0, 9
	syscall
	
	# Endereço base do espaço alocado para a matriz de YTrain vai para $t4.
	move $t4, $v0
	
	# Contador de quantas linhas já inseri na matriz de YTrain, em $t5.
	addi $t5, $0, 0
	popular_matriz_ytrain:
		beq $t5, $t1, terminei_popular_matriz_ytrain
		# Se ainda há linhas a popular.
		# Posição do valor a ser colocado na matriz YTrain, em $t6.
		add $t6, $t9, $t8
		subi $t6, $t6, 1
		mul $t6, $t6, 8
		mul $t7, $t5, 8
		add $t6, $t6, $t7
		add $t6, $t3, $t6
		# Valor a ser colocado na matriz YTrain, em $f0.
		l.d $f0, 0($t6)
		# Posição de YTrain em que o valor deve ser guardado, em $t6.
		mul $t6, $t5, 8
		add $t6, $t4, $t6
		s.d $f0, 0($t6)
		addi $t5, $t5, 1
		j popular_matriz_ytrain

	terminei_popular_matriz_ytrain:
	# retornar o endereço base da matriz YTrain.
	move $v0, $t4
	jr $ra

################ FUNÇÃO QUE ALOCA MEMÓRIA PARA OS VETORES YTEST E DISTÂNCIAS.
# Recebe como parâmetro a quantidade de elementos que os vetores terão
# Retorna o endereço base do vetor ytest e endereço base de distâncias
alocar_vetores_ytest_e_distancias:
    mul $a0, $a0, 8     # calcula a quantidade de bytes necessárias
    li $v0, 9           # Chamada para alocar memória do primeiro vetor
    syscall
    move $v1, $v0       # salva o endereço base do vetor 1

    li $v0, 9           # Chamada para alocar memória do segundo vetor
    syscall
    jr $ra              # retorna para a função chamadora
    
################ FUNÇÃO QUE ALOCA UM VETOR DE TAMANHO K PARA ARMAZENAR OS ÍNDICES DOS K VIZINHOS MAIS PRÓXIMOS
# Não recebe parâmetros porque k é uma variável global
# Retorna o endereço base do vetor de índices
alocar_vetor_k:
    la $t0, k           # carrega o endereço da variável k
    lw $t0, 0($t0)      # carrega o valor de k
    mul $t0, $t0, 4     # calcula a quantidade de bytes necessárias
    move $a0, $t0       # passa o tamanho do vetor como parâmetro
    li $v0, 9           # Chamada para alocar memória
    syscall

    jr $ra              # retorna para a função chamadora
    
################ FUNÇÃO QUE ALOCA ESPAÇO PARA VETOR DE Ws
alocar_vetor_Ws:
	la $t2, w
	lw $t2, 0($t2)
	mul $t3, $t2, 8
	move $a0, $t3
	li $v0, 9
	syscall
	jr $ra

################ FUNÇÃO QUE MONTA O VETOR DE DISTÂNCIAS

# Parâmetros:
# Endereço base matriz Xtrain ($a0).
# Endereço base matriz Xtest ($a1).
# Índice da linha estudada (de Xtest) ($a2).
# Endereço base do vetor de Distâncias ($a3).

calcular_vetor_distancias:
	# Obter o índice da linha de Xtest que estou estudando, em $t0.
	move $t0, $a2
	# Obter endereço base da matriz Xtest, em $t1.
	move $t1, $a1
	# Obter a quantidade de elementos em cada linha, em $t2.
	la $t2, w
	lw $t2, 0($t2)
	# Obter o endereço base da linha de Xtest que estou estudando.
	# Quantos elementos há antes do início dessa linha?
	mul $t0, $t0, $t2
	# Quantos bytes isso ocupa?
	mul $t0, $t0, 8
	# Em qual endereço isso está?
	add $t0, $t0, $t1
	
	# Guardar endereço base da matriz Xtrain, em $t1.
	move $t1, $a0
		
	# Alocar espaço para vetor de Ws (que terá w doubles).
	subi $sp, $sp, 12
	sw $ra, 0($sp)
	sw $t0, 4($sp)
	sw $t1, 8($sp)
	jal alocar_vetor_Ws
	lw $t1, 8($sp)
	lw $t0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 12
	move $t3, $v0
	# Agora, o endereço base do vetor de Ws está em $t3.
	
	# Guardar os valores que estão na linha estudada, no vetor de Ws.
	# Quantos valores há na linha? $t2
	# Quantos valores já guardei?
	addi $t4, $0, 0
	# Guardar.
	guardar_no_vetor_Ws:
		beq $t4, $t2, fim_guardar_no_vetor_Ws
		# Endereço inicial do que tenho que guardar e de onde vou guardar.
		mul $t5, $t4, 8
		add $t6, $t3, $t5 # Endereço de onde tenho que guardar.
		add $t5, $t0, $t5 # Endereço do que tenho que guardar.
		l.d $f0, 0($t5) # Valor que tenho que guadar.
		s.d $f0, 0($t6) # Guardar o valor.
		addi $t4, $t4, 1
		j guardar_no_vetor_Ws

	fim_guardar_no_vetor_Ws:
		# Registradores que ainda importam.
		# $t1: endereço base da matriz Xtrain.
		# $t2: w
		# $t3: endereço base do vetor de Ws.
	
		# Agora, quero calcular a distância do vetor de Ws a cada linha de Xtrain.
	
		# Número de elementos do Xtrain em $t0.
		la $t0, tamanho
		lw $t0, 0($t0)
	
		# Número de linhas do Vetor De Distâncias, em $t4.
		la $t8, h
		lw $t8, 0($t8)
		addi $t4, $t0, 1
		add $t5, $t2, $t8
		sub $t4, $t4, $t5  # t4 recebe a quantidade total de linhas
	
		# Número de linhas já calculadas, em $t0.
		li $t0, 0
		calcular_linha:
			beq $t0, $t4, fim_calcular_linha
			# Obter endereço base da matriz Xtrain que quero considerar.
			mul $t5, $t0, $t2	# linhas calculadas*w
			mul $t5, $t5, 8		# em bytes
			add $t5, $t1, $t5	# + endereço base do XTrain
			# Verificar cada valor dessa linha.
			la $t6, numero_0
			l.d $f4, 0($t6)
			li $t6, 0
			calcular_valor:
				beq $t6, $t2, fim_calcular_valor	# Se t6 for igual a w, parar
				# Obter o deslocamento.
				mul $t7, $t6, 8
				# Endereço do elemento em Xtrain.
				add $t8, $t5, $t7	# Adiciona posição*8  no end base da linha
				# Endereço do elemento na linha fixa de Xtest (no vetor de Ws).
				add $t7, $t3, $t7	# 
				# Calcular.
				l.d $f0, 0($t8) # Elemento de Xtrain.
				l.d $f2, 0($t7) # Elemento de Xtest.
				sub.d $f0, $f2, $f0
				add.d $f4, $f4, $f0
				addi $t6, $t6, 1
				j calcular_valor
			fim_calcular_valor:
			# Guardar a distância na posição correta do vetor de Distâncias.
			# Posicação onde devo guardar.
			mul $t7, $t0, 8
			add $t7, $a3, $t7
			s.d $f4, 0($t7)
			addi $t0, $t0, 1
			j calcular_linha	
		fim_calcular_linha:
		jr $ra
	
####################     FUNÇÃO QUE CALCULA A MÉDIA DOS VALORES EM "YTRAIN" CORRESPONDENTES ÀS K MENORES DISTÂNCIAS
# Parâmetros:
# $a0: Endereço base do vetor de Ytrain.
# $a1: Endereço base do vetor com os índices das K menores distâncias.
calcular_media_ytrain:
	# Tamanho do vetor com os índices das K menores distâncias em double.
	la $t0, k_double
	l.d $f4, 0($t0)
	
	# Tamanho do vetor com os índices das K menores distâncias em int.
	la $t0, k
	lw $t0, 0($t0)
	
	# Para cada valor do arranjo em $a1.
	# Número de valores trabalhados.
	li $t1, 0
	# Somador.
	la $t9, numero_0
	l.d $f0, 0($t9)
	contabilizar:
		beq $t0, $t1, fim_contabilizar
		# Descobrir qual é o índice.
		mul $t2, $t1, 4
		add $t2, $a1, $t2
		lw $t2, 0($t2)
		# Descobrir o valor em Ytrain correspondente ao índice $t2.
		mul $t2, $t2, 8
		add $t2, $t2, $a0
		l.d $f2, 0($t2)
		# Somar esse valor ao somador.
		add.d $f0, $f0, $f2
		# Ir para próximo valor.
		addi $t1, $t1, 1
		j contabilizar

	fim_contabilizar:
	# Dividir a soma por k.
	# Converter o número inteiro em $t0 para um float, em $f2.
	div.d $f0, $f0, $f4
	
	# Aloca um espaço na memória para retornar o resultado
	li $a0, 8
	li $v0, 9
	syscall
	
	# Salva o resultado no endereço alocado e retorna o endereço
	s.d $f0, 0($v0)
	
	jr $ra
	
################ FUNÇÃO QUE ENCONTRA O K MENORES VALORES DE UM VETOR
# Função que encontra os menores k valores de um vetor
# Recebe: endereço do vetor k, endereço do vetor de distâncias
# Retorna: endereço do vetor com os k menores valores
achar_k_menores_distancias:
    move $t0, $a0         # t0 = endereço do vetor k
    move $t1, $a1         # t1 = endereço do vetor de distâncias
    la $t8, numero_0  # f0 = 0.0
    l.d $f0, 0($t8)       # f6 = maior valor

    # calculo o tamanho do vetor de distâncias
    la $t2, tamanho
    lw $t2, 0($t2)
    la $t3, w
    lw $t3, 0($t3)
    la $t6, h
    lw $t6, 0($t6)
    addi $t4, $t2, 1
    add $t5, $t3, $t6
    sub $t4, $t4, $t5
    move $t2, $t4     # t2 = tamanho do vetor de distâncias

    la $t5, k
    lw $t5, 0($t5)     # t5 = valor de k

    la $t4, maior_valor
    l.d $f6, 0($t4)     # salvo o maior valor em f6
    
    li $t6, 0		# salvo a posição 0
    li $t3, 0            # t3 = contador de elementos no vetor de K
    encontrar_k_valores:
        beq $t3, $t5, fim_k_valores
        # addi $t3, $t3, 1 tem que adicionar isso no final para poder usar como indice de onde guardar em k

	li $t6, 0            # t6 = resetar o indice do menor valor
        #guardar o primeiro elemento em $f2 para comparações
        l.d $f2, 0($t1)
        c.lt.d $f2, $f0 # se o valor for negativo
        bc1t primeiro_negativo

    volta_primeiro_negativo:
        li $t4, 0            # t4 = índice para percorrer
        # percorrer o array de distâncias e econtrar o menor elemento
        encontrar_menor_valor:
            beq $t4, $t2, fim_menor_valor
            mul $t7, $t4, 8
            add $t7, $t1, $t7
            l.d $f4, 0($t7)  # f4 = valor atual
            
            c.lt.d $f4, $f0 # se o valor for negativo
            bc1t e_negativo
        
        volta_e_negativo:
            c.lt.d $f4, $f2
            bc1t achei_menor
        volta_encontrar_menor:
            addi $t4, $t4, 1
            j encontrar_menor_valor
        
        #salvar o indice e colocar o maior valor no lugar
        fim_menor_valor:
            mul $t9, $t3, 4   # transforma o contador em um uma posição de .word
            add $t7, $t0, $t9 # t7 = endereço onde salvar o indice
            sw $t6, 0($t7)    # salvar o indice na posição correta no vetor k

            addi $t3, $t3, 1  # incrementar o contador de elementos ja armazenados em k

            #salvar o maior valor no lugar do menor, calcular a posição correta e salvar o maior_valor
            mul $t8, $t6, 8	   # conversao para bytes
            add $t7, $t1, $t8       #posição para inserir maior valor
            s.d $f6, 0($t7)         #salvar o maior valor na posição em que o menor valor estava anteriormente

            j encontrar_k_valores
    
    fim_k_valores:
        move $v0, $a0 #retornar o endereço do vetor k
        jr $ra

achei_menor:
    mov.d $f2, $f4  # f2 vira o menor valor para futuras comparações
    move $t6, $t4   # t6 salva o indice do menor valor, para conseguir sobrescrever e salvar no vetor k
    j volta_encontrar_menor

e_negativo:
    sub.d $f4, $f0, $f4 # transformar o valor negativo em positivo
    # armazenar o valor positivo no lugar do negativo
    mul $t9, $t4, 8
    add $t7, $t1, $t9
    s.d $f4, 0($t7)
    j volta_e_negativo
   
primeiro_negativo:
    sub.d $f2, $f0, $f2 # transformar o valor negativo em positivo
    # armazenar o valor positivo no lugar do negativo
    s.d $f2, 0($t1)
    j volta_primeiro_negativo

############################### FUNÇÃO QUE CALCULA A QUANTIDADE DE LINHAS DAS MATRIZES
# calcula a quantidade de linhas nas matrizes e escreve esse valor em linhas_matriz

calcula_linhas:
	# Quantidade total de linhas.
	la $s6, tamanho
	lw $s6, 0($s6)
	addi $s6, $s6, 1
	la $t9, w
	lw $t9, 0($t9)
	la $t8, h
	lw $t8, 0($t8)
	add $t9, $t9, $t8
	sub $s6, $s6, $t9
	sw $s6, linhas_matriz
	jr $ra
	
# Lógica para escrever em arquivo.
# Divide, até ter algo menos que 10. Escreve o dígito inteiro.
# Se dividi 2 vezes, faço o caractere que escreve * 100 e subtraio do número inicial.
# Vou repetindo.
# Se n tenho mais que dividir o número, escrevo ele e .
# Depois, vou multiplincado por 10, até ficar maior que 1.
# Escrevo e subtraio o que coloquei (dividido pelo número de mults).
# E assim vai.
# No arquivo, ele quer precisão de 2 casas.

# Função KNN
# Função que estima valores para YTest utilizando um algoritmo KNN
# Recebe como parâmetro: endereço de matriz x_train, endereço de matriz x_test e endereço de vetor y_train
knn:
	move $s0, $a0	# s0 = endereço de matriz x_train
	move $s1, $a1	# s1 = endereço de matriz x_test
	move $s2, $a2	# s2 = endereço de vetor y_train
	
	# Salvar em sp o $ra, porque teremos alguns jumps aqui dentro
	subi $sp, $sp, 4
	sw $ra, 0($sp)
	
	# Alocar espaço para Vetor de Distâncias.
	la $s6, linhas_matriz
	lw $s6, 0($s6)
	move $a0, $s6
	jal alocar_vetores_ytest_e_distancias
	move $s3, $v0 # Endereço base do Vetor de Distâncias = s3
	move $s4, $v1 # Endereço base do Vetor de Ytest = s4
	
	jal alocar_vetor_k
	move $s5, $v0	# Endereço base do Vetor de tamanho k = s5
	
	# Para cada índice de linha em Xtest, chamar "calcular_vetor_distancias"
	# Linhas de Xtest já usadas.
	li $s7, 0
		chamar_calcular_distancias:
		beq $s7, $s6, fim_chamar_distancia
		move $a0, $s0
		move $a1, $s1
		move $a2, $s7			# indice da linha fixada em X test
		move $a3, $s3
		jal calcular_vetor_distancias
		
		# Aqui eu tenho que chamar a função para achar as k menores distancias
		move $a0, $s5			# endereço do vetor de tamanho k
		move $a1, $s3			# endereço base do vetor de distancias
		jal achar_k_menores_distancias
		
		# Aqui eu tenho que chamar a função que calcula o valor correto de y test
		move $a0, $s2
		move $a1, $s5
		jal calcular_media_ytrain
		
		l.d $f20, 0($v0)		# Agora f20 possui o valor correto para ser armazenado

		mul $t0, $s7, 8		# Encontra o deslocamento correto para armazenar
		add $t0, $t0, $s4	# Encontra o endereço correto para armazenar em ytest

		s.d $f20, 0($t0)		# Armazenar o valor de ytest no local correto
		
		addi $s7, $s7, 1			# ir para a próxima linha fixada
		j chamar_calcular_distancias	

	fim_chamar_distancia:
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	# Retorna endereço do vetor ytest
	move $v0, $s4
	
	jr $ra

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
			bgt $s5, $s4, fim_escreve_antes_do_ponto
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
	
	jr $ra
	
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
