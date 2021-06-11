section	.bss
    stack: resd 5
    input: resb 82
    tmpVar: resb 1
section .data
    stackSize: dd 0
    tmp: dd 0
    stackStart: dd 0
    digitCount: dd 0
	firstAddArgument: dd 0
	secondAddArgument: dd 0
	firstAddDigitCount: dd 0
	secondAddDigitCount: dd 0
	firstMultiplyArgument: dd 0
	secondMultiplyArgument: dd 0
	carryFlag: dd 0
	carryFlag2: dd 0
	tmp2: dd 0
	tmp3: dd 0
	operationNum: dd 0
	functionOrInputFlag: dd 0
	addressToFree: dd 0
	nextAddressToFree: dd 0
	numHolder1: dd 0
	numHolder2: dd 0
section	.rodata			; we define (global) read-only variables in .rodata section
	format_string: db "Error: Insufficient Number of Arguments on Stack", 10, 0	; format string for failure
	format_string2: db "Error: Operand Stack Overflow", 10, 0	; format string for failure
	format_string3: db "%X", 10, 0	; format string for popPrint
	format_string8: db "%X", 0
	format_string4: db "%02X", 0	; format string for popPrint without newline
	format_string5: db 10, 0	; newline
	format_string6: db "calc: ", 0	; format string for printing "calc: "
	format_string7: db "wrong Y value", 10, 0	; format string for failure

section .text
align 16
     global main
     extern printf
     extern fflush
     extern malloc
     extern calloc
     extern free
     extern gets
     extern fgets
     
main:
    call myCalc
    pushad			
	push dword [operationNum]		              ; print the number of operations before exiting
	push format_string3                    
	call printf
	add esp, 8
	popad
    mov eax,1						              ; exit system call
    mov ebx,0
    int 0x80
    
    
    
myCalc:
    push ebp              		                  ; save Base Pointer (bp) original value
    mov ebp, esp         		                  ; use Base Pointer to access stack contents 
    pushad                   	                  ; push all signficant registers onto stack (backup registers values)
    
    myCalcLoop:
        pushad					
        push format_string6
        call printf
        add esp,4
        popad
        mov dword [functionOrInputFlag], 0
        push input
        call gets
        add esp, 4
        cmp byte [input], 0x71                    ; user entered 'q'
        jz finish
        cmp byte [input], 0x2b                    ; user entered '+'
        jnz noAddition
        call addition
        noAddition:
        cmp byte [input], 0x70                    ; user entered 'p'
        jnz noPopPrint
        call popPrint
        noPopPrint:
        cmp byte [input], 0x64                    ; user entered 'd'
        jnz noDuplicate
        call duplicate
        noDuplicate:
        cmp byte [input], 0x5e                    ; user entered '^'
        jnz noPower
        call power
        noPower:
        cmp byte [input], 0x76                    ; user entered 'v'
        jnz noMinusPower
        call minusPower
        noMinusPower:
        cmp byte [input], 0x6e                    ; user entered 'n'
        jnz noNumOfOneBits
        call numOfOneBits
        noNumOfOneBits:
        cmp dword [stackSize], 5                  ; stack overflow error
        jnz noOverFlow
        call error2
        noOverFlow:
        cmp dword [functionOrInputFlag], 1
        jz myCalcLoop
        
        call EnterNumber
        jmp myCalcLoop
        
EnterNumber:
        push ebp              		                ; save Base Pointer (bp) original value
        mov ebp, esp         		                ; use Base Pointer to access stack contents 
        pushad                   	                ; push all signficant registers onto stack (backup registers values)
        
        mov ecx, 0                                  ; zero a counter to count the inputs digits
    digitCounter:					                ; count how many digits the input has
            cmp byte [input+ecx], 0x0
            jz buildLinkedList
            inc ecx
            jmp digitCounter
    
    
    buildLinkedList:
        mov dword eax, [stackSize]	; we need to reach [stack+4*[stackSize]]
        mov dword ebx, stack
        mov edx, 4
        mul edx
        add ebx, eax
        mov dword [digitCount], ecx	; save number of digits in a variable
        cmp ecx, 1
        jz buildLinkedListLoop		; we need digitCount/2 nodes
        shr ecx, 1					; shift right to divide by two
        adc ecx, 0					; add carry to round up the result
    buildLinkedListLoop:
        mov edx, 5              	; zero counters
        pushad						; save all registers
        push edx					; push edx which contains 5 as an argument to malloc
        push 1
        call calloc             	; call malloc
        add esp, 8					; ignore the pushed argument
        mov [tmp], eax				; save the returned address in a variable so we wont lose it after restoring the registers
        popad			
        mov dword eax, [tmp]    	; put the returned address in eax
        mov [ebx], eax          	; let the Next link of ebx be the address that returned from malloc which is saved in eax
        mov ebx, eax          		; let ebx point to the new link
        add ebx, 1                 	; ignore the byte of the number, move to the 4 bytes of the address
        dec ecx                 	; decrease counter
        cmp ecx, 0
        jnz buildLinkedListLoop
        mov dword [ebx], 0			; the address of the last node is assigned zero
        jmp fillDigits

    fillDigits:
        mov esi,stack           	; for relative address use
		mov dword ecx, [digitCount]				; Hex represenation we enter the numbers backwards (from right to left) 
        mov dword edx, [stackSize]	  ; use edx for relative addressing
        mov ebx, [esi+4*edx]          ; let ebx point to address of the link
        dec ecx
        fillDigitsLoop:
			mov edx, 0   			; zero edx to use as a result variable
			mov eax, 0
			
            mov al, [input+ecx]		; every digits is a byte so we use the lower 8 bits of registers
            cmp byte al, '9'
            jg hexa2
            sub al,'0'				; normal decimal represenation, sub 48 from the ascii value
            jmp continueFillDigits2
            hexa2:
            sub al, '7'				; fix the hexadecimal represenation
            continueFillDigits2:
            dec ecx				  	; decrement ecx to point to the next digit
            add dl, al			  	; add the result to dl
			cmp ecx, -1
			jz continueDigits
			
			mov al, [input+ecx]           
            cmp byte al, '9'
            jg hexa
            sub al, '0'
            jmp continueFillDigits
            hexa:
            sub al, '7'
            continueFillDigits:
            mov esi, eax		  	; we did this to expand the number in al from 1 byte to 4 bytes using AND operation, considering the biggest digit in hex is F which is 1111
            mov eax, 16
            mov dword [tmp], edx
            mul esi				  	; multiply 16 with esi
            mov dword edx, [tmp]
			add dl, al
			dec ecx
			
		continueDigits:		
            mov byte [ebx], dl   	; mov the number we got to the address in ebx
            add ebx, 1       		; ignore the number byte
            mov dword ebx, [ebx]   	; mov the 4-byte address to ebx (next link)
            cmp ecx, -1				; -1 because we need the digit at [input+0] so we need to use ecx=0, so we stop at ecx=-1
            jnz fillDigitsLoop
            inc dword [stackSize]  	; inc stack size by one
        
    popad                    	; restore all previously used registers
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret	  
        
        
error1:
    push ebp              		; save Base Pointer (bp) original value
    mov ebp, esp         		; use Base Pointer to access stack contents 
    pushad                   	; push all signficant registers onto stack (backup registers values)
    mov dword [functionOrInputFlag], 1
	pushad					
    push format_string2
    call printf
    add esp,4
    popad
    popad                    	; restore all previously used registers
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret		
    
        
error3:
    push ebp              		; save Base Pointer (bp) original value
    mov ebp, esp         		; use Base Pointer to access stack contents 
    pushad                   	; push all signficant registers onto stack (backup registers values)
    mov dword [functionOrInputFlag], 1
	pushad					
    push format_string7
    call printf
    add esp,4
    popad
    popad                    	; restore all previously used registers
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret		        

error2:
    push ebp              		; save Base Pointer (bp) original value
    mov ebp, esp         		; use Base Pointer to access stack contents 
    pushad                   	; push all signficant registers onto stack (backup registers values)
    mov dword [functionOrInputFlag], 1
    pushad							; save all registers
    push format_string				; push the error message argument
    call printf						; call printf
    add esp,4						; ignore the pushed argument
    popad							; restore all registers
    popad                    	; restore all previously used registers
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret								; return to main


numOfOneBits:
    push ebp              		; save Base Pointer (bp) original value
    mov ebp, esp         		; use Base Pointer to access stack contents 
    pushad                   	; push all signficant registers onto stack (backup registers values)
    
    mov dword [functionOrInputFlag], 1
	inc dword [operationNum]		; increment the number of operations
	cmp dword [stackSize], 1		; if no numbers found print an error message
	jge noError1
	call error2
	popad                    	; restore all previously used registers
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret
    noError1:
	mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 1						; so ebx can point to the previous number
	mov dword ebx, stack
	mov edx, 4
    mul edx
	add ebx, eax
	mov ebx, [ebx]					; similar to **var in C, so we do this to access the inner address
	mov esi, 0						; zero a counter
	
	numOfOneBitsLoop:
		mov ecx, 0                  ; zero a counter
		mov edx, 32					; check the 32-bits
		mov byte al, [ebx]
		numOfOneBitsInsideLoop:
			bt eax, edx				; check the bit in the edx place from eax register.
			jnc dontAddCounter		; jmp not carry if the bit is 0
			inc ecx					; if the bit is set, increment the counter
			dontAddCounter:
			dec edx					; decrement edx, we check the 32 bit although we only need 8
			cmp edx, 0				; stop if no more bits to check
			jnz numOfOneBitsInsideLoop
		
		inc ebx						; ignore the number byte in the node
		add esi, ecx				; esi serves as a result variable here
		mov dword ebx, [ebx]		; redirect ebx to the next node
		cmp ebx, 0					; stop if ebx is zero (meaning no more nodes left)
		jnz numOfOneBitsLoop
    
    mov ecx, 0                      ; digit counter   
    mov eax, esi
    mov ebx, 16                     ; divide by 16 to turn into hexa
    mov edx, 0
    numOfDigitsInBufferLoop:
        div ebx
        inc ecx
        mov edx, 0
        cmp eax, 0
        jnz numOfDigitsInBufferLoop
    
    mov byte [input+ecx], 0x0       ; put NULL termination
    dec ecx                         ; start to fill numbers from digitCount-1
    
    mov eax, esi
    mov esi, 0x10                  
    mov edx, 0
    decToHexToAscii:
        div esi
        cmp edx, 9
        jg hexToAsc                 ; if greater turn to hexa, otherwise turn to decimal
        add edx, '0'
        jmp fillInBuffer
        hexToAsc:
        add edx, '7'
        fillInBuffer:
        mov byte [input+ecx], dl    ; push the digit into buffer
        dec ecx
        mov edx, 0
        cmp eax, 0
        jnz decToHexToAscii
    
    mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 1						; so ebx can point to the previous number
	mov dword ebx, stack
	mov edx, 4
    mul edx
	add ebx, eax
	mov dword eax, [ebx]
	mov dword [ebx], 0              ; zero the place on stack
	dec dword [stackSize]
    call EnterNumber                ; build a new number and add to stack
    
    mov dword [addressToFree], eax  ; save the address to free later
    pushad
    call freeMemory
    popad
    
    popad                    	; restore all previously used registers
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret		

power:
    push ebp              		; save Base Pointer (bp) original value
    mov ebp, esp         		; use Base Pointer to access stack contents 
    pushad                   	; push all signficant registers onto stack (backup registers values)
    
    mov dword [functionOrInputFlag], 1
    inc dword [operationNum]
	cmp dword [stackSize], 2
	jge noError2
	call error2
	popad                    	; restore all previously used registers
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret
    noError2:
    mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 1						; so ebx can point to the previous number
	mov dword esi, stack
	mov edx, 4
    mul edx
	add esi, eax
	mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 2
	mov dword ebx, stack
	mov edx, 4
    mul edx
	add ebx, eax
	
	mov esi, [esi]					; point to the inner address
	mov ebx, [ebx]					; point to the inner address
	mov dword [firstMultiplyArgument], ebx
	mov dword [secondMultiplyArgument], esi
	mov edx, 0
	
	mov byte dl, [ebx]
	cmp edx, 200                    ; Y bigger than 200 wrong value
	jl powerLoopPrepare
	call error3
	popad                    	    ; restore all previously used registers
    mov esp, ebp			        ; free function activation frame
    pop ebp				            ; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret	
	powerLoopPrepare:
	mov dword [tmp], edx            ; save the loop counter in variable
	mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 2
	mov dword ebx, stack
	mov edx, 4
    mul edx
	add ebx, eax
	mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 1						; so ebx can point to the previous number
	mov dword esi, stack
	mov edx, 4
    mul edx
	add esi, eax
	
	mov dword esi, [esi]            ; double addressing 
	mov dword [ebx], esi            ; let X take Y variable's place on stack
	
	mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 1						; so ebx can point to the previous number
	mov dword esi, stack
	mov edx, 4
    mul edx
	add esi, eax
	
	mov dword [esi], 0              ; clean up Y place's on stack
	dec dword [stackSize]
	mov dword edx, [tmp]            ; restore edx from variable
	cmp edx, 0
	jz powerFinishedLoop
	powerLoop:
    call duplicate                  
    call addition
    sub dword [operationNum], 2     ; subtract the two functions that were automatically added
    dec edx
    cmp edx, 0
    jnz powerLoop
    powerFinishedLoop:
    
    mov dword eax, [firstMultiplyArgument]  ; prepare the address to free
    mov dword [addressToFree], eax
    pushad
    call freeMemory                 ; call freeing function
    popad
    
    popad                    	; restore all previously used registers
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret		

minusPower:
    push ebp              		; save Base Pointer (bp) original value
    mov ebp, esp         		; use Base Pointer to access stack contents 
    pushad                   	; push all signficant registers onto stack (backup registers values)
    
    mov dword [functionOrInputFlag], 1
    inc dword [operationNum]
	cmp dword [stackSize], 2
	jge noError7
	call error2
	popad                    	; restore all previously used registers
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret
    noError7:
    mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 1						; so ebx can point to the previous number
	mov dword esi, stack
	mov edx, 4
    mul edx
	add esi, eax
	mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 2
	mov dword ebx, stack
	mov edx, 4
    mul edx
	add ebx, eax
	
	mov esi, [esi]					; point to the inner address
	mov ebx, [ebx]					; point to the inner address
	mov dword [firstMultiplyArgument], ebx
	mov dword [secondMultiplyArgument], esi
	mov edx, 0
	
	mov byte dl, [ebx]
	cmp edx, 200
	jl powerLoopPrepareMinus
	call error3
	popad                    	; restore all previously used registers
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret	
	powerLoopPrepareMinus:
	mov dword [tmp], edx
	mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 2
	mov dword ebx, stack
	mov edx, 4
    mul edx
	add ebx, eax
	
	mov dword esi, [secondMultiplyArgument]
	mov dword [ebx], esi
	
	mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 1						; so ebx can point to the previous number
	mov dword esi, stack
	mov edx, 4
    mul edx
	add esi, eax
	
	mov dword [esi], 0              ; clean up after Y place's on stack
	dec dword [stackSize]
	mov dword edx, [tmp]
	mov ebx, [ebx]
	
	mov ecx, 0					    ; zero a counter
        lengthLoop3:				; loop to count the digits
            inc ecx					; at least it has one digit so increase straight when entering the loop
            inc ebx					; ignore the number byte
            cmp dword [ebx],0		; ebx zero meaning no more nodes left
            jz continueMinus
            mov ebx, [ebx]			; move to the next node
            jmp lengthLoop3
            
    continueMinus:
    mov eax, 0
    mov dword [digitCount], ecx
    mov dword [carryFlag], 0
    mov dword [tmp2], ecx
    mov esi, [tmp]
    mov dword [tmp3], 0
    cmp esi, 0
    jz minusPowerFinishedLoop
    YvalueLoop:
        mov dword eax, [stackSize]	; use eax for relative addressing
        sub eax, 1					; so ebx can point to the previous number
        mov dword ebx, stack
        mov edx, 4
        mul edx
        add ebx, eax
        mov ebx, [ebx]              ; let ebx point to the first node
        dec esi                     ; esi is the loop counter
        mov dword ecx, [tmp2]       ; tmp2 is the descending counter everytime (starting from digitCount to 1)
        mov dword [digitCount], ecx ; save in digitCount
        mov dword [carryFlag], 0    ; zero the carryFlag
        minusPowerLoop:
        mov dword [tmp3], 0         ; zero the carryFlag backup variable
        mov dword ecx, [digitCount] ; restore ecx
            minusPowerInnerLoop:
                ToTheEndLoop3:			; loop so we move ebx to the appropriate node (starting from the end and heading towards the first node)
                cmp ecx, 1			; if ecx is 1 then we reached our wanted node
                jz continueMinusLoop
                inc ebx				; ignore the number byte 
                mov dword ebx, [ebx]; point to the next node
                dec ecx				
                cmp ecx, 1
                jnz ToTheEndLoop3
            continueMinusLoop:
                mov eax, 0
                mov byte al, [ebx]  ; take the number in the byte
                shr al, 1           ; shift it right once
                adc dword [tmp3], 0 ; save the bit that we shifted
                cmp dword [carryFlag], 1 ; check if carry flag is set
                jnz noCarrySet
                or eax, 256         ; if we have carry, we OR the number we shifted with 256 ( in binary 10000000 ), to set the 8th bit that we shifted from the earlier node
                noCarrySet:
                mov byte [ebx], al  ; replace the number in the byte
                mov eax, 0
                mov eax, [tmp3]     ; cant replace mm32 with mm32 directly so we send it through eax
                mov dword [carryFlag], eax  ; update the carry flag
                
            dec dword [digitCount]  
            cmp dword [digitCount], 0
            jnz minusPowerLoop
        cmp esi, 0                  ; no more shifts left
        jnz YvalueLoop
    minusPowerFinishedLoop:
    
    mov dword eax, [firstMultiplyArgument]
    mov dword [addressToFree], eax  ; save address to free later
    
    pushad
    call freeMemory
    popad
    
    popad                    	    ; restore all previously used registers
    mov esp, ebp			        ; free function activation frame
    pop ebp				            ; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret		

duplicate:
        push ebp              		; save Base Pointer (bp) original value
        mov ebp, esp         		; use Base Pointer to access stack contents 
        pushad                   	; push all signficant registers onto stack (backup registers values)
        mov dword [functionOrInputFlag], 1
		inc dword [operationNum]	
		cmp dword [stackSize], 1	; less than one print error message
		jge noError3
        call error2
        popad                    	; restore all previously used registers
        mov esp, ebp			    ; free function activation frame
        pop ebp				        ; restore Base Pointer previous value (to returnt to the activation frame of main(...))
        ret
        noError3: 
		cmp dword [stackSize], 5	; 5 or more numbers in stack, is stack overflow error
		jl noError4
        call error1
        popad                    	; restore all previously used registers
        mov esp, ebp			    ; free function activation frame
        pop ebp				        ; restore Base Pointer previous value (to returnt to the activation frame of main(...))
        ret
        noError4:			
		mov dword eax, [stackSize]	; use eax for relative addressing
		mov dword esi, stack
		mov edx, 4
        mul edx
		add esi, eax
		mov dword eax, [stackSize]	; use eax for relative addressing
		sub eax, 1					; so ebx can point to the previous number
		mov dword ebx, stack
        mov edx, 4
        mul edx
        add ebx, eax
        
        mov ebx, [ebx]
		duplicateLoop:
			mov edx, 0				; zero the counter
			mov byte dl, [ebx]		; get the digit from ebx to dl
			add ebx, 1				; let ebx ignore the number byte and point to the next link address
			mov ecx, 5				; push argument for malloc
			pushad
			push ecx				; argument
			push 1
			call calloc             ; call malloc
			add esp, 8				; ignore the pushed argument
			mov [tmp], eax			; save the returned address in variable
			popad
			mov dword eax, [tmp]	
			mov dword [esi], eax	; let the 5 bytes in stack (those pointed to by esi) point to the address returned from malloc
			mov esi, [esi]			; let esi point to the address of the 5 bytes to be filled with a digit and a next address
			mov byte [esi], dl		; fill the first byte with the number we copied
			add esi, 1				; ignore the number and point to the next 4 bytes ( which is the address for the next link )
			mov ebx, [ebx]			; let ebx point to the next link
			cmp ebx, 0				; if ebx is zero, meaning we reached a NULL address to next link (no more digits)
			jnz duplicateLoop
		mov dword [esi], 0	
        inc dword [stackSize]
        
        popad                    	; restore all previously used registers
        mov esp, ebp			    ; free function activation frame
        pop ebp				        ; restore Base Pointer previous value (to returnt to the activation frame of main(...))
        ret				

popPrint: 							; prints from the last node to the first
        push ebp              		; save Base Pointer (bp) original value
        mov ebp, esp         		; use Base Pointer to access stack contents 
        pushad                   	; push all signficant registers onto stack (backup registers values)
        mov dword [functionOrInputFlag], 1
		inc dword [operationNum]
        cmp dword [stackSize], 1
        jge noError5
        call error2
        popad                    	; restore all previously used registers
        mov esp, ebp			    ; free function activation frame
        pop ebp				        ; restore Base Pointer previous value (to returnt to the activation frame of main(...))
        ret
        noError5:
        dec dword [stackSize]		; reduce the stackSize
		mov dword ebx, stack
		mov dword eax, [stackSize]
		mov edx, 4
        mul edx
		add ebx, eax
		mov ebx, [ebx]				; let ebx point the first node
		
		mov dword [addressToFree], ebx
        
        mov ecx, 0					; zero a counter
        lengthLoop:					; loop to count the digits
            inc ecx					; at least it has one digit so increase straight when entering the loop
            inc ebx					; ignore the number byte
            cmp dword [ebx],0		; ebx zero meaning no more nodes left
            jz beforePopPrint
            mov ebx, [ebx]			; move to the next node
            jmp lengthLoop
            
            
            
        beforePopPrint:
            mov dword [tmp2], ecx	; save the number of digits in a variable
            mov dword [tmp3], ecx	; save the number of digits in a variable
            mov dword [tmp], 0
        subLeadingZerosFromCounter:
            mov dword ecx, [tmp3]	; restore the number of digits
            
            mov dword ebx, stack
            mov dword eax, [stackSize]
            mov edx, 4
            mul edx
            add ebx, eax
            mov ebx, [ebx]			; let ebx point to the first node
            
            mov edx, 0           	; zero a variable
            subLeadingZerosFromCounterLoop:
                cmp ecx, 1			; if ecx is 1 then we reached our wanted node
                jz continueSubZeros
                inc ebx				; ignore the number byte 
                mov dword ebx, [ebx]; point to the next node
                dec ecx				
                cmp ecx, 1
                jnz subLeadingZerosFromCounterLoop
            
            continueSubZeros:
            dec dword [tmp3]
            mov byte dl, [ebx]      ; everytime there is a zero starting from left meaining its a leading zero
            cmp edx, 0              ; we increase the counter of leading zeros
            jz increaseCounter      ; so we can print starting from the first number which is not zero
            jmp popPrintBeforeLoop
            increaseCounter:
            inc dword [tmp]         ; 
            mov dword ecx, [tmp]
            cmp dword [tmp2], ecx
            jz numIsZero
            jmp subLeadingZerosFromCounter
            
            numIsZero:
            dec dword [tmp]
            
        popPrintBeforeLoop:
            mov dword ecx, [tmp]
            sub dword [tmp2], ecx
            mov dword ecx, [tmp2]	; restore the number of digits
            mov dword [tmp3], ecx
        
        popPrintLoop:
            mov dword ecx, [tmp2]	; restore the number of digits
            
            mov dword ebx, stack
            mov dword eax, [stackSize]
            mov edx, 4
            mul edx
            add ebx, eax
            mov ebx, [ebx]			; let ebx point to the first node
            
            mov edx, 0           	; zero a variable
            ToTheEndLoop:			; loop so we move ebx to the appropriate node (starting from the end and heading towards the first node)
                cmp ecx, 1			; if ecx is 1 then we reached our wanted node
                jz continuePopPrint
                inc ebx				; ignore the number byte 
                mov dword ebx, [ebx]; point to the next node
                dec ecx				
                cmp ecx, 1
                jnz ToTheEndLoop
             
            continuePopPrint:
            mov byte dl, [ebx]	 	; mov the number byte to dl
            add ebx, 1			 	; ignore the number byte and point to the start of the address
            mov ebx, [ebx]		 	; let ebx point to to the address
            push    ebp             ; Save caller state
            mov     ebp, esp
            pushad
            push edx				; push the number
            mov dword ecx, [tmp3]
            cmp dword [tmp2], ecx
            jz oneDigitFormat
            push format_string4		; push string format
            jmp callPrint
            oneDigitFormat:
            push format_string8 
            callPrint:
            call printf				; print the digit 
            add esp,8				; ignore pushed arugment
            popad			
            mov esp, ebp	
            pop ebp
            dec dword [tmp2]
            cmp dword [tmp2], 0		; if variable is zero meaning no next address and the number has finished printing.
            jnz popPrintLoop
            pushad
            push format_string5		; print new line
            call printf				; call printf function
            add esp, 4				; ignore pushed arguemnt
            popad					; restore all registers
            
        pushad
        call freeMemory
        popad
        
        popad                    	; restore all previously used registers
        mov esp, ebp			; free function activation frame
        pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
        ret				
            
    

addition:
    push ebp              		; save Base Pointer (bp) original value
    mov ebp, esp         		; use Base Pointer to access stack contents 
    pushad                   	; push all signficant registers onto stack (backup registers values)
    mov dword [functionOrInputFlag], 1
	inc dword [operationNum]
	cmp dword [stackSize], 2
	jge noError6
	call error2
	popad                    	; restore all previously used registers
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret
    noError6:
	mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 1						; so ebx can point to the previous number
	mov dword esi, stack
	mov edx, 4
    mul edx
	add esi, eax
	mov dword eax, [stackSize]		; use eax for relative addressing
	sub eax, 2
	mov dword ebx, stack
	mov edx, 4
    mul edx
	add ebx, eax

	mov dword esi, [esi]					; point to the inner address
	mov dword ebx, [ebx]					; point to the inner address
	
	mov dword [numHolder1], esi
	mov dword [numHolder2], ebx
	
	mov ecx, 1						; initalize counters
	mov edx, 1
	howManyDigits1:					; count how many digits in the first
		inc esi
		cmp dword [esi],0
		jz howManyDigits2
		inc ecx
		mov esi, [esi]
		jmp howManyDigits1
	howManyDigits2:					; count how many digits in the second
		inc ebx
		cmp dword [ebx],0			; if zero means we reached the last node
		jz continueAddition
		inc edx							; increment the counter
		mov ebx, [ebx]				; point to the next node
		jmp howManyDigits2
		
	continueAddition:				; copy the biggest into eax and then to ecx
		cmp ecx, edx
		jg secondIsBigger			; ecx is bigger
		mov eax, edx				; meaning edx is bigger
		jmp prepareForAddition
		
		secondIsBigger:
			mov eax, ecx			; meaning ecx is bigger
		
		prepareForAddition:
		mov dword [firstAddDigitCount], ecx				; save the count of digits for the two numbers
		mov dword [secondAddDigitCount], edx
		mov ecx, eax				; let ecx be the counter for the number of nodes
		mov dword eax, [stackSize]	; use eax for relative addressing
		sub eax, 1					; so ebx can point to the previous number
		mov dword esi, stack
		mov edx, 4
        mul edx
		add esi, eax
		mov dword [tmp], esi
		mov esi, [esi]
		mov dword [firstAddArgument], esi		; save the first argument
		mov dword esi, [tmp]		; restore the first argument to register so we can zero it
		mov dword [esi], 0			; clean the first argument place in stack
		
        mov dword eax, [stackSize]	; use eax for relative addressing
		sub eax, 2					; so ebx can point to the previous number
        mov dword ebx, stack
        mov edx, 4
        mul edx
        add ebx, eax
		mov dword [tmp], ebx
        mov ebx, [ebx]
		mov dword [secondAddArgument], ebx		; save the second argument
		mov dword ebx, [tmp]
		mov dword [ebx], 0 			; clean the second argument place in stack
		
		sub dword [stackSize], 2	; remove those two numbers from the stack
		mov dword eax, [stackSize]	; use eax for relative addressing
        mov dword ebx, stack
        mov edx, 4
        mul edx
        add ebx, eax
		inc ecx
		
		buildLinkedListLoopForAddition:
			mov edx, 5              ; zero counters
			pushad					; save registers
			push edx				; push 5 argument to malloc function
			push 1
			call calloc             ; call malloc
			add esp, 8				; ignore the pushed argument
			mov [tmp], eax			; save the returned address before restoring the registers
			popad					; restore all registers
			mov dword eax, [tmp]    ; put the returned address in eax
			mov [ebx], eax          ; let the Next link of ebx be the address that returned from malloc which is saved in eax
			mov ebx, eax          	; let ebx point to the new link
			add ebx, 1              ; ignore the byte of the number, move to the 4 bytes of the address
			dec ecx                 ; decrease counter
			cmp ecx, 0
			jnz buildLinkedListLoopForAddition
			mov dword [ebx], 0
		
		mov dword eax, [stackSize]	; use eax for relative addressing
        mov dword ecx, stack
        mov edx, 4
        mul edx
        add ecx, eax	; let ecx point to the newly added number place in stack
		mov dword esi, [firstAddArgument]	
		mov dword ebx, [secondAddArgument]
		mov ecx, [ecx]				; let ecx point to the first node
		mov dword [carryFlag], 0	; turn the carry flag off
		
		sumNumberLoop:
            mov dword [tmp2], 0
			mov eax, 0				; zero a counter
			cmp dword [carryFlag], 1	; check if we have a carry from previous caluclations
			jnz goOn
			mov edx, 1				; if carry exists we change edx to 1
			jmp carried
		goOn:
			mov edx, 0				; no carry exists we start from 0 as normal
		carried:
			cmp dword [firstAddDigitCount], 0
			jz dontAddFirst			; first number is done
			mov byte al, [esi]		; copy the number in eax lower 8-bits
			inc esi					; ignore the number byte
			mov esi, [esi]			; let esi point to the next link
			dec dword [firstAddDigitCount]
		dontAddFirst:
			cmp dword [secondAddDigitCount], 0
			jz dontAddSecond
			add byte dl, [ebx]
			inc ebx
			mov ebx, [ebx]
			dec dword [secondAddDigitCount]
		dontAddSecond:
            
			cmp dword [carryFlag], 1
			jnz problematicCarry
			inc dword [tmp2]
			
        problematicCarry:
            mov dword [carryFlag], 0	; turn the carry flag off
            cmp edx, 0
            jnz problematicCarrySolved
            inc dword [tmp2]
            
            cmp dword [tmp2], 2
            jnz problematicCarrySolved
            mov dword [carryFlag], 1	; turn the carry flag on
            
        problematicCarrySolved:
			add eax, edx			; eax serves as final result variable here
			cmp eax, 255			; 255 is FF in hexa the maximum number to fit in 1 byte as in our linked-list, more than that a carry exists
			jle noCarry
		
			mov dword [carryFlag], 1	; turn the carry flag on
			sub eax, 256			; sub 255 from the number because we add a carry to the next digit
		noCarry:
			mov byte [ecx], al		; move the result number to the node
			inc ecx					; ignore the number byte
			mov ecx, [ecx]			; point to the next node
			
			mov edx,0				; zero a counter
			add dword edx, [firstAddDigitCount]
			add dword edx, [secondAddDigitCount]
			cmp edx, 0				; if their sum is 0, means no more digits to sum up
			jnz sumNumberLoop
			cmp dword [carryFlag], 1
			jz sumNumberLoop
			
    inc dword [stackSize]	; increment stack size by one
	mov dword eax, [numHolder1]
	mov dword [addressToFree], eax
	call freeMemory
	mov dword eax, [numHolder2]
	mov dword [addressToFree], eax
	call freeMemory
			
    popad                    	    ; restore all previously used registers
    mov esp, ebp			        ; free function activation frame
    pop ebp				            ; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret
    
freeMemory:
    push ebp              		    ; save Base Pointer (bp) original value
    mov ebp, esp         		    ; use Base Pointer to access stack contents 
    pushad                   	    ; push all signficant registers onto stack (backup registers values)
    
    mov dword ebx, [addressToFree]
    mov ecx, 0					    ; zero a counter
        numLengthLoop:				; loop to count the digits
            inc ecx					; at least it has one digit so increase straight when entering the loop
            inc ebx					; ignore the number byte
            cmp dword [ebx],0		; ebx zero meaning no more nodes left
            jz startFreeingMemory
            mov ebx, [ebx]			; move to the next node
            jmp numLengthLoop
        startFreeingMemory:
            mov dword ebx, [addressToFree]
            
        startFreeingMemoryLoop:
            inc ebx
            dec ecx
            mov dword eax, [ebx]
            dec ebx
            mov dword [nextAddressToFree], eax
            pushad
            push ebx
            call free
            add esp, 4
            popad                   ; restore all registers 
            cmp ecx, 0
            jz finishedFreeingMem
            mov dword ebx, [nextAddressToFree]
            jmp startFreeingMemoryLoop
            
    finishedFreeingMem:
        popad                    	; restore all previously used registers
        mov esp, ebp			    ; free function activation frame
        pop ebp				        ; restore Base Pointer previous value (to returnt to the activation frame of main(...))
        ret		
        
            
		
	
	
finish:

    memoryFree:
        cmp dword [stackSize], 0
        jz final
        mov dword eax, [stackSize]	; use eax for relative addressing
        dec eax
        mov dword ecx, stack
        mov edx, 4
        mul edx
        add ecx, eax	            ; let ecx point to the newly added number place in stack
        mov ecx, [ecx]
        mov dword [addressToFree], ecx
        call freeMemory
        dec dword [stackSize]
        jmp memoryFree
        
    final:
	popad                    	; restore all previously used registers
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret		


    
    
