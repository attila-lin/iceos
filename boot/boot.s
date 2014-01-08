use16

org 0x7c00  ; Set up 4K stack space after this bootloader

boot:
    ; initialize segment registers
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    ; initialize stack
    mov ax, 0x7bff
    mov sp, ax
    ; load rust code into 0x7e00 so we can jump to it later
    mov ah, 2       ; read
    mov al, 24      ; 24 sectors (12 KiB)
    mov ch, 0       ; cylinder & 0xff
    mov cl, 2       ; sector | ((cylinder >> 2) & 0xc0)
    mov dh, 0       ; head
    mov bx, 0x7e00  ; read buffer
    int 0x13
    jc error
    ; load protected mode GDT and a null IDT (we don't need interrupts)
    cli
    lgdt [gdtr]
    lidt [idtr]
    ; set protected mode bit of cr0
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    ; far jump to load CS with 32 bit segment
    jmp 0x08:protected_mode

error:
    mov si, .msg
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp .loop
.done:
    jmp $
    .msg db "could not read disk", 0

protected_mode:
    use32
    ; load all the other segments with 32 bit data segments
    mov eax, 0x10
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax
    mov ss, eax
    ; set up stack
    mov eax, 0x7bff
    mov esp, eax
    ; clear the screen
    mov edi, 0xb8000
    mov ecx, 80*25*2
    mov al, 0
    rep stosb
    ; jump into rust
    jmp 0x7e00

gdtr:
    dw (gdt_end - gdt) + 1  ; size
    dd gdt                  ; offset

idtr:
    dw 0
    dd 0

gdt:
    ; null entry
    dq 0
    ; code entry
    dw 0xffff       ; limit 0:15
    dw 0x0000       ; base 0:15
    db 0x00         ; base 16:23
    db 0b10011010   ; access byte - code
    db 0x4f         ; flags/(limit 16:19). flag is set to 32 bit protected mode
    db 0x00         ; base 24:31
    ; data entry
    dw 0xffff       ; limit 0:15
    dw 0x0000       ; base 0:15
    db 0x00         ; base 16:23
    db 0b10010010   ; access byte - data
    db 0x4f         ; flags/(limit 16:19). flag is set to 32 bit protected mode
    db 0x00         ; base 24:31
gdt_end:

; times 123 db 0 ; 这个表示填充123个字节的0
; 所以，times 510-($-$$) db 0 表示填充 510-($-$$) 这么多个字节的0
; 这里面的$表示当前指令的地址
; $$表示程序的起始地址(也就是最开始的7c00)
; 所以$-$$就等于本条指令之前的所有字节数
; 510-($-$$)的效果就是，填充了这些0之后，从程序开始到最后一个0，一共是510个字节。
; 再加上最后的dw两个字节(0xaa55是结束标志)，整段程序的大小就是512个字节，刚好占满一个扇区

times 510-($-$$) db 0

; dw 0xAA55       ; The standard PC boot signature

db 0x55
db 0xaa
