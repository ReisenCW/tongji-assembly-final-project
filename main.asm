; 数据段
section .data
    ; 棋盘数据，初始为 '1'-'9'
    board db '1', '2', '3', '4', '5', '6', '7', '8', '9'
    ; 当前玩家，初始为 'X'
    player db 'X'
    
    ; 提示信息
    ; db: define byte
    ; equ: 类似 #define
    ; $ 符号：表示"当前指令的偏移地址", 常用 "$ - label_name" 来计算字符串长度
    msg_prompt db "Player ", 0 ; 字符串以 null 结尾
    msg_prompt_len equ $ - msg_prompt

    msg_enter db ", enter a number (1-9): ", 0
    msg_enter_len equ $ - msg_enter

    msg_win db "Player ", 0
    msg_win_len equ $ - msg_win

    msg_wins db " wins!", 10, 0
    msg_wins_len equ $ - msg_wins

    msg_draw db "It's a draw!", 10, 0
    msg_draw_len equ $ - msg_draw

    newline db 10 ; 换行符
    space db ' ' ; 空格字符
    
    ; 棋盘绘制字符
    ; 水平分隔符
    row_sep db "---+---+---", 10
    row_sep_len equ $ - row_sep
    ; 垂直分隔符
    col_sep db " | "
    col_sep_len equ $ - col_sep

    ; ANSI Color Codes
    color_red db 0x1B, '[31m'
    color_red_len equ $ - color_red
    color_cyan db 0x1B, '[36m'
    color_cyan_len equ $ - color_cyan
    color_green db 0x1B, '[32m'
    color_green_len equ $ - color_green
    color_reset db 0x1B, '[0m'
    color_reset_len equ $ - color_reset

; 为 "用户输入数据" 预留一块内存缓冲区（不初始化，仅分配空间）
section .bss
    ; 用户输入缓冲区
    input resb 2 ; resb: reserve byte 预留2个字节作为缓冲区

; 代码段
section .text
    global _start

_start:
game_loop:
    ; 打印棋盘
    call print_board

    ; 获取玩家移动
    call get_move

    ; 检查是否获胜
    call check_win
    cmp rax, 1
    je game_over_win
    
    ; 检查是否平局
    call check_draw
    cmp rax, 1
    je game_over_draw
    
    ; 游戏继续, 回合结束切换玩家
    call switch_player
    jmp game_loop

game_over_win:
    call print_board
    ; 胜利处理
    ; 输出胜利信息
    mov rax, 1              ; 64位write系统调用号=1
    mov rdi, 1              ; 文件描述符1=标准输出
    mov rsi, msg_win        ; 字符串地址
    mov rdx, msg_win_len    ; 字符串长度
    syscall
    
    ; 输出当前玩家 'X' 或 'O'
    call set_color_green
    mov rax, 1
    mov rdi, 1
    mov rsi, player         ; 当前玩家 'X' 或 'O'
    mov rdx, 1              ; 长度1
    syscall
    call set_color_reset
    
    ; 输出 " wins!\n"
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_wins
    mov rdx, msg_wins_len
    syscall
    jmp exit

game_over_draw:
    ; 平局处理
    call print_board
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_draw
    mov rdx, msg_draw_len
    syscall
    jmp exit

exit:
    ; 退出程序
    mov rax, 60     ; 64位exit系统调用号=60
    xor rdi, rdi    ; xor: 将rdi清零，表示退出码0
    syscall

print_board:
    ; 打印换行
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; 打印每一行
    call print_row_1
    call print_divider
    call print_row_2
    call print_divider
    call print_row_3
    
    ; 打印换行
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ret

print_space:
    mov rax, 1
    mov rdi, 1
    mov rsi, space
    mov rdx, 1
    syscall
    ret

print_row_1:
    mov rbx, 0
    call print_space
    call print_cell
    call print_vert
    mov rbx, 1
    call print_cell
    call print_vert
    mov rbx, 2
    call print_cell
    call print_nl
    ret

print_row_2:
    mov rbx, 3
    call print_space
    call print_cell
    call print_vert
    mov rbx, 4
    call print_cell
    call print_vert
    mov rbx, 5
    call print_cell
    call print_nl
    ret

print_row_3:
    mov rbx, 6
    call print_space
    call print_cell
    call print_vert
    mov rbx, 7
    call print_cell
    call print_vert
    mov rbx, 8
    call print_cell
    call print_nl
    ret

; 打印单个格子内容
print_cell:
    push rbx
    ; 判断格子内容，设置颜色
    mov al, [board + rbx]
    cmp al, 'X'
    je print_x_color
    cmp al, 'O'
    je print_o_color
    
    ; 普通颜色打印
    mov rax, 1
    mov rdi, 1
    lea rsi, [board + rbx]
    mov rdx, 1
    syscall
    jmp print_cell_done

; 红色打印X
print_x_color:
    call set_color_red
    mov rax, 1
    mov rdi, 1
    lea rsi, [board + rbx]
    mov rdx, 1
    syscall
    call set_color_reset
    jmp print_cell_done
; 青色打印O
print_o_color:
    call set_color_cyan
    mov rax, 1
    mov rdi, 1
    lea rsi, [board + rbx]  ; 字符串地址
    mov rdx, 1              ; 字符串长度
    syscall
    call set_color_reset

print_cell_done:
    pop rbx
    ret

; 打印垂直分隔符
print_vert:
    mov rax, 1
    mov rdi, 1
    mov rsi, col_sep
    mov rdx, col_sep_len
    syscall
    ret

; 打印水平分隔符
print_divider:
    mov rax, 1
    mov rdi, 1
    mov rsi, row_sep
    mov rdx, row_sep_len
    syscall
    ret

; 打印换行符
print_nl:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ret

; 获取玩家输入并更新棋盘
get_move:
    ; 提示输入
    ; 输出 "Player "
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_prompt
    mov rdx, msg_prompt_len
    syscall
    
    ; 输出当前玩家 'X' 或 'O'
    call set_color_green
    mov rax, 1
    mov rdi, 1
    mov rsi, player
    mov rdx, 1
    syscall
    call set_color_reset
    
    ; 输出 ", enter a number (1-9): "
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_enter
    mov rdx, msg_enter_len
    syscall

    ; 读取输入
    mov rax, 0      ; 64位read系统调用号=0
    mov rdi, 0      ; 文件描述符0=标准输入
    mov rsi, input  ; 输入缓冲区地址
    mov rdx, 2      ; 读取2个字节
    syscall
    
    ; 验证输入范围 '1'-'9'
    mov al, [input] ; 读取第一个字节
    sub al, '1'     ; 转换为0-8范围
     ; 检查是否在0-8范围内
     ; 如果小于0或大于8，重新获取输入
     ; jl: jump if less, jg: jump if greater
    cmp al, 0
    jl get_move
    cmp al, 8
    jg get_move
    
    ; 检查位置是否被占用
    movzx rbx, al           ; 扩展为64位索引
    mov cl, [board + rbx]   ; 读取对应格子内容
    cmp cl, 'X'             ; 检查是否为 'X'
    je get_move             ; 已被占用，重新输入
    cmp cl, 'O'             ; 检查是否为 'O'
    je get_move             ; 已被占用，重新输入
    
    ; 将当前玩家符号写入棋盘
    mov dl, [player]
    mov [board + rbx], dl
    ret

switch_player:
    ; 切换 'X' 和 'O'
    mov al, [player]
    cmp al, 'X'
    je set_o
    mov byte [player], 'X'
    ret
set_o:
    mov byte [player], 'O'
    ret

check_win:
    ; 检查行、列、对角线
    call check_rows
    cmp rax, 1
    je win_found
    call check_cols
    cmp rax, 1
    je win_found
    call check_diags
    cmp rax, 1
    je win_found
    mov rax, 0
    ret
win_found:
    mov rax, 1
    ret

check_rows:
    mov al, [board]
    cmp al, [board+1]
    jne row2
    cmp al, [board+2]
    jne row2
    mov rax, 1
    ret
row2:
    mov al, [board+3]
    cmp al, [board+4]
    jne row3
    cmp al, [board+5]
    jne row3
    mov rax, 1
    ret
row3:
    mov al, [board+6]
    cmp al, [board+7]
    jne no_row
    cmp al, [board+8]
    jne no_row
    mov rax, 1
    ret
no_row:
    mov rax, 0
    ret

check_cols:
    mov al, [board]
    cmp al, [board+3]
    jne col2
    cmp al, [board+6]
    jne col2
    mov rax, 1
    ret
col2:
    mov al, [board+1]
    cmp al, [board+4]
    jne col3
    cmp al, [board+7]
    jne col3
    mov rax, 1
    ret
col3:
    mov al, [board+2]
    cmp al, [board+5]
    jne no_col
    cmp al, [board+8]
    jne no_col
    mov rax, 1
    ret
no_col:
    mov rax, 0
    ret

check_diags:
    mov al, [board]
    cmp al, [board+4]
    jne diag2
    cmp al, [board+8]
    jne diag2
    mov rax, 1
    ret
diag2:
    mov al, [board+2]
    cmp al, [board+4]
    jne no_diag
    cmp al, [board+6]
    jne no_diag
    mov rax, 1
    ret
no_diag:
    mov rax, 0
    ret

check_draw:
    ; 检查是否所有格子都已填满
    mov rcx, 0              ; 计数索引
check_draw_loop:
    cmp rcx, 9              ; 检查是否遍历完所有格子
    je draw_found           ; 全部格子已检查，且无空位，平局
    mov al, [board + rcx]   ; 读取当前格子内容
     ; 如果发现数字（未被占用），则不是平局
    cmp al, 'X'
    je next_cell
    cmp al, 'O'
    je next_cell
    mov rax, 0 ; 发现空位（数字），未平局
    ret
next_cell:
    inc rcx                 ; 检查下一个格子
    jmp check_draw_loop
draw_found:
    mov rax, 1
    ret

set_color_red:
    mov rax, 1
    mov rdi, 1
    mov rsi, color_red
    mov rdx, color_red_len
    syscall
    ret

set_color_cyan:
    mov rax, 1
    mov rdi, 1
    mov rsi, color_cyan
    mov rdx, color_cyan_len
    syscall
    ret

set_color_green:
    mov rax, 1
    mov rdi, 1
    mov rsi, color_green
    mov rdx, color_green_len
    syscall
    ret

set_color_reset:
    mov rax, 1
    mov rdi, 1
    mov rsi, color_reset
    mov rdx, color_reset_len
    syscall
    ret
