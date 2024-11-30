# Cerinta bidimensional

.data
    # 4194304 : 1024 : 1048576
    mem: .space 256 # 2D 1024x1024 Array of longs instead of bytes so that its easier to work with
    n: .long 8
    nTotal: .long 64 # n * n
    
    # Printf/Scanf formats
    format_number: .asciz "%d"
    format_numberSpace: .asciz "%d "
    format_addInputNL: .asciz "%d %d"
    format_descriptor: .asciz "%d: "
    format_rangeNL: .asciz "((%d, %d), (%d, %d))\n" 
    format_newLine: .asciz "\n"

    format_physicalFilePrefix: .asciz "File "
    format_physicalFileSuffix: .asciz ".txt"

    # Buffer mainly used for converting numbers to strings
    auxBuffer1: .space 128
    auxBuffer2: .space 128

    # Input related variables:
    nrOperations: .long 0

    # Auxiliary variables used mainly for scanf; they can be used anywhere without managing call saving
    auxVar1: .long 0
    auxVar2: .long 0
.text

# FOR UTILITY: Converts number to string
convertNrToString: # (x:.long, *string) RETURNS VIA *string
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax # Number to convert

    xorl %ecx, %ecx
    convertNrToString_while: # Push all digits onto stack
        cmpl $0, %eax
        je convertNrToString_while_exit

        xorl %edx, %edx
        movl $10, %ebx
        divl %ebx

        pushl %edx

        incl %ecx
        jmp convertNrToString_while
    convertNrToString_while_exit:
    
    movl 12(%ebp), %edi

    xorl %edx, %edx # Index in *string
    convertNrToString_for: # Build the number back up in ascii
        popl %eax

        addl $0x30, %eax
        movb %al, (%edi, %edx, 1)

        incl %edx
        loop convertNrToString_for
    
    movb $0x00, (%edi, %edx, 1) # Add null character

    convertNrToString_exit:
        popl %ebp
        ret

# FOR UTILITY: Creates file based on given file descriptor
createPhysicalFile: # (fileDescriptor: .long) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    # Put null character at the start of auxBuffer2, effectively resetting it for strcat calls
    xorl %ecx, %ecx
    lea auxBuffer2, %edi
    movb $0x00, (%edi, %ecx, 1)

    pushl $auxBuffer1
    pushl 8(%ebp)
    call convertNrToString
    popl %edx
    popl %edx

    # Build the name of the file in auxBuffer2
    # Add the prefix of the file to auxBuffer2
    pushl $format_physicalFilePrefix
    pushl $auxBuffer2
    call strcat
    popl %edx
    popl %edx

    # Add the converted file descriptor to auxBuffer2
    pushl $auxBuffer1
    pushl $auxBuffer2
    call strcat
    popl %edx
    popl %edx

    # Add the file sufix to auxBuffer2
    pushl $format_physicalFileSuffix
    pushl $auxBuffer2
    call strcat
    popl %edx
    popl %edx

    # Add the newLine character to auxBuffer2
    pushl $format_newLine # FOR DEBUGGING
    pushl $auxBuffer2
    call strcat
    popl %edx
    popl %edx

    # Create the file physically
    movl $5, %eax # Syscall_open
    movl $auxBuffer2, %ebx # File name
    movl $0101, %ecx # File flags: O_CREAT | O_WRONLY
    movl $0777, %edx # File permissions: full permissions
    int $0x80

    createPhysicalFile_exit:
        popl %ebp
        ret

# FOR DEBUG: Prints the memory range startIndex:endIndex
printMemoryRange: # (startX:.long, startY:.long, endX:.long, endY:.long) NO RETURN 
    pushl %ebp
    movl %esp, %ebp

    lea mem, %edi

    movl 12(%ebp), %ecx # %ecx = startY * n + startX
    movl %ecx, %eax
    mull n
    movl %eax, %ecx
    addl 8(%ebp), %ecx

    movl 20(%ebp), %ebx # %ebx = endY * n + endX
    movl %ebx, %eax
    mull n
    movl %eax, %ebx
    addl 16(%ebp), %ebx

    add $1, %ebx
    printMemoryRange_loop:
        cmpl %ebx, %ecx
        je printMemoryRange_exit

        movl %ecx, %eax
        xorl %edx, %edx
        divl n
        cmpl $0, %edx
        jne printMemoryRange_loop_if_endOfLine_exit
        # Print \n 
        pushl %ecx # Save registry before printf call

        pushl $format_newLine
        call printf
        popl %edx

        popl %ecx # Recover registry

        printMemoryRange_loop_if_endOfLine_exit:


        pushl %ecx # Save registry before printf call

        pushl (%edi, %ecx, 4)
        pushl $format_numberSpace
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

# FOR UTILITY/DEBUG: Transforms contiguous indices into (X, Y) indices and prints them
printRange: # (startIndex:.long, endIndex:.long) NO RETURNS
    pushl %ebp
    movl %esp, %ebp

    movl 12(%ebp), %eax
    xorl %edx, %edx
    divl n
    pushl %eax # %eax: endY
    pushl %edx # %edx: endX

    movl 8(%ebp), %eax
    xorl %edx, %edx
    divl n
    pushl %eax # %eax: startY
    pushl %edx # %edx: startX

    pushl $format_rangeNL
    call printf
    popl %edx
    popl %edx
    popl %edx
    popl %edx
    popl %edx

    pushRangeOntoStack_exit:
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
        cmp nTotal, %ecx
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
        pushl %edx # Save register before printf call

        pushl %eax # descriptor
        pushl $format_descriptor
        call printf
        popl %edx
        popl %eax

        # pushl %edx, but its already on the stack
        pushl %ebx
        call printRange
        popl %edx

        popl %edx # Restore register after printf call
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

    pushl %eax # descriptor
    pushl $format_descriptor
    call printf
    popl %edx
    popl %eax

    pushl %ecx
    pushl %ebx
    call printRange
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
memADD: # (descriptor:.long, dimensiune:.long in bytes) NO RETURNS      
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
        cmpl nTotal, %ecx
        je memADD_failedToFindSpace

        pushl %eax # Save %eax from division operation

        movl %ecx, %eax
        xorl %edx, %edx
        divl n
        popl %eax # Recover %eax from div
        cmpl $0, %edx # Check if we moved onto a new line
        jne memADD_loop_if_endOfLine_exit
        xorl %ebx, %ebx # Reset counter and index, a file cant occupy multiple lines
        movl %ecx, %eax

        memADD_loop_if_endOfLine_exit:

        cmpl $0, (%edi, %ecx, 4)
        jne memADD_if_foundOccupiedBlock

        # Current block is free
        incl %ebx
        cmpl -4(%ebp), %ebx
        je memADD_foundSpace

        jmp memADD_loop_continue

        memADD_if_foundOccupiedBlock:
            movl %ecx, %eax # Reset current index and current size
            incl %eax
            xorl %ebx, %ebx
        
        memADD_loop_continue:

        incl %ecx
        jmp memADD_loop


    memADD_failedToFindSpace:
        xorl %eax, %eax
        xorl %ebx, %ebx

        jmp memADD_exit
    
    memADD_foundSpace:
        addl %eax, %ebx
        subl $1, %ebx

        pushl %eax # Save %eax from createPhysicalFile call
        pushl %ebx # Save %ebx from createPhysicalFile call

        pushl 8(%ebp)
        call createPhysicalFile
        popl %edx

        popl %ebx # Recover %ebx from createPhysicalFile call
        popl %eax # Recover %eax from createPhysicalFile call

        pushl %eax # Save %eax from fillMemoryRange call
        pushl %ebx # Save %ebx from fillMemoryRange call

        pushl %ebx
        pushl %eax
        pushl 8(%ebp)
        call fillMemoryRange
        popl %edx
        popl %edx
        popl %edx

        popl %ebx # Recover %ebx from fillMemoryRange call
        popl %eax # Recover %eax from fillMemoryRange call
        
        jmp memADD_exit

    memADD_exit:
        pushl %eax # Save registers before printf call
        pushl %ebx

        pushl 8(%ebp) # descriptor
        pushl $format_descriptor
        call printf
        popl %edx
        popl %edx

        popl %ebx
        popl %eax # Recover registers after printf call

        pushl %ebx
        pushl %eax
        call printRange
        popl %edx
        popl %edx

        popl %ebp # Pop local variable
        popl %ebp
        ret

# FOR TASK: Get file range from memory
#   Exactly the same as the unidimensional case
#   Loop through the memory until the first occurance of the descriptor and then measure how much it spans
memGET: # (descriptor:.long) RETURNS (%eax: startIndex, %ebx: endIndex), indices are considered to be contiguous
    pushl %ebp
    movl %esp, %ebp

    # %eax: start index of current range
    xorl %eax, %eax

    # %ecx: current index
    xorl %ecx, %ecx

    movl 8(%ebp), %edx

    lea mem, %edi
    memGET_loop:
        cmpl nTotal, %ecx
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
            cmpl nTotal, %ecx
            je memGET_while_exit

            cmpl (%edi, %ecx, 4), %edx
            jne memGET_while_exit

            incl %ecx

            jmp memGET_while

        memGET_while_exit:
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
#   Exactly the same as unidimensional case
memDELETE: # (descriptor: .long) NO RETURNS
    pushl %ebp
    movl %esp, %ebp

    pushl 8(%ebp)
    call memGET # Get the file memory range
    popl %edx

    cmp $0, %ebx # If get couldnt find it, exit out
    je memDELETE_exit

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
#   Loop through the memory, save the first position of a free block, continue looping
# until we find a file, then determine its size and after that check if it can be
# placed where we found the free block; loop like this until the end of the memory
memDEFRAGMENT: # (NO ARGS) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    xorl %eax, %eax # Index to latest empty space
    lea mem, %edi
    # Skip over any files at the start of the memory
    memDEFRAGMENT_initializationLoop: # Move %eax to the first empty space
        cmpl nTotal, %eax
        je memDEFRAGMENT_exit

        cmpl $0, (%edi, %eax, 4)
        je memDEFRAGMENT_initializationLoop_exit

        incl %eax
        jmp memDEFRAGMENT_initializationLoop
    memDEFRAGMENT_initializationLoop_exit:

    movl %eax, %ecx # %ecx: Iterator

    xorl %ebx, %ebx # %ebx: Size of the current file

    pushl $0 # -4(%ebp): current file descriptor

    memDEFRAGMENT_mainLoop:
        cmpl nTotal, %ecx
        je memDEFRAGMENT_mainLoop_exit

        cmpl $0, (%edi, %ecx, 4)
        je memDEFRAGMENT_mainLoop_continue

        # Found a file:
        movl %ecx, %ebx
        movl (%edi, %ecx, 4), %edx
        movl %edx, -4(%ebp)
        memDEFRAGMENT_mainLoop_while: # Loop through the file and determine its size 
            cmpl nTotal, %ebx
            je memDEFRAGMENT_mainLoop_while_exit

            cmpl %edx, (%edi, %ebx, 4)
            jne memDEFRAGMENT_mainLoop_while_exit

            incl %ebx
            jmp memDEFRAGMENT_mainLoop_while
        memDEFRAGMENT_mainLoop_while_exit:


        # Check if we can fit the file at %eax
        subl %ecx, %ebx

        pushl %eax # Save %eax from division operation

        xorl %edx, %edx
        divl n # In %eax we will have the row (Y value) and in %edx we will have the column (X value)
        
        popl %eax # Recover %eax from division operation

        # Calculate how many free blocks theres left until the end of the row
        pushl n
        subl %edx, (%esp) # Calculate n - %edx
        popl %edx

        cmp %edx, %ebx
        jle memDEFRAGMENT_mainLoop_canFit # File can fit
        # File cant be fit:

        # If file cant be fit, move to the next line and check if it can be fit there
        xorl %edx, %edx
        divl n # Get the row
        addl $1, %eax # Get the next row
        mull n # Get the full index to the first element of the row

        cmpl $0, (%edi, %eax, 4)
        jne memDEFRAGMENT_mainLoop_findNextFreeBlockLoop # The file is at the start of the line, nothing to do

        memDEFRAGMENT_mainLoop_canFit:
        movl -4(%ebp), %edx # Current file descriptor
        memDEFRAGMENT_mainLoop_moveFileLoop:
            cmpl $0, %ebx
            je memDEFRAGMENT_mainLoop_moveFileLoop_exit

            movl $0, (%edi, %ecx, 4)
            movl %edx, (%edi, %eax, 4)

            incl %eax
            incl %ecx

            decl %ebx
            jmp memDEFRAGMENT_mainLoop_moveFileLoop

        memDEFRAGMENT_mainLoop_moveFileLoop_exit:

        # Move %eax to the next empty block:
        memDEFRAGMENT_mainLoop_findNextFreeBlockLoop:
            cmpl nTotal, %eax
            je memDEFRAGMENT_exit

            cmpl $0, (%edi, %eax, 4)
            je memDEFRAGMENT_mainLoop_findNextFreeBlockLoop_exit

            incl %eax
            jmp memDEFRAGMENT_mainLoop_findNextFreeBlockLoop
        memDEFRAGMENT_mainLoop_findNextFreeBlockLoop_exit:

        cmpl %eax, %ecx
        jge memDEFRAGMENT_mainLoop
        movl %eax, %ecx

        jmp memDEFRAGMENT_mainLoop

        memDEFRAGMENT_mainLoop_continue:
        incl %ecx
        jmp memDEFRAGMENT_mainLoop

    memDEFRAGMENT_mainLoop_exit:

    # #######################################################
    # #### TEST WITH FILE DELETED AT THE START OF MEMORY ####
    # #######################################################


    # ######################################################
    # #### TEST WITH FILE AT THE VERY END OF THE MEMORY ####
    # ######################################################

    memDEFRAGMENT_exit:
        call printAllFiles

        popl %edx # Pop -4(%ebp): current file descriptor
        popl %ebp
        ret


# FOR READING:
#   Read ADD command inputs
cmd_readADD: # (NO ARGS) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    pushl $auxVar1
    pushl $format_number
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
    pushl $format_number
    call scanf
    popl %edx
    popl %edx

    pushl auxVar1
    call memGET
    popl %edx

    pushl %ebx
    pushl %eax
    call printRange
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
    pushl $format_number
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

    pushl $nrOperations
    pushl $format_number
    call scanf
    popl %edx
    popl %edx

    cmd_readOperations_loop:
        cmpl $0, nrOperations
        je cmd_readOperations_exit

        pushl $auxVar1 # Which command to execute
        pushl $format_number
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
        call cmd_readDELETE # Read input for DELETE operation and execute it
        jmp cmd_readOperations_loop_continue
        cmd_readOperations_loop_if_DELETE_exit:

        # Execute Defrag operation
        call memDEFRAGMENT

        cmd_readOperations_loop_continue:
        pushl $7
        pushl $0
        pushl $0
        pushl $0
        call printMemoryRange
        popl %edx
        popl %edx
        popl %edx
        popl %edx

        decl nrOperations
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
