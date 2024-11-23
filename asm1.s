# Cerinta bidimensional

.data           
    mem: .space 4194304 # 2D 1024x1024 Array of longs instead of bytes so that its easier to work with
    n: .long 1024
    
    # Printf/Scanf formats
    format_numar: .asciz "%d"
    format_numarNL: .asciz "%d\n"
    format_addInputNL: .asciz "%d\n%d\n"        
    format_2numereNL: .asciz "%d %d\n"
    format_fisierNL: .asciz "%d: (%d, %d)\n"
    format_rangeNL: .asciz "(%d, %d)\n" 
    format_newLine: .asciz "\n"

    # Input related variables:
    nrOperatii: .long 0
    operatieID: .long 0
    # Auxiliary variables used mainly for scanf; they can be used anywhere without managing call saving
    auxVar1: .long 0
    auxVar2: .long 0
.text

# FOR DEBUG: Prints the memory range startIndex:endIndex
printMemoryRange: # (startIndex:.long, endIndex:.long) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    lea mem, %edi
    movl 8(%ebp), %ecx
    movl 12(%ebp), %ebx
    add $1, %ebx
    printMemoryRange_loop:
        cmpl %ebx, %ecx
        je printMemoryRange_exit

        pushl %ecx # Save registry before printf call

        pushl (%edi, %ecx, 4)
        pushl $format_numar
        call printf
        popl %edx
        popl %edx

        popl %ecx # Recover registry

        incl %ecx
        jmp printMemoryRange_loop

    printMemoryRange_exit:
        pushl $format_newLine
        call printf
        popl %edx

        popl %ebp
        ret

# FOR DEBUG: Prints the entire memory array
printMemory: # (NO ARGS) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    lea mem, %edi
    xorl %ecx, %ecx
    printMemory_loop:
        cmpl n, %ecx
        je printMemory_exit

        pushl %ecx # Save registry before printf call

        pushl (%edi, %ecx, 4)
        pushl $format_2numereNL
        call printf
        popl %ebx
        popl %ebx

        popl %ecx # Recover registry

        incl %ecx
        jmp printMemory_loop

    printMemory_exit:
        popl %ebp
        ret

# FOR UTILITY: Prints all files in format id: (i, j)
printAllFiles: # (NO ARGS) NO RETURN
    pushl %ebp
    movl %esp, %ebp
    
    xorl %eax, %eax # %eax: current file descriptor

    xorl %ebx, %ebx # %ebx: start index of current file

    # %edx: auxiliary 'variable'

    lea mem, %edi
    xorl %ecx, %ecx
    printAllFiles_loop:
        cmp n, %ecx
        je printAllFiles_loop_exit

        cmp %eax, (%edi, %ecx, 4)
        je printAllFiles_loop_continue
        
        # Found a new file:
        cmp $0, %eax
        jne printAllFiles_loop_if1_exit 
        # If we are coming from an empty block:
        movl (%edi, %ecx, 4), %eax
        movl %ecx, %ebx
        jmp printAllFiles_loop_continue

        printAllFiles_loop_if1_exit:
        # If we are coming from a different block:
        # Print the previous file
        movl %ecx, %edx
        subl $1, %edx

        pushl %ecx # Save register before printf call

        pushl %edx
        pushl %ebx
        pushl %eax
        pushl $format_fisierNL
        call printf
        popl %edx
        popl %edx
        popl %edx
        popl %edx

        popl %ecx # Restore register after printf call

        movl (%edi, %ecx, 4), %eax
        movl %ecx, %ebx

        printAllFiles_loop_continue:
        incl %ecx
        jmp printAllFiles_loop

    printAllFiles_loop_exit:
    subl $1, %ecx
    cmp %eax, (%edi, %ecx, 4)
    jne printAllFiles_exit

    cmp $0, %eax
    je printAllFiles_exit

    pushl %ecx
    pushl %ebx
    pushl %eax
    pushl $format_fisierNL
    call printf
    popl %edx
    popl %edx
    popl %edx
    popl %edx


    printAllFiles_exit:
        popl %ebp
        ret


# FOR UTILITY: Sets all the elements between startIndex:endIndex to fillWith
fillMemoryRange: # (fillWith:.long, startIndex:.long, endIndex:.long) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    lea mem, %edi

    movl 8(%ebp), %edx # %edx: fillWith
    
    movl 12(%ebp), %ecx
    movl 16(%ebp), %ebx
    add $1, %ebx
    fillMemoryRange_loop:
        cmpl %ebx, %ecx
        je fillMemoryRange_exit

        movl %edx, (%edi, %ecx, 4) # mem[%ecx] = fillWith   

        incl %ecx
        jmp fillMemoryRange_loop

    fillMemoryRange_exit:
        popl %ebp
        ret


# FOR TASK: Add file into memory
#   Go through the memory, find a range thats long enough to fit this file
memADD: # (descriptor:.long, dimensiune:.long in bytes) RETURNS (%eax: startIndex, %ebx: endIndex)      
    pushl %ebp
    movl %esp, %ebp

    # -4(%ebp): number of blocks the file requires
    movl 12(%ebp), %eax
    xorl %edx, %edx
    movl $8, %ebx
    divl %ebx # 1 memory block spans 8 bytes
    cmpl $0, %edx
    je memADD_if_divRoundUp_exit
    # Round up the divison
    add $1, %eax
    memADD_if_divRoundUp_exit:
    pushl %eax                  
    
    # %eax: start index of current range
    xorl %eax, %eax

    # %ebx: size of the current range
    xorl %ebx, %ebx

    # %ecx: current index
    xorl %ecx, %ecx

    # %edx: auxiliary variable

    lea mem, %edi
    memADD_loop:
        cmpl n, %ecx
        je memADD_failedToFindSpace # If we have gone through the entire memory that means we didnt find a space for the file

        cmpl $0, (%edi, %ecx, 4) # Check if the current block is occupied 
        jne memADD_if_foundOccupiedBlock

        # Current block is free:
        incl %ebx # Increment the size of the current range if the current block is free
        cmpl -4(%ebp), %ebx
        je memADD_foundSpace # If the size reached the size of the file we are trying to add, exit the loop and return out
        
        jmp memADD_if_foundOccupiedBlock_exit 


        # Current block is occupied:
        memADD_if_foundOccupiedBlock: # Reset %ebx and update %eax to the next element
            movl %ecx, %eax
            incl %eax
            xorl %ebx, %ebx

        memADD_if_foundOccupiedBlock_exit:
        
        incl %ecx
        jmp memADD_loop

    memADD_foundSpace:
        addl %eax, %ebx
        subl $1, %ebx

        pushl %eax # Store registers to keep after function call
        pushl %ebx # Store registers to keep after function call

        pushl %ebx
        pushl %eax
        pushl 8(%ebp)
        call fillMemoryRange
        popl %edx
        popl %edx
        popl %edx

        popl %ebx # Restore registers
        popl %eax # Restore registers

        pushl %ebx
        pushl %eax
        pushl 8(%ebp)
        pushl $format_fisierNL
        call printf
        popl %edx
        popl %edx
        popl %edx
        popl %edx

        jmp memADD_exit

    memADD_failedToFindSpace:
        xorl %eax, %eax
        xorl %ebx, %ebx
        jmp memADD_exit

    memADD_exit:
        popl %edx # Pop local variable
        popl %ebp
        ret


# FOR TASK: Get file range from memory
#   Loop through the memory until the first occurance of the descriptor and then measure how much it spans
memGET: # (descriptor:.long) RETURNS (%eax: startIndex, %ebx: endIndex)
    pushl %ebp
    movl %esp, %ebp

    # %eax: start index of current range
    xorl %eax, %eax

    # %ecx: current index
    xorl %ecx, %ecx

    movl 8(%ebp), %edx

    lea mem, %edi
    memGET_loop:
        cmpl n, %ecx
        je memGET_cantFind

        cmpl (%edi, %ecx, 4), %edx
        jne memGET_if__exit
        movl %ecx, %eax # Found the file, store index of the first block of the file
        jmp memGET_found

        memGET_if__exit:
        
        incl %ecx
        jmp memGET_loop

    memGET_found: # Found the file, search for where it ends
        # while(mem[%ecx] == %dl):              
        memGET_while:
            cmpl n, %ecx
            je memGET_while_exit

            cmpl (%edi, %ecx, 4), %edx
            jne memGET_while_exit

            incl %ecx

            jmp memGET_while

        memGET_while_exit: # 
        subl $1, %ecx
        movl %ecx, %ebx # Store end index in %ebx for return

        jmp memGET_exit

    memGET_cantFind:
        xorl %eax, %eax
        xorl %ebx, %ebx
        jmp memGET_exit

    memGET_exit:

        popl %ebp
        ret

# FOR TASK: Delete file with descriptor and print all files
memDELETE: # (descriptor: .long) NO RETURNS
    pushl %ebp
    movl %esp, %ebp

    pushl 8(%ebp)
    call memGET # Get the file memory range
    popl %edx

    pushl %ebx
    pushl %eax
    pushl $0
    call fillMemoryRange # Fill it with 0 / Remove the file
    popl %edx
    popl %edx
    popl %edx

    call printAllFiles

    memDELETE_exit:
        popl %ebp
        ret

# FOR TASK: Defragment
#   Loop using two pointers %eax, %ebx
#   %ebx goes through the memory normally while %eax only gets incremented if there isnt a 0 at %ebx
memDEFRAGMENT: # (NO ARGS) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    xorl %eax, %eax # %eax: real/trailing index

    xorl %ebx, %ebx # %ebx: effective/leading index

    lea mem, %edi
    memDEFRAGMENT_loop:
        cmp n, %ebx
        je memDEFRAGMENT_cleanupLoop

        movl (%edi, %ebx, 4), %edx
        movl %edx, (%edi, %eax, 4)

        cmpl $0, (%edi, %ebx, 4)
        je memDEFRAGMENT_loop_continue
        incl %eax

        memDEFRAGMENT_loop_continue:

        incl %ebx
        jmp memDEFRAGMENT_loop

    memDEFRAGMENT_cleanupLoop: # Fill with 0s to the end
        cmp n, %eax
        je memDEFRAGMENT_exit

        movl $0, (%edi, %eax, 4)

        incl %eax
        jmp memDEFRAGMENT_cleanupLoop

    memDEFRAGMENT_exit:
        call printAllFiles

        popl %ebp
        ret
    

# FOR READING:
#   Read ADD command inputs
cmd_readADD: # (NO ARGS) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    pushl $auxVar1
    pushl $format_numarNL
    call scanf
    popl %edx
    popl %edx

    # -4(%ebp): number of files to add
    pushl auxVar1

    cmd_readADD_loop:
        cmpl $0, -4(%ebp)
        je cmd_readADD_exit

        pushl $auxVar2 # Dimensiune
        pushl $auxVar1 # Descriptor
        pushl $format_addInputNL
        call scanf
        popl %edx
        popl %edx
        popl %edx

        pushl auxVar2
        pushl auxVar1
        call memADD # Call the memory add function with the read input
        popl %edx
        popl %edx

        decl -4(%ebp)
        jmp cmd_readADD_loop

    cmd_readADD_exit:
        popl %edx # Pop local variable
        popl %ebp
        ret

# FOR READING:
#   Read GET command inputs
cmd_readGET: # (NO ARGS) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    pushl $auxVar1 # descriptor
    pushl $format_numarNL
    call scanf
    popl %edx
    popl %edx

    pushl auxVar1
    call memGET
    popl %edx

    pushl %ebx
    pushl %eax
    pushl $format_rangeNL   
    call printf # Print the GET result
    popl %edx
    popl %edx
    popl %edx

    cmd_readGET_exit:
        popl %ebp
        ret

# FOR READING:
#   Read DELETE command inputs
cmd_readDELETE: # (NO ARGS) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    pushl $auxVar1
    pushl $format_numarNL
    call scanf
    popl %edx
    popl %edx
    
    pushl auxVar1
    call memDELETE
    popl %edx 

    cmd_readDELETE_exit:
        popl %ebp
        ret


# FOR READING: 
#   Main reading function
cmd_readOperations: # (NO ARGS) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    pushl $nrOperatii
    pushl $format_numar 
    call scanf
    popl %edx
    popl %edx

    cmd_readOperations_loop:
        cmpl $0, nrOperatii
        je cmd_readOperations_exit

        pushl $auxVar1 # Which command to execute
        pushl $format_numarNL
        call scanf
        popl %edx
        popl %edx

        cmpl $1, auxVar1
        jne cmd_readOperations_loop_if_ADD_exit
        call cmd_readADD # Read input for ADD operation and execute it
        jmp cmd_readOperations_loop_continue
        cmd_readOperations_loop_if_ADD_exit:

        cmpl $2, auxVar1
        jne cmd_readOperations_loop_if_GET_exit
        call cmd_readGET # Read input for GET operation and execute it
        jmp cmd_readOperations_loop_continue
        cmd_readOperations_loop_if_GET_exit:

        cmpl $3, auxVar1
        jne cmd_readOperations_loop_if_DELETE_exit
        call cmd_readDELETE
        jmp cmd_readOperations_loop_continue
        cmd_readOperations_loop_if_DELETE_exit:

        # Execute Defrag operation
        call memDEFRAGMENT

        cmd_readOperations_loop_continue:

        decl nrOperatii
        jmp cmd_readOperations_loop

    cmd_readOperations_exit:
        popl %ebp
        ret 



.global main
main:
    call cmd_readOperations

exit:
    movl $1, %eax
    movl $0, %ebx       
    int $0x80
