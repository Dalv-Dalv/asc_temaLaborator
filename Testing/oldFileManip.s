.data
    filepath: .asciz "file" 
    convertedName: .asciz ""
    buffer: .space 20        
    x: .long 1069
    format_newLine: .asciz "\n"

    str_a: .asciz "hello"
    str_b: .asciz " there"
.text
itoa: # (x:.long, *s_out) RETURNS VIA s_out 
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax # Number to convert to string

    # Use stack to get inverse

    xorl %ecx, %ecx

    itoa_while:
        cmpl $0, %eax
        je itoa_while_exit

        xorl %edx, %edx
        movl $10, %ebx
        divl %ebx

        pushl %edx

        incl %ecx

        jmp itoa_while
    
    itoa_while_exit:

    movl 12(%ebp), %eax
    lea (%eax), %edi

    xorl %edx, %edx
    itoa_for:
        popl %eax

        addl $0x30, %eax
        movb %al, (%edi, %edx, 1)

        incl %edx
        loop itoa_for

    itoa_exit:
        popl %ebp
        ret

.global main
main:
    lea buffer, %edi
    xorl %ecx, %ecx
    movl $69, %eax
    movl %eax, (%edi, %ecx, 4)

exit:
    movl $1, %eax
    movl $0, %ebx       
    int $0x80


    # Old code:

    movl x, %eax
    xorl %edx, %edx
    movl $10, %ebx
    divl %ebx
    
    lea buffer, %edi
    xorl %ecx, %ecx
    addb $0x30, %dl
    movb %dl, (%edi, %ecx, 1)

    pushl $buffer
    pushl $filepath
    call strcat
    popl %edx
    popl %edx

    pushl $format_newLine
    pushl $filepath
    call strcat
    popl %edx
    popl %edx

    pushl $filepath
    call printf
    popl %edx

    movl $8, %eax
    movl $filepath, %ebx
    movl $0100, %ecx
    int $0x80
