# Cerinta bidimensional

.data           
    # Memory array:
    mem: .space 256 # 2D Array of longs instead of bytes so that its easier to work with
    n: .long 8 # number of rows/columns
    nTotal: .long 64 # n * n
    
    # Printf/Scanf formats:
    format_numar: .asciz "%d"
    format_numarNL: .asciz "%d\n"
    format_addInputNL: .asciz "%d\n%d\n"        
    format_2numereNL: .asciz "%d %d\n"
    format_descriptor: .asciz "%d: "
    format_fisierNL: .asciz "%d: ((%d, %d), (%d, %d))\n"
    format_rangeNL: .asciz "((%d, %d), (%d, %d))\n" 
    format_newLine: .asciz "\n"

    # Files related arrays:
    # Number of elements = nTotal (case where every file spans exactly 1 block)
    # Space = nTotal * 4 (array of longs for ease of manipulation)
    farray_descriptor: .space 256
    farray_start: .space 256
    farray_end: .space 256
    farray_count: .long 0 # Number of files

    # Input related variables:
    nrOperatii: .long 0

    # Auxiliary variables used mainly for scanf; they can be used anywhere without managing call saving
    auxVar1: .long 0
    auxVar2: .long 0
.text

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
    
    xorl %ecx, %ecx
    lea farray_descriptor, %edi
    lea farray_start, %eax
    lea farray_end, %ebx
    printAllFiles_loop:
        cmpl farray_count, %ecx
        je printAllFiles_exit

        pushl %eax # Save %eax from printf call
        pushl %ecx # Save %ecx from printf call

        pushl (%edi, %ecx, 4)
        pushl $format_descriptor
        call printf # Print descriptor
        popl %edx
        popl %edx

        popl %ecx # Recover %ecx from printf call
        popl %eax # Recover %eax from printf call


        pushl %eax # Save %eax from printRange call
        pushl %ecx # save %ecx from printRange call

        pushl (%ebx, %ecx, 4)
        pushl (%eax, %ecx, 4)
        call printRange # Print memory range
        popl %edx
        popl %edx

        popl %ecx # Recover %ecx from printRange call
        popl %eax # Recover %eax from printRange call

        incl %ecx
        jmp printAllFiles_loop


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
        jne memADD_loop__if_endOfLine_exit
        xorl %ebx, %ebx # Reset counter and index, a file cant occupy multiple lines
        movl %ecx, %eax

        memADD_loop__if_endOfLine_exit:

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

        # Add file to file arrays:
        movl farray_count, %ecx

        lea farray_descriptor, %edi
        movl 8(%ebp), %edx
        movl %edx, (%edi, %ecx, 4) # Add descriptor

        lea farray_start, %edi
        movl %eax, (%edi, %ecx, 4) # Add start index

        lea farray_end, %edi
        movl %ebx, (%edi, %ecx, 4) # Add end index

        incl farray_count

        # Fill the memory range with the file descriptor:
        pushl %eax # Store registers to keep after function call
        pushl %ebx

        pushl %ebx
        pushl %eax
        pushl 8(%ebp)
        call fillMemoryRange
        popl %edx
        popl %edx
        popl %edx

        popl %ebx
        popl %eax # Restore registers
        
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
#   Loop through all the files and check if we found a matching descriptor, if so return its start and end indices
memGET: # (descriptor:.long) RETURNS (%eax: startIndex, %ebx: endIndex, %ecx: fileIndex), indices are considered to be contiguous
    pushl %ebp
    movl %esp, %ebp

    xorl %ecx, %ecx
    lea farray_descriptor, %edi
    memGET_loop: # Loop over the files
        cmpl farray_count, %ecx
        je memGET_cantFind

        movl 8(%ebp), %edx # Cant compare 8(%ebp) directly to (%edi, %ecx, 4) so we use %edx
        cmpl %edx, (%edi, %ecx, 4) # Check if we found the file
        je memGET_found

        incl %ecx
        jmp memGET_loop

    memGET_found:
    lea farray_start, %edi
    movl (%edi, %ecx, 4), %eax
    lea farray_end, %edi
    movl (%edi, %ecx, 4), %ebx
    jmp memGET_exit

    memGET_cantFind:
    xorl %eax, %eax
    xorl %ebx, %ebx
    movl $-1, %ecx

    memGET_exit:
        popl %ebp
        ret

# FOR TASK: Delete file with descriptor and print all files
#   Find the file using memGET, fill the corresponding memory range with 0s
# and remove the file from the file arrays
memDELETE: # (descriptor: .long) NO RETURNS
    pushl %ebp
    movl %esp, %ebp

    pushl 8(%ebp)
    call memGET # Get the file memory range
    popl %edx
    # %ecx will have the index of the file after memGET call

    cmp $0, %ebx # If get couldnt find it, exit out
    je memDELETE_exit 

    pushl %ecx # Save %ecx from fillMemoryRange call

    pushl %ebx
    pushl %eax
    pushl $0
    call fillMemoryRange # Fill the memory with 0s
    popl %edx
    popl %eax
    popl %ebx

    popl %ecx # Recover %ecx after fillMemoryRange call


    # Delete file from file arrays:
    movl %ecx, %edx # Save the index of the deleted file
    incl %ecx

    lea farray_descriptor, %edi
    lea farray_start, %eax
    lea farray_end, %ebx
    memDELETE_loop:
        cmpl farray_count, %ecx
        je memDELETE_loop_exit

        pushl (%edi, %ecx, 4)
        popl (%edi, %edx, 4)

        pushl (%eax, %ecx, 4)
        popl (%eax, %edx, 4)

        pushl (%ebx, %ecx, 4)
        popl (%ebx, %edx, 4)

        incl %ecx
        incl %edx
        jmp memDELETE_loop
    memDELETE_loop_exit:
    movl $0, (%edi, %edx, 4)
    movl $0, (%eax, %edx, 4)
    movl $0, (%ebx, %edx, 4)

    decl farray_count

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

    memDEFRAGMENT_exit:
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
        call cmd_readDELETE # Read input for DELETE operation and execute it
        jmp cmd_readOperations_loop_continue
        cmd_readOperations_loop_if_DELETE_exit:

        # Execute Defrag operation
        call memDEFRAGMENT

        cmd_readOperations_loop_continue:

        pushl $7
        pushl $7
        pushl $0
        pushl $0
        call printMemoryRange
        popl %edx
        popl %edx
        popl %edx
        popl %edx

        pushl $format_newLine
        call printf
        popl %edx

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
