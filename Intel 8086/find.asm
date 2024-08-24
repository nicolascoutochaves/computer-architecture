;============================ Trabalho Intel 8086 =================================
;	Programa assembly do Intel 8086 que encontra palavras em um arquivo texto
;     - Nome do arquivo passado como argumento na linha de comando
;     - O programa mostrara o numero da linha que encontrou a palavra
;     - O programa mostrara a palavra anterior e a seguinte a palavra encontrada
;     - O texto deve estar de acordo com a tabela ascii, caso contrario, acentuacoes,
;       cedilha e outros caracteres serao ignorados
;     - O limite de linhas do texto e de 999. acima disso printara errado a linha atual
;===================================================================================
;

    .model small
    .stack

CR equ 0dh ;Carriage Return
LF equ 0ah ;Line Feed
BS equ 08h ;Backspace

BUFFER_SIZE equ 30 ;tamnho maximo para buffer de palavras
MAX_CMD equ 30     ;tamanho maximo para o nome do arquivo passado atraves do console

    .data
;========================== Variaveis ===============================
handle dw ? ;handle de arquivos
wasfound db ? ;flag para printar se foi encontrado
isNotValid db 0 ;flag para verificar se a palavra digitada e valida
linha dw 0 ;linha atual dentro do arquivo
showNext db 0   ;flag que controla se deve mostrar a proxima palavra (caso a palavra pesquisada foi encontrada
sw_n	dw	0   ;sprintf: numero n a ser convertido para string
sw_m	dw	0   ;sprintf: numero m usado para obter n / m e n % m
; =============================== Strings ===============================
CMDLINE db 256 dup(0) ;buffer para armazenar a linha de comando
input db BUFFER_SIZE dup(0) ;buffer para armazenar a palavra digitada pelo usuario
charContinue db 0 ;variavel para armazenar a resposta do usuario se ele quer continuar a busca
fileBuffer db ? ;buffer para armazenar o caractere lido do arquivo
palavra_anterior db BUFFER_SIZE dup(0) ;buffer para armazenar a palavra anterior a palavra encontrada
palavra_atual db BUFFER_SIZE dup(0) ;buffer para armazenar a palavra atual lida do arquivo
palavra_tmp db BUFFER_SIZE dup(0) ;t emporario usado para printar em uppercase a palavra atual
;========================================================================

;========================== Seção de mensagens ===========================
msgPedePalavra db "-- Que palavra voce quer buscar?", CR,LF,0
msgPalavraInvalida db "-- Por favor, digite uma palavra valida (sem acentuacao).", CR, LF, 0
msgErrorOpenFile db "Erro na abertura do arquivo.", CR, LF, 0
msgErrorReadFile db "Erro na leitura do arquivo.", CR, LF, 0
msgFound db CR, LF, "-- Foram encontradas as seguintes ocorrencias:", CR, LF, 0
msgNotFound db "-- Nao foram encontradas ocorrencias.", CR, LF, 0
msgFimBusca db "-- Fim das ocorrencias.", CR, LF, CR, LF, 0
msgContinuar db "-- Quer buscar outra palavra? (S/N)", CR, LF, 0
msgCharInvalido db "-- Por favor, responda somente S ou N.", CR, LF, 0
strLinha db "Linha 000: ", 0 ;string para printar o numero da linha que foi encontrada a palavra
strLinhaBuffer db 3 dup(0)  ;buffer para o n da linha atual convertido para string
space db " ", 0  ;string para printar um espaco
CRLF db CR, LF, 0 ;string para printar uma nova linha
;========================================================================

    .code
;========================== Main ========================================
    .startup
    push ds ; Salva as informacoes de segmentos
    push es
    mov ax, ds ; Troca DS com ES para poder usa o REP MOVSB
    mov bx, es
    mov ds, bx
    mov es, ax
    mov si, 80h ; Obtem o tamanho da linha de comando e coloca em CX
    mov ch, 0
    mov cl, [si]
    mov ax, cx ; Salva o tamanho do string em AX, para uso futuro
    mov si, 81h ; Inicializa o ponteiro de origem
    lea di, CMDLINE ; Inicializa o ponteiro de destino
    rep movsb
    pop es ; retorna os dados dos registradores de segmentos
    pop ds

    mov si, ax ; Coloca o tamanho do string em SI
    mov bx, di ; Coloca o ponteiro para o string em BX
    mov byte ptr [bx+si], 0 ; Adiciona um \0 ao final do string
    
    mov ax, ds
    mov es, ax

main_loop:
; reset de variaveis e flags
    mov linha, 1 ;inicializa a variavel linha com o valor inicial '1'
    mov wasfound, 0
    mov showNext, 0
    mov isNotValid, 0

; limpa os buffers de palavras
    mov cx, BUFFER_SIZE
    lea di, input
    call ClearBuffer
    mov cx, BUFFER_SIZE
    lea di, palavra_anterior
    call ClearBuffer

; pede a palavra para o usuario
    lea bx, msgPedePalavra
    call printf
; le a palavra digitada pelo usuario
    mov cx, BUFFER_SIZE
    lea bx, input
    call Gets
; converte a palavra para uppercase e verifica se e valida
    mov cx, BUFFER_SIZE
    lea bx, input
    call toUpper
    call IsValid
    cmp isNotValid, 0
    je call_Openfile
    mov isNotValid, 0
;exibe mensagem de erro caso a palavra seja invalida
    lea bx, msgPalavraInvalida
    call printf
    jmp main_loop

call_Openfile:
; abre o arquivo
    call OpenFile
    jc OpenFileError
    call GetOccurences  ;chama a funcao que le o arquivo e procura a palavra

;verifica se nao encontrou para printar a msg
    cmp wasfound, 0
    jne continue
    lea bx, msgNotFound
    call printf
continue:
;Se encontrou, printa a mensagem de fim da busca
    cmp wasfound, 0    
    je pergunta_continuar
    lea bx, msgFimBusca
    call printf
pergunta_continuar:
;pergunta se usuario deseja continuar
    lea bx, msgContinuar
    call printf
    mov cx, 1
    lea bx, charContinue
    call Gets

;converte o char recebiido para uppercase
    mov cx, 1
    lea bx, charContinue
    call toUpper

    cmp charContinue, 'N'
    je Finish
    cmp charContinue, 'S'
;se o char nao for valido, exibe mensagem de erro
    je main_loop
    lea bx, msgCharInvalido
    call printf
    jmp pergunta_continuar 

;====================================================================

;========================== Erros ===================================

ReadFileError:
    lea bx, msgErrorReadFile
    call printf
    jmp Finish
    
OpenFileError:
    lea bx, msgErrorOpenFile
    call printf
    jmp Finish
Finish:
    mov bx, handle
    mov ah, 3eh
    int 21h
    .exit

;=====================================================================

;============= Funcoes de pesquisa no arquivo ========================

;Le o arquivo e procura a palavra
GetOccurences proc near   
getoccurences_reset:
;carrega o buffer de leiura do arquivo
    lea dx,fileBuffer
    mov di, 0 ;di conta os caracteres da palavra atual
getoccurences_loop:
;le um caractere do arquivo
    mov bx, handle
    mov ah, 3fh
    mov cx, 1
    int 21h
    jc ReadFileError
    cmp ax, 0   ;verifica se chegou ao fim do arquivo
    je getoccurences_end 

;compara com os caracteres especiais e ignora algumas pontuacoes para achar palavras terminadas por ponto ou virgula por exemplo
    cmp fileBuffer, ' '
    je getoccurences_again
    cmp fileBuffer, CR
    je getoccurences_newline
    cmp fileBuffer, LF
    je getoccurences_again
    cmp fileBuffer, 'A'
    jl getoccurences_again
;move o buffer para a palavra atual
    lea bx, palavra_atual
    mov al, fileBuffer
    mov [bx+di], al
    inc di
    jmp getoccurences_loop
getoccurences_newline:
    inc linha
getoccurences_again:
;acrecenta um \0 ao final da palavra atual
    lea bx, palavra_atual
    mov byte ptr [bx+di], 0
;verifica se a flag showNext foi alterada na chamada anterior da funcao Find
    cmp showNext, 1
    jne getoccurences_find
;se a flag showNext for 1, printa a palavra atual
    mov showNext, 0
    lea bx, palavra_atual
    call printf
    lea bx, CRLF
    call printf
getoccurences_find:
;incrementa di para percorrer o vetor de palavras
    inc di
;chama a funcao que compara a palavra atual com o input do usuario
    call Find
;move a palavra atual para a palavra anterior
    mov cx, di
    push di
    lea si, palavra_atual
    lea di, palavra_anterior
    rep movsb
    pop di
    jmp getoccurences_reset
getoccurences_end:
    lea bx, palavra_atual
    mov byte ptr [bx+di], 0
    cmp showNext, 1
    jne getoccurences_ret
;se a flag showNext for 1, printa a palavra atual
    mov showNext, 0
    call printf
    lea bx, CRLF
    call printf
getoccurences_ret:
    ret
GetOccurences endp  ;chama a funcao que le o arquivo e procura a palavra endp
;--------------------------------------------------------------------



;Compara a palavra atual com a palavra digitada pelo usuario
Find proc near

;salva a palavra atual em uma variavel temporaria
    mov cx, di
    lea si, palavra_atual
    push di
    lea di, palavra_tmp
    rep movsb
    pop di

;converte a temp para uppercase
    mov cx, BUFFER_SIZE
    lea bx, palavra_tmp
    call toUpper

;compara a temp com a palavra digitada
    mov cx, di
    lea si, palavra_tmp
    push di
    lea di, input
    repe cmpsb
    jnz find_ret
;atualiza a flag wasfound para printar a mensagem de ocorrencias apenas uma vez
    mov dl, wasfound
    cmp dl, 0
    jne find_continue
    mov wasfound, 1
find_continue:
;printa a linha atual e a ocorrencia encontrada
    call PrintLinha
find_ret:
;recupera o contexto de di e retorna
    pop di
    ret
Find endp
;--------------------------------------------------------------------

;Printa a linha atual, a palavra anterior, a palavra atual
PrintLinha proc near
;verifica se a flag wasfound e igual a 1
    mov dl, wasfound
    cmp dl, 1
    je puts_foundmsg
    jmp printlinha_continue
puts_foundmsg:
;printa a mensagem de ocorrencias encontradas
    lea bx, msgFound
    call printf
    mov wasfound, 2 ;atualiza a flag para nao printar a mensagem de ocorrencia novamente
printlinha_continue:
;printa a linha atual, palavra anterior, palavra atual em caixa alta e a proxima palavra
    mov ax, Linha
    lea bx, strLinhaBuffer
    call sprintf_w
    
    push di
    push si
    lea si, strLinhaBuffer
    lea di, strLinha
    add di, 6
    mov cx, 3
    rep movsb
    pop si
    pop di
   
    lea bx, strLinha
    call printf
    lea bx, palavra_anterior
    call printf
    lea bx, space
    call printf
    lea bx, palavra_tmp
    call printf
    lea bx, space
    call printf
    mov showNext, 1 ;atualiza a flag para informar que a proxima palavra deve ser printada
    ;a proxima palavra sera printada na funcao GetOccurences, apos terminar de ser lida
    ret
PrintLinha endp
;--------------------------------------------------------------------
;=====================================================================


;========== Funcoes de manipulacao de I/O e buffers ==================



;Verifica se e uma palavra valida (A-Z) ou (a-z)
IsValid proc near
    push ax
    push si
    mov si, 0
isvalid_loop:
    mov al, [bx + si]
    cmp al, 0
    je isvalid_end
    cmp al, 'a'
    jl compare_upper
    cmp al, 'z'
    jg invalid_char
    jmp upper_next
invalid_char:
    mov isNotValid, 1   ;atualiza a flag para informar que a palavra digitada e invalida
    pop si
    pop ax
    ret
compare_upper:
    cmp al, 'Z'
    jg invalid_char
    cmp al, 'A'
    jl invalid_char
isvalid_next:
    inc si
    loop isvalid_loop
    jmp isvalid_ret
isvalid_end:
    cmp si, 0
    jne isvalid_ret
    mov isNotValid, 1
isvalid_ret:
    pop si
    pop ax
    ret

IsValid endp
;--------------------------------------------------------------------

;Converte todos os caracteres de uma string carregada em bx para maiusculo
toUpper proc near
    push ax
    push si
    mov si, 0
upper_loop:
    mov al, [bx + si]
    cmp al, 0
    je upper_ret

    cmp al, 'a'
    jl upper_next
    cmp al, 'z'
    jg upper_next
    sub al, 32
    mov [bx + si], al
    jmp upper_next
upper_next:
    inc si
    loop upper_loop
upper_ret:
    pop si
    pop ax
    ret
toUpper endp
;--------------------------------------------------------------------

;Converte um inteiro de 2 bytes em uma string de no maximo 3 bytes (pode printar ate 999 linhas dentro de um arquivo)
sprintf_w	proc	near
;void sprintf_w(char *string, WORD n) {
	mov		sw_n,ax
;	k=3;
	mov		cx,3
;	m=100;
	mov		sw_m,100
	
sprintf_loop:

;		quociente = n / m : resto = n % m;
	mov		dx,0
	mov		ax,sw_n
    cmp ax, 0
    je sprintf_continue ;verifica divisao por zero
	div		sw_m
	
sprintf_store:
	add		al,'0'  ;soma com '0' para converter para ascii
	mov		[bx],al
	inc		bx

sprintf_continue:
;		n = resto;
	mov		sw_n,dx
;		m = m/10;
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax
	
	dec		cx
	cmp		cx,0
	jnz		sprintf_loop

	ret
		
sprintf_w	endp
;--------------------------------------------------------------------

;Printa um string na tela ate o \0
Printf proc near
print_loop:
    mov dl, [bx]
    cmp dl, 0
    je print_end
    mov ah, 2
    int 21h
    inc bx
    jmp print_loop
print_end:
    ret
Printf endp
;--------------------------------------------------------------------



;Funcao que obtem uma string lida do teclado
Gets proc near
	mov	dx,0
gets_loop:
;   Espera pelo teclado
    mov	ah,7
    int	21H

    cmp	al, CR
    jne	gets_handle_backspace

    mov	byte ptr[bx],0  ;coloca o caractere nulo, new line e retorna
    lea bx, CRLF
    call printf
    ret

gets_handle_backspace:
    cmp	al, BS
    jne	gets_getchar
    cmp	dx,0
    jz	gets_loop
    push dx
    
;Se usuario digitar backspace, cursor retorna, printa um espaco e retorna o cursor de novo
    mov	dl, BS
    mov	ah,2
    int	21H

    mov	dl, ' '
    mov	ah,2
    int	21H

    mov	dl, BS
    mov	ah,2
    int	21H

    pop	dx ;retoma dx da stack
    dec	bx ;decrementa o ponteiro para sobrescrever o que apagou
    inc	cx ;reincrementa cx para desconsiderar o char apagado
    dec	dx
    jmp	gets_loop
gets_getchar:
    cmp	cx,0    ;verifica se atingiu o limite do buffer
    je	gets_loop ;se atingiu, retorna ao loop para esperar por CR ou BS
    cmp	al,' '  ;verifica se usuario digitou algum caracter de controle
    jl	gets_loop ;se al = char de controle, desconsidera e retorna ao loop
    mov	[bx],al ;move o char para o buffer
;faz os inrementos/decremtos dos ponteiros/contadores
    inc	bx      
    dec	cx
    inc	dx
    push dx
;Printa o char digitado na tela
    mov	dl,al
    mov	ah,2
    int	21H
    pop	dx
    jmp		gets_loop

Gets	endp
;--------------------------------------------------------------------

;limpa o buffer carregado em di
ClearBuffer proc near
    xor ax, ax
    rep stosb   ;preenche o buffer com 0
    ret
ClearBuffer endp
;--------------------------------------------------------------------

;Abre um arquivo
OpenFile proc near
    lea dx, CMDLINE
    add dx, 1   ; Pula o primeiro caractere, pois o mesmo e um espaco em branco
    mov al, 0
    mov ah, 3dh
    int 21h
    mov handle, ax
    ret
OpenFile endp
;--------------------------------------------------------------------
;====================================================================
    end