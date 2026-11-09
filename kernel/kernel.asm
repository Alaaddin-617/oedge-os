bits 16
org 0x7E00

start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov ax, 0x0003
    int 0x10
    mov ax, 0xB800
    mov es, ax
    call draw_ui

command_loop:
    call read_line
    call clear_output

    mov si, command_help
    call compare_command
    jc show_help

    mov si, command_about
    call compare_command
    jc show_about

    mov si, command_status
    call compare_command
    jc show_status

    mov si, command_time
    call compare_command
    jc show_time

    mov si, command_clear
    call compare_command
    jc clear_ui

    mov si, command_reboot
    call compare_command
    jc reboot

    mov si, command_echo
    call compare_command
    jc show_echo_usage

    call try_echo
    jc command_loop

    mov byte [color], 0x0C
    mov si, unknown_message
    mov dx, 10 * 160 + 12
    call print_at
    jmp command_loop

show_help:
    mov byte [color], 0x0B
    mov si, help_line_1
    mov dx, 10 * 160 + 12
    call print_at
    mov si, help_line_2
    mov dx, 11 * 160 + 12
    call print_at
    jmp command_loop

show_about:
    mov byte [color], 0x0E
    mov si, about_line_1
    mov dx, 10 * 160 + 12
    call print_at
    mov byte [color], 0x07
    mov si, about_line_2
    mov dx, 11 * 160 + 12
    call print_at
    jmp command_loop

show_status:
    mov byte [color], 0x0A
    mov si, status_line_1
    mov dx, 10 * 160 + 12
    call print_at
    mov byte [color], 0x07
    mov si, status_line_2
    mov dx, 11 * 160 + 12
    call print_at
    jmp command_loop

show_time:
    mov byte [color], 0x07
    mov si, time_line
    mov dx, 10 * 160 + 12
    call print_at

    mov al, 0x04
    out 0x70, al
    in al, 0x71
    mov di, 10 * 160 + 56
    call write_bcd
    mov al, ':'
    call put_char

    mov al, 0x02
    out 0x70, al
    in al, 0x71
    call write_bcd
    mov al, ':'
    call put_char

    mov al, 0x00
    out 0x70, al
    in al, 0x71
    call write_bcd
    jmp command_loop

show_echo_usage:
    mov byte [color], 0x07
    mov si, echo_usage
    mov dx, 10 * 160 + 12
    call print_at
    jmp command_loop

clear_ui:
    call draw_ui
    jmp command_loop

reboot:
    int 0x19
    jmp reboot

draw_ui:
    mov byte [color], 0x17
    mov di, 0
    mov ax, 0x1720
    mov cx, 2000
    rep stosw

    mov di, 0
    mov ax, 0x1F20
    mov cx, 80
    rep stosw

    mov byte [color], 0x1F
    mov si, header
    mov dx, 4
    call print_at

    mov byte [color], 0x0B
    mov si, title
    mov dx, 2 * 160 + 12
    call print_at

    mov byte [color], 0x07
    mov si, subtitle
    mov dx, 3 * 160 + 12
    call print_at
    mov si, divider
    mov dx, 5 * 160 + 12
    call print_at

    mov byte [color], 0x0E
    mov si, independence_note
    mov dx, 7 * 160 + 12
    call print_at

    mov byte [color], 0x07
    mov si, welcome
    mov dx, 9 * 160 + 12
    call print_at
    mov si, prompt
    mov dx, 16 * 160 + 8
    call print_at

    mov di, 24 * 160
    mov ax, 0x1F20
    mov cx, 80
    rep stosw
    mov byte [color], 0x1F
    mov si, footer
    mov dx, 24 * 160 + 4
    call print_at
    ret

clear_output:
    mov di, 10 * 160
    mov ax, 0x1720
    mov cx, 5 * 80
    rep stosw
    ret

read_line:
    mov word [input_length], 0
    mov word [cursor_position], 16 * 160 + 22
.next_key:
    xor ax, ax
    int 0x16
    cmp al, 0x0D
    je .done
    cmp al, 0x08
    je .backspace
    cmp al, 0x20
    jb .next_key
    cmp al, 0x7E
    ja .next_key
    cmp al, 'A'
    jb .lowercase
    cmp al, 'Z'
    ja .lowercase
    add al, 32
.lowercase:
    cmp word [input_length], 60
    jae .next_key
    mov bx, [input_length]
    mov [command_buffer + bx], al
    inc word [input_length]
    mov di, [cursor_position]
    call put_char
    mov [cursor_position], di
    jmp .next_key
.backspace:
    cmp word [input_length], 0
    je .next_key
    dec word [input_length]
    sub word [cursor_position], 2
    mov di, [cursor_position]
    mov al, 0x20
    call put_char
    jmp .next_key
.done:
    mov bx, [input_length]
    mov byte [command_buffer + bx], 0
    ret

compare_command:
    mov bx, command_buffer
.compare:
    mov al, [bx]
    cmp al, [si]
    jne .not_equal
    inc bx
    inc si
    test al, al
    jnz .compare
    stc
    ret
.not_equal:
    clc
    ret

try_echo:
    mov si, command_buffer
    cmp byte [si], 'e'
    jne .not_echo
    cmp byte [si + 1], 'c'
    jne .not_echo
    cmp byte [si + 2], 'h'
    jne .not_echo
    cmp byte [si + 3], 'o'
    jne .not_echo
    cmp byte [si + 4], ' '
    jne .not_echo
    add si, 5
    mov byte [color], 0x0A
    mov dx, 10 * 160 + 12
    call print_at
    stc
    ret
.not_echo:
    clc
    ret

print_at:
    push ax
    push di
    push si
    mov di, dx
.next_character:
    lodsb
    test al, al
    jz .done
    mov ah, [color]
    stosw
    jmp .next_character
.done:
    pop si
    pop di
    pop ax
    ret

put_char:
    mov ah, [color]
    stosw
    ret

write_bcd:
    and al, 0x7F
    push ax
    mov ah, al
    shr al, 4
    and al, 0x0F
    add al, '0'
    call put_char
    mov al, ah
    and al, 0x0F
    add al, '0'
    call put_char
    pop ax
    ret

color db 0x07
input_length dw 0
cursor_position dw 0
command_buffer times 61 db 0

header db "OEDGE OS  |  Origin Edge esintili bagimsiz prototip", 0
title db "BIOS tabanli komut satiri", 0
subtitle db "Ogrenme amacli, kucuk bir x86 onyukleme deneyi.", 0
divider times 72 db '-'
db 0
independence_note db "Bagimsiz prototip - Oedge.xyz ile resmi baglanti veya onay yoktur.", 0
welcome db "Komutlari gormek icin help yazin. Komutlar her istemde yeniden okunur.", 0
prompt db "oedge> ", 0
footer db "Oedge OS  |  Deneysel 16-bit BIOS prototipi", 0
help_line_1 db "Komutlar: help, about, status, time, echo <metin>", 0
help_line_2 db "clear ekrani yeniler; reboot BIOS'u yeniden baslatir.", 0
about_line_1 db "Oedge OS: bagimsiz, 16-bit gercek mod BIOS shell prototipi.", 0
about_line_2 db "Oedge.xyz tarafindan desteklenmez veya onaylanmaz.", 0
status_line_1 db "CPU: x86 real mode | Arayuz: VGA metin | Giris: BIOS klavyesi", 0
status_line_2 db "Dosya sistemi, ag, coklu gorev ve kalici depolama bulunmaz.", 0
time_line db "RTC saati (HH:MM:SS): 00:00:00", 0
echo_usage db "Kullanim: echo yazmak istediginiz metin", 0
unknown_message db "Bilinmeyen komut. Komut listesi icin help yazin.", 0
command_help db "help", 0
command_about db "about", 0
command_status db "status", 0
command_time db "time", 0
command_clear db "clear", 0
command_reboot db "reboot", 0
command_echo db "echo", 0
