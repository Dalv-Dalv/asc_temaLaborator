# Cerinta unidimensional

.data           
    mem: .space 4096 # Array of longs instead of bytes so that its easier to work with
    n: .long 1024
    
    # Printf/Scanf formats
    format_number: .asciz "%d"
    format_addInputNL: .asciz "%d %d"
    format_fileNL: .asciz "%d: (%d, %d)\n"
    format_rangeNL: .asciz "(%d, %d)\n" 
    format_newLine: .asciz "\n"

    format_physicalFilePrefix: .asciz "File "
    format_physicalFileSuffix: .asciz ".txt"

    format_string: .asciz "%s"

    format_concrete_file: .asciz "File %d.txt"
    format_concrete_test: .asciz "File with descriptor %d has a size of %d bytes\n"

    # Buffer mainly used for converting numbers to strings
    auxBuffer1: .space 1024
    auxBuffer2: .space 1024

    # Buffers for memCONCRETE
    filesBuffer: .space 4096
    statBuffer: .space 128

    # Input related variables:
    nrOperations: .long 0
    
    # Auxiliary variables used mainly for scanf, they can be used anywhere without managing call saving
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
        pushl $format_number
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
        pushl $format_fileNL
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
    pushl $format_fileNL
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

    memADD_failedToFindSpace:
        xorl %eax, %eax
        xorl %ebx, %ebx
        jmp memADD_exit

    memADD_exit:
        pushl %ebx
        pushl %eax
        pushl 8(%ebp)
        pushl $format_fileNL
        call printf
        popl %edx
        popl %edx
        popl %edx
        popl %edx

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

# FOR TASK: Concrete
#   Use and parse syscall_getdents
memCONCRETE: # (*directoryPath) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp): directory path

    pushl $0 # -4(%ebp): Directory file descriptor
    pushl $0 # -8(%ebp): Total number of bytes read

    pushl $0 # -12(%ebp): Current d_reclen
    pushl $0 # -16(%ebp): Current entry start index

    pushl $0 # -20(%ebp): Size of current file
    pushl $0 # -24(%ebp): Current file descriptor

    xorl %ecx, %ecx
    lea auxBuffer2, %edi
    movl $0x00, (%edi, %ecx, 1) # Reset auxBuffer2 for strings

    # Open directory
    movl $5, %eax       # Syscall_open
    movl 8(%ebp), %ebx  # Path
    movl $0, %ecx       # File mode
    int $0x80
    movl %eax, -4(%ebp) # Save directory file descriptor

    # Get directory entries
    movl $141, %eax         # Syscall_getdents
    movl -4(%ebp), %ebx      # Directory file descriptor
    movl $filesBuffer, %ecx # Buffer to read into
    movl $4096, %edx        # Size of buffer
    int $0x80
    movl %eax, -8(%ebp) # Save total number of bytes read

    cmpl $0, %eax # Check if we read anything
    jle memCONCRETE_closeDirectory

    xorl %ecx, %ecx
    lea filesBuffer, %edi
    memCONCRETE_loop:
        cmpl -8(%ebp), %ecx
        jge memCONCRETE_closeDirectory

        # Read entry:
        movl %ecx, -16(%ebp) # Save entry start index
        addl $8, %ecx # Skip over first 8 bytes


        # Read d_reclen:
        xorl %eax, %eax
        movb (%edi, %ecx, 1), %al # Read little-endian representation
        incl %ecx
        movb (%edi, %ecx, 1), %ah
        incl %ecx

        movl %eax, -12(%ebp) # Save d_reclen

        # Check if the file is a '.' or '..'
        cmpb $46, (%edi, %ecx, 1)
        je memCONCRETE_loop_continue

        pushl %ecx # Save %ecx

        # Extract number from file name
        movl %edi, %eax
        addl (%esp), %eax # Get address to the start of the file name
        pushl $auxVar1
        pushl $format_concrete_file
        pushl %eax
        call sscanf
        popl %edx
        popl %edx
        popl %edx

        # Reset auxBuffer2 for constructing the file path
        pushl %edi

        xorl %edx, %edx
        lea auxBuffer2, %edi
        movl $0x00, (%edi, %edx, 1)

        popl %edi


        # Construct full file path
        pushl 8(%ebp) # Source
        pushl $auxBuffer2 # Destination
        call strcat
        popl %edx
        popl %edx

        movl %edi, %eax
        addl (%esp), %eax # %eax = %eax + %ecx

        pushl %eax # Source
        pushl $auxBuffer2 # Destination
        call strcat
        popl %edx
        popl %edx

        # Open the file
        movl $5, %eax           # Syscall_open
        movl $auxBuffer2, %ebx  # File path
        movl $0, %ecx           # O_RDONLY
        int $0x80
        # File descriptor in %eax
        movl %eax, -24(%ebp)

        # Get statistics about the file
        movl %eax, %ebx         # File descriptor
        movl $108, %eax         # Syscall_fstat
        movl $statBuffer, %ecx  # Buffer to save data into
        int $0x80

        # Extract file size from the statistics
        pushl %edi # Save %edi
        
        xorl %eax, %eax
        movl $20, %ecx
        lea statBuffer, %edi
        movb (%edi, %ecx, 1), %al # Read little-endian representation
        incl %ecx
        movb (%edi, %ecx, 1), %ah

        movl %eax, -20(%ebp) # Save file size
    
        popl %edi # Recover %edi
        popl %ecx # Recover %ecx from all the chaos

        # Close the file
        movl $6, %eax           # Syscall_close
        movl -24(%ebp), %ebx    # File descriptor
        int $0x80

        # FOR DEBUG: Print the file number and size
        # pushl -20(%ebp)     # File size
        # pushl auxVar1       # File number
        # pushl $format_concrete_test
        # call printf
        # popl %edx
        # popl %edx
        # popl %edx

        # Call memADD with the relevant data
        pushl %edi # Save %edi from memADD call
        pushl %ecx # Save %ecx from memADD call

        pushl -20(%ebp)
        pushl auxVar1 # File descriptor
        call memADD
        popl %edx
        popl %edx

        popl %ecx # Recover %ecx from memADD call
        popl %edi # Recover %edi from memADD call



        memCONCRETE_loop_continue:
        # Move on to next entry:
        movl -16(%ebp), %ecx # Go back to the start of the entry
        addl -12(%ebp), %ecx  # Advance by d_reclen number of bytes
        jmp memCONCRETE_loop


    memCONCRETE_closeDirectory:
    movl $6, %eax       # Syscall_close  
    movl -4(%ebp), %ebx # File descriptor
    int $0x80

    memCONCRETE_exit:
        popl %edx # Pop local variable
        popl %edx # Pop local variable
        popl %edx # Pop local variable
        popl %edx # Pop local variable
        popl %edx # Pop local variable
        popl %edx # Pop local variable

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
#   Read memCONCRETE command inputs
cmd_readCONCRETE: # (NO ARGS) NO RETURN
    pushl %ebp
    movl %esp, %ebp

    xorl %ecx, %ecx
    lea auxBuffer1, %edi
    movl $0x00, (%edi, %ecx, 1) # Put null character at the start of auxBuffer1 to reset it

    pushl $auxBuffer1
    pushl $format_string # Read directory path
    call scanf
    popl %edx
    popl %edx
    
    pushl $auxBuffer1
    call memCONCRETE
    popl %edx 

    cmd_readCONCRETE_exit:
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

        cmpl $4, auxVar1
        jne cmd_readOperations_loop_if_DEFRAGMENT_exit
        call memDEFRAGMENT # Execute DEFRAGMENT operation
        jmp cmd_readOperations_loop_continue
        cmd_readOperations_loop_if_DEFRAGMENT_exit:

        cmpl $5, auxVar1
        jne cmd_readOperations_loop_if_DEFRAGMENT_exit
        call cmd_readCONCRETE # Read input for CONCRETE operation and execute it
        jmp cmd_readOperations_loop_continue
        cmd_readOperations_loop_if_CONCRETE_exit:

        cmd_readOperations_loop_continue:
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
