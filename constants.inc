;
; x86-64 psABI:
;    https://gitlab.com/x86-psABIs/x86-64-ABI/-/jobs/artifacts/master/raw/x86-64-ABI/abi.pdf?job=build
; x86-64 Linux syscall table:
;    https://github.com/torvalds/linux/blob/v6.16-rc1/arch/x86/entry/syscalls/syscall_64.tbl
;


; ELF constants
;     ELF Header constants
ELFMAG0         equ 0x7F
ELFMAG1         equ 'E'
ELFMAG2         equ 'L'
ELFMAG3         equ 'F'
ELFCLASS64      equ 2
ELFDATA2LSB     equ 1
EV_CURRENT      equ 1
ELFOSABI_LINUX  equ 3
ET_EXEC         equ 2       ; We'd normally use EXECutable, but we actually use...
ET_DYN          equ 3       ; DYNamic object, which is what is required for static PIE.
EM_X86_64       equ 0x3E

;     ELF Program header constants
PT_LOAD         equ 0x00000001
PF_X            equ 0x1
PF_W            equ 0x2
PF_R            equ 0x4


; Linux constants
;     x86-64 Syscalls
sys_write       equ 1
sys_open        equ 2
sys_close       equ 3
sys_socket      equ 41
sys_bind        equ 49
sys_getsockname equ 51
sys_exit        equ 60

;     File Descriptors
STDOUT_FD       equ 1

;     Sockets
AF_INET         equ 2
SOCK_STREAM     equ 1
INADDR_ANY      equ 0x00000000 ; 0.0.0.0
ANY_PORT        equ 0          ; binding to port 0 picks any free port.
