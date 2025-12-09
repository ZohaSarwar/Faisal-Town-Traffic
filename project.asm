[org 0x0100]         

jmp start



; ==================== DATA SECTION ====================

; Color definitions for VGA mode 13h (256 colors)
COLOR_BLACK           equ 0
COLOR_BLUE            equ 1
COLOR_GREEN           equ 2
COLOR_RED             equ 4
COLOR_DARK_BROWN      equ 6    
COLOR_PINK            equ 86     
COLOR_GRAY            equ 8
COLOR_YELLOW          equ 14
COLOR_WHITE           equ 15

; Screen dimensions
SCREEN_WIDTH    equ 320
SCREEN_HEIGHT   equ 200

; Road parameters
ROAD_LEFT       equ 70        ; Left edge of road 
ROAD_RIGHT      equ 250       ; Right edge of road 
ROAD_CENTER     equ 160       ; Center of screen/road
LANE_WIDTH      equ 60        ; Width of each lane
LANE1_CENTER    equ 100       ; Left lane center
LANE2_CENTER    equ 160       ; Middle lane center
LANE3_CENTER    equ 220       ; Right lane center

; Car dimensions 
CAR_WIDTH       equ 24   
CAR_HEIGHT      equ 40    

; Player car position
PLAYER_X        equ 151     
PLAYER_Y        equ 160    

; Tree parameters
TREE_TRUNK_WIDTH   equ 6
TREE_TRUNK_HEIGHT  equ 15
TREE_LEAVES_WIDTH  equ 20
TREE_LEAVES_HEIGHT equ 25

; Title string
title_text:      db 'FAISAL TOWN TRAFFIC', 0



; ==================== CODE SECTION ====================

start:
    ; Set video mode to 13h (320x200, 256 colors)
    mov ax, 0x0013
    int 0x10

    ; Set ES to video memory segment
    mov ax, 0xA000
    mov es, ax

    ; Draw the game screen
    call draw_background     ; 1. Green grass
    call draw_road           ; 2. Gray road
    call draw_road_borders   ; 3. Yellow and black striped borders
    call draw_lane_dividers  ; 4. White dashed lane dividers (2 lines)
    call draw_trees          ; 5. Cherry blossom trees
    call draw_title_bar      ; 6. Centered title bar
    call draw_obstacle_cars  ; 7. One random blue obstacle car
    call draw_player_car     ; 8. Red player car

    ; Wait for keypress
    xor ah, ah
    int 0x16

    ; Restore text mode (mode 03h)
    mov ax, 0x0003
    int 0x10

    ; Exit to DOS
    mov ax, 0x4C00
    int 0x21



; ==================== DRAWING ROUTINES ====================

; Draw green grass background - fill entire screen
draw_background:
    push ax
    push cx
    push di

    xor di, di                ; Start at offset 0
    mov cx, 64000             ; 320 * 200 = 64000 pixels
    mov al, COLOR_GREEN       ; Green color

.fill_loop:
    mov byte [es:di], al
    inc di
    loop .fill_loop

    pop di
    pop cx
    pop ax
    ret


; Draw gray road in the center
draw_road:
    push ax
    push bx
    push cx
    push dx

    mov dx, 0                 ; Start Y = 0
.loop_y:
    mov cx, ROAD_LEFT         ; Start at left edge of road
.loop_x:
    mov al, COLOR_GRAY        ; Gray color for road
    call put_pixel
    
    inc cx
    cmp cx, ROAD_RIGHT
    jl .loop_x
    
    inc dx
    cmp dx, SCREEN_HEIGHT
    jl .loop_y

    pop dx
    pop cx
    pop bx
    pop ax
    ret


; Draw yellow and black striped borders on both sides of the road
draw_road_borders:
    push ax
    push bx
    push cx
    push dx
    push si

    ; Left border (4 pixels wide) with alternating stripes
    mov dx, 0                 ; Start Y
.left_y_loop:
    ; Determine stripe color (alternate every 5 pixels)
    mov ax, dx
    mov si, 5                ; Stripe height
    push dx
    xor dx, dx
    div si                    ; AX = stripe number, DX = remainder
    pop dx
    test ax, 1                ; Check if odd or even stripe
    jz .left_yellow
    mov al, COLOR_BLACK       ; Odd stripe = black
    jmp .left_draw
.left_yellow:
    mov al, COLOR_YELLOW      ; Even stripe = yellow
.left_draw:
    mov cx, ROAD_LEFT         ; Start X
    mov bx, 4                 ; Border width
.left_x_loop:
    call put_pixel
    inc cx
    dec bx
    jnz .left_x_loop
    
    inc dx
    cmp dx, SCREEN_HEIGHT
    jl .left_y_loop

    ; Right border (4 pixels wide) with alternating stripes
    mov dx, 0                 ; Start Y
.right_y_loop:
    ; Determine stripe color (alternate every 5 pixels)
    mov ax, dx
    mov si, 5                ; Stripe height
    push dx
    xor dx, dx
    div si                    ; AX = stripe number, DX = remainder
    pop dx
    test ax, 1                ; Check if odd or even stripe
    jz .right_yellow
    mov al, COLOR_BLACK       ; Odd stripe = black
    jmp .right_draw
.right_yellow:
    mov al, COLOR_YELLOW      ; Even stripe = yellow
.right_draw:
    mov cx, ROAD_RIGHT        ; Start X
    mov bx, 4                 ; Border width
.right_x_loop:
    call put_pixel
    inc cx
    dec bx
    jnz .right_x_loop
    
    inc dx
    cmp dx, SCREEN_HEIGHT
    jl .right_y_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; Draw two dashed white lane divider lines (between 3 lanes)
draw_lane_dividers:
    push ax
    push bx
    push cx
    push dx

    ; First divider line (between left and middle lane)
    mov cx, 130               ; X position for first divider
    mov dx, 0                 ; Start Y = 0

.loop1:
    cmp dx, SCREEN_HEIGHT
    jge .second_line

    ; Draw dash (10 pixels)
    mov bx, 10
.draw_dash1:
    cmp dx, SCREEN_HEIGHT
    jge .second_line
    mov al, COLOR_WHITE
    call put_pixel
    inc dx
    dec bx
    jnz .draw_dash1

    ; Skip gap (10 pixels)
    add dx, 10
    jmp .loop1

.second_line:
    ; Second divider line (between middle and right lane)
    mov cx, 190               ; X position for second divider
    mov dx, 0                 ; Start Y = 0

.loop2:
    cmp dx, SCREEN_HEIGHT
    jge .done

    ; Draw dash (10 pixels)
    mov bx, 10
.draw_dash2:
    cmp dx, SCREEN_HEIGHT
    jge .done
    mov al, COLOR_WHITE
    call put_pixel
    inc dx
    dec bx
    jnz .draw_dash2

    ; Skip gap (10 pixels)
    add dx, 10
    jmp .loop2

.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; Draw trees on both sides of the road 
draw_trees:
    push ax
    push bx
    push cx
    push dx

    xor ah, ah
    int 0x1A                  ; CX:DX = tick count
    
    ; Left side trees
    ; Tree 1 - Top
    mov bx, 30                ; X position
    mov ax, dx
    and ax, 0x000F            ; Small random offset
    add ax, 30                ; Y position around 30-45
    mov dx, ax
    call draw_pixel_tree
    
    ; Tree 2 - Middle
    mov bx, 35
    mov ax, cx
    and ax, 0x000F
    add ax, 85                ; Y position around 85-100
    mov dx, ax
    call draw_pixel_tree
    
    ; Tree 3 - Bottom
    mov bx, 25
    xor ah, ah
    int 0x1A
    mov ax, dx
    and ax, 0x000F
    add ax, 140               ; Y position around 140-155
    mov dx, ax
    call draw_pixel_tree

    ; Right side trees 
    ; Tree 4 - Top
    mov bx, 275
    mov ax, cx
    and ax, 0x000F
    add ax, 35                ; Y position around 35-50
    mov dx, ax
    call draw_pixel_tree
    
    ; Tree 5 - Middle
    mov bx, 280
    xor ah, ah
    int 0x1A
    mov ax, dx
    and ax, 0x000F
    add ax, 90                ; Y position around 90-105
    mov dx, ax
    call draw_pixel_tree
    
    ; Tree 6 - Bottom
    mov bx, 270
    mov ax, cx
    add ax, dx
    and ax, 0x000F
    add ax, 145               ; Y position around 145-160
    mov dx, ax
    call draw_pixel_tree

    pop dx
    pop cx
    pop bx
    pop ax
    ret


; Draw a pixelated cherry blossom tree at position BX (X), DX (Y)
draw_pixel_tree:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, bx                ; Save center X
    mov di, dx                ; Save top Y

    ; Draw tree crown
    ; Row 1 (top) - 1 block wide (4 pixels)
    mov dx, di
    mov cx, si
    sub cx, 2
    mov bx, 4
.row1:
    push cx
    mov al, COLOR_PINK
    call put_pixel
    pop cx
    inc cx
    dec bx
    jnz .row1

    ; Rows 2-3 - 3 blocks wide (12 pixels)
    add di, 4
    mov dx, di
    mov bx, 8                 ; 2 rows * 4 pixels
.row2_3:
    push bx
    mov cx, si
    sub cx, 6
    mov bx, 12
.row2_3_pix:
    push cx
    mov al, COLOR_PINK
    call put_pixel
    pop cx
    inc cx
    dec bx
    jnz .row2_3_pix
    inc dx
    pop bx
    dec bx
    jnz .row2_3

    ; Rows 4-6 - 5 blocks wide (20 pixels)
    mov dx, di
    add dx, 8
    mov bx, 12                ; 3 rows * 4 pixels
.row4_6:
    push bx
    mov cx, si
    sub cx, 10
    mov bx, 20
.row4_6_pix:
    push cx
    mov al, COLOR_PINK
    call put_pixel
    pop cx
    inc cx
    dec bx
    jnz .row4_6_pix
    inc dx
    pop bx
    dec bx
    jnz .row4_6

    ; Rows 7-9 - 7 blocks wide (28 pixels) 
    mov dx, di
    add dx, 20
    mov bx, 12
.row7_9:
    push bx
    mov cx, si
    sub cx, 14
    mov bx, 28
.row7_9_pix:
    push cx
    mov al, COLOR_PINK
    call put_pixel
    pop cx
    inc cx
    dec bx
    jnz .row7_9_pix
    inc dx
    pop bx
    dec bx
    jnz .row7_9

    ; Bottom notch (where trunk connects)
    ; Left notch
    mov dx, di
    add dx, 32
    mov cx, si
    sub cx, 14
    mov bx, 8
.notch_left:
    push cx
    mov al, COLOR_PINK
    call put_pixel
    pop cx
    inc cx
    dec bx
    jnz .notch_left

    ; Right notch
    mov cx, si
    add cx, 6
    mov bx, 8
.notch_right:
    push cx
    mov al, COLOR_PINK
    call put_pixel
    pop cx
    inc cx
    dec bx
    jnz .notch_right

    ; Draw trunk (brown) - simple straight rectangle
    mov dx, di
    add dx, 32                ; Start trunk below leaves
    mov bx, 16                ; 16 rows for trunk height
.trunk_row:
    push bx
    mov cx, si
    sub cx, 3                 ; 6 pixels wide trunk
    mov bx, 6
.trunk_col:
    push cx
    mov al, COLOR_DARK_BROWN
    call put_pixel
    pop cx
    inc cx
    dec bx
    jnz .trunk_col
    inc dx
    pop bx
    dec bx
    jnz .trunk_row

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; Draw title bar at top with text "FAISAL TOWN TRAFFIC"
draw_title_bar:
    push ax
    push bx
    push cx
    push dx
    push bp
    push es

    ; Draw the title bar background 
    push es
    mov ax, 0xA000
    mov es, ax
    mov dx, 0                 ; Start Y = 0
.bar_loop_y:
    mov cx, 0                 ; Start X = 0
.bar_loop_x:
    mov al, COLOR_BLACK       ; Black background
    call put_pixel
    inc cx
    cmp cx, SCREEN_WIDTH
    jl .bar_loop_x
    inc dx
    cmp dx, 20                ; Title bar height = 20 pixels
    jl .bar_loop_y
    pop es

    ; Display text using BIOS interrupt 10h, function 13h
    
    mov ah, 0x13              ; Write string function
    mov al, 0x01               
                              
    mov bh, 0                
    mov bl, 0x0F              ; white text on black
    mov cx, 19                ; String length
    mov dh, 1                 ; Row 
    mov dl, 11                ; Column
    
    push cs
    pop es
    mov bp, title_text        ; ES:BP points to string
    
    int 0x10                  ; Call BIOS

    pop es
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; Draw red player car
draw_player_car:
    push ax
    push bx
    push cx
    push dx
    push si

    mov bx, PLAYER_X
    mov si, PLAYER_Y          ; Save starting Y in SI
    mov dx, PLAYER_Y
    
    ; Row 0 - slim top (12 pixels)
    mov cx, 12
    push bx
    add bx, 3
.row0:
    push cx
    mov cx, bx
    mov al, COLOR_RED
    call put_pixel
    pop cx
    inc bx
    loop .row0
    pop bx
    inc dx

    ; Rows 1-2 - medium (14 pixels)
    mov di, 2
.rows1_2:
    push di
    mov cx, 14
    push bx
    add bx, 2
.row1_2_col:
    push cx
    mov cx, bx
    mov al, COLOR_RED
    call put_pixel
    pop cx
    inc bx
    loop .row1_2_col
    pop bx
    inc dx
    pop di
    dec di
    jnz .rows1_2

    ; Rows 3-4 - full width (18 pixels)
    mov di, 2
.rows3_4:
    push di
    mov cx, 18
    push bx
.row3_4_col:
    push cx
    mov cx, bx
    mov al, COLOR_RED
    call put_pixel
    pop cx
    inc bx
    loop .row3_4_col
    pop bx
    inc dx
    pop di
    dec di
    jnz .rows3_4

    ; Rows 5-8 - windshield area (body with window)
    mov di, 4
.rows5_8:
    push di
    mov cx, 18
    push bx
.row5_8_col:
    push cx
    mov cx, bx
    push bx
    sub bx, PLAYER_X          
    cmp bx, 3
    jl .red_pixel
    cmp bx, 15
    jge .red_pixel
    mov al, COLOR_BLACK       ; Window
    jmp .draw_pix
.red_pixel:
    mov al, COLOR_RED
.draw_pix:
    pop bx
    call put_pixel
    pop cx
    inc bx
    loop .row5_8_col
    pop bx
    inc dx
    pop di
    dec di
    jnz .rows5_8

    ; Rows 9-23 - full body (18 pixels)
    mov di, 15
.rows9_23:
    push di
    mov cx, 18
    push bx
.row9_23_col:
    push cx
    mov cx, bx
    mov al, COLOR_RED
    call put_pixel
    pop cx
    inc bx
    loop .row9_23_col
    pop bx
    inc dx
    pop di
    dec di
    jnz .rows9_23

    ; Rows 24-27 - body with tires (18 pixels)
    mov di, 4
.rows24_27:
    push di
    mov cx, 18
    push bx
.row24_27_col:
    push cx
    mov cx, bx
    push bx
    sub bx, PLAYER_X
    cmp bx, 4
    jge .check_right
    mov al, COLOR_BLACK       ; Left tire
    jmp .draw_tire
.check_right:
    cmp bx, 14
    jl .red_tire
    mov al, COLOR_BLACK       ; Right tire
    jmp .draw_tire
.red_tire:
    mov al, COLOR_RED
.draw_tire:
    pop bx
    call put_pixel
    pop cx
    inc bx
    loop .row24_27_col
    pop bx
    inc dx
    pop di
    dec di
    jnz .rows24_27

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; Draw random blue obstacle car 
draw_obstacle_cars:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; Get random position
    xor ah, ah
    int 0x1A
    
    ; Random X (80-220)
    mov ax, dx
    xor dx, dx
    mov bx, 140
    div bx
    add dx, 80
    mov si, dx                ; SI = car X position
    
    ; Random Y (30-110)
    mov ax, cx
    xor dx, dx
    mov cx, 80
    div cx
    add dx, 30
    mov di, dx                ; DI = car starting Y
    
    ; Draw car - simplified row by row
    mov bx, si                ; X position
    mov dx, di                ; Y position
    
    ; Row 0 - slim top (12 pixels)
    mov cx, 12
    push bx
    add bx, 3
.row0:
    push cx
    mov cx, bx
    mov al, COLOR_BLUE
    call put_pixel
    pop cx
    inc bx
    loop .row0
    pop bx
    inc dx

    ; Rows 1-2 - medium (14 pixels)
    mov ax, 2
.rows1_2:
    push ax
    mov cx, 14
    push bx
    add bx, 2
.row1_2_col:
    push cx
    mov cx, bx
    mov al, COLOR_BLUE
    call put_pixel
    pop cx
    inc bx
    loop .row1_2_col
    pop bx
    inc dx
    pop ax
    dec ax
    jnz .rows1_2

    ; Rows 3-4 - full width (18 pixels)
    mov ax, 2
.rows3_4:
    push ax
    mov cx, 18
    push bx
.row3_4_col:
    push cx
    mov cx, bx
    mov al, COLOR_BLUE
    call put_pixel
    pop cx
    inc bx
    loop .row3_4_col
    pop bx
    inc dx
    pop ax
    dec ax
    jnz .rows3_4

    ; Rows 5-8 - windshield area
    mov ax, 4
.rows5_8:
    push ax
    mov cx, 18
    push bx
.row5_8_col:
    push cx
    push bx
    sub bx, si
    cmp bx, 3
    jl .blue1
    cmp bx, 15
    jge .blue1
    mov al, COLOR_BLACK
    jmp .draw1
.blue1:
    mov al, COLOR_BLUE
.draw1:
    pop bx
    mov cx, bx
    call put_pixel
    pop cx
    inc bx
    loop .row5_8_col
    pop bx
    inc dx
    pop ax
    dec ax
    jnz .rows5_8

    ; Rows 9-23 - full body
    mov ax, 15
.rows9_23:
    push ax
    mov cx, 18
    push bx
.row9_23_col:
    push cx
    mov cx, bx
    mov al, COLOR_BLUE
    call put_pixel
    pop cx
    inc bx
    loop .row9_23_col
    pop bx
    inc dx
    pop ax
    dec ax
    jnz .rows9_23

    ; Rows 24-27 - with tires
    mov ax, 4
.rows24_27:
    push ax
    mov cx, 18
    push bx
.row24_27_col:
    push cx
    push bx
    sub bx, si
    cmp bx, 4
    jge .check_right2
    mov al, COLOR_BLACK
    jmp .draw2
.check_right2:
    cmp bx, 14
    jl .blue2
    mov al, COLOR_BLACK
    jmp .draw2
.blue2:
    mov al, COLOR_BLUE
.draw2:
    pop bx
    mov cx, bx
    call put_pixel
    pop cx
    inc bx
    loop .row24_27_col
    pop bx
    inc dx
    pop ax
    dec ax
    jnz .rows24_27

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



; ==================== UTILITY ROUTINES ====================

; Pixel at (CX, DX) with color AL
; Video memory at A000:0000, offset = Y * 320 + X
put_pixel:
    push ax
    push bx
    push cx
    push dx
    push di

    ; Check bounds
    cmp cx, SCREEN_WIDTH
    jge .skip
    cmp dx, SCREEN_HEIGHT
    jge .skip

    ; Calculate offset: DI = DX * 320 + CX
    push ax
    mov ax, dx
    mov bx, SCREEN_WIDTH
    mul bx                    ; AX = DX * 320
    add ax, cx                ; AX = Y * 320 + X
    mov di, ax
    pop ax

    ; Write pixel 
    mov byte [es:di], al

.skip:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
