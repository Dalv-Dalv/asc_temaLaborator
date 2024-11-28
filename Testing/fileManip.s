.data
    filepath: .asciz "file" 
    convertedName: .asciz ""
    itoa_buffer: .space 20        
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

    movl 12(%ebp), %edi

    xorl %edx, %edx
    itoa_for:
        popl %eax

        addl $0x30, %eax
        movb %al, (%edi, %edx, 1)

        incl %edx
        loop itoa_for
    
    movb $0x0A, (%edi, %edx, 1) # Add new line
    incl %edi
    movb $0x00, (%edi, %edx, 1) # Add null character

    itoa_exit:
        popl %ebp
        ret

.global main
main:
    lea itoa_buffer, %eax
    pushl %eax
    pushl $1725192
    call itoa
    popl %edx
    popl %edx

    movl $8, %eax
    movl $itoa_buffer, %ebx
    movl $0100, %ecx
    int $0x80

exit:
    movl $1, %eax
    movl $0, %ebx       
    int $0x80
