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
COLOR_ORANGE          equ 65

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

; Animation variables
spawn_timer     dw 0          ; Timer for spawning obstacles

; Obstacle cars (up to 3 active)
obstacle_count  db 0
obstacle_x      times 3 dw 0  ; X positions
obstacle_y      times 3 dw 0  ; Y positions
obstacle_old_y  times 3 dw 0  ; Previous Y positions for clearing
obstacle_active times 3 db 0  ; Active flags

; Coin management (up to 5 active)
coin_count      db 0
coin_x          times 5 dw 0  ; X positions
coin_y          times 5 dw 0  ; Y positions
coin_old_y      times 5 dw 0  ; Previous Y positions for clearing
coin_active     times 5 db 0  ; Active flags
coin_timer      dw 0          ; Timer for spawning coins

; Road management
lane_offset       dw 0
border_offset     dw 0

; Title strings
title_text:     db 'Score:    FAISAL TOWN TRAFFIC  Fuel:  ', 0
fuel:           dw 3
score:          dw 0




; ==================== CODE SECTION ====================

start:
    ; Set video mode to 13h (320x200, 256 colors)
    mov ax, 0x0013
    int 0x10

    ; Set ES to video memory segment
    mov ax, 0xA000
    mov es, ax

    ; Draw initial STATIC frame 
    call draw_background     ; 1. Green grass
    call draw_road           ; 2. Gray road
    call draw_road_borders   ; 3. Yellow and black striped borders
    call draw_lane_dividers  ; 4. White dashed lane dividers (2 lines)
    call draw_trees          ; 5. Cherry blossom trees
    call draw_title_bar      ; 6. Centered title bar
    call draw_player_car     ; 8. Red player car

    ; Initialize obstacles and coins
    mov byte [obstacle_count], 0
    mov byte [coin_count], 0
    mov word [spawn_timer], 0
    mov word [coin_timer], 0




; ==================== MAIN ANIMATION LOOP ====================

animation_loop:
    ; Check for ESC key to exit
    mov ah, 0x01
    int 0x16
    jz .no_key_pressed
    
    mov ah, 0x00
    int 0x16
    cmp al, 27               ; ESC key?
    je exit_program
    
.no_key_pressed:
    
    call clear_old_obstacles
    call clear_old_coins
   
    call update_obstacles
    call update_coins

    add word [lane_offset], 3
    cmp word [lane_offset], 20
    jl .no_lane_reset
    sub word [lane_offset], 20
.no_lane_reset:

    ; Same offset for borders to keep them in sync
    mov ax, [lane_offset]
    mov [border_offset], ax

    call draw_lane_dividers
    call draw_road_borders
    call draw_obstacles
    call draw_coins
    
    call draw_player_car

    call check_collisions
    call update_title_numbers
    
    call check_spawn_obstacle
    call check_spawn_coin
    
    inc word [spawn_timer]
    inc word [coin_timer]
    
    call animation_delay    
    jmp animation_loop

exit_program:
    mov ax, 0x0003
    int 0x10
    mov ax, 0x4C00
    int 0x21




; ==================== DRAWING ROUTINES ====================

; ----- DRAW GREEN CRASS BG - fill entire screen -----
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



; ----- DRAW GRAY ROAD IN CENTER -----
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



; ----- DRAW YELLOW AND BLACK STRIPED ROAD BORDERS ON BOTH SIDES OF ROAD -----
draw_road_borders:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, [border_offset]

    ; Left border
    mov bx, ROAD_LEFT
    call .draw_border

    ; Right border
    mov bx, ROAD_RIGHT
    call .draw_border

    jmp .done

.draw_border:
    push bx
    push si

    mov dx, 0                 ; Start from Y=0 (top of screen)
.row:
    cmp dx, SCREEN_HEIGHT
    jge .end_border
    
    ; Skip title bar area
    cmp dx, 20
    jl .skip_row
    
    ; Calculate pattern position with offset 
    mov ax, dx
    sub ax, 20                ; Adjust for title bar
    sub ax, si                ; Subtract scroll offset for upward movement
    
    ; Handle negative values by adding pattern size until positive
.make_positive:
    cmp ax, 0
    jge .is_positive
    add ax, 20                ; Add pattern size 
    jmp .make_positive
    
.is_positive:
    ; Get stripe index (pattern repeats every 20 pixels, alternating every 10)
    push dx
    mov di, ax                ; Save the calculated position
    xor dx, dx
    mov cx, 20
    div cx                    ; AX = quotient, DX = remainder
    mov ax, dx                ; AX now has the remainder
    pop dx
    
    ; Determine color based on remainder (alternating stripes every 10 pixels)
    cmp ax, 10
    jge .black_stripe
    mov al, COLOR_YELLOW
    jmp .draw_stripe
.black_stripe:
    mov al, COLOR_BLACK

.draw_stripe:
    ; Draw 4 pixels wide
    mov cx, bx
    push dx
    mov di, 4
.pixel_loop:
    call put_pixel
    inc cx
    dec di
    jnz .pixel_loop
    pop dx

.skip_row:
    inc dx
    jmp .row

.end_border:
    pop si
    pop bx
    ret

.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



; ----- DRAW TWO DASHED WHITE LANE DIVIDER LINES (between 3 lanes) -----
draw_lane_dividers:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, [lane_offset]

    ; First divider at X = 130
    mov bx, 130
    call .draw_divider

    ; Second divider at X = 190
    mov bx, 190
    call .draw_divider

    jmp .done

.draw_divider:
    push bx
    push si

    mov dx, 20                ; Start from Y=20 (below title bar)
.row:
    cmp dx, SCREEN_HEIGHT
    jge .end_divider
    
    ; Calculate pattern position with offset
    mov ax, dx
    sub ax, 20                ; Adjust for title bar
    sub ax, si                ; Subtract scroll offset for upward movement
    
    ; Handle negative values by adding pattern size until positive
.make_positive:
    cmp ax, 0
    jge .is_positive
    add ax, 20                ; Add pattern size (20 pixels)
    jmp .make_positive
    
.is_positive:
    ; Get remainder for dash pattern (20 pixels cycle: 10 white, 10 gray)
    push dx
    mov di, ax                ; Save original value
    xor dx, dx
    mov cx, 20
    div cx                    ; AX = quotient, DX = remainder
    mov ax, dx                ; AX now has the remainder
    pop dx
    
    ; Draw either white or gray based on pattern
    cmp ax, 10
    jge .draw_gray
    
    ; Draw white
    push ax
    mov al, COLOR_WHITE
    mov cx, bx
    call put_pixel
    pop ax
    jmp .skip_pixel

.draw_gray:
    ; Draw gray
    push ax
    mov al, COLOR_GRAY
    mov cx, bx
    call put_pixel
    pop ax

.skip_pixel:
    inc dx
    jmp .row

.end_divider:
    pop si
    pop bx
    ret

.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



; ----- DRAW TREES on both sides of road -----
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



; ----- DRAW CHERRY BLOSSOM TREE at position BX (X), DX (Y) -----
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



; ----- DRAW TITLE BAR AT TOP WITH VALUES ----- 
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

    ; Display main title text
    mov ah, 0x13              ; Write string function
    mov al, 0x01               
    mov bh, 0                
    mov bl, 0x0F              ; white text on black
    mov cx, 38                ; String length
    mov dh, 1                 ; Row 
    mov dl, 1                 ; Column
    
    push cs
    pop es
    mov bp, title_text        ; ES:BP points to string
    int 0x10                  ; Call BIOS

    ; Display score value
    mov ah, 0x02              ; Set cursor position
    mov bh, 0                 ; Page 0
    mov dh, 1                 ; Row 1
    mov dl, 7                 ; Column 7 (after "Score: ")
    int 0x10

    mov ax, [score]           ; Get score value
    call print_number         ; Print the number

    ; Display fuel value
    mov ah, 0x02              ; Set cursor position
    mov bh, 0                 ; Page 0
    mov dh, 1                 ; Row 1
    mov dl, 37                ; Column 37 (after "Fuel: ")
    int 0x10

    mov ax, [fuel]            ; Get fuel value
    call print_number         ; Print the number

    pop es
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret




; ==================== CLEARING ROUTINES ====================

; ----- Clear obstacle cars at their OLD positions -----
clear_old_obstacles:
    push ax
    push bx
    push cx
    push dx
    
    xor bx, bx
.loop:
    cmp bx, 3
    jge near .done
    
    ; Check if active
    cmp byte [obstacle_active + bx], 0
    je near .next
    
    ; Get OLD position
    push bx
    shl bx, 1
    mov ax, [obstacle_x + bx]
    mov dx, [obstacle_old_y + bx]
    shr bx, 1
    
    ; Clear the car at old position
    push bx
    mov bx, ax                ; X position
    call clear_car_area
    pop bx
    
    pop bx
    
.next:
    inc bx
    jmp near .loop
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret



; ----- Clear coins at their OLD positions -----
clear_old_coins:
    push ax
    push bx
    push cx
    push dx
    
    xor bx, bx
.loop:
    cmp bx, 5
    jge near .done
    
    ; Check if active
    cmp byte [coin_active + bx], 0
    je near .next
    
    ; Get OLD position
    push bx
    shl bx, 1
    mov ax, [coin_x + bx]
    mov dx, [coin_old_y + bx]
    shr bx, 1
    
    ; Clear the coin at old position
    push bx
    mov bx, ax
    call clear_coin_area
    pop bx
    
    pop bx
    
.next:
    inc bx
    jmp near .loop
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret



; ----- Clear a car-sized area (18x28) at BX (X), DX (Y) -----
clear_car_area:
    push ax
    push cx
    push dx
    push si
    push di
    
    mov si, bx                ; Save X
    mov di, dx                ; Save Y
    
    ; Skip if completely off-screen
    cmp di, SCREEN_HEIGHT
    jge .done
    cmp di, 0
    jl .done
    
    ; Clear 28 rows
    mov ax, 28
.row_loop:
    push ax
    
    ; Check if this row is visible
    cmp di, 20
    jl .next_row
    cmp di, SCREEN_HEIGHT
    jge .done_pop
    
    ; Clear 18 pixels in this row
    mov cx, si
    mov bx, 18
.col_loop:
    push cx
    push bx
    mov dx, di
    mov al, COLOR_GRAY        ; Road color
    call put_pixel
    pop bx
    pop cx
    inc cx
    dec bx
    jnz .col_loop
    
.next_row:
    inc di
    pop ax
    dec ax
    jnz .row_loop
    jmp .done

.done_pop:
    pop ax
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret



; ----- Clear a coin-sized area at BX (X), DX (Y) -----
clear_coin_area:
    push ax
    push cx
    push dx
    push si
    push di
    
    mov si, bx                ; Save X center
    mov di, dx                ; Save Y center
    sub si, 8                 ; Top-left corner (16/2)
    sub di, 8
    
    ; Skip if completely off-screen
    cmp di, SCREEN_HEIGHT
    jge .done
    cmp di, 0
    jl .done
    
    ; Clear 16 rows
    mov ax, 16
.row_loop:
    push ax
    
    ; Check if this row is visible
    cmp di, 20
    jl .next_row
    cmp di, SCREEN_HEIGHT
    jge .done_pop
    
    ; Clear 16 pixels in this row
    mov cx, si
    mov bx, 16
.col_loop:
    push cx
    push bx
    mov dx, di
    mov al, COLOR_GRAY        ; Road color
    call put_pixel
    pop bx
    pop cx
    inc cx
    dec bx
    jnz .col_loop
    
.next_row:
    inc di
    pop ax
    dec ax
    jnz .row_loop
    jmp .done

.done_pop:
    pop ax
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret




; ==================== COIN MANAGEMENT ====================

; ----- Check if it's time to spawn a new coin -----
check_spawn_coin:
    push ax
    push bx
    push dx
    
    ; Check coin timer (spawn every 35 frames)
    cmp word [coin_timer], 35
    jl near .done
    
    ; Reset timer
    mov word [coin_timer], 0
    
    ; Check if we already have max coins (5)
    cmp byte [coin_count], 5
    jge near .done
    
    ; Find empty slot
    xor bx, bx
.find_slot:
    cmp bx, 5
    jge near .done
    
    cmp byte [coin_active + bx], 0
    je near .spawn_here
    
    inc bx
    jmp near .find_slot
    
.spawn_here:
    ; Get random lane that doesn't have an obstacle OR coin
    call get_free_lane
    cmp al, 0xFF
    je near .done                  ; No free lane
    
    ; Mark as active
    mov byte [coin_active + bx], 1
    inc byte [coin_count]
    
    ; Calculate X position based on lane (al = 0, 1, or 2)
    cmp al, 0
    je near .lane_left
    cmp al, 1
    je near .lane_middle
    ; Lane right
    mov ax, LANE3_CENTER
    jmp near .set_x
.lane_left:
    mov ax, LANE1_CENTER
    jmp near .set_x
.lane_middle:
    mov ax, LANE2_CENTER
    
.set_x:
    ; Coin X position is already the lane center 
    ; Store position
    shl bx, 1
    mov [coin_x + bx], ax           ; Store exact lane center
    mov word [coin_y + bx], 25      ; Start position
    mov word [coin_old_y + bx], 25  ; Initialize old position
    
.done:
    pop dx
    pop bx
    pop ax
    ret



; ----- Get a random lane that doesn't have an obstacle car OR coin in it -----
; Returns: AL = lane number (0-2) or 0xFF if no free lane
get_free_lane:
    push bx
    push cx
    push dx
    
    ; Get random lane
    call get_random_byte
    xor ah, ah
    mov dl, 3
    div dl
    mov al, ah                ; AL = random lane (0-2)
    
    ; Try this lane and next two
    mov cl, 3                 ; Try counter
.try_lane:
    push ax
    call is_lane_free_complete
    pop ax
    
    cmp dl, 1
    je near .found_free
    
    ; Try next lane
    inc al
    cmp al, 3
    jl near .no_wrap
    xor al, al
.no_wrap:
    dec cl
    jnz near .try_lane
    
    ; No free lane found
    mov al, 0xFF
    jmp near .done
    
.found_free:
    ; AL already has the lane number
    
.done:
    pop dx
    pop cx
    pop bx
    ret



; ----- Check if a lane is free from both obstacles AND coins -----
; Input: AL = lane number (0-2)
; Output: DL = 1 if free, 0 if occupied
is_lane_free_complete:
    push ax
    push bx
    push cx
    
    ; Convert lane to X center
    cmp al, 0
    je near .lane0
    cmp al, 1
    je near .lane1
    mov ax, LANE3_CENTER
    jmp near .check
.lane0:
    mov ax, LANE1_CENTER
    jmp near .check
.lane1:
    mov ax, LANE2_CENTER
    
.check:
    mov cx, ax                ; CX = lane center
    
    ; Check all obstacles
    xor bx, bx
.loop_obstacles:
    cmp bx, 3
    jge near .check_coins
    
    ; Check if active
    cmp byte [obstacle_active + bx], 0
    je near .next_obstacle
    
    ; Get obstacle X
    push bx
    shl bx, 1
    mov ax, [obstacle_x + bx]
    
    ; Check Y position (only check if obstacle is near spawn area)
    mov dx, [obstacle_y + bx]
    shr bx, 1
    
    cmp dx, 100               ; Only check if in upper half of screen
    jg near .next_obstacle_pop
    
    ; Check if in same lane (within 30 pixels)
    sub ax, cx
    cmp ax, -30
    jl near .next_obstacle_pop
    cmp ax, 30
    jg near .next_obstacle_pop
    
    ; Obstacle in this lane
    pop bx
    mov dl, 0
    jmp near .done
    
.next_obstacle_pop:
    pop bx
.next_obstacle:
    inc bx
    jmp near .loop_obstacles
    
.check_coins:
    ; Check all coins
    xor bx, bx
.loop_coins:
    cmp bx, 5
    jge near .is_free
    
    ; Check if active
    cmp byte [coin_active + bx], 0
    je near .next_coin
    
    ; Get coin X
    push bx
    shl bx, 1
    mov ax, [coin_x + bx]
    
    ; Check Y position (only check if coin is near spawn area)
    mov dx, [coin_y + bx]
    shr bx, 1
    
    cmp dx, 100               ; Only check if in upper half of screen
    jg near .next_coin_pop
    
    ; Check if in same lane (within 20 pixels for coins)
    sub ax, cx
    cmp ax, -20
    jl near .next_coin_pop
    cmp ax, 20
    jg near .next_coin_pop
    
    ; Coin in this lane
    pop bx
    mov dl, 0
    jmp near .done
    
.next_coin_pop:
    pop bx
.next_coin:
    inc bx
    jmp near .loop_coins
    
.is_free:
    mov dl, 1
    
.done:
    pop cx
    pop bx
    pop ax
    ret




; ----- UPDATE COIN POSITIONS (move them down) -----
update_coins:
    push ax
    push bx
    push cx
    
    xor bx, bx
.loop:
    cmp bx, 5
    jge near .done
    
    ; Check if active
    cmp byte [coin_active + bx], 0
    je near .next
    
    ; Get Y position
    push bx
    shl bx, 1
    
    ; Save old Y
    mov ax, [coin_y + bx]
    mov [coin_old_y + bx], ax
    
    ; Move down by 3 pixels 
    add ax, 3
    
    ; Check if completely off screen (add buffer for coin size)
    cmp ax, SCREEN_HEIGHT + 15
    jl near .keep
    
    ; Deactivate this coin
    shr bx, 1
    mov byte [coin_active + bx], 0
    dec byte [coin_count]
    pop bx
    jmp near .next
    
.keep:
    mov [coin_y + bx], ax
    pop bx
    
.next:
    inc bx
    jmp near .loop
    
.done:
    pop cx
    pop bx
    pop ax
    ret



; ----- DRAW ALL ACTIVE COINS -----
draw_coins:
    push ax
    push bx
    push cx
    push dx
    
    xor bx, bx
.loop:
    cmp bx, 5
    jge near .done
    
    ; Check if active
    cmp byte [coin_active + bx], 0
    je near .next
    
    ; Get position
    push bx
    shl bx, 1
    mov ax, [coin_x + bx]
    mov dx, [coin_y + bx]
    shr bx, 1
    
    ; Draw the coin
    push bx
    mov bx, ax
    call draw_coin
    pop bx
    
    pop bx
    
.next:
    inc bx
    jmp near .loop
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret



; ----- DRAW COIN at BX (X), DX (Y) -----
draw_coin:
    push ax
    push cx
    push dx
    push si
    push di
    
    mov si, bx                ; Save X (center)
    mov di, dx                ; Save Y (center)
    
    ; Check if coin is in title bar area
    cmp di, 25
    jge .start_drawing
    jmp .done_early
    
.start_drawing:
    sub si, 5
    sub di, 5
    
    ; Row 0 - top (4 pixels) - white highlight
    mov cx, si
    add cx, 3
    mov dx, di
    mov bx, 4
.r0:
    cmp dx, 20
    jl near .r0_skip
    push cx
    mov al, COLOR_WHITE
    call put_pixel
    pop cx
.r0_skip:
    inc cx
    dec bx
    jnz near .r0
    inc di

    ; Row 1 - (6 pixels) - white + yellow
    mov cx, si
    add cx, 2
    mov dx, di
    mov bx, 1
.r1_white:
    cmp dx, 20
    jl near .r1w_skip
    push cx
    mov al, COLOR_WHITE
    call put_pixel
    pop cx
.r1w_skip:
    inc cx
    dec bx
    jnz near .r1_white
    
    mov bx, 5
.r1_yellow:
    cmp dx, 20
    jl near .r1y_skip
    push cx
    mov al, COLOR_YELLOW
    call put_pixel
    pop cx
.r1y_skip:
    inc cx
    dec bx
    jnz near .r1_yellow
    inc di

    ; Rows 2-3 - (8 pixels wide) - all yellow
    mov ax, 2
.r2_3:
    push ax
    mov cx, si
    add cx, 1
    mov dx, di
    mov bx, 8
.r2_3_px:
    cmp dx, 20
    jl short .r2_3_skip
    push cx
    mov al, COLOR_YELLOW
    call put_pixel
    pop cx
.r2_3_skip:
    inc cx
    dec bx
    jnz short .r2_3_px
    inc di
    pop ax
    dec ax
    jnz near .r2_3

    ; Rows 4-5 - (8 pixels) - yellow + dark edge
    mov ax, 2
.r4_5:
    push ax
    mov cx, si
    add cx, 1
    mov dx, di
    mov bx, 7
.r4_5_yellow:
    cmp dx, 20
    jl short .r4_5y_skip
    push cx
    mov al, COLOR_YELLOW
    call put_pixel
    pop cx
.r4_5y_skip:
    inc cx
    dec bx
    jnz short .r4_5_yellow
    
    mov bx, 1
.r4_5_dark:
    cmp dx, 20
    jl short .r4_5d_skip
    push cx
    mov al, COLOR_ORANGE
    call put_pixel
    pop cx
.r4_5d_skip:
    inc cx
    dec bx
    jnz short .r4_5_dark
    
    inc di
    pop ax
    dec ax
    jnz near .r4_5

    ; Rows 6-7 - (8 pixels) - yellow + more dark
    mov ax, 2
.r6_7:
    push ax
    mov cx, si
    add cx, 1
    mov dx, di
    mov bx, 5
.r6_7_yellow:
    cmp dx, 20
    jl short .r6_7y_skip
    push cx
    mov al, COLOR_YELLOW
    call put_pixel
    pop cx
.r6_7y_skip:
    inc cx
    dec bx
    jnz short .r6_7_yellow
    
    mov bx, 3
.r6_7_dark:
    cmp dx, 20
    jl short .r6_7d_skip
    push cx
    mov al, COLOR_ORANGE
    call put_pixel
    pop cx
.r6_7d_skip:
    inc cx
    dec bx
    jnz short .r6_7_dark
    
    inc di
    pop ax
    dec ax
    jnz near .r6_7

    ; Row 8 - (6 pixels) - yellow + dark
    mov cx, si
    add cx, 2
    mov dx, di
    mov bx, 3
.r8_yellow:
    cmp dx, 20
    jl near .r8y_skip
    push cx
    mov al, COLOR_YELLOW
    call put_pixel
    pop cx
.r8y_skip:
    inc cx
    dec bx
    jnz near .r8_yellow
    
    mov bx, 3
.r8_dark:
    cmp dx, 20
    jl near .r8d_skip
    push cx
    mov al, COLOR_ORANGE
    call put_pixel
    pop cx
.r8d_skip:
    inc cx
    dec bx
    jnz near .r8_dark
    inc di

    ; Row 9 - bottom (4 pixels) - dark shadow
    mov cx, si
    add cx, 3
    mov dx, di
    mov bx, 4
.r9:
    cmp dx, 20
    jl near .r9_skip
    push cx
    mov al, COLOR_ORANGE
    call put_pixel
    pop cx
.r9_skip:
    inc cx
    dec bx
    jnz near .r9

.done_early:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret




; ==================== OBSTACLE MANAGEMENT ====================

; ----- Check if it's time to spawn a new obstacle -----
check_spawn_obstacle:
    push ax
    push bx
    push dx
    
    ; Check spawn timer (spawn every 50 frames)
    cmp word [spawn_timer], 50
    jl near .done
    
    ; Reset timer
    mov word [spawn_timer], 0
    
    ; Check if we already have max obstacles (3)
    cmp byte [obstacle_count], 3
    jge near .done
    
    ; Find empty slot
    xor bx, bx
.find_slot:
    cmp bx, 3
    jge near .done
    
    cmp byte [obstacle_active + bx], 0
    je near .spawn_here
    
    inc bx
    jmp near .find_slot
    
.spawn_here:
    ; Get random lane that doesn't have an obstacle OR coin
    call get_free_lane
    cmp al, 0xFF
    je near .done                  ; No free lane
    
    ; Mark as active
    mov byte [obstacle_active + bx], 1
    inc byte [obstacle_count]
    
    ; Calculate X position based on lane
    cmp al, 0
    je near .lane_left
    cmp al, 1
    je near .lane_middle
    ; Lane right
    mov ax, LANE3_CENTER
    jmp near .set_x
.lane_left:
    mov ax, LANE1_CENTER
    jmp near .set_x
.lane_middle:
    mov ax, LANE2_CENTER
    
.set_x:
    ; Center the car in lane
    sub ax, 9                 ; Half of car width
    
    ; Store position
    shl bx, 1                           ; BX * 2 for word array
    mov [obstacle_x + bx], ax
    mov word [obstacle_y + bx], 25      ; Start position
    mov word [obstacle_old_y + bx], 25  ; Initialize old position
    
.done:
    pop dx
    pop bx
    pop ax
    ret



; ------ UPDATE OBSTACLE POSITIONS (move them down) -----
update_obstacles:
    push ax
    push bx
    push cx
    
    xor bx, bx
.loop:
    cmp bx, 3
    jge near .done
    
    ; Check if active
    cmp byte [obstacle_active + bx], 0
    je near .next
    
    ; Get Y position
    push bx
    shl bx, 1
    
    ; Save old Y
    mov ax, [obstacle_y + bx]
    mov [obstacle_old_y + bx], ax
    
    ; Move down by 3 pixels
    add ax, 3
    
    ; Check if off screen
    cmp ax, SCREEN_HEIGHT
    jl near .keep
    
    ; Deactivate this obstacle
    shr bx, 1
    mov byte [obstacle_active + bx], 0
    dec byte [obstacle_count]
    pop bx
    jmp near .next
    
.keep:
    mov [obstacle_y + bx], ax
    pop bx
    
.next:
    inc bx
    jmp near .loop
    
.done:
    pop cx
    pop bx
    pop ax
    ret



; ----- DRAW ALL ACTIVE OBSTACLES -----
draw_obstacles:
    push ax
    push bx
    push cx
    push dx
    
    xor bx, bx
.loop:
    cmp bx, 3
    jge near .done
    
    ; Check if active
    cmp byte [obstacle_active + bx], 0
    je near .next
    
    ; Get position
    push bx
    shl bx, 1
    mov ax, [obstacle_x + bx]
    mov dx, [obstacle_y + bx]
    shr bx, 1
    
    ; Draw the car
    push bx
    mov bx, ax                ; X position
    call draw_blue_car
    pop bx
    
    pop bx
    
.next:
    inc bx
    jmp near .loop
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret



; ----- DRAW BLUE OBSTACLE CAR at BX (X), DX (Y) -----
draw_blue_car:
    push ax
    push cx
    push dx
    push si
    push di
    
    mov si, bx                ; Save X
    mov di, dx                ; Save Y
    
    ; Check if car is too high (in title area)
    cmp di, 22
    jge .start_drawing
    jmp .done_early
    
.start_drawing:    
    ; Row 0 - top (slim)
    mov cx, 12
    mov bx, si
    add bx, 3
.row0:
    push cx
    mov cx, bx
    mov dx, di
    cmp dx, 20                ; Skip if in title
    jle near .skip0
    mov al, COLOR_BLUE
    call put_pixel
.skip0:
    pop cx
    inc bx
    loop .row0
    inc di

    ; Rows 1-2 - medium
    mov ax, 2
.rows1_2:
    push ax
    mov cx, 14
    mov bx, si
    add bx, 2
.r1_2:
    push cx
    mov cx, bx
    mov dx, di
    cmp dx, 20
    jle near .skip1_2
    mov al, COLOR_BLUE
    call put_pixel
.skip1_2:
    pop cx
    inc bx
    loop .r1_2
    inc di
    pop ax
    dec ax
    jnz near .rows1_2

    ; Rows 3-4 - full width
    mov ax, 2
.rows3_4:
    push ax
    mov cx, 18
    mov bx, si
.r3_4:
    push cx
    mov cx, bx
    mov dx, di
    cmp dx, 20
    jle near .skip3_4
    mov al, COLOR_BLUE
    call put_pixel
.skip3_4:
    pop cx
    inc bx
    loop .r3_4
    inc di
    pop ax
    dec ax
    jnz near .rows3_4

    ; Rows 5-8 - windshield
    mov ax, 4
.rows5_8:
    push ax
    mov cx, 18
    mov bx, si
.r5_8:
    push cx
    push bx
    sub bx, si
    cmp bx, 3
    jl short .blue_wind
    cmp bx, 15
    jge short .blue_wind
    mov al, COLOR_BLACK
    jmp short .draw_wind
.blue_wind:
    mov al, COLOR_BLUE
.draw_wind:
    pop bx
    mov cx, bx
    mov dx, di
    cmp dx, 20
    jle short .skip5_8
    call put_pixel
.skip5_8:
    pop cx
    inc bx
    loop .r5_8
    inc di
    pop ax
    dec ax
    jnz near .rows5_8

   ; Rows 9-23 - body 
mov ax, 15
.rows9_23_blue:
    push ax
    mov cx, 18
    mov bx, si
.r9_23_blue_col:
    push cx
    mov cx, bx
    mov dx, di
    cmp dx, 20
    jle near .skip9_23_blue
    mov al, COLOR_BLUE
    call put_pixel
.skip9_23_blue:
    pop cx
    inc bx
    loop .r9_23_blue_col
    inc di
    pop ax
    dec ax
    jnz near .rows9_23_blue

    ; Rows 24-28 - with tires
    mov ax, 4
.rows24_28:
    push ax
    mov cx, 18
    mov bx, si
.r24_28:
    push cx
    push bx
    sub bx, si
    cmp bx, 4
    jge near .check_right
    mov al, COLOR_BLACK
    jmp near .draw_tire
.check_right:
    cmp bx, 14
    jl near .blue_tire
    mov al, COLOR_BLACK
    jmp near .draw_tire
.blue_tire:
    mov al, COLOR_BLUE
.draw_tire:
    pop bx
    mov cx, bx
    mov dx, di
    cmp dx, 20
    jle near .skip_tire
    call put_pixel
.skip_tire:
    pop cx
    inc bx
    loop .r24_28
    inc di
    pop ax
    dec ax
    jnz near .rows24_28

.done_early:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret



; ----- DRAW RED PLAYER CAR -----
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




; ==================== UTILITY ROUTINES ====================

; ----- COLLISION DETECTION -----
check_collisions:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; Player box
    mov ax, PLAYER_X
    mov si, ax              ; si = player_x
    mov ax, PLAYER_Y
    mov di, ax              ; di = player_y

; --- CHECK OBSTACLE CARS ---
    xor bx, bx
check_obs_loop:
    cmp bx, 3
    jge check_coins_start

    cmp byte [obstacle_active + bx], 0
    je next_obs

    ; load obstacle position
    push bx
    shl bx, 1
    mov ax, [obstacle_x + bx]
    mov dx, [obstacle_y + bx]
    shr bx, 1

    ; check overlap (simple AABB)
    ; if NOT (right < left2 OR left > right2 OR bottom < top2 OR top > bottom2)
    ; then collision

    ; horizontal overlap?
    mov cx, ax              ; ob_x
    add cx, 18              ; ob_right
    cmp cx, si
    jl next_obs_pop

    mov cx, si              ; player_x
    add cx, 18
    cmp cx, ax
    jl next_obs_pop

    ; vertical overlap?
    mov cx, dx              ; ob_y
    add cx, 28
    cmp cx, di
    jl next_obs_pop

    mov cx, di
    add cx, 28
    cmp cx, dx
    jl next_obs_pop

    ; ----- COLLISION OCCURRED -----
    mov byte [obstacle_active + bx], 0
    dec byte [obstacle_count]

    ; Immediately clear obstacle from screen
    push bx
    shl bx, 1
    mov ax, [obstacle_x + bx]
    mov dx, [obstacle_y + bx]
    shr bx, 1
    mov bx, ax
    call clear_car_area
    pop bx

next_obs_pop:
    pop bx
next_obs:
    inc bx
    jmp check_obs_loop

; --- CHECK COINS ---
check_coins_start:
    xor bx, bx
check_coin_loop:
    cmp bx, 5
    jge coll_done

    cmp byte [coin_active + bx], 0
    je next_coin

    ; load coin center
    push bx
    shl bx, 1
    mov ax, [coin_x + bx]   ; center X
    mov dx, [coin_y + bx]   ; center Y
    shr bx, 1

    ; convert to top-left of coin (10x10)
    sub ax, 5
    sub dx, 5

    ; --- AABB collision with player size 18x28 ---

    mov cx, ax
    add cx, 10
    cmp cx, si
    jl next_coin_pop

    mov cx, si
    add cx, 18
    cmp cx, ax
    jl next_coin_pop

    mov cx, dx
    add cx, 10
    cmp cx, di
    jl next_coin_pop

    mov cx, di
    add cx, 28
    cmp cx, dx
    jl next_coin_pop

    ; ----- COLLISION OCCURRED -----
    mov byte [coin_active + bx], 0
    dec byte [coin_count]

    ; Increase score
    add word [score], 10

    ; Immediately clear coin from screen
    push bx
    shl bx, 1
    mov ax, [coin_x + bx]
    mov dx, [coin_y + bx]
    shr bx, 1
    mov bx, ax
    call clear_coin_area
    pop bx

next_coin_pop:
    pop bx
next_coin:
    inc bx
    jmp check_coin_loop

coll_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    call draw_player_car
    ret



; ----- UPDATE SCORE + FUEL NUMBERS -----
update_title_numbers:
    push ax
    push bx
    push cx
    push dx

    ; --- Update SCORE (row 1, col 7) ---
    mov ah, 0x02      ; set cursor pos
    mov bh, 0
    mov dh, 1
    mov dl, 7
    int 0x10

    mov ax, [score]
    call print_number

    ; --- Update FUEL (row 1, col 37) ---
    mov ah, 0x02
    mov bh, 0
    mov dh, 1
    mov dl, 37
    int 0x10

    mov ax, [fuel]
    call print_number

    pop dx
    pop cx
    pop bx
    pop ax
    ret



; ----- RANDOM BYTE -----
get_random_byte:
    push dx
    xor ah, ah
    int 0x1A
    mov al, dl
    and al, 0x7F
    pop dx
    ret

animation_delay:
    push bx
    push cx
    
    mov bx, 3
.outer:
    mov cx, 0xFFFF
.inner:
    nop
    loop .inner
    dec bx
    jnz near .outer
    
    pop cx
    pop bx
    ret



; ----- DRAWING PIXELS -----
; Pixel at (CX, DX) with color AL
; Video memory at A000:0000, offset = Y * 320 + X
put_pixel:
    push ax
    push bx
    push cx
    push dx
    push di

    cmp cx, SCREEN_WIDTH
    jge near .skip
    cmp dx, SCREEN_HEIGHT
    jge near .skip
    cmp dx, 0
    jl near .skip

    push ax
    mov ax, dx
    mov bx, SCREEN_WIDTH
    mul bx
    add ax, cx
    mov di, ax
    pop ax
    mov byte [es:di], al

.skip:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret



; ----- NUMBER PRINTING -----
; Print number in AX as decimal
; Uses BIOS teletype output
print_number:
    push ax
    push bx
    push cx
    push dx

    mov cx, 0                 ; Digit counter
    mov bx, 10                ; Divisor

    ; Handle zero case
    test ax, ax
    jnz .convert_loop
    push ax
    mov cx, 1
    jmp .print_loop

.convert_loop:
    test ax, ax
    jz .print_loop
    xor dx, dx                ; Clear DX for division
    div bx                    ; AX = AX / 10, DX = remainder
    add dl, '0'               ; Convert to ASCII
    push dx                   ; Save digit
    inc cx                    ; Count digit
    jmp .convert_loop

.print_loop:
    test cx, cx
    jz .done
    pop dx                    ; Get digit
    mov ah, 0x0E              ; Teletype output
    mov al, dl
    mov bh, 0                 ; Page 0
    int 0x10
    dec cx
    jmp .print_loop

.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
