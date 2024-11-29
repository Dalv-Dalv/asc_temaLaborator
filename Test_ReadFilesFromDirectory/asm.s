.data
    dir_path: .asciz "/home/dalv/Dalv/University/ASC/TemaLaborator/Test_ReadFilesFromDirectory/Files" # Path to the directory
    filesBuffer: .space 4096  # filesBuffer for `getdents`
    fmt: .asciz "Pls %s dont be empty\n"  # Format for output (filename and size)
    dir_fd: .long 0  # File descriptor for the directory
    nr_bytes: .long 0

    aux: .long 0
    format_printf: .asciz "Printing at %d\n"
    format_scanf: .asciz "%d"
    format_nr: .asciz "%d\n"
    format_str: .asciz "%s\n"
.text
.global main

main:
    pushl $aux
    pushl $format_scanf
    call scanf
    popl %edx
    popl %edx

    # Open the directory
    movl $5, %eax           # syscall: open
    movl $dir_path, %ebx    # Path to directory
    movl $0, %ecx           # Flags (read-only)
    int $0x80
    movl %eax, dir_fd       # Store directory file descriptor

    # Read directory entries with getdents
    movl $141, %eax         # syscall: getdents
    movl dir_fd, %ebx       # Directory file descriptor
    movl $filesBuffer, %ecx # filesBuffer to store entries
    movl $4096, %edx        # filesBuffer size
    int $0x80

    cmpl $0, %eax           # Check if any entries read
    jle close_dir           # Exit if none

    movl %eax, nr_bytes     # Number of bytes read

    # Parse directory entries
    lea filesBuffer, %edi   # Start of filesBuffer
    movl $0, %ecx           # Initialize index to 0
parse_entry:
    # Load the entry's reclen (record length) to skip over the entry properly
    movl (%edi), %eax       # Get the entry's inode (d_ino)
    movw 2(%edi), %dx       # Get the entry's reclen (d_reclen)

    cmpw $0, %dx            # If the record length is 0, we're done
    jle close_dir

    addl %edx, %edi          # Move the pointer forward by the length of the current entry (d_reclen)
    subl $4, %edx            # Adjust by 4 bytes to account for the initial d_ino and d_reclen fields

    # Now print the file name from d_name
    lea 8(%edi), %esi       # Load the address of the d_name field (skip the first 8 bytes: d_ino + d_reclen)
    pushl %esi
    pushl $format_str
    call printf
    addl $8, %edi           # Move to the next entry

    # Repeat for the next entry
    movl nr_bytes, %eax
    subl %ecx, %eax         # Remaining bytes
    cmpl $0, %eax           # Check if there are any bytes left
    jg parse_entry

close_dir:
    # Close the directory
    movl $6, %eax           # syscall: close
    movl dir_fd, %ebx       # Directory file descriptor
    int $0x80

    # Exit program
    movl $1, %eax           # syscall: exit
    xorl %ebx, %ebx         # Status 0
    int $0x80
