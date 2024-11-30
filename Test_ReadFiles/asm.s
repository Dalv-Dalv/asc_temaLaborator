.data
    directoryPath: .asciz "/home/dalv/Dalv/University/ASC/TemaLaborator/Test_ReadFiles/"
    filesBuffer: .space 4096
    format_fileName: .asciz "The file's name is \"%s\" I hope thats not empty"

    directoryFileDescriptor: .long 0

    format_scanf: .asciz "%s"
    format_printf: .asciz "%s\n"

    scanfString: .space 1024

.text
.global main
main:
    pushl $scanfString
    pushl $format_scanf
    call scanf
    popl %edx
    popl %edx

    pushl $scanfString
    pushl $format_printf
    call printf
    popl %edx
    popl %edx

    # movl $5, %eax
    # movl $directoryPath, %ebx
    # movl $0, %ecx
    # int $0x80
    # movl %eax, directoryFileDescriptor

exit:
    movl $1, %eax
    movl $0, %ebx
    int $0x80
