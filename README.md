# tictactoe
Dinamic TicTacToe in Assembly

Resumo:
O programa proposto tem como objetivo replicar o tradicional “Jogo do Galo” com o
número de colunas e linhas escolhidas pelo utilizador .
Para utilizar as interrupções é necessário abrir e conectar ao MIPS a ferramenta “Keyboard
and Display MMIO Simulator”.
Para utilizar a interface gráfica é necessário abrir e conectar ao MIPS a ferramenta “Bitmap
display”.

Para uma melhor interação com o utilizador no preenchimento do tabuleiro as posições
estão dispostas da seguinte forma (exemplo 4x4):

![alt text](https://i.imgur.com/HPEZsWx.png)

Após o utilizador escolher a posição que pretende preencher é necessário haver uma interrupção.
Para uma melhor experiência com a interface gráfica, é necessário utilizar a configuração seguinte:

![alt text](https://i.imgur.com/6PCd7JU.png)

Tabela das interrupções:

![alt text](https://i.imgur.com/P0g7v7u.png)

Imagens do programa em execução:
• Criação do tabuleiro na interface gráfica:
O número de linhas e colunas terá de ser maior que 3.

![alt text](https://i.imgur.com/uGNR41V.png)

• Escolher posição para o player1

![alt text](https://i.imgur.com/C44sSWd.png)

• Executar interrupção para verificar pontos dos players

![alt text](https://i.imgur.com/FBbUB1R.png)

• Player 1 vence

![alt text](https://i.imgur.com/UhS1h4n.png)
