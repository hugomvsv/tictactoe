#$s0= número de linhas
#$s1= número de colunas
#s3=primeiro endereço onde foi alocada memoria
#s4=número total de elementos
#$s5=endereço onde esta o elemento escolhido
#$s6=elemento escolhido
#$s7=n jogadas

.data	
	infotabuleiro_msg: .asciiz "Legenda-> 0=Vazio, 1=X, 2=O\n"
    	linhas: .asciiz "Numero de linhas(>3): "
  	colunas: .asciiz "Numero de colunas(>3): "
  	linhasinv: .asciiz "O numero de linhas tem de ser >3\n"
  	colunasinv: .asciiz "O numero de colunas tem de ser >3\n"
   	player1_msg: .asciiz "P1:Digite uma posição: "
	player2_msg: .asciiz "P2:Digite uma posição: "
	player1_vitoria: .asciiz"Player 1 ganhou!!(+3pontos) e o"
	player2_vitoria: .asciiz"Player 2 ganhou!!(+3pontos)e o"
	player2zeropoints_msg: .asciiz "Player 2 continua com 0 pontos!\n"
	player1zeropoints_msg: .asciiz "Player 1 continua com 0 pontos!\n"
	p1losepoints_msg: .asciiz "Player 1 perde um ponto!\n"
	p2losepoints_msg: .asciiz "Player 2 perde um ponto!\n"
	invalida_msg: .asciiz "Esta posicao esta fora do tabuleiro ou ja foi preenchida!\n"
	printpoints: .asciiz "Pontos: "
	printwins: .asciiz "\tVitorias: "
	player1print_msg: .asciiz "Player 1-> "
	player2print_msg: .asciiz "Player 2-> "
	newline_msg:	.asciiz "\n"
	pontosp1:	.word 0
	pontosp2:	.word 0
	winsp1:		.word 0
	winsp2:		.word 0
	msg_empate: .asciiz "Jogo empatado!\n"

# Overwrites existing exception handler
        .ktext 0x80000180
        .set   noat     	# tell assembler not to use $at (assembler temporary)
       	                	# and hence not to complain when we do
        move   $k0, $at 	# save $at in $k0
                        	# $k0 and $k1 are reserved for 
                        	# OS and Exception Handling
                        	# programmer should not use them, so not saved
        .set   at       	# tell assembler it may use $at again

        li    $a0, 0xFFFF0004 	# Receiver data address (interrupt based, so don't need to check Receiver control)
        lw    $v0, 0($a0)     	# Receiver data 
       

	eret  			# return from exception, PC <- EPC

.text


main:	
	        li    $a0, 0xFFFF0000	# Receiver control
        lw    $t0, 0($a0)
        ori   $t0, 0x02		# set bit 1 to enable input interrupts
                              	# such a-synchronous I/O (handling of keyboard input in this case) 
                              	# this is much more efficient than the "polling" we use for output
                              	# In particular, it does not "block" the main program in case there is no input
        sw     $t0, 0($a0)    	# update Receiver control
	
        mfc0   $t0, $12  	# load coprocessor0 Status register
        ori    $t0, 0x01 	# set interrupt enable bit
    	j linha

forever:      
	beq $v0,'x',player1ganhou
	beq $v0,'o',player2ganhou
	beq $v0,'p',printtabuleiro
	beq $v0,'e',printwinsandpoints
	beq $v0,'f',exit
	
        j forever

linha:
        la $a0, linhas		#da print da msg linhas
        li $v0, 4
        syscall
        li $v0,5			#recebe int
        syscall
        move $s0,$v0
        bgt $v0,3,coluna 	#verifica se é maior que 3
        la $a0, linhasinv
        li $v0, 4		#da print da msg linhas invalidas
        syscall
	j linha
	
coluna:
        la $a0, colunas		#da print da msg colunas
        li $v0, 4
        syscall
        li $v0,5			#recebe int
        syscall
        move $s1, $v0
        bgt $v0,3,criarespaco	#verifca se é maior que 3
       	la $a0, colunasinv	#da print da msg colunas invalidas
        li $v0, 4
        syscall
        j coluna
        
criarespaco:
        mul $s4,$s0,$s1		#multiplica o n linhas pelo n colunas
        #alocar espaço
        sll $a0,$s4, 2		#mult n elemento por 4
        li  $v0,9		# utiliza o sbrk para alocar memoria na heap
        syscall 
        move $s3,$v0		#o primeiro endereço ondeé alocada memória é guardado em s3
	jal desenhar_linhas	#desenha as N linhas no bitmap
	jal desenhar_colunas	#desenha as M linhas no bitmap
	jal limpartabuleiro
        j player1
        
player1:
	li $v0,4			#imprime a msg do player1
	la $a0,player1_msg
	syscall
	li $v0,5			#Scan da posição
	syscall
	addi $v0,$v0,-1		#remove 1, para poder começar em 1 e não em 0
	move $s6,$v0		#$s6 fica com o valor da posição escolhida
	mul $t0,$v0,4		#multiplica por 4 por causa da memora c inteiros saltar de 4 em 4
	move $s5,$s3		#neste momento s5 tem o valor do primeiro endereço onde esta alocado memoria
	add $s5,$s5,$t0		#adiciona a $s5 o numero de bytes onde pretende escrever
	move $a0,$v0		#move para a0 a posiçao escolhida
	jal posicaovalida	#faz a verificação se a posição é valida
	beq $v0,0,posinvalidap1	#se $v0=0 a posição é inválida
	li $t1,1 		#t1=1=>x
	sw $t1, 0($s5)		#guarda na posição obtida do output
	addi $s7,$s7,1
	bgt $s7,$s4,empate
	jal desenha_x	#desenha o x no bitmap
	#verificações de vitoria
	jal verificalinha1
	jal verificalinha2
	jal verificalinha3
	jal verificacoluna1
	jal verificacoluna2	
	jal verificacoluna3
	jal verifica1diagonal1
	jal verifica1diagonal2
	jal verifica1diagonal3
	jal verifica2diagonal1
	jal verifica2diagonal2
	jal verifica2diagonal3
	jal forever
	j player2		#salta para a jogada seguinte se nao existir vitoria
	
player2:
	li $v0,4			#imprime a msg do player2
	la $a0,player2_msg
	syscall
	li $v0,5			#Scan da posição
	syscall
	addi $v0,$v0,-1		#remove 1, para poder começar em 1 e não em 0
	move $s6,$v0		#$s6 fica com o valor da posição escolhida
	mul $t0,$v0,4		#multiplica por 4 por causa da memora c inteiros saltar de 4 em 4
	move $s5,$s3		#neste momento s5 tem o valor do primeiro endereço onde esta alocado memoria
	add $s5,$s5,$t0		#adiciona o numero de bytes necessário para avançar para a posição seguinte
	move $a0,$v0		#move para a0 a posiçao escolhida
	jal posicaovalida	#verifica se a posição é valida
	beq $v0,0,posinvalidap2	#se $v0=0, a posição é invalida
	li $t1,2 		#t1=2=>y
	sw $t1, 0($s5)		#guarda na posição obtida do output
	jal desenha_o		#desenha os O no bitmap
	addi $s7,$s7,1
	bgt $s7,$s4,empate
	#verificações de vitoria
	jal verificalinha1
	jal verificalinha2
	jal verificalinha3
	jal verificacoluna1
	jal verificacoluna2	
	jal verificacoluna3
	jal verifica1diagonal1
	jal verifica1diagonal2
	jal verifica1diagonal3
	jal verifica2diagonal1
	jal verifica2diagonal2
	jal verifica2diagonal3
	jal forever
	j player1		#salta para a jogada seguinte se não existir vitória
	
exit: 
	li $v0,10
	syscall
#Verifica se a posição está dentro da matriz, e se não está ocupada(0=invalida, 1=valida)
posicaovalida:
	addi $t1,$s4,-1		# n elementos -1
	bgt $a0,$t1,invalida	#se >n elementos-1 posição invalida
	blt $a0,0,invalida	#se <0 posiçao inválida
	move $t6,$s3		#move para $t6 o valor do primeiro endereço alocado
	mul  $t0,$a0,4		#multipiclar por 4 o valor da posição escolhida e guardar em $t0
	add $t6,$t6,$t0		#adicionar a $t6 o valor necessário para saltar para o endereço da posição escolhida
	lw $t7,0($t6)		
	beq $t7,1,invalida	#se for diferente de 1 está ocupado
	beq $t7,2,invalida	#se for diferente de 2 está ocupado
	li $v0,1			#se a posição for valida retorna 1
	jr $ra
		
invalida:
	li $v0,0			#se a posição for invalida retorna 0
	jr $ra

posinvalidap1:
	li $v0,4			#da print que a posição é invalida
	la $a0, invalida_msg
	syscall
	j player1
	
posinvalidap2:
	li $v0,4			#da print que a posição é invalida
	la $a0, invalida_msg
	syscall
	j player2
	
#Dà print ao conteudo do tabuleiro
printtabuleiro:
		li $v0,4
		li $t2,0
		la $a0,infotabuleiro_msg
		syscall
		move $t0,$s3
	print:	
		beq $t3,$s4,endprint
		lw $t1,0($t0)
		addi $t3,$t3,1
		addi $t0,$t0,4
		li $v0,1
		move $a0,$t1
		syscall
		addi $t2,$t2,1
		beq $t2,$s1,newline
		j print
	newline:
		li $t2,0
		li $v0,4
		la $a0,newline_msg
		syscall
		j print
		
	endprint:
		li $v0,4
		la $a0,newline_msg
		syscall
		jr $ra

	
#########VERIFICA VITORIA

naovenceu:
jr $ra				#volta à função onde foi chamada
#se o player 1 ganhar
player1ganhou:
	li $v0,4
	la $a0,player1_vitoria
	syscall
	lw $t0,winsp1
	addi $t0,$t0,1
	sw $t0,winsp1
	lw $t0,pontosp1
	addi $t0,$t0,3
	sw $t0,pontosp1
	lw $t0,pontosp2
	beq $t0,0 p2zeropoints#se o player 1 não tiver nenhum ponto não se substrai
	li $v0,4
	la $a0, p2losepoints_msg
	syscall
	addi $t0,$t0,-1
	sw $t0,pontosp2
	j endpoints
p2zeropoints:
	li $v0,4
	la $a0,player2zeropoints_msg
	syscall
	j endpoints

	
#se o player2 ganhar
player2ganhou:
	li $v0,4
	la $a0,player2_vitoria
	syscall
	lw $t0,winsp2
	addi $t0,$t0,1
	sw $t0,winsp2
	lw $t0,pontosp2
	addi $t0,$t0,3
	sw $t0,pontosp2
	lw $t0,pontosp1
	beq $t0,0 p1zeropoints#se o player 1 não tiver nenhum ponto não se substrai
	li $v0,4
	la $a0, p1losepoints_msg
	syscall
	addi $t0,$t0,-1
	sw $t0,pontosp1
	j endpoints
p1zeropoints:
	li $v0,4
	la $a0,player1zeropoints_msg
	syscall
	j endpoints
endpoints:
	jal limpartabuleiro
	jal printwinsandpoints
	j linha
empate:
	li $v0,4
	la $a0,msg_empate
	syscall
	j linha
limpartabuleiro:
	li $t0,0
	move $t2,$s3
	add $s7,$0,$0
loop1:	beq $t0,$s4,leave1
	addi $t1,$0,0
	sw $t1,0($t2)
	addi $t2,$t2,4
	addi $t0,$t0,1
	j loop1
leave1:
	jr $ra
	#dá print das wins e dos pontos dos 2 players
printwinsandpoints:
	li $v0,4
	la $a0,player1print_msg
	syscall
	li $v0,4
	la $a0,printpoints
	syscall
	lw $t0, pontosp1
	li $v0,1
	move $a0,$t0
	syscall
	li $v0,4
	la $a0, printwins
	syscall
	lw $t0, winsp1
	li $v0,1
	move $a0,$t0
	syscall
	li $v0,4
	la $a0,newline_msg
	syscall
	li $v0,4
	la $a0,player1print_msg
	syscall
	li $v0,4
	la $a0,printpoints
	syscall
	lw $t0, pontosp2
	li $v0,1
	move $a0,$t0
	syscall
	li $v0,4
	la $a0, printwins
	syscall
	lw $t0, winsp2
	li $v0,1
	move $a0,$t0
	syscall
	li $v0,4
	la $a0,newline_msg
	syscall
	jr $ra
##LINHA

verificalinha1:			# X - -

move $t1,$s5			#passa para t1 o valor do endereço na posição escolhida
addi $t2,$s5,4			#adiciona 4 para verificar a posição seguinte
addi $t3,$s5,8			#adiciona 8 para verificar a segunda posiçao seguinte
lw $t1,0($t1)			#da load do conteúdo
lw $t2,0($t2)
lw $t3,0($t3)
bne $t1,$t2,naovenceu		#se $t1 != $t2 então nao testa mais
bne $t1,$t3,naovenceu		#Se $t1 != $t3 então nao ganhou
beq $t1,1,player1ganhou		#verifica se foi o p1 ou p2 que ganhou
beq $t1,2,player2ganhou

verificalinha2:			# - - X
move $t1,$s5			#passa para t1 o valor do endereço na posição escolhida
addi $t2,$s5,-4			#adiciona -4 para verificar a posição anterior
addi $t3,$s5,-8			#adiciona -8 para verificar a segunda posição anterio
lw $t1,0($t1)			#da load do conteudo
lw $t2,0($t2)
lw $t3,0($t3)
bne $t1,$t2,naovenceu		#se $t1 != $t2 então nao testa mais
bne $t1,$t3,naovenceu		#se $t1 != $t3 nao ganhou
beq $t1,1,player1ganhou		# verifica se foi p1 ou p2 que ganou
beq $t1,2,player2ganhou

verificalinha3:			# - X -
move $t1,$s5			#passa para $t1, o valor do endereço na posição escolhida
addi $t2,$s5,-4			#adiciona -4 para verifcar a posição anterior
addi $t3,$s5,4			#adiciona 4 para verificar a posição seguinte
lw $t1,0($t1)			#da load do conteudo
lw $t2,0($t2)
lw $t3,0($t3)
bne $t1,$t2,naovenceu		#se $t1 != $t2 então nao testa mais
bne $t1,$t3,naovenceu		#se $t1 != $t3 nao ganhou
beq $t1,1,player1ganhou		#verifica se foi p1 ou p2 que ganhou
beq $t1,2,player2ganhou

##COLUNA

verificacoluna1:			# X | |
move $t1,$s5			#passa para $t1, o valor do endereço na posição escolhida
mul $t4,$s1,4			#multipilica o numero de colunas por 4
add $t2,$s5,$t4			#vai para a linha seguinte
mul $t5,$s1,8			#multiplica por 2 para ir para a segunda linha seguinte
add $t3,$s5,$t5
lw $t1,0($t1)			#da load do conteudo
lw $t2,0($t2)
lw $t3,0($t3)
bne $t1,$t2,naovenceu		#se $t1 != $t2 então nao testa mais
bne $t1,$t3,naovenceu		#se $t1 != $t3 nao ganhou
beq $t1,1,player1ganhou		#verifica se foi p1 ou p2 que ganhou
beq $t1,2,player2ganhou


verificacoluna2:			# | | X
move $t1,$s5			#passa para $t1, o valor do endereço na posição escolhida
mul $t4,$s1,-4			#multipilica o numero de colunas por -4
add $t2,$s5,$t4			#vai  para a linha anterior
mul $t5,$s1,-8			#vai para a segunda linha anterior
add $t3,$s5,$t5
lw $t1,0($t1)			#da load do conteudo
lw $t2,0($t2)
lw $t3,0($t3)
bne $t1,$t2,naovenceu		#se $t1 != $t2 então nao testa mais
bne $t1,$t3,naovenceu		#se $t1 != $t2 nao ganhou
beq $t1,1,player1ganhou		#verifica se foi p1 ou p2 que ganhou
beq $t1,2,player2ganhou

verificacoluna3:			# | X |
move $t1,$s5			#passa para $t1, o valor do endereço na posição escolhida
mul $t4,$s1,4			#multipilica o numero de colunas por 4
add $t2,$s5,$t4			#vai para a linha seguinte
mul $t5,$s1,-4			#multipilica o numero de colunas por -4
add $t3,$s5,$t5			#vai para a linha anterior
lw $t1,0($t1)			#da load do conteudo
lw $t2,0($t2)
lw $t3,0($t3)
bne $t1,$t2,naovenceu		#se $t1 != $t2 então nao testa mais
bne $t1,$t3,naovenceu		#se $t1 != $t3 nao ganhou
beq $t1,1,player1ganhou		#verifica se foi p1 ou p2 que ganhou
beq $t1,2,player2ganhou


##DIAGONAL1			# X \ \
verifica1diagonal1:
move $t1,$s5			#passa para $t1, o valor do endereço na posição escolhida
mul $t4,$s1,4			#multiplica o numero de colunas por 4 para ir para a linha seguinte
addi $t4,$t4,4			#adiciona 4 para andar mais uma posição
add $t2,$s5,$t4			
mul $t5,$s1,8			#multiplica o numero de colunas por 8 para ir para a segunda linha seguinte 
addi $t5,$t5,8			#adiciona 8  para andar para andar duas posições
add $t3,$s5,$t5
lw $t1,0($t1)			#da load do conteudo
lw $t2,0($t2)
lw $t3,0($t3)
bne $t1,$t2,naovenceu		#se $t1 != $t2 então nao testa mais
bne $t1,$t3,naovenceu		#se $t1 != $t3 nao ganhou
beq $t1,1,player1ganhou		#verifica se foi p1 ou p2 que ganhou
beq $t1,2,player2ganhou

verifica1diagonal2:		# \ \ X
move $t1,$s5			#passa para $t1, o valor do endereço na posição escolhida
mul $t4,$s1,-4			#multiplica o numero de colunas por -4 para ir para a linha anterior
addi $t4,$t4,-4			#adiciona -4 para andar uma posuçao para tras
add $t2,$s5,$t4
mul $t5,$s1,-8			#multiplica o numero de colunas por -8 para ir para a segunda linha anterior
addi $t5,$t5,-8			#adiciona -8 para and
add $t3,$s5,$t5
lw $t1,0($t1)			#da load do conteudo
lw $t2,0($t2)
lw $t3,0($t3)
bne $t1,$t2,naovenceu		#se $t1 != $t2 então nao testa mais
bne $t1,$t3,naovenceu		#se $t1 != $t3 nao ganhou
beq $t1,1,player1ganhou		#verifica se foi p1 ou p2 que ganhou
beq $t1,2,player2ganhou

verifica1diagonal3:		# \ X \
move $t1,$s5			#passa para $t1, o valor do endereço na posição escolhida
mul $t4,$s1,4			#multiplica o numero de colunas por 4 para ir para a linha seguinte
addi $t4,$t4,4			#adiciona 4 para andar uma posição para a frente
add $t2,$s5,$t4
mul $t5,$s1,-4			#multiplica o numero de colunas por -4 para ir para a linha anterior
addi $t5,$t5,-4			# adiciona -4 para andar uma poseção para trás
add $t3,$s5,$t5
lw $t1,0($t1)			#da load do conteudo
lw $t2,0($t2)
lw $t3,0($t3)
bne $t1,$t2,naovenceu		#se $t1 != $t2 então nao testa mais	
bne $t1,$t3,naovenceu		#se $t1 != $t3 nao ganhou
beq $t1,1,player1ganhou		#verifica se foi p1 ou p2 que ganou
beq $t1,2,player2ganhou

##DIAGONAL2
verifica2diagonal1:		# / / X
move $t1,$s5			#passa para $t1, o valor do endereço na posição escolhida
mul $t4,$s1,4			#multiplica o numero de colunas por 4 para ir para a linha seguinte
addi $t4,$t4,-4			#adiciona -4 para andar uma posiçao para tras
add $t2,$s5,$t4
mul $t5,$s1,8			#multiplica o numero de colunas por 8 para ir para a segunda linha seguinte
addi $t5,$t5,-8			#adiciona -8 para andar para andar duas posições para tras 
add $t3,$s5,$t5
lw $t1,0($t1)			#dar load de conteudo
lw $t2,0($t2)
lw $t3,0($t3)
bne $t1,$t2,naovenceu		#se $t1!=!$t2 entao nao testa mais
bne $t1,$t3,naovenceu		#se $t1 !=$t3 nao ganhou
beq $t1,1,player1ganhou		#verifica se foi p1 ou p2 que ganou
beq $t1,2,player2ganhou
j linha

verifica2diagonal2:		# X / /
move $t1,$s5			#passa para $t1, o valor do endereço na posição escolhida
mul $t4,$s1,-4			#multiplica o numero de colunas por -4 para ir para a linha anterior
addi $t4,$t4,4			#adiciona 4 para andar uma posição para a frente
add $t2,$s5,$t4
mul $t5,$s1,-8			#multiplica o numero de colunas por -8 para ir para a segunda linha anterior
addi $t5,$t5,8			#adiciona 8 para andar duas posições para a frente
add $t3,$s5,$t5
lw $t1,0($t1)			#dar load de conteuto
lw $t2,0($t2)
lw $t3,0($t3)
bne $t1,$t2,naovenceu		#se $t1!=$t2 entao nao testa mais
bne $t1,$t3,naovenceu		#se $t1 !=$t3 nao ganhou
beq $t1,1,player1ganhou		#verifica se foi p1 ou p2 que ganou
beq $t1,2,player2ganhou
j linha

verifica2diagonal3:		# / X /
move $t1,$s5			#passa para $t1, o valor do endereço na posição escolhida
mul $t4,$s1,4			#multiplica o numero de colunas por 4 para ir para a linha seguinte
addi $t4,$t4,-4			#adicionar -4 para andar uma posição para tras
add $t2,$s5,$t4			
mul $t5,$s1,-4			#multiplica o numero de colunas por -4 para ir para a linha anterior
addi $t5,$t5,4			#adicionar 4 para andar uma posição para a frente
add $t3,$s5,$t5
lw $t1,0($t1)			#dar load do conteudo
lw $t2,0($t2)
lw $t3,0($t3)
bne $t1,$t2,naovenceu		#se $t1!=$t2 entao nao testa mais
bne $t1,$t3,naovenceu		#se $t1!=$t3 nao ganhou
beq $t1,1,player1ganhou		#verifica se foi p1 ou p2 que ganhpi
beq $t1,2,player2ganhou		
j linha

desenhar_linhas:
li $t7,1 			# porquew temos de desenhar ncolunas -1 
ciclo:
beq $t7,$s0,desenhar_colunas	#se s7=ncolunas-1 passa para as colunas	

# PASSANDO A COR DESEJADA EM HEXADECIMAL
li $t1, 0xF3F6FE
#Endereco inicial onde sera desenhado
lui $t0, 0x1001
#1024 x 256 equivale a distancia vertical do inicio do bitmap e aonde sera desenhado o primeiro pixel
li $t5, 1024
li $t6, 256
div $t6,$t6,$s1  		#dividir 256 pelo n colunas
mul $t8,$t7,$t6			# distancia a incrementar
addi $t7,$t7,1			
add $t6,$t8,$0			#incrementa a distancia
mult $t5, $t6
mflo $t6
#VERTICAL
add $t0, $t0, $t6
#HORIZONTAL
#A soma do endereco inicial com 56 significa incrementar em 56 pixels a distancia horizontal
addi $t0, $t0, 56
# contador
li $t2, 0
linha_horizontal:
	# STORE NA COR NO ENDEREÃ‡O DESEJADO
	sb $t1, 0($t0)
	# AUMENTANDO DE 4 EM 4 PARA IR PARA A DIREITA
	addi $t0, $t0, 4
	# INCRIMENTAR CONTADOR
	addi $t2, $t2, 1
	bne $t2, 224, linha_horizontal
	j ciclo	
fim_contador:
jr $ra

desenhar_colunas:
li $t7,1
ciclo2:
beq $t7,$s1,fim_contador
# Desenha linhas verticais
lui $t0, 0x1001
li $t6, 20
mult $t5, $t6
mflo $t6
#VERTICAL
add $t0, $t0, $t6
#HORIZONTAL
li $t8,1024
div $t8,$t8,$s1
mul $t8,$t8,$t7
addi $t7,$t7,1
add $t0, $t0, $t8
li $t2, 0
linha_vertical:
	addi $t0, $t0, 1024
	sb $t1, 0($t0)
	addi $t2, $t2, 1
	bne $t2, 200,linha_vertical
	j ciclo2
	
desenha_x:

	li $t1, 0x00FF00
	lui $t0, 0x1001
	ori $t2, $0, 0
	#VERTICAL
	li $t3,0
	li $t4,0
	move $t9,$s6
	ciclo3:
	bgt $s1,$t9,fim_ciclo3
	li $t8,256
	div $t8,$t8,$s0
	add $t3,$t3,$t8
	sub $t9,$t9,$s1
	j ciclo3
	fim_ciclo3:
	add $t4,$t4,1024
	add $t4,$t4,0
	mult $t3, $t4
	mflo $t5
	add $t0, $t0, $t5
	#HORIZONTA
	li $t8,1024
	div $t8,$t8,$s1
	move $t9,$s6
	mul $t8,$t8,$t9
	add $t0,$t0,$t8
	
	j primeira_linha

primeira_linha:
	addi $t0, $t0, 1024
	addi $t0, $t0, 4
	sw $t1, 0($t0)
	addi $t2, $t2, 1
	bne $t2, 30, primeira_linha
	subu $t0, $t0, 120
	ori $t2, $0, 0
segunda_linha:
	sub $t0, $t0, 1024
	addi $t0, $t0, 4
	sw $t1, 0($t0)
	addi $t2, $t2, 1	
	bne $t2, 30, segunda_linha
	jr $ra

desenha_o:
				
	li $t1, 0xFF1493
	lui $t0, 0x1001
	ori $t2, $0, 0
	#VERTICAL
	li $t3,0
	li $t4,0
	move $t9,$s6
	ciclo4:
	bgt $s1,$t9,fim_ciclo4
	li $t8,256
	div $t8,$t8,$s0
	add $t3,$t3,$t8
	sub $t9,$t9,$s1
	j ciclo4
	fim_ciclo4:
	add $t4,$t4,1024
	mult $t3, $t4
	mflo $t5
	add $t0, $t0, $t5
	#HORIZONTA
	li $t8,1024
	div $t8,$t8,$s1
	move $t9,$s6
	mul $t8,$t8,$t9
	add $t0,$t0,$t8
	
	j desenhar_y
	
desenhar_y:	
	segunda_parte:
		addi $t0, $t0, 108
		addi $t0, $t0, 30720
		li $t2, 0
	segunda_linha_h:
		sb $t1, 0($t0)
		subu $t0, $t0, 4
		addi $t2, $t2, 1
		bne $t2, 15, segunda_linha_h
	terceira_parte:
		ori $t2, $0, 0
	primeira_diagonal:
		sb $t1, 0($t0)
		subu $t0, $t0, 1024
		sub $t0, $t0, 4
		addi $t2, $t2, 1
		bne $t2, 9, primeira_diagonal
	quarta_parte:
		ori $t2, $0, 0
	primeira_linha_v:
		sb $t1, 0($t0)	
		subu $t0, $t0, 1024
		addi $t2, $t2, 1
		bne $t2, 15, primeira_linha_v
	quinta_parte:
		ori $t2, $0, 0
	segunda_diagonal:
		sb $t1, 0($t0)
		addi $t0, $t0, 4
		subu $t0, $t0, 1024
		addi $t2, $t2, 1
		bne $t2, 9, segunda_diagonal
	sexta_parte:
		ori $t2, $0, 0
	segunda_linha_ho:
		sb $t1, 0($t0)
		addi $t0, $t0, 4
		addi $t2, $t2, 1
		bne $t2, 15, segunda_linha_ho
		nop
	setima_parte:
		ori $t2, $0, 0
	terceira_diagonal:
		sb $t1, 0($t0)
		addi $t0, $t0, 4
		addi $t0, $t0, 1024
		addi $t2, $t2, 1
		bne $t2, 9, terceira_diagonal
	
	oitava_parte:
		ori $t2, $0, 0
	segunda_vertical:
		sb $t1, 0($t0)
		addi $t0, $t0, 1024
		addi $t2, $t2, 1
		bne $t2, 15, segunda_vertical
	nona_parte:
		ori $t2, $0, 0
	quarta_diagonal:
		sb $t1, 0($t0)
		addi $t0, $t0, 1024
		subu $t0, $t0, 4
		addi $t2, $t2, 1
		bne $t2, 9, quarta_diagonal
		jr $ra
		

