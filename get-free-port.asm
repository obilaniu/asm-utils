%include "constants.inc"


; We compile for x86-64 so select 64-bit mode
bits 64


; ELF Header
_elf_header:
db   ELFMAG0, 'ELF'         ; e_ident[EI_MAG0..3]
db   ELFCLASS64             ; e_ident[EI_CLASS]
db   ELFDATA2LSB            ; e_ident[EI_DATA]
db   EV_CURRENT             ; e_ident[EI_VERSION]
db   ELFOSABI_LINUX         ; e_ident[EI_OSABI]
db   0                      ; e_ident[EI_ABIVERSION]
db   0,0,0,0,0,0,0          ; e_ident[EI_PAD]
dw   ET_DYN                 ; e_type
dw   EM_X86_64              ; e_machine
dd   EV_CURRENT             ; e_version
dq   _start                 ; e_entry
dq   _program_header        ; e_phoff
dq   0                      ; e_shoff     (We declare no sections)
dd   0                      ; e_flags
dw   (_end_elf_header -     \
          _elf_header)      ; e_ehsize    (Must equal 64)
dw   (_end_program_header - \
          _program_header)  ; e_phentsize (Must equal 56 on x86_64)
dw   1                      ; e_phnum
dw   0x40                   ; e_shentsize (Must equal 64 on x86_64)
dw   0                      ; e_shnum     (We declare no sections)
dw   0                      ; e_shstrndx  (We declare no sections)
_end_elf_header:

%if (_end_elf_header-_elf_header) != 64
%error "ELF header not exactly 64 bytes!"
%endif


; Program header
_program_header:
dd   PT_LOAD                ; p_type
dd   PF_R|PF_X              ; p_flags
dq   _elf_header            ; p_offset
dq   _elf_header            ; p_vaddr
dq   _elf_header            ; p_paddr
dq   _end-_start            ; p_filesz
dq   _end-_start            ; p_memsz
dq   0x1000                 ; p_align
_end_program_header:

%if (_end_program_header-_program_header) != 56
%error "ELF program header not exactly 56 bytes!"
%endif


; Entry point, contains program proper
_start:
    ; socket(AF_INET, SOCK_STREAM, 0)
    mov     edi,    AF_INET
    mov     esi,    SOCK_STREAM
    xor     edx,    edx
    mov     eax,    sys_socket
    syscall

    test    rax,    rax
    js      fail

    mov     r12d,   eax        ; Save socket fd in r12
    sub     rsp,    32         ; Allocate 32 bytes on the stack


    ; bind(fd, &sockaddr, sizeof(sockaddr))
    mov     edi,    r12d
    mov     rsi,    rsp        ; Build struct sockaddr_in on the stack at [rsi+0]
    mov     eax,    AF_INET
    mov    [rsi],   ax
    mov     eax,    ANY_PORT
    xchg    ah,     al         ; Port is network-endian (big-endian)
    mov    [rsi+2], ax
    mov     eax,    INADDR_ANY
    bswap   eax                ; Addr is network-endian (big-endian)
    mov    [rsi+4], eax
    xor     eax,    eax
    mov    [rsi+8], rax        ; Clear remaining 8 bytes of struct sockaddr_in
    mov     edx,    16         ; sizeof(struct sockaddr_in)
    mov     eax,    sys_bind
    syscall

    test    eax,    eax
    js      fail


    ; getsockname(fd, &sockaddr, sizeof(sockaddr))
    mov     edi,    r12d
    mov     rsi,    rsp
    lea     rdx,   [rsp+16]
    mov qword [rdx], 16
    mov     eax,    sys_getsockname
    syscall

    test    eax,    eax
    js      fail

    cmp qword [rsp+16], 4      ; addrlen < 4 (?)
    jl      fail

    movzx   eax,    word [rsp+2]
    xchg    ah,     al         ; Port is network-endian (big-endian)
    mov     r13d,   eax


    ; close(fd)
    mov     edi,    r12d
    mov     eax,    sys_close
    syscall


    ;
    ; Simplistic 16-bit port number to decimal string conversion.
    ; Write '00000\n\0\0' to the stack, convert uint16 to decimal by up to
    ; five repeated divisions and write out.
    ;
    mov dword [rsp+0], 0x30303030
    mov dword [rsp+4], 0x00000a30
    mov     edi,    10
    lea     rsi,   [rsp+4]
    mov     eax,    r13d
divloop:
    xor     edx,    edx        ; Re-zero high bits
    div     edi                ; EDX, EAX = EDX:EAX % 10, EDX:EAX / 10
    add    [rsi],   dl         ; '0' += Remainder
    test    eax,    eax        ; Quotient now zero, break
    jz      end_divloop
    dec     rsi
    jmp     divloop
end_divloop:


    ; write(1, "port#\n", strlen("port#\n"))
    lea     rdx,   [rsp+6]     ; One-past-the-end, after the trailing '\n'
    sub     rdx,    rsi        ; Compute string length
    mov     edi,    STDOUT_FD  ; FD 1 == stdout
    mov     eax,    sys_write
    syscall

    xor     edi,    edi        ; exit_code = EXIT_SUCCESS (0)
    jmp     exit


fail:
    mov     edi,    1          ; exit_code = EXIT_FAILURE (1)
exit:
    ; exit(exit_code)
    mov     eax,    sys_exit
    syscall
_end:
