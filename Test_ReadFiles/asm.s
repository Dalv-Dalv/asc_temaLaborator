.data
    dir_path: .asciz "/home/dalv/Dalv/University/ASC/TemaLaborator/Test_ReadFiles/Inputs/"
    filesBuffer: .space 4096
    format_fileName: .asciz "The file's name is \"%s\" I hope thats not empty\n"

    format_file: .asciz "File%d.txt"

    dir_fd: .long 0

    format_scanf: .asciz "%s"
    format_printf: .asciz "%s\n"
    
    nrBytes: .long 0

    auxVar: .long 0

.text
.global main
main:
    movl %esp, %ebp

    movl $5, %eax
    movl $dir_path, %ebx
    movl $0, %ecx
    int $0x80
    movl %eax, dir_fd

    movl $141, %eax
    movl dir_fd, %ebx      
    movl $filesBuffer, %ecx
    movl $4096, %edx       
    int $0x80

    cmpl $0, %eax # Check if any entries read
    jle close_dir # Exit if none

    pushl %eax  # -4(%ebp): total bytes read
    pushl $0    # -8(%ebp): current d_reclen
    pushl $0    # -12(%ebp): current entry start index

    xorl %ecx, %ecx
    lea filesBuffer, %edi
    parse_entries:
        cmpl -4(%ebp), %ecx
        je close_dir

        # Read entry:
        movl %ecx, -12(%ebp) # Save entry start index
        addl $8, %ecx # Skip over first 8 bytes


        # Read d_reclen:
        xorl %eax, %eax
        movb (%edi, %ecx, 1), %al # Read little-endian representation
        incl %ecx
        movb (%edi, %ecx, 1), %ah
        incl %ecx

        movl %eax, -8(%ebp) # Save d_reclen

        # Print string:
        movl %edi, %eax
        addl %ecx, %eax
        pushl %eax
        pushl $format_fileName
        call printf
        popl %edx
        popl %eax

        pushl $auxVar
        pushl $format_file
        pushl %eax
        call sscanf
        popl %edx
        popl %edx
        popl %edx

        # Move on to next entry:
        movl -12(%ebp), %ecx # Go back to the start of the entry
        addl -8(%ebp), %ecx  # Advance by d_reclen number of bytes
        jmp parse_entries


    close_dir:
    # Close the directory
    movl $6, %eax        
    movl dir_fd, %ebx    
    int $0x80

exit:
    movl $1, %eax
    movl $0, %ebx
    int $0x80
