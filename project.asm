[org 0x0100] 
[bits 16]         

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
COLOR_DARK_BLUE     equ 1       ; Dark Blue
COLOR_DARK_CYAN     equ 3       ; Dark Cyan
COLOR_BRIGHT_RED    equ 4       ; Bright Red
COLOR_LIGHT_GRAY    equ 7       ; Light Gray
COLOR_DARK_GRAY     equ 8       ; Dark Gray
COLOR_WINDSHIELD    equ 8       ; Windshield color
COLOR_BRIGHT_GREEN  equ 10      ; Bright Green
COLOR_BRIGHT_YELLOW equ 14      ; Bright Yellow
COLOR_DARK_RED      equ 32      ; Dark Red
COLOR_WINDSHIELD_TOP equ 56     ; Windshield top
COLOR_LIGHT_RED     equ 68      ; Light Red
COLOR_GRILL_GRAY    equ 7       ; Grill gray
COLOR_MEDIUM_GRAY   equ 7       ; Medium gray

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

; Animation and timing constants
SCROLL_SPEED           equ 5      ; Pixels per frame for scrolling
LANE_PATTERN_SIZE      equ 20     ; Lane divider pattern repeats every 20px
BORDER_PATTERN_SIZE    equ 20     ; Border pattern repeats every 20px
OBSTACLE_SPAWN_TIME    equ 50     ; Frames between obstacle spawns
COIN_SPAWN_TIME        equ 28     ; Frames between coin spawns
DELAY_OUTER_LOOP       equ 2      ; Outer delay loop count
DELAY_INNER_LOOP       equ 0xE000 ; Inner delay loop count
FUEL_TANK_SPAWN_TIME   equ 80     ; Frames between fuel tank spawns (slower than coins)
FUEL_TANK_SIZE         equ 12     ; Fuel tank is 12x16 pixels

; Object dimensions for collision detection
COIN_SIZE              equ 10     ; Coin is 10x10 pixels
COIN_HALF_SIZE         equ 5      ; Half size for center calculations
COIN_CLEAR_SIZE        equ 16     ; Size to clear around coin

; Spawn positions
SPAWN_Y_POSITION       equ -10     ; Y position where objects spawn
SPAWN_CHECK_THRESHOLD  equ 100    ; Y threshold for spawn checking
LANE_CHECK_DISTANCE    equ 30     ; Distance to check for obstacles in lane
COIN_LANE_DISTANCE     equ 20     ; Distance to check for coins in lane

; Collision adjustments
OBSTACLE_CLEAR_BUFFER  equ 15     ; Buffer when clearing obstacles off-screen

; Animation variables
spawn_timer     dw 0          ; Timer for spawning obstacles
coin_timer      dw 0          ; Timer for spawning coins
fuel_timer      dw 0            ; Timer for fuel depletion

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
; Fuel tank management (up to 3 active)
fuel_tank_count      db 0
fuel_tank_x          times 3 dw 0  ; X positions
fuel_tank_y          times 3 dw 0  ; Y positions
fuel_tank_old_y      times 3 dw 0  ; Previous Y positions
fuel_tank_active     times 3 db 0  ; Active flags
fuel_tank_timer      dw 0           ; Timer for spawning fuel tanks

; Fuel tank sprite: 12x12 pixels (same size as coin)
; Color legend: 0=black outline, 2=dark green body, 255=transparent
fuel_tank_sprite:
    ; Row 0
    db 255,255,0,0,0,0,0,0,0,0,255,255
    ; Row 1
    db 255,0,0,2,2,2,2,2,2,0,0,255
    ; Row 2
    db 0,0,2,2,2,2,2,2,2,2,0,0
    ; Row 3
    db 0,2,2,2,2,2,2,2,2,2,2,0
    ; Row 4
    db 0,2,2,2,2,2,2,2,2,2,2,0
    ; Row 5
    db 0,2,2,2,2,2,2,2,2,2,2,0
    ; Row 6
    db 0,2,2,2,2,2,2,2,2,2,2,0
    ; Row 7
    db 0,2,2,2,2,2,2,2,2,2,2,0
    ; Row 8
    db 0,2,2,2,2,2,2,2,2,2,2,0
    ; Row 9
    db 0,2,2,2,2,2,2,2,2,2,2,0
    ; Row 10
    db 255,0,0,2,2,2,2,2,2,0,0,255
    ; Row 11
    db 255,255,0,0,0,0,0,0,0,0,255,255

FUEL_TANK_WIDTH  equ 12
FUEL_TANK_HEIGHT equ 12
; Road management
lane_offset       dw 0
border_offset     dw 0

; Player car management
player_lane     db 1          ; Current lane (0=left, 1=center, 2=right)
player_x        dw PLAYER_X   ; Current X position
player_y        dw PLAYER_Y   ; Current Y position

; Game state
game_started    db 0          ; 0 = not started, 1 = started
game_crashed    db 0          ; 0 = no crash, 1 = crashed
game_over_reason db 0         ; 0 = crash, 1 = fuel

; Title strings
title_text:     db 'Score:    FAISAL TOWN TRAFFIC  Fuel:  ', 0
start_message:  db 'PRESS ANY KEY TO START', 0
fuel:           dw 3
score:          dw 0

; Game state management
game_paused     db 0             ; 0 = running, 1 = paused
confirm_active  db 0             ; 0 = no confirmation, 1 = showing confirmation
saved_road_area times 4800 db 0  ; Buffer to save screen area (80x60 pixels)

; Confirmation box strings
confirm_msg1:   db 'Do you want to quit?', 0
confirm_msg2:   db 'Press Y or N', 0

; Car drawing variables
startX  dw 0
startY  dw 0
color   db 0

; Main screen strings
STR_MAIN_TITLE:     db "FAISAL TOWN TRAFFIC", 0
STR_DEVELOPER:      db "ZOHA SARWAR (24L-0536)", 0
STR_ROLL:           db "ABDULLAH OMAR (24L-0576)", 0
STR_MAIN_INSTRUCTION: db "ENGAGE DRIVE / PRESS START KEY", 0

; Instruction screen strings
STR_INST_TITLE:     db "INSTRUCTIONS", 0
STR_INST_1:         db "Arrow Keys: Move car", 0
STR_INST_2:         db "ESC: Pause & Quit Menu", 0
STR_INST_3:         db "Y: Quit (when paused)", 0
STR_INST_4:         db "N or ESC: Resume game", 0
STR_INST_5:         db "Collect fuel cans!", 0
STR_INST_6:         db "Game ends if fuel runs out", 0
STR_INST_7:         db "Press any key...", 0

; Registration screen strings
STR_REG_TITLE:      db "FINAL EXAM", 0
STR_ROLL_PROMPT:    db "Roll Num: ", 0
STR_NAME_PROMPT:    db "Name: ", 0
STR_TIME:           db "Time: 3 hours", 0
STR_INSTRUCTOR:     db "Instructor: Zummar Saad", 0
STR_TA:             db "TA: Abdul Moeed Maan", 0
STR_START:          db "ANDDD YOUR RACE STARTS NOW!!!(press P)", 0
STR_STARTING:       db "STARTING...", 0

; Input buffers
player_roll:        times 21 db 0
player_name:        times 21 db 0

; Game end messages
crash_message:     db 'CRASHED!', 0
fuel_empty_msg:    db 'OUT OF FUEL!', 0
crash_continue:    db 'Press any key...', 0

; End screen strings 
STR_TITLE:          db "GAME OVER", 0
STR_HEADING:        db "DISCIPLINARY ACTION NOTICE", 0
STR_NOTICE1:        db "Action taken for ", 0
STR_REASON_FUEL:    db "'Low Fuel'", 0        
STR_REASON_CRASH:   db "'Crashing'", 0         
STR_NOTICE2:        db "against the student below:", 0
STR_POINTS:         db "POINTS: ", 0
STR_INSTRUCTION1:   db "ENTER:Menu  SPACE:Restart", 0
STR_INSTRUCTION2:   db "ESC:Exit", 0




; ==================== CODE SECTION ====================

start:
    ; Set video mode to 13h (320x200, 256 colors)
    mov ax, 0x0013
    int 0x10

    call start_screen_layout
    call show_instructions
    call show_registration

    ; Set ES to video memory segment
    mov ax, 0xA000
    mov es, ax

    ; Initialize player position 
    mov byte [player_lane], 1
    mov word [player_x], PLAYER_X
    mov word [player_y], PLAYER_Y

    ; Initialize game state
    mov byte [game_crashed], 0        ; No crash at start

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
    mov byte [fuel_tank_count], 0
    mov word [fuel_tank_timer], 0

    ; Wait for key press to start animation
    call wait_for_start_key




; ==================== MAIN GAME LOOP ====================

animation_loop:
    call check_keyboard
    
    ; Check if game crashed
    cmp byte [game_crashed], 1
    je .game_over             ; Skip updates if crashed
    
    ; Check if game is paused
    cmp byte [game_paused], 1
    je .skip_updates
    
    ; Normal game updates (only when not paused)
    call clear_old_objects
    call update_all_objects
    call update_lane_scroll
    call draw_all_objects
    call check_collisions
    call update_title_numbers
    call spawn_objects
    call update_game_timers
    
.skip_updates:
    call animation_delay
    jmp animation_loop

.game_over:
    ; Game is crashed, wait here
    jmp animation_loop        ; Just keep looping (frozen state)


exit_program:
    mov ax, 0x0003
    int 0x10
    mov ax, 0x4C00
    int 0x21




; ==================== GAME SCREENS ====================

; ----- Main Screen with Car -----
start_screen_layout:
    ; Fill entire screen with DARK_BLUE
    mov bx, 0
    mov cx, 0
    mov dx, 320
    mov si, 200
    mov al, COLOR_DARK_BLUE
    call fill_rect
    
    ; Draw Outer Border
    mov bx, 0
    mov cx, 0
    mov dx, 320
    mov si, 2
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    mov bx, 0
    mov cx, 198
    mov dx, 320
    mov si, 2
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    mov bx, 0
    mov cx, 2
    mov dx, 2
    mov si, 196
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    mov bx, 318
    mov cx, 2
    mov dx, 2
    mov si, 196
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    ; Top Dashboard Panel
    mov bx, 5
    mov cx, 5
    mov dx, 310
    mov si, 25
    mov al, COLOR_DARK_GRAY
    call fill_rect
    
    ; Central Display Panel
    mov bx, 30
    mov cx, 40
    mov dx, 260
    mov si, 120
    mov al, COLOR_DARK_CYAN
    call fill_rect
    
    ; Instruction Panel
    mov bx, 5
    mov cx, 175
    mov dx, 310
    mov si, 20
    mov al, COLOR_BRIGHT_RED
    call fill_rect
    
    ; Draw the Car
    call draw_car
    
    ; Title
    mov bx, 8
    mov cx, 10
    mov si, STR_MAIN_TITLE
    mov al, COLOR_WHITE
    call print_string_gfx_2x
    
    ; Developer info
    mov bx, 72
    mov cx, 135
    mov si, STR_DEVELOPER
    mov al, COLOR_WHITE
    call print_string_gfx
    
    ; Roll numbers
    mov bx, 64
    mov cx, 145
    mov si, STR_ROLL
    mov al, COLOR_WHITE
    call print_string_gfx
    
    ; Instruction text
    mov bx, 36
    mov cx, 180
    mov si, STR_MAIN_INSTRUCTION
    mov al, COLOR_WHITE
    call print_string_gfx
    
    ; Wait for User Input
    call wait_for_key
    ret


; ----- Show Instructions Screen -----
show_instructions:
    ; Clear the cyan panel only
    mov bx, 30
    mov cx, 40
    mov dx, 260
    mov si, 120
    mov al, COLOR_DARK_CYAN
    call fill_rect
    
    ; Title
    mov bx, 100
    mov cx, 45
    mov si, STR_INST_TITLE
    mov al, COLOR_BRIGHT_YELLOW
    call print_string_gfx
    
    ; Instructions
    mov bx, 35
    mov cx, 60
    mov si, STR_INST_1
    mov al, COLOR_WHITE
    call print_string_gfx
    
    mov bx, 35
    mov cx, 72
    mov si, STR_INST_2
    mov al, COLOR_WHITE
    call print_string_gfx
    
    mov bx, 35
    mov cx, 84
    mov si, STR_INST_3
    mov al, COLOR_WHITE
    call print_string_gfx
    
    mov bx, 35
    mov cx, 96
    mov si, STR_INST_4
    mov al, COLOR_WHITE
    call print_string_gfx
    
    mov bx, 35
    mov cx, 108
    mov si, STR_INST_5
    mov al, COLOR_BRIGHT_GREEN
    call print_string_gfx
    
    mov bx, 35
    mov cx, 120
    mov si, STR_INST_6
    mov al, COLOR_BRIGHT_GREEN
    call print_string_gfx
    
    mov bx, 35
    mov cx, 135
    mov si, STR_INST_7
    mov al, COLOR_BRIGHT_YELLOW
    call print_string_gfx
    
    ; Wait for key
    call wait_for_key
    ret


; ----- Show Registration Screen -----
show_registration:
    ; Clear entire screen
    mov bx, 0
    mov cx, 0
    mov dx, 320
    mov si, 200
    mov al, COLOR_DARK_BLUE
    call fill_rect
    
    ; Draw borders
    mov bx, 0
    mov cx, 0
    mov dx, 320
    mov si, 2
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    mov bx, 0
    mov cx, 198
    mov dx, 320
    mov si, 2
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    mov bx, 0
    mov cx, 2
    mov dx, 2
    mov si, 196
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    mov bx, 318
    mov cx, 2
    mov dx, 2
    mov si, 196
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    ; Top panel
    mov bx, 5
    mov cx, 5
    mov dx, 310
    mov si, 25
    mov al, COLOR_BRIGHT_RED
    call fill_rect
    
    ; Central panel
    mov bx, 30
    mov cx, 40
    mov dx, 260
    mov si, 120
    mov al, COLOR_DARK_CYAN
    call fill_rect
    
    ; Bottom panel
    mov bx, 5
    mov cx, 175
    mov dx, 310
    mov si, 20
    mov al, COLOR_DARK_GRAY
    call fill_rect
    
    ; Title
    mov bx, 80
    mov cx, 10
    mov si, STR_REG_TITLE
    mov al, COLOR_WHITE
    call print_string_gfx_2x
    
    ; Roll Number box 
    mov bx, 45
    mov cx, 58
    mov dx, 230 
    mov si, 20  
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    mov bx, 47
    mov cx, 60
    mov dx, 226  
    mov si, 16   
    mov al, COLOR_DARK_GRAY
    call fill_rect
    
    mov bx, 50
    mov cx, 65
    mov si, STR_ROLL_PROMPT
    mov al, COLOR_WHITE
    call print_string_gfx
    
    ; Name box
    mov bx, 45
    mov cx, 93
    mov dx, 230
    mov si, 20
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    mov bx, 47
    mov cx, 95
    mov dx, 226
    mov si, 16
    mov al, COLOR_DARK_GRAY
    call fill_rect
    
    mov bx, 50
    mov cx, 100
    mov si, STR_NAME_PROMPT
    mov al, COLOR_WHITE
    call print_string_gfx
    
    ; Time
    mov bx, 180
    mov cx, 45
    mov si, STR_TIME
    mov al, COLOR_BRIGHT_GREEN
    call print_string_gfx
    
    ; Instructor
    mov bx, 35
    mov cx, 135
    mov si, STR_INSTRUCTOR
    mov al, COLOR_WHITE
    call print_string_gfx
    
    ; TA
    mov bx, 35
    mov cx, 145
    mov si, STR_TA
    mov al, COLOR_WHITE
    call print_string_gfx
    
    ; Start instruction
    mov bx, 10
    mov cx, 180
    mov si, STR_START
    mov al, COLOR_WHITE
    call print_string_gfx
    
    ; Get Roll Number Input
    mov bx, 130
    mov cx, 65
    mov si, player_roll
    call get_string_input
    
    cmp byte [player_roll], 0
    je .exit_reg
    
    ; Get Name Input
    mov bx, 110
    mov cx, 100
    mov si, player_name
    call get_string_input
    
    cmp byte [player_name], 0
    je .exit_reg
    
    ; Wait for 'P' key
.wait_for_p:
    mov ah, 0x00
    int 0x16
    
    cmp al, 'p'
    je .start_game
    cmp al, 'P'
    je .start_game
    jmp .wait_for_p
    
.start_game:
    call show_game_start
    
.exit_reg:
    ret


; ----- Show Game Start Message -----
show_game_start:
    mov bx, 30
    mov cx, 40
    mov dx, 260
    mov si, 120
    mov al, COLOR_DARK_CYAN
    call fill_rect
    
    mov bx, 90
    mov cx, 90
    mov si, STR_STARTING
    mov al, COLOR_BRIGHT_GREEN
    call print_string_gfx_2x
    
    mov cx, 0xFFFF
.delay_loop:
    loop .delay_loop
    
    ret


; ----- End Screen Layout Logic - Game Over Screen -----
end_screen_layout:

    ; 1. Fill entire screen with DARK_BLUE
    mov bx, 0                   ; X = 0
    mov cx, 0                   ; Y = 0
    mov dx, 320                 ; Width = 320 (full screen)
    mov si, 200                 ; Height = 200 (full screen)
    mov al, COLOR_DARK_BLUE     ; Background color
    call fill_rect
    
    ; 2. Draw Outer Border (2-pixel thick)
    ; Top border (2 pixels high)
    mov bx, 0                   ; X = 0
    mov cx, 0                   ; Y = 0
    mov dx, 320                 ; Width = 320
    mov si, 2                   ; Height = 2
    mov al, COLOR_BRIGHT_YELLOW ; Border color
    call fill_rect
    
    ; Bottom border (2 pixels high)
    mov bx, 0                   ; X = 0
    mov cx, 198                 ; Y = 198
    mov dx, 320                 ; Width = 320
    mov si, 2                   ; Height = 2
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    ; Left border (2 pixels wide)
    mov bx, 0                   ; X = 0
    mov cx, 2                   ; Y = 2
    mov dx, 2                   ; Width = 2
    mov si, 196                 ; Height = 196
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    ; Right border (2 pixels wide)
    mov bx, 318                 ; X = 318
    mov cx, 2                   ; Y = 2
    mov dx, 2                   ; Width = 2
    mov si, 196                 ; Height = 196
    mov al, COLOR_BRIGHT_YELLOW
    call fill_rect
    
    ; 3. Top Dashboard Panel 
    mov bx, 5                   ; X = 5
    mov cx, 5                   ; Y = 5
    mov dx, 310                 ; Width = 310 (320 - 10)
    mov si, 25                  ; Height = 25 (Y=5 to Y=30)
    mov al, COLOR_BRIGHT_RED
    call fill_rect
    
    ; 4. Central Display Panel (DARK_CYAN)
    mov bx, 30                  ; X = 30
    mov cx, 40                  ; Y = 40
    mov dx, 260                 ; Width = 260
    mov si, 110                 ; Height = 110 (reduced from 120)
    mov al, COLOR_DARK_CYAN
    call fill_rect
    
    ; 5. Instruction Panel COLOR_DARK_GRAY
    mov bx, 5                   ; X = 5
    mov cx, 165                 ; Y = 165 (moved up from 175)
    mov dx, 310                 ; Width = 310 (320 - 10)
    mov si, 30                  ; Height = 30 (increased from 20)
    mov al, COLOR_DARK_GRAY
    call fill_rect

    ; 6. Display Text in Graphics Mode    
    ; Title "GAME OVER" in top dashboard (2x size, centered)
    ; "GAME OVER" = 9 chars * 16 pixels = 144 pixels
    ; Center: (320 - 144) / 2 = 88
    mov bx, 88                  ; X = 88 pixels (centered)
    mov cx, 10                  ; Y = 10 pixels
    mov si, STR_TITLE           ; String pointer
    mov al, COLOR_WHITE         ; White text
    call print_string_gfx_2x
    
    ; Heading "DISCIPLINARY ACTION NOTICE" (normal size, centered)
    ; 26 chars * 8 pixels = 208 pixels
    ; Center: (260 - 208) / 2 + 30 = 56
    mov bx, 56                  ; X = 56 pixels (centered in cyan panel)
    mov cx, 48                  ; Y = 48 pixels
    mov si, STR_HEADING         ; String pointer
    mov al, COLOR_BRIGHT_YELLOW ; Yellow heading
    call print_string_gfx
    
    ; Notice text line 1 - "Action taken for "
    mov bx, 44                  
    mov cx, 65                  
    mov si, STR_NOTICE1         
    mov al, COLOR_WHITE         
    call print_string_gfx
    
    ; Display the appropriate reason based on game_over_reason
    add bx, 136                 ; Move to position after "Action taken for "
    cmp byte [game_over_reason], 0
    je .show_crash_reason
    
    ; Show fuel reason
    mov si, STR_REASON_FUEL
    jmp .display_reason
    
.show_crash_reason:
    mov si, STR_REASON_CRASH
    
.display_reason:
    mov al, COLOR_BRIGHT_YELLOW
    call print_string_gfx
    
    ; Notice text line 2 (normal size, centered)
    ; "against the student below:" = 27 chars * 8 = 216 pixels
    ; Center: (260 - 216) / 2 + 30 = 52
    mov bx, 52                  ; X = 52 pixels (centered)
    mov cx, 78                  ; Y = 78 pixels
    mov si, STR_NOTICE2         ; String pointer
    mov al, COLOR_WHITE         ; White text
    call print_string_gfx
    
    ; Student info - Display actual player data
    mov bx, 52                  
    mov cx, 105                 
    mov si, player_roll       
    mov al, COLOR_WHITE         
    call print_string_gfx
    ; Add space between roll and name
    add bx, 80                  ; Adjust spacing
    mov si, player_name         
    mov al, COLOR_WHITE
    call print_string_gfx
    
    ; Display "POINTS: " label
    mov bx, 112                 
    mov cx, 130                 
    mov si, STR_POINTS          
    mov al, COLOR_BRIGHT_GREEN  
    call print_string_gfx
    
    mov ah, 0x02                ; Set cursor position
    mov bh, 0                   ; Page 0
    mov dh, 16                  ; Row 16 (130/8 ≈ 16)
    mov dl, 22                  ; Column 22 (after "POINTS: ")
    int 0x10
    
    mov ax, [score]             
    call print_number           
    
    ; Instruction text - LINE 1 (centered in red panel)
    ; "ENTER:Menu  SPACE:Restart" = 25 chars * 8 = 200 pixels
    ; Center: (310 - 200) / 2 + 5 = 60
    mov bx, 60                  ; X = 60 pixels (centered)
    mov cx, 170                 ; Y = 170 pixels (top line)
    mov si, STR_INSTRUCTION1    ; String pointer
    mov al, COLOR_WHITE         ; White text
    call print_string_gfx
    
    ; Instruction text - LINE 2 (centered in red panel)
    ; "ESC:Exit" = 8 chars * 8 = 64 pixels
    ; Center: (310 - 64) / 2 + 5 = 128
    mov bx, 128                 ; X = 128 pixels (centered)
    mov cx, 182                 ; Y = 182 pixels (bottom line, more space)
    mov si, STR_INSTRUCTION2    ; String pointer
    mov al, COLOR_WHITE         ; White text
    call print_string_gfx
    
    ; 7. Wait for User Input
    call wait_for_key
    
    ; 8. Cleanup and Exit
    call exit_program




; ==================== CONTROLLER FUNCTIONS ====================

; ----- Wait for Key Press -----
wait_for_key:
    mov ah, 0x00
    int 0x16
    ret


; ----- WAIT FOR ANY KEY PRESS TO START GAME -----
wait_for_start_key:
    push ax
    
    ; Wait for keypress
    mov ah, 0x00
    int 0x16
    
    ; Mark game as started
    mov byte [game_started], 1
    
    ; Redraw title bar (now shows score/fuel)
    call draw_title_bar
    
    pop ax
    ret


; ----- CHECK KEYBOARD INPUT (ESC, ARROW KEYS, Y, N) -----
check_keyboard:
    push ax
    push bx
    push cx
    
    mov ah, 0x01              ; Check if key available
    int 0x16
    jnz .key_pressed         
    jmp .no_key              

.key_pressed:
    mov ah, 0x00              ; Read key
    int 0x16
    
    ; Check if confirmation screen is active
    cmp byte [confirm_active], 1
    je .handle_confirmation
    
    ; Normal game controls
    cmp al, 27                ; ESC key?
    je .pause_game
    
    ; Check if game is paused (but no confirmation)
    cmp byte [game_paused], 1
    je .no_key                ; Ignore other keys if paused
    
    ; Check for extended keys (arrow keys) - only if not paused
    cmp ah, 0x48              ; Up arrow
    je .move_up
    cmp ah, 0x50              ; Down arrow
    je .move_down
    cmp ah, 0x4B              ; Left arrow
    je .move_left
    cmp ah, 0x4D              ; Right arrow
    je .move_right
    jmp .no_key

.handle_confirmation:
    ; Only Y or N are valid during confirmation
    cmp al, 'y'
    je .quit_yes
    cmp al, 'Y'
    je .quit_yes
    cmp al, 'n'
    je .quit_no
    cmp al, 'N'
    je .quit_no
    jmp .no_key
    
.pause_game:
    ; Check if already paused with confirmation
    cmp byte [confirm_active], 1
    je .resume_game
    
    ; Pause the game and show confirmation
    mov byte [game_paused], 1
    mov byte [confirm_active], 1
    call show_confirmation_screen
    jmp .no_key
    
.resume_game:
    ; Resume from pause (ESC pressed while in confirmation)
    mov byte [game_paused], 0
    mov byte [confirm_active], 0
    call restore_game_screen
    jmp .no_key
    
.quit_yes:
    ; User confirmed quit
    call restore_game_screen
    jmp end_screen_layout
    
.quit_no:
    ; User canceled quit - resume game
    mov byte [game_paused], 0
    mov byte [confirm_active], 0
    call restore_game_screen
    jmp .no_key
    
.move_left:
    call move_player_left
    jmp .no_key
    
.move_right:
    call move_player_right
    jmp .no_key
    
.move_up:
    call move_player_up
    jmp .no_key
    
.move_down:
    call move_player_down
    jmp .no_key
    
.no_key:
    pop cx
    pop bx
    pop ax
    ret


; ----- CLEAR ALL OLD OBJECT POSITIONS -----
clear_old_objects:
    call clear_old_obstacles
    call clear_old_coins
    call clear_old_fuel_tanks    ; ADD THIS LINE
    ret

; ----- UPDATE ALL OBJECT POSITIONS -----
update_all_objects:
    call update_obstacles
    call update_coins
    call update_fuel_tanks    ; ADD THIS LINE
    ret


; ----- UPDATE SCROLLING LANE DIVIDERS -----
update_lane_scroll:
    push ax
    
    add word [lane_offset], SCROLL_SPEED
    cmp word [lane_offset], LANE_PATTERN_SIZE
    jl .no_reset
    sub word [lane_offset], LANE_PATTERN_SIZE
    
.no_reset:
    ; Sync border offset with lane offset
    mov ax, [lane_offset]
    mov [border_offset], ax
    
    pop ax
    ret


; ----- DRAW ALL GAME OBJECTS -----
draw_all_objects:
    call draw_obstacles
    call draw_coins
    call draw_fuel_tanks    ; ADD THIS LINE
    call draw_lane_dividers
    call draw_road_borders
    call draw_player_car
    ret
; ----- SPAWN NEW OBJECTS (OBSTACLES AND COINS) -----
spawn_objects:
    call check_spawn_obstacle
    call check_spawn_coin
    call check_spawn_fuel_tank    ; ADD THIS LINE
    ret

; ----- UPDATE ALL GAME TIMERS -----
update_game_timers:
    push ax
    
    inc word [spawn_timer]
    inc word [coin_timer]
    inc word [fuel_tank_timer]
    
    ; Decrease fuel every 100 frames (adjust as needed)
    inc word [fuel_timer]
    cmp word [fuel_timer], 100
    jl .skip_fuel
    
    mov word [fuel_timer], 0
    
    ; Check if fuel is already zero BEFORE decrementing
    cmp word [fuel], 0
    jle .fuel_empty        
    
    dec word [fuel]
    
    ; Check if fuel just reached zero
    cmp word [fuel], 0
    je .fuel_empty
    
    jmp .skip_fuel
    
.fuel_empty:
    ; Game over - out of fuel
    mov byte [game_crashed], 1
    mov byte [game_over_reason], 1  ; 1 = fuel reason
    call show_fuel_empty_message
    call wait_for_key
    jmp end_screen_layout
    
.skip_fuel:
    pop ax
    ret




; ==================== COLLISION SYSTEM ====================

; ----- CHECK ALL COLLISIONS -----
check_collisions:
    push ax
    push bx
    
    ; Check if already crashed
    cmp byte [game_crashed], 1
    je .done                  ; Skip collision checks if crashed
    
    ; Check all obstacles
    xor bx, bx
.check_obstacles:
    cmp bx, 3
    jge .check_coins
    
    call check_obstacle_collision
    
    ; Check if crash occurred
    cmp byte [game_crashed], 1
    je .done                  ; Stop checking if crash detected
    
    inc bx
    jmp .check_obstacles
    
.check_coins:
    ; Check all coins
    xor bx, bx
.coin_loop:
    cmp bx, 5
    jge .check_fuel_tanks    ; CHANGE THIS from .done
    
    call check_coin_collision
    
    inc bx
    jmp .coin_loop

; ADD THIS NEW SECTION:
.check_fuel_tanks:
    ; Check all fuel tanks
    xor bx, bx
.fuel_tank_loop:
    cmp bx, 3
    jge .done
    
    call check_fuel_tank_collision
    
    inc bx
    jmp .fuel_tank_loop
    
.done:
    call draw_player_car
    
    pop bx
    pop ax
    ret

; ----- CHECK COLLISION BETWEEN PLAYER AND ONE OBSTACLE -----
; Input: BX = obstacle index
check_obstacle_collision:
    push ax
    push cx
    push dx
    push si
    push di
    
    ; Check if active
    cmp byte [obstacle_active + bx], 0
    je .no_collision
    
    ; Get obstacle position
    push bx
    shl bx, 1
    mov ax, [obstacle_x + bx]
    mov dx, [obstacle_y + bx]
    shr bx, 1
    
    ; Player box 
    mov si, [player_x]
    mov di, [player_y]
    
    ; Check horizontal overlap
    mov cx, ax
    add cx, CAR_WIDTH
    cmp cx, si
    jl .no_collision_pop
    
    mov cx, si
    add cx, CAR_WIDTH
    cmp cx, ax
    jl .no_collision_pop
    
    ; Check vertical overlap
    mov cx, dx
    add cx, CAR_HEIGHT
    cmp cx, di
    jl .no_collision_pop
    
    mov cx, di
    add cx, CAR_HEIGHT
    cmp cx, dx
    jl .no_collision_pop
    
    ; Collision detected!
    pop bx
    call handle_obstacle_collision
    jmp .done
    
.no_collision_pop:
    pop bx
.no_collision:
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret


; ----- CHECK COLLISION BETWEEN PLAYER AND ONE COIN -----
; Input: BX = coin index
check_coin_collision:
    push ax
    push cx
    push dx
    push si
    push di
    
    ; Check if active
    cmp byte [coin_active + bx], 0
    je .no_collision
    
    ; Get coin center position
    push bx
    shl bx, 1
    mov ax, [coin_x + bx]
    mov dx, [coin_y + bx]
    shr bx, 1
    
    ; Convert to top-left (coin is 10x10)
    sub ax, COIN_HALF_SIZE
    sub dx, COIN_HALF_SIZE
    
    ; Player box
    mov si, [player_x]
    mov di, [player_y]
    
    ; Check horizontal overlap
    mov cx, ax
    add cx, COIN_SIZE
    cmp cx, si
    jl .no_collision_pop
    
    mov cx, si
    add cx, CAR_WIDTH
    cmp cx, ax
    jl .no_collision_pop
    
    ; Check vertical overlap
    mov cx, dx
    add cx, COIN_SIZE
    cmp cx, di
    jl .no_collision_pop
    
    mov cx, di
    add cx, CAR_HEIGHT
    cmp cx, dx
    jl .no_collision_pop
    
    ; Collision detected!
    pop bx
    call handle_coin_collection
    jmp .done
    
.no_collision_pop:
    pop bx
.no_collision:
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret


; ----- HANDLE OBSTACLE COLLISION -----
; Input: BX = obstacle index
handle_obstacle_collision:
    push ax
    push bx
    push dx
    
    ; Set crash state and reason
    mov byte [game_crashed], 1
    mov byte [game_over_reason], 0    ; 0 = crash reason
    
    ; Show crash message
    call show_crash_message
    
    ; Wait for user to press any key
    call wait_for_key
    
    ; Go to end screen
    jmp end_screen_layout
    
    pop dx
    pop bx
    pop ax
    ret


; ----- SHOW CRASH MESSAGE IN TITLE BAR -----
show_crash_message:
    push ax
    push bx
    push cx
    push dx
    push bp
    push es
    
    push es
    mov ax, 0xA000
    mov es, ax
    mov dx, 0                 ; Start Y = 0
.bar_loop_y:
    mov cx, 0                 ; Start X = 0
.bar_loop_x:
    mov al, COLOR_BLACK       ; Keep black background
    call put_pixel
    inc cx
    cmp cx, SCREEN_WIDTH
    jl .bar_loop_x
    inc dx
    cmp dx, 20                ; Title bar height = 20 pixels
    jl .bar_loop_y
    pop es
    
    ; Display "CRASHED!" message in center
    mov ah, 0x13              ; Write string function
    mov al, 0x01               
    mov bh, 0                
    mov bl, 0x0C              ; Bright RED text (color code 12)
    mov cx, 8                 ; String length
    mov dh, 1                 ; Row 
    mov dl, 16                ; Column (centered)
    
    push cs
    pop es
    mov bp, crash_message
    int 0x10
    
    ; Display "Press any key..."
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 0x0E              ; Yellow text
    mov cx, 16                ; String length
    mov dh, 23                ; Row (near bottom)
    mov dl, 12                ; Column (centered)
    mov bp, crash_continue
    int 0x10
    
    pop es
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; ----- SHOW FUEL EMPTY MESSAGE -----
show_fuel_empty_message:
    push ax
    push bx
    push cx
    push dx
    push bp
    push es
    
    push es
    mov ax, 0xA000
    mov es, ax
    mov dx, 0                 
.bar_loop_y:
    mov cx, 0                 
.bar_loop_x:
    mov al, COLOR_BLACK       ; Keep black background
    call put_pixel
    inc cx
    cmp cx, SCREEN_WIDTH
    jl .bar_loop_x
    inc dx
    cmp dx, 20                
    jl .bar_loop_y
    pop es
    
    ; Display "OUT OF FUEL!" message in RED text, centered
    mov ah, 0x13              
    mov al, 0x01               
    mov bh, 0                
    mov bl, 0x0C              ; Bright RED text (color code 12)
    mov cx, 12                ; String length
    mov dh, 1                 
    mov dl, 14                ; Column (centered)
    
    push cs
    pop es
    mov bp, fuel_empty_msg
    int 0x10
    
    ; Display "Press any key..." 
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 0x0E              ; Yellow text
    mov cx, 16                
    mov dh, 23                ; Row (near bottom)
    mov dl, 12                ; Column (centered)
    mov bp, crash_continue
    int 0x10
    
    pop es
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; ----- HANDLE COIN COLLECTION -----
; Input: BX = coin index
handle_coin_collection:
    push ax
    push bx
    push dx
    
    ; Deactivate coin
    mov byte [coin_active + bx], 0
    dec byte [coin_count]
    
    ; Increase score
    add word [score], 10
    
    ; Get position and clear from screen
    push bx
    shl bx, 1
    mov ax, [coin_x + bx]
    mov dx, [coin_y + bx]
    shr bx, 1
    
    push bx
    mov bx, ax
    call clear_coin_area
    pop bx
    pop bx
    
    pop dx
    pop bx
    pop ax
    ret

; ==================== FUEL TANK SYSTEM ====================

; ----- CLEAR OLD FUEL TANKS -----
clear_old_fuel_tanks:
    push ax
    push bx
    push cx
    push dx
    
    xor bx, bx
.loop:
    cmp bx, 3
    jge .done
    
    cmp byte [fuel_tank_active + bx], 0
    je .next
    
    push bx
    shl bx, 1
    mov ax, [fuel_tank_x + bx]
    mov dx, [fuel_tank_old_y + bx]
    shr bx, 1
    
    push bx
    mov bx, ax
    call clear_fuel_tank_area
    pop bx
    
    pop bx
    
.next:
    inc bx
    jmp .loop
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; ----- UPDATE FUEL TANK POSITIONS -----
update_fuel_tanks:
    push ax
    push bx
    push cx
    
    xor bx, bx
.loop:
    cmp bx, 3
    jge .done
    
    cmp byte [fuel_tank_active + bx], 0
    je .next
    
    push bx
    shl bx, 1
    
    mov ax, [fuel_tank_y + bx]
    mov [fuel_tank_old_y + bx], ax
    
    add ax, SCROLL_SPEED
    
    cmp ax, SCREEN_HEIGHT + 20
    jl .keep
    
    shr bx, 1
    mov byte [fuel_tank_active + bx], 0
    dec byte [fuel_tank_count]
    pop bx
    jmp .next
    
.keep:
    mov [fuel_tank_y + bx], ax
    shr bx, 1
    pop bx
    
.next:
    inc bx
    jmp .loop
    
.done:
    pop cx
    pop bx
    pop ax
    ret


; ----- DRAW ALL FUEL TANKS -----
draw_fuel_tanks:
    push ax
    push bx
    push cx
    push dx
    
    xor bx, bx
.loop:
    cmp bx, 3
    jge .done
    
    cmp byte [fuel_tank_active + bx], 0
    je .next
    
    push bx
    shl bx, 1
    mov ax, [fuel_tank_x + bx]
    mov dx, [fuel_tank_y + bx]
    shr bx, 1
    
    push bx
    mov bx, ax
    call draw_fuel_tank
    pop bx
    
    pop bx
    
.next:
    inc bx
    jmp .loop
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; ----- DRAW FUEL TANK SPRITE at BX (X center), DX (Y center) -----
draw_fuel_tank:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; Center the sprite
    sub bx, 6               ; X center (12/2 = 6) - CHANGED
    sub dx, 6         
    
    ; Check if completely off-screen
    cmp dx, SCREEN_HEIGHT
    jge .done
    mov ax, dx
    add ax, FUEL_TANK_HEIGHT
    cmp ax, 20              ; Above title bar
    jl .done
    
    mov si, fuel_tank_sprite  ; SI = sprite data pointer
    mov di, dx                ; DI = current Y
    mov bp, FUEL_TANK_HEIGHT  ; BP = row counter
    
.row_loop:
    cmp bp, 0
    je .done
    
    ; Check if this row is visible
    cmp di, 20
    jl .skip_row
    cmp di, SCREEN_HEIGHT
    jge .done
    
    ; Draw this row
    push bx                   ; Save start X
    mov cx, FUEL_TANK_WIDTH   ; CX = column counter
    
.col_loop:
    cmp cx, 0
    je .next_row
    
    ; Get pixel color
    lodsb                     ; AL = [SI], SI++
    
    ; Check for transparency
    cmp al, 255
    je .skip_pixel
    
    ; Check X bounds
    cmp bx, 0
    jl .skip_pixel
    cmp bx, SCREEN_WIDTH
    jge .skip_pixel
    
    ; Draw pixel
    push bx
    push cx
    push dx
    mov cx, bx              ; X coordinate
    mov dx, di              ; Y coordinate
    call put_pixel
    pop dx
    pop cx
    pop bx
    
.skip_pixel:
    inc bx                  ; Next X
    dec cx
    jmp .col_loop
    
.next_row:
    pop bx                  ; Restore start X
    inc di                  ; Next Y
    dec bp
    jmp .row_loop
    
.skip_row:
    ; Skip entire row in sprite data
    add si, FUEL_TANK_WIDTH
    inc di
    dec bp
    jmp .row_loop
    
.done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ----- CLEAR FUEL TANK AREA -----
clear_fuel_tank_area:
    push ax
    push cx
    push dx
    push si
    push di
    
    mov si, bx
    mov di, dx
    sub si, 6               ; X offset (12/2) - CHANGED
    sub di, 6               ; Y offset (12/2) - CHANGED
    
    cmp di, SCREEN_HEIGHT + 12  ; CHANGED
    jge .done
    cmp di, -12             ; CHANGED
    jl .done
    
    mov ax, 12              ; Height - CHANGED
.row_loop:
    push ax
    
    cmp di, 20
    jl .next_row
    cmp di, SCREEN_HEIGHT
    jge .done_pop
    
    mov cx, si
    mov bx, 12              ; Width - CHANGED
.col_loop:
    push cx
    push bx
    mov dx, di
    mov al, COLOR_GRAY
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

; ----- CHECK SPAWN FUEL TANK -----
check_spawn_fuel_tank:
    push ax
    push bx
    push dx
    
    cmp word [fuel_tank_timer], FUEL_TANK_SPAWN_TIME
    jl .done
    
    mov word [fuel_tank_timer], 0
    
    cmp byte [fuel_tank_count], 3
    jge .done
    
    xor bx, bx
.find_slot:
    cmp bx, 3
    jge .done
    
    cmp byte [fuel_tank_active + bx], 0
    je .spawn_here
    
    inc bx
    jmp .find_slot
    
.spawn_here:
    call get_free_lane
    cmp al, 0xFF
    je .done
    
    mov byte [fuel_tank_active + bx], 1
    inc byte [fuel_tank_count]
    
    cmp al, 0
    je .lane_left
    cmp al, 1
    je .lane_middle
    mov ax, LANE3_CENTER
    jmp .set_x
.lane_left:
    mov ax, LANE1_CENTER
    jmp .set_x
.lane_middle:
    mov ax, LANE2_CENTER
    
.set_x:
    shl bx, 1
    mov [fuel_tank_x + bx], ax
    mov word [fuel_tank_y + bx], -10
    mov word [fuel_tank_old_y + bx], -10
    
.done:
    pop dx
    pop bx
    pop ax
    ret


; ----- CHECK FUEL TANK COLLISION -----
check_fuel_tank_collision:
    push ax
    push cx
    push dx
    push si
    push di
    
    cmp byte [fuel_tank_active + bx], 0
    je .no_collision
    
    push bx
    shl bx, 1
    mov ax, [fuel_tank_x + bx]
    mov dx, [fuel_tank_y + bx]
    shr bx, 1
    
    sub ax, 6
    sub dx, 8
    
    mov si, [player_x]
    mov di, [player_y]
    
    mov cx, ax
    add cx, 12
    cmp cx, si
    jl .no_collision_pop
    
    mov cx, si
    add cx, CAR_WIDTH
    cmp cx, ax
    jl .no_collision_pop
    
    mov cx, dx
    add cx, 16
    cmp cx, di
    jl .no_collision_pop
    
    mov cx, di
    add cx, CAR_HEIGHT
    cmp cx, dx
    jl .no_collision_pop
    
    pop bx
    call handle_fuel_tank_collection
    jmp .done
    
.no_collision_pop:
    pop bx
.no_collision:
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret


; ----- HANDLE FUEL TANK COLLECTION -----
handle_fuel_tank_collection:
    push ax
    push bx
    push dx
    
    mov byte [fuel_tank_active + bx], 0
    dec byte [fuel_tank_count]
    
    ; Add fuel (increase by 1)
    add word [fuel], 1
    
    ; Clear from screen
    push bx
    shl bx, 1
    mov ax, [fuel_tank_x + bx]
    mov dx, [fuel_tank_y + bx]
    shr bx, 1
    
    push bx
    mov bx, ax
    call clear_fuel_tank_area
    pop bx
    pop bx
    
    pop dx
    pop bx
    pop ax
    ret


; ==================== PLAYER MOVEMENT SYSTEM ====================

; ----- MOVE PLAYER LEFT -----
move_player_left:
    push ax
    push bx
    push dx
    
    ; Check if already in leftmost lane
    cmp byte [player_lane], 0
    je .done
    
    ; Clear old position
    mov bx, [player_x]
    mov dx, [player_y]
    call clear_car_area
    
    ; Move to previous lane
    dec byte [player_lane]
    
    ; Update X position based on lane
    mov al, [player_lane]
    call calculate_lane_x
    mov [player_x], ax
    
.done:
    pop dx
    pop bx
    pop ax
    ret


; ----- MOVE PLAYER RIGHT -----
move_player_right:
    push ax
    push bx
    push dx
    
    ; Check if already in rightmost lane
    cmp byte [player_lane], 2
    je .done
    
    ; Clear old position
    mov bx, [player_x]
    mov dx, [player_y]
    call clear_car_area
    
    ; Move to next lane
    inc byte [player_lane]
    
    ; Update X position based on lane
    mov al, [player_lane]
    call calculate_lane_x
    mov [player_x], ax
    
.done:
    pop dx
    pop bx
    pop ax
    ret


; ----- MOVE PLAYER UP -----
move_player_up:
    push ax
    push bx
    push dx
    
    ; Check if already at top (below title bar)
    cmp word [player_y], 25
    jle .done
    
    ; Clear old position
    mov bx, [player_x]
    mov dx, [player_y]
    call clear_car_area
    
    ; Move up by CAR_HEIGHT pixels (one block)
    sub word [player_y], CAR_HEIGHT
    
    ; Ensure we don't go too high
    cmp word [player_y], 25
    jge .done
    mov word [player_y], 25
    
.done:
    pop dx
    pop bx
    pop ax
    ret


; ----- MOVE PLAYER DOWN -----
move_player_down:
    push ax
    push bx
    push dx
    
    ; Calculate maximum Y position (screen height - car height)
    mov ax, SCREEN_HEIGHT
    sub ax, CAR_HEIGHT
    
    ; Check if already at bottom
    cmp word [player_y], ax
    jge .done
    
    ; Clear old position
    mov bx, [player_x]
    mov dx, [player_y]
    call clear_car_area
    
    ; Move down by CAR_HEIGHT pixels (one block)
    add word [player_y], CAR_HEIGHT
    
    ; Ensure we don't go too low
    mov ax, SCREEN_HEIGHT
    sub ax, CAR_HEIGHT
    cmp word [player_y], ax
    jle .done
    mov word [player_y], ax
    
.done:
    pop dx
    pop bx
    pop ax
    ret


; ----- CALCULATE X POSITION FROM LANE NUMBER -----
; Input: AL = lane number (0, 1, 2)
; Output: AX = X position (centered)
calculate_lane_x:
    push bx
    
    cmp al, 0
    je .lane0
    cmp al, 1
    je .lane1
    ; Lane 2
    mov ax, LANE3_CENTER
    jmp .center_car
    
.lane0:
    mov ax, LANE1_CENTER
    jmp .center_car
    
.lane1:
    mov ax, LANE2_CENTER
    
.center_car:
    ; Center the car in lane 
    sub ax, 9
    
    pop bx
    ret




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


; ----- DRAW TWO DASHED WHITE LANE DIVIDER LINES -----
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

    ; Check if game has started
    cmp byte [game_started], 0
    jne .show_normal_title
    
    ; Show start message
    mov ah, 0x13              ; Write string function
    mov al, 0x01               
    mov bh, 0                
    mov bl, 0x0F              ; white text
    mov cx, 22                ; String length
    mov dh, 1                 ; Row 
    mov dl, 9                 ; Column
    push cs
    pop es
    mov bp, start_message
    int 0x10
    jmp .done_text

.show_normal_title:
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

.done_text:
    pop es
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
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


; ----- DRAW RED PLAYER CAR -----
draw_player_car:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov bx, [player_x]        ; Dynamic X position
    mov si, [player_y]        ; Dynamic Y position
    mov dx, si                ; Current Y for drawing
    mov di, bx                ; Save starting X in DI
    
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
    mov ax, 2
.rows1_2:
    push ax
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
    mov al, COLOR_RED
    call put_pixel
    pop cx
    inc bx
    loop .row3_4_col
    pop bx
    inc dx
    pop ax
    dec ax
    jnz .rows3_4

    ; Rows 5-8 - windshield area (body with window)
    mov ax, 4
.rows5_8:
    push ax
    mov cx, 18
    push bx
.row5_8_col:
    push cx
    mov cx, bx
    push bx
    sub bx, di                ; use DI (starting X) 
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
    pop ax
    dec ax
    jnz .rows5_8

    ; Rows 9-23 - full body (18 pixels)
    mov ax, 15
.rows9_23:
    push ax
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
    pop ax
    dec ax
    jnz .rows9_23

    ; Rows 24-27 - body with tires (18 pixels)
    mov ax, 4
.rows24_27:
    push ax
    mov cx, 18
    push bx
.row24_27_col:
    push cx
    mov cx, bx
    push bx
    sub bx, di                ; use DI (starting X)
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


; ----- DRAW CAR ON MAIN SCREEN -----
draw_car:
    push ax
    push bx
    push cx
    push dx

    mov word [startX], 125
    mov word [startY], 55

    ; Windshield (top dark part) - 40x8 pixels
    mov bx, [startX]
    add bx, 15
    mov dx, [startY]
    add dx, 5
    mov cx, 40
    mov ax, 8
    mov byte [color], COLOR_WINDSHIELD_TOP
    call draw_rect

    ; Windshield (main part) - 46x15 pixels
    mov bx, [startX]
    add bx, 12
    mov dx, [startY]
    add dx, 13
    mov cx, 46
    mov ax, 15
    mov byte [color], COLOR_WINDSHIELD
    call draw_rect

    ; Hood (top red part) - 54x6 pixels
    mov bx, [startX]
    add bx, 8
    mov dx, [startY]
    add dx, 28
    mov cx, 54
    mov ax, 6
    mov byte [color], COLOR_DARK_RED
    call draw_rect

    ; Main body - 60x18 pixels
    mov bx, [startX]
    add bx, 5
    mov dx, [startY]
    add dx, 34
    mov cx, 60
    mov ax, 18
    mov byte [color], COLOR_RED
    call draw_rect

    ; Side mirror (left) - 5x6 pixels
    mov bx, [startX]
    mov dx, [startY]
    add dx, 38
    mov cx, 5
    mov ax, 6
    mov byte [color], COLOR_RED
    call draw_rect

    ; Side mirror (right) - 5x6 pixels
    mov bx, [startX]
    add bx, 65
    mov dx, [startY]
    add dx, 38
    mov cx, 5
    mov ax, 6
    mov byte [color], COLOR_RED
    call draw_rect

    ; Headlight (left outer) - 12x6 pixels
    mov bx, [startX]
    add bx, 8
    mov dx, [startY]
    add dx, 42
    mov cx, 12
    mov ax, 6
    mov byte [color], COLOR_WHITE
    call draw_rect

    ; Headlight (left inner) - 10x4 pixels
    mov bx, [startX]
    add bx, 9
    mov dx, [startY]
    add dx, 43
    mov cx, 10
    mov ax, 4
    mov byte [color], COLOR_LIGHT_GRAY
    call draw_rect

    ; Headlight (right outer) - 12x6 pixels
    mov bx, [startX]
    add bx, 50
    mov dx, [startY]
    add dx, 42
    mov cx, 12
    mov ax, 6
    mov byte [color], COLOR_WHITE
    call draw_rect

    ; Headlight (right inner) - 10x4 pixels
    mov bx, [startX]
    add bx, 51
    mov dx, [startY]
    add dx, 43
    mov cx, 10
    mov ax, 4
    mov byte [color], COLOR_LIGHT_GRAY
    call draw_rect

    ; Front grille - 22x8 pixels
    mov bx, [startX]
    add bx, 24
    mov dx, [startY]
    add dx, 42
    mov cx, 22
    mov ax, 8
    mov byte [color], COLOR_BLACK
    call draw_rect

    ; Grille detail line 1
    mov bx, [startX]
    add bx, 25
    mov dx, [startY]
    add dx, 43
    mov cx, 20
    mov ax, 1
    mov byte [color], COLOR_GRILL_GRAY
    call draw_rect

    ; Grille detail line 2
    mov bx, [startX]
    add bx, 25
    mov dx, [startY]
    add dx, 45
    mov cx, 20
    mov ax, 1
    mov byte [color], COLOR_GRILL_GRAY
    call draw_rect

    ; Grille detail line 3
    mov bx, [startX]
    add bx, 25
    mov dx, [startY]
    add dx, 47
    mov cx, 20
    mov ax, 1
    mov byte [color], COLOR_GRILL_GRAY
    call draw_rect

    ; License plate area - 14x3 pixels
    mov bx, [startX]
    add bx, 28
    mov dx, [startY]
    add dx, 51
    mov cx, 14
    mov ax, 3
    mov byte [color], COLOR_BLACK
    call draw_rect

    ; Bumper - 54x3 pixels
    mov bx, [startX]
    add bx, 8
    mov dx, [startY]
    add dx, 52
    mov cx, 54
    mov ax, 3
    mov byte [color], COLOR_DARK_RED
    call draw_rect

    ; Wheel (left) - 12x8 pixels
    mov bx, [startX]
    add bx, 8
    mov dx, [startY]
    add dx, 55
    mov cx, 12
    mov ax, 8
    mov byte [color], COLOR_BLACK
    call draw_rect

    ; Wheel center (left) - 8x4 pixels
    mov bx, [startX]
    add bx, 10
    mov dx, [startY]
    add dx, 57
    mov cx, 8
    mov ax, 4
    mov byte [color], COLOR_DARK_GRAY
    call draw_rect

    ; Wheel (right) - 12x8 pixels
    mov bx, [startX]
    add bx, 50
    mov dx, [startY]
    add dx, 55
    mov cx, 12
    mov ax, 8
    mov byte [color], COLOR_BLACK
    call draw_rect

    ; Wheel center (right) - 8x4 pixels
    mov bx, [startX]
    add bx, 52
    mov dx, [startY]
    add dx, 57
    mov cx, 8
    mov ax, 4
    mov byte [color], COLOR_DARK_GRAY
    call draw_rect

    ; Wheel well shadow (left) - 3x4 pixels
    mov bx, [startX]
    add bx, 5
    mov dx, [startY]
    add dx, 54
    mov cx, 3
    mov ax, 4
    mov byte [color], COLOR_BLACK
    call draw_rect

    ; Wheel well shadow (right) - 3x4 pixels
    mov bx, [startX]
    add bx, 62
    mov dx, [startY]
    add dx, 54
    mov cx, 3
    mov ax, 4
    mov byte [color], COLOR_BLACK
    call draw_rect

    ; Body shine/highlight (left) - 25x2 pixels
    mov bx, [startX]
    add bx, 10
    mov dx, [startY]
    add dx, 36
    mov cx, 25
    mov ax, 2
    mov byte [color], COLOR_LIGHT_RED
    call draw_rect

    ; Body shine/highlight (right) - 15x2 pixels
    mov bx, [startX]
    add bx, 45
    mov dx, [startY]
    add dx, 36
    mov cx, 15
    mov ax, 2
    mov byte [color], COLOR_LIGHT_RED
    call draw_rect

    ; Windshield reflection (left) - 8x2 pixels
    mov bx, [startX]
    add bx, 14
    mov dx, [startY]
    add dx, 15
    mov cx, 8
    mov ax, 2
    mov byte [color], COLOR_WINDSHIELD_TOP
    call draw_rect

    ; Windshield reflection (right) - 8x2 pixels
    mov bx, [startX]
    add bx, 48
    mov dx, [startY]
    add dx, 15
    mov cx, 8
    mov ax, 2
    mov byte [color], COLOR_WINDSHIELD_TOP
    call draw_rect

    pop dx
    pop cx
    pop bx
    pop ax
    ret




; ==================== OBJECT RENDERING ====================

; ----- DRAW ALL ACTIVE OBSTACLES -----
draw_obstacles:
    push ax
    push bx
    push cx
    push dx
    
    xor bx, bx
.loop:
    cmp bx, 3
    jge   .done
    
    ; Check if active
    cmp byte [obstacle_active + bx], 0
    je   .next
    
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
    jmp   .loop
    
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
    mov di, dx                ; Save Y (starting Y)
    
    ; Check if car is completely off-screen
    cmp di, SCREEN_HEIGHT
    jge .done_early           ; Completely below screen
    
    mov dx, di                ; Current Y for drawing
    
    ; Draw all rows
    call .draw_row0
    call .draw_rows1_2
    call .draw_rows3_4
    call .draw_rows5_8
    call .draw_rows9_23
    call .draw_rows24_27
    
.done_early:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret

; Helper: Draw row 0
.draw_row0:
    push ax
    push bx
    push cx
    
    mov cx, 12
    mov bx, si
    add bx, 3
.row0_loop:
    cmp dx, 20
    jl .row0_skip
    cmp dx, SCREEN_HEIGHT
    jge .row0_skip
    
    push cx
    mov cx, bx
    mov al, COLOR_BLUE
    call put_pixel
    pop cx
.row0_skip:
    inc bx
    loop .row0_loop
    inc dx
    
    pop cx
    pop bx
    pop ax
    ret

; Helper: Draw rows 1-2
.draw_rows1_2:
    push ax
    push bx
    push cx
    
    mov ax, 2
.outer1_2:
    push ax
    mov cx, 14
    mov bx, si
    add bx, 2
.col1_2:
    cmp dx, 20
    jl .skip1_2
    cmp dx, SCREEN_HEIGHT
    jge .skip1_2
    
    push cx
    mov cx, bx
    mov al, COLOR_BLUE
    call put_pixel
    pop cx
.skip1_2:
    inc bx
    loop .col1_2
    inc dx
    pop ax
    dec ax
    jnz .outer1_2
    
    pop cx
    pop bx
    pop ax
    ret

; Helper: Draw rows 3-4
.draw_rows3_4:
    push ax
    push bx
    push cx
    
    mov ax, 2
.outer3_4:
    push ax
    mov cx, 18
    mov bx, si
.col3_4:
    cmp dx, 20
    jl .skip3_4
    cmp dx, SCREEN_HEIGHT
    jge .skip3_4
    
    push cx
    mov cx, bx
    mov al, COLOR_BLUE
    call put_pixel
    pop cx
.skip3_4:
    inc bx
    loop .col3_4
    inc dx
    pop ax
    dec ax
    jnz .outer3_4
    
    pop cx
    pop bx
    pop ax
    ret

; Helper: Draw rows 5-8 (windshield)
.draw_rows5_8:
    push ax
    push bx
    push cx
    
    mov ax, 4
.outer5_8:
    push ax
    mov cx, 18
    mov bx, si
.col5_8:
    cmp dx, 20
    jl .skip5_8
    cmp dx, SCREEN_HEIGHT
    jge .skip5_8
    
    push cx
    push bx
    sub bx, si
    cmp bx, 3
    jl .blue5_8
    cmp bx, 15
    jge .blue5_8
    mov al, COLOR_BLACK
    jmp .draw5_8
.blue5_8:
    mov al, COLOR_BLUE
.draw5_8:
    pop bx
    mov cx, bx
    call put_pixel
    pop cx
.skip5_8:
    inc bx
    loop .col5_8
    inc dx
    pop ax
    dec ax
    jnz .outer5_8
    
    pop cx
    pop bx
    pop ax
    ret

; Helper: Draw rows 9-23 (body)
.draw_rows9_23:
    push ax
    push bx
    push cx
    
    mov ax, 15
.outer9_23:
    push ax
    mov cx, 18
    mov bx, si
.col9_23:
    cmp dx, 20
    jl .skip9_23
    cmp dx, SCREEN_HEIGHT
    jge .skip9_23
    
    push cx
    mov cx, bx
    mov al, COLOR_BLUE
    call put_pixel
    pop cx
.skip9_23:
    inc bx
    loop .col9_23
    inc dx
    pop ax
    dec ax
    jnz .outer9_23
    
    pop cx
    pop bx
    pop ax
    ret

; Helper: Draw rows 24-27 (tires)
.draw_rows24_27:
    push ax
    push bx
    push cx
    
    mov ax, 4
.outer24_27:
    push ax
    mov cx, 18
    mov bx, si
.col24_27:
    cmp dx, 20
    jl .skip24_27
    cmp dx, SCREEN_HEIGHT
    jge .skip24_27
    
    push cx
    push bx
    sub bx, si
    cmp bx, 4
    jge .check_r24_27
    mov al, COLOR_BLACK
    jmp .draw24_27
.check_r24_27:
    cmp bx, 14
    jl .body24_27
    mov al, COLOR_BLACK
    jmp .draw24_27
.body24_27:
    mov al, COLOR_BLUE
.draw24_27:
    pop bx
    mov cx, bx
    call put_pixel
    pop cx
.skip24_27:
    inc bx
    loop .col24_27
    inc dx
    pop ax
    dec ax
    jnz .outer24_27
    
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
    jge   .done
    
    ; Check if active
    cmp byte [coin_active + bx], 0
    je   .next
    
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
    jmp   .loop
    
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
    
    ; Check if coin is completely off-screen
    cmp di, SCREEN_HEIGHT + 10
    jge .done_early
    
    ; Calculate top-left corner
    sub si, 5
    sub di, 5
    
    mov dx, di                ; Current Y for drawing
    
    ; Draw all rows using helper routines
    call .draw_coin_row0
    call .draw_coin_row1
    call .draw_coin_rows2_3
    call .draw_coin_rows4_5
    call .draw_coin_rows6_7
    call .draw_coin_row8
    call .draw_coin_row9
    
.done_early:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret

; Helper: Draw coin row 0 (4 pixels white highlight)
.draw_coin_row0:
    push ax
    push bx
    push cx
    
    mov cx, si
    add cx, 3
    mov bx, 4
.r0_loop:
    cmp dx, 20
    jl .r0_skip
    cmp dx, SCREEN_HEIGHT
    jge .r0_skip
    
    push cx
    push bx
    mov al, COLOR_WHITE
    call put_pixel
    pop bx
    pop cx
.r0_skip:
    inc cx
    dec bx
    jnz .r0_loop
    inc dx
    
    pop cx
    pop bx
    pop ax
    ret

; Helper: Draw coin row 1 (1 white + 5 yellow)
.draw_coin_row1:
    push ax
    push bx
    push cx
    
    ; 1 white pixel
    mov cx, si
    add cx, 2
    cmp dx, 20
    jl .r1_skip_white
    cmp dx, SCREEN_HEIGHT
    jge .r1_skip_white
    
    push cx
    mov al, COLOR_WHITE
    call put_pixel
    pop cx
    
.r1_skip_white:
    inc cx
    
    ; 5 yellow pixels
    mov bx, 5
.r1_yellow_loop:
    cmp dx, 20
    jl .r1_skip_yellow
    cmp dx, SCREEN_HEIGHT
    jge .r1_skip_yellow
    
    push cx
    push bx
    mov al, COLOR_YELLOW
    call put_pixel
    pop bx
    pop cx
.r1_skip_yellow:
    inc cx
    dec bx
    jnz .r1_yellow_loop
    inc dx
    
    pop cx
    pop bx
    pop ax
    ret

; Helper: Draw coin rows 2-3 (8 yellow pixels each)
.draw_coin_rows2_3:
    push ax
    push bx
    push cx
    
    mov ax, 2
.r2_3_outer:
    push ax
    mov cx, si
    add cx, 1
    mov bx, 8
.r2_3_loop:
    cmp dx, 20
    jl .r2_3_skip
    cmp dx, SCREEN_HEIGHT
    jge .r2_3_skip
    
    push cx
    push bx
    mov al, COLOR_YELLOW
    call put_pixel
    pop bx
    pop cx
.r2_3_skip:
    inc cx
    dec bx
    jnz .r2_3_loop
    inc dx
    pop ax
    dec ax
    jnz .r2_3_outer
    
    pop cx
    pop bx
    pop ax
    ret

; Helper: Draw coin rows 4-5 (7 yellow + 1 orange)
.draw_coin_rows4_5:
    push ax
    push bx
    push cx
    
    mov ax, 2
.r4_5_outer:
    push ax
    mov cx, si
    add cx, 1
    
    ; 7 yellow pixels
    mov bx, 7
.r4_5_yellow:
    cmp dx, 20
    jl .r4_5_skip_y
    cmp dx, SCREEN_HEIGHT
    jge .r4_5_skip_y
    
    push cx
    push bx
    mov al, COLOR_YELLOW
    call put_pixel
    pop bx
    pop cx
.r4_5_skip_y:
    inc cx
    dec bx
    jnz .r4_5_yellow
    
    ; 1 orange pixel
    cmp dx, 20
    jl .r4_5_skip_o
    cmp dx, SCREEN_HEIGHT
    jge .r4_5_skip_o
    
    push cx
    mov al, COLOR_ORANGE
    call put_pixel
    pop cx
    
.r4_5_skip_o:
    inc dx
    pop ax
    dec ax
    jnz .r4_5_outer
    
    pop cx
    pop bx
    pop ax
    ret

; Helper: Draw coin rows 6-7 (5 yellow + 3 orange)
.draw_coin_rows6_7:
    push ax
    push bx
    push cx
    
    mov ax, 2
.r6_7_outer:
    push ax
    mov cx, si
    add cx, 1
    
    ; 5 yellow pixels
    mov bx, 5
.r6_7_yellow:
    cmp dx, 20
    jl .r6_7_skip_y
    cmp dx, SCREEN_HEIGHT
    jge .r6_7_skip_y
    
    push cx
    push bx
    mov al, COLOR_YELLOW
    call put_pixel
    pop bx
    pop cx
.r6_7_skip_y:
    inc cx
    dec bx
    jnz .r6_7_yellow
    
    ; 3 orange pixels
    mov bx, 3
.r6_7_orange:
    cmp dx, 20
    jl .r6_7_skip_o
    cmp dx, SCREEN_HEIGHT
    jge .r6_7_skip_o
    
    push cx
    push bx
    mov al, COLOR_ORANGE
    call put_pixel
    pop bx
    pop cx
.r6_7_skip_o:
    inc cx
    dec bx
    jnz .r6_7_orange
    
    inc dx
    pop ax
    dec ax
    jnz .r6_7_outer
    
    pop cx
    pop bx
    pop ax
    ret

; Helper: Draw coin row 8 (3 yellow + 3 orange)
.draw_coin_row8:
    push ax
    push bx
    push cx
    
    mov cx, si
    add cx, 2
    
    ; 3 yellow pixels
    mov bx, 3
.r8_yellow:
    cmp dx, 20
    jl .r8_skip_y
    cmp dx, SCREEN_HEIGHT
    jge .r8_skip_y
    
    push cx
    push bx
    mov al, COLOR_YELLOW
    call put_pixel
    pop bx
    pop cx
.r8_skip_y:
    inc cx
    dec bx
    jnz .r8_yellow
    
    ; 3 orange pixels
    mov bx, 3
.r8_orange:
    cmp dx, 20
    jl .r8_skip_o
    cmp dx, SCREEN_HEIGHT
    jge .r8_skip_o
    
    push cx
    push bx
    mov al, COLOR_ORANGE
    call put_pixel
    pop bx
    pop cx
.r8_skip_o:
    inc cx
    dec bx
    jnz .r8_orange
    inc dx
    
    pop cx
    pop bx
    pop ax
    ret

; Helper: Draw coin row 9 (4 orange pixels - bottom)
.draw_coin_row9:
    push ax
    push bx
    push cx
    
    mov cx, si
    add cx, 3
    mov bx, 4
.r9_loop:
    cmp dx, 20
    jl .r9_skip
    cmp dx, SCREEN_HEIGHT
    jge .r9_skip
    
    push cx
    push bx
    mov al, COLOR_ORANGE
    call put_pixel
    pop bx
    pop cx
.r9_skip:
    inc cx
    dec bx
    jnz .r9_loop
    inc dx
    
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
    jge   .done
    
    ; Check if active
    cmp byte [obstacle_active + bx], 0
    je   .next
    
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
    jmp   .loop
    
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
    jge   .done
    
    ; Check if active
    cmp byte [coin_active + bx], 0
    je   .next
    
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
    jmp   .loop
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; ----- Clear a car-sized area (18x28) at BX (X), DX (Y) -----
; Around line 1194 in clear_car_area:
clear_car_area:
    push ax
    push cx
    push dx
    push si
    push di
    
    mov si, bx                ; Save X
    mov di, dx                ; Save Y
    
    ; Skip if completely off-screen
    cmp di, SCREEN_HEIGHT + 28
    jge .done
    cmp di, -28
    jl .done
    
    ; Clear 28 rows
    mov ax, 28
.row_loop:
    push ax
    
    ; Check if this row is visible (not in title bar, not off bottom)
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
    cmp di, SCREEN_HEIGHT + 16
    jge .done
    cmp di, -16
    jl .done
    
    ; Clear 16 rows
    mov ax, 16
.row_loop:
    push ax
    
    ; Check if this row is visible (not in title bar, not off bottom)
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




; ==================== OBJECT MANAGEMENT ====================

; ------ UPDATE OBSTACLE POSITIONS (move them down) -----
update_obstacles:
    push ax
    push bx
    push cx
    
    xor bx, bx
.loop:
    cmp bx, 3
    jge   .done
    
    ; Check if active
    cmp byte [obstacle_active + bx], 0
    je   .next
    
    ; Get Y position
    push bx
    shl bx, 1
    
    ; Save old Y
    mov ax, [obstacle_y + bx]
    mov [obstacle_old_y + bx], ax
    
    ; Move down by SCROLL_SPEED pixels
    add ax, SCROLL_SPEED
    
    ; Check if off screen
    cmp ax, SCREEN_HEIGHT
    jl   .keep
    
    ; Deactivate this obstacle
    shr bx, 1
    mov byte [obstacle_active + bx], 0
    dec byte [obstacle_count]
    pop bx
    jmp   .next
    
.keep:
    mov [obstacle_y + bx], ax
    shr bx, 1
    
    ; Check if off screen at BOTTOM (fade-out complete)
    cmp ax, SCREEN_HEIGHT + 15     ; Add buffer for car height
    jge .deactivate_now
    
    pop bx
    jmp .next
    
.deactivate_now:
    mov byte [obstacle_active + bx], 0
    dec byte [obstacle_count]
    pop bx
    jmp .next
    
.next:
    inc bx
    jmp   .loop
    
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
    jge   .done
    
    ; Check if active
    cmp byte [coin_active + bx], 0
    je   .next
    
    ; Get Y position
    push bx
    shl bx, 1
    
    ; Save old Y
    mov ax, [coin_y + bx]
    mov [coin_old_y + bx], ax
    
    ; Move down by SCROLL_SPEED pixels
    add ax, SCROLL_SPEED
    
    ; Check if completely off screen (add buffer for coin size)
    cmp ax, SCREEN_HEIGHT + 15
    jl   .keep
    
    ; Deactivate this coin
    shr bx, 1
    mov byte [coin_active + bx], 0
    dec byte [coin_count]
    pop bx
    jmp   .next
    
.keep:
    mov [coin_y + bx], ax
    shr bx, 1
    
    ; Check if completely off screen at BOTTOM (add buffer for coin size)
    cmp ax, SCREEN_HEIGHT + 20     ; Add buffer beyond screen
    jge .deactivate_now
    
    pop bx
    jmp .next

.deactivate_now:
    mov byte [coin_active + bx], 0
    dec byte [coin_count]
    pop bx
    jmp .next
    
.next:
    inc bx
    jmp   .loop
    
.done:
    pop cx
    pop bx
    pop ax
    ret


; ----- Check if it's time to spawn a new obstacle -----
check_spawn_obstacle:
    push ax
    push bx
    push dx
    
    ; Check spawn timer (spawn every 50 frames)
    cmp word [spawn_timer], OBSTACLE_SPAWN_TIME
    jl   .done
    
    ; Reset timer
    mov word [spawn_timer], 0
    
    ; Check if we already have max obstacles (3)
    cmp byte [obstacle_count], 3
    jge   .done
    
    ; Find empty slot
    xor bx, bx
.find_slot:
    cmp bx, 3
    jge   .done
    
    cmp byte [obstacle_active + bx], 0
    je   .spawn_here
    
    inc bx
    jmp   .find_slot
    
.spawn_here:
    ; Get random lane that doesn't have an obstacle OR coin
    call get_free_lane
    cmp al, 0xFF
    je   .done                  ; No free lane
    
    ; Mark as active
    mov byte [obstacle_active + bx], 1
    inc byte [obstacle_count]
    
    ; Calculate X position based on lane
    cmp al, 0
    je   .lane_left
    cmp al, 1
    je   .lane_middle
    ; Lane right
    mov ax, LANE3_CENTER
    jmp   .set_x
.lane_left:
    mov ax, LANE1_CENTER
    jmp   .set_x
.lane_middle:
    mov ax, LANE2_CENTER
    
.set_x:
    ; Center the car in lane
    sub ax, 9                           ; Half of car width
    
    ; Store position
    shl bx, 1                           ; BX * 2 for word array
    mov [obstacle_x + bx], ax
    mov word [obstacle_y + bx], SPAWN_Y_POSITION        ; Start position
    mov word [obstacle_old_y + bx], SPAWN_Y_POSITION    ; Initialize old position
    
.done:
    pop dx
    pop bx
    pop ax
    ret


; ----- Check if it's time to spawn a new coin -----
check_spawn_coin:
    push ax
    push bx
    push dx
    
    ; Check coin timer (spawn every 35 frames)
    cmp word [coin_timer], COIN_SPAWN_TIME
    jl   .done
    
    ; Reset timer
    mov word [coin_timer], 0
    
    ; Check if we already have max coins (5)
    cmp byte [coin_count], 5
    jge   .done
    
    ; Find empty slot
    xor bx, bx
.find_slot:
    cmp bx, 5
    jge   .done
    
    cmp byte [coin_active + bx], 0
    je   .spawn_here
    
    inc bx
    jmp   .find_slot
    
.spawn_here:
    ; Get random lane that doesn't have an obstacle OR coin
    call get_free_lane
    cmp al, 0xFF
    je   .done                  ; No free lane
    
    ; Mark as active
    mov byte [coin_active + bx], 1
    inc byte [coin_count]
    
    ; Calculate X position based on lane (al = 0, 1, or 2)
    cmp al, 0
    je   .lane_left
    cmp al, 1
    je   .lane_middle
    ; Lane right
    mov ax, LANE3_CENTER
    jmp   .set_x
.lane_left:
    mov ax, LANE1_CENTER
    jmp   .set_x
.lane_middle:
    mov ax, LANE2_CENTER
    
.set_x:
    ; Coin X position is already the lane center 
    ; Store position
    shl bx, 1
    mov [coin_x + bx], ax           ; Store exact lane center
    mov word [coin_y + bx], SPAWN_Y_POSITION    
    mov word [coin_old_y + bx], SPAWN_Y_POSITION
    
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
    je   .found_free
    
    ; Try next lane
    inc al
    cmp al, 3
    jl   .no_wrap
    xor al, al
.no_wrap:
    dec cl
    jnz   .try_lane
    
    ; No free lane found
    mov al, 0xFF
    jmp   .done
    
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
    je   .lane0
    cmp al, 1
    je   .lane1
    mov ax, LANE3_CENTER
    jmp   .check
.lane0:
    mov ax, LANE1_CENTER
    jmp   .check
.lane1:
    mov ax, LANE2_CENTER
    
.check:
    mov cx, ax                ; CX = lane center
    
    ; Check all obstacles
    xor bx, bx
.loop_obstacles:
    cmp bx, 3
    jge   .check_coins
    
    ; Check if active
    cmp byte [obstacle_active + bx], 0
    je   .next_obstacle
    
    ; Get obstacle X
    push bx
    shl bx, 1
    mov ax, [obstacle_x + bx]
    
    ; Check Y position (only check if obstacle is   spawn area)
    mov dx, [obstacle_y + bx]
    shr bx, 1
    
    cmp dx, SPAWN_CHECK_THRESHOLD             ; Only check if in upper half of screen
    jg   .next_obstacle_pop
    
    ; Check if in same lane (within 30 pixels)
    sub ax, cx
    cmp ax, -LANE_CHECK_DISTANCE   
    jl   .next_obstacle_pop
    cmp ax, LANE_CHECK_DISTANCE
    jg   .next_obstacle_pop
    
    ; Obstacle in this lane
    pop bx
    mov dl, 0
    jmp   .done
    
.next_obstacle_pop:
    pop bx
.next_obstacle:
    inc bx
    jmp   .loop_obstacles
    
.check_coins:
    ; Check all coins
    xor bx, bx
.loop_coins:
    cmp bx, 5
    jge   .is_free
    
    ; Check if active
    cmp byte [coin_active + bx], 0
    je   .next_coin
    
    ; Get coin X
    push bx
    shl bx, 1
    mov ax, [coin_x + bx]
    
    ; Check Y position (only check if coin is   spawn area)
    mov dx, [coin_y + bx]
    shr bx, 1
    
    cmp dx, 100               ; Only check if in upper half of screen
    jg   .next_coin_pop
    
    ; Check if in same lane (within 20 pixels for coins)
    sub ax, cx
    cmp ax, -20
    jl   .next_coin_pop
    cmp ax, 20
    jg   .next_coin_pop
    
    ; Coin in this lane
    pop bx
    mov dl, 0
    jmp   .done
    
.next_coin_pop:
    pop bx
.next_coin:
    inc bx
    jmp   .loop_coins
    
.is_free:
    mov dl, 1
    
.done:
    pop cx
    pop bx
    pop ax
    ret




; ==================== PAUSE/CONFIRMATION SYSTEM ====================

; ----- SHOW CONFIRMATION SCREEN -----
show_confirmation_screen:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push es
    
    ; Draw confirmation box (this will overlay the game, but game objects stay)
    call draw_confirmation_box
    
    ; Set up ES for BIOS string functions
    push cs
    pop es
    
    ; Message 1: "Do you want to quit?"
    mov ah, 0x13              ; Write string function
    mov al, 0x01              ; Update cursor
    mov bh, 0                 ; Page 0
    mov bl, 0x0F              ; White text
    mov cx, 20                ; String length
    mov dh, 10                ; Row (centered)
    mov dl, 10                ; Column (centered)
    mov bp, confirm_msg1
    int 0x10
    
    ; Message 2: "Press Y or N"
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 0x0E              ; Yellow text
    mov cx, 13                ; String length
    mov dh, 12                ; Row
    mov dl, 14                ; Column
    mov bp, confirm_msg2
    int 0x10
    
    pop es
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ----- DRAW CONFIRMATION BOX (DARK OVERLAY) -----
draw_confirmation_box:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    
    ; Set ES to video memory
    mov ax, 0xA000
    mov es, ax
    
    ; Box dimensions: 166x80 centered at screen
    mov dx, 60                ; Start Y
    
.row_loop:
    cmp dx, 140               ; End Y
    jge .done
    
    mov cx, 79                ; Start X
    
.col_loop:
    cmp cx, 245               ; End X
    jge .next_row
    
    ; Determine pixel color
    mov al, COLOR_BLACK       ; Default to black interior
    
    ; Draw white border (2 pixels thick)
    cmp dx, 60
    je .make_white
    cmp dx, 61
    je .make_white
    cmp dx, 138
    je .make_white
    cmp dx, 139
    je .make_white
    cmp cx, 79
    je .make_white
    cmp cx, 80
    je .make_white
    cmp cx, 243
    je .make_white
    cmp cx, 244
    je .make_white
    jmp .draw_pixel
    
.make_white:
    mov al, COLOR_WHITE
    
.draw_pixel:
    ; Calculate video memory offset and draw
    push ax
    push dx
    mov ax, dx
    mov bx, SCREEN_WIDTH
    mul bx
    add ax, cx
    mov di, ax
    pop dx
    pop ax
    mov byte [es:di], al
    
    inc cx
    jmp .col_loop
    
.next_row:
    inc dx
    jmp .row_loop
    
.done:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; ----- RESTORE GAME SCREEN (REDRAW EVERYTHING) -----
restore_game_screen:
    push ax
    push bx
    push cx
    push dx
    push es
    
    ; Set ES to video memory
    mov ax, 0xA000
    mov es, ax
    
    ; Redraw the road area that was covered by confirmation box
    ; Box was at Y: 60-140, X: 79-245
    mov dx, 60                ; Start Y
    
.row_loop:
    cmp dx, 140               ; End Y
    jge .redraw_objects
    
    mov cx, 70                ; Start from left edge of road
    
.col_loop:
    cmp cx, 250               ; End at right edge of road
    jge .next_row
    
    ; Determine color based on position
    mov al, COLOR_GRAY        ; Default to road
    
    ; Check if outside road area
    cmp cx, ROAD_LEFT
    jl .make_green
    cmp cx, ROAD_RIGHT
    jge .make_green
    jmp .draw_pixel
    
.make_green:
    mov al, COLOR_GREEN
    
.draw_pixel:
    ; Calculate offset and draw
    push ax
    push dx
    mov ax, dx
    mov bx, SCREEN_WIDTH
    mul bx
    add ax, cx
    mov di, ax
    pop dx
    pop ax
    mov byte [es:di], al
    
    inc cx
    jmp .col_loop
    
.next_row:
    inc dx
    jmp .row_loop
    
.redraw_objects:
    ; Redraw lane dividers and borders in the affected area
    call draw_lane_dividers
    call draw_road_borders
    
    ; Redraw all active game objects (they never disappeared from memory)
    call draw_obstacles
    call draw_coins
    call draw_player_car
    
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret




; ==================== UTILITY ROUTINES ====================

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


; ----- RANDOM BYTE -----
get_random_byte:
    push dx
    xor ah, ah
    int 0x1A
    mov al, dl
    and al, 0x7F
    pop dx
    ret


; ----- ANIMATION DELAY -----
animation_delay:
    push bx
    push cx
    
    mov bx, DELAY_OUTER_LOOP
.outer:
    mov cx, DELAY_INNER_LOOP
.inner:
    nop
    loop .inner
    dec bx
    jnz   .outer
    
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
    jge   .skip
    cmp dx, SCREEN_HEIGHT
    jge   .skip
    cmp dx, 0
    jl   .skip

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


; ----- PUT PIXEL V2 FOR SCREENS -----
put_pixel_2:
    push ax
    push bx
    push cx
    push dx
    push di

    ; Check bounds
    cmp cx, 320
    jge .skip
    cmp dx, 200
    jge .skip

    ; Set ES to video memory segment
    push ax
    mov ax, 0xA000
    mov es, ax
    pop ax

    ; Calculate offset: DI = (Y * 320) + X
    push ax
    mov ax, dx
    mov bx, 320
    mul bx
    add ax, cx
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


; ----- Draw pixel -----
draw_pixel:
    push ax                     ; Save color value
    push bx                     ; Save registers
    
    ; Calculate offset: Y * 320 + X
    mov ax, cx                  ; AX = Y
    mov di, 320                 ; DI = screen width
    mul di                      ; DX:AX = Y * 320
    add ax, bx                  ; AX = Y * 320 + X
    mov di, ax                  ; DI = offset into video memory
    
    ; Set ES to video memory segment
    mov ax, 0xA000              ; Video memory segment for Mode 13h
    mov es, ax
    
    pop bx                      ; Restore registers
    pop ax                      ; Restore color
    
    ; Write pixel to video memory
    stosb                       ; ES:[DI] = AL, increment DI
    
    ret


; --------------- DRAW CHARACTER ---------------
; ----- Draw Single Character (normal 8x8) -----
draw_char_gfx:
    pusha
    push es
    push ds
    
    xor ah, ah
    shl ax, 3
    mov si, ax
    
    push 0xF000
    pop ds
    add si, 0xFA6E
    
    push 0xA000
    pop es
    
    push bx
    push cx
    
    mov dh, 8
    
.row_loop:
    mov ax, cx
    push dx
    mov dx, 320
    mul dx
    pop dx
    add ax, bx
    mov di, ax
    
    mov al, [ds:si]
    inc si
    mov ah, al
    
    mov ch, 8
    
.pixel_loop:
    test ah, 0x80
    jz .skip_pixel
    
    mov al, dl
    mov [es:di], al
    
.skip_pixel:
    inc di
    shl ah, 1
    dec ch
    jnz .pixel_loop
    
    inc cx
    dec dh
    jnz .row_loop
    
    pop cx
    pop bx
    
    pop ds
    pop es
    popa
    ret


; ----- Draw Single Character (16x16, 2x scaled) -----
draw_char_gfx_2x:
    pusha
    push es
    push ds
    
    xor ah, ah
    shl ax, 3
    mov si, ax
    
    push 0xF000
    pop ds
    add si, 0xFA6E
    
    push 0xA000
    pop es
    
    push bx
    push cx
    
    mov dh, 8
    
.row_loop:
    mov al, [ds:si]
    inc si
    
    push cx
    mov byte [bp-1], al
    
    call .draw_scaled_row
    
    inc cx
    mov al, [bp-1]
    call .draw_scaled_row
    
    pop cx
    add cx, 2
    
    dec dh
    jnz .row_loop
    
    pop cx
    pop bx
    
    pop ds
    pop es
    popa
    ret

.draw_scaled_row:
    push ax
    mov ax, cx
    push dx
    mov dx, 320
    mul dx
    pop dx
    add ax, bx
    mov di, ax
    pop ax
    
    mov ah, al
    
    mov ch, 8
    
.pixel_loop_2x:
    test ah, 0x80
    jz .skip_pixel_2x
    
    mov al, dl
    mov [es:di], al
    mov [es:di+1], al
    
.skip_pixel_2x:
    add di, 2
    shl ah, 1
    dec ch
    jnz .pixel_loop_2x
    
    ret


; ----- Draw Single Character (4x4, 0.5x scaled) -----
draw_char_gfx_half:
    pusha
    push es
    push ds
    
    ; Get font data from ROM BIOS
    xor ah, ah                  ; AX = character code
    shl ax, 3                   ; Multiply by 8 (each char is 8 bytes)
    mov si, ax                  ; SI = offset into font
    
    ; Point DS to font ROM
    push 0xF000
    pop ds
    add si, 0xFA6E              ; Font data starts at F000:FA6E
    
    ; Point ES to video memory
    push 0xA000
    pop es
    
    ; Save starting position
    push bx                     ; Save X
    push cx                     ; Save Y
    
    ; Draw 4 rows (sample every other row from 8)
    mov dh, 4                   ; Row counter
    
.row_loop:
    ; Calculate video memory offset for this row: Y * 320 + X
    mov ax, cx                  ; AX = current Y
    push dx
    mov dx, 320
    mul dx                      ; DX:AX = Y * 320
    pop dx
    add ax, bx                  ; AX = Y * 320 + X
    mov di, ax                  ; DI = video offset
    
    ; Get font byte for this row
    mov al, [ds:si]             ; AL = font byte (8 pixels)
    add si, 2                   ; Skip next row (sample every other row)
    mov ah, al                  ; Save font byte in AH
    
    ; Draw 4 pixels for this row (sample every other pixel)
    mov ch, 4                   ; Pixel counter
    
.pixel_loop:
    test ah, 0x80               ; Test leftmost bit
    jz .skip_pixel              ; If 0, skip this pixel
    
    mov al, dl                  ; AL = color
    mov [es:di], al             ; Write pixel
    
.skip_pixel:
    inc di                      ; Next pixel position
    shl ah, 2                   ; Shift by 2 bits (skip every other pixel)
    dec ch
    jnz .pixel_loop
    
    ; Move to next row
    inc cx                      ; Y++
    dec dh
    jnz .row_loop
    
    ; Restore starting position
    pop cx                      ; Restore Y
    pop bx                      ; Restore X
    
    pop ds
    pop es
    popa
    ret


; --------------- PRINT STRING ---------------
; ----- Print String in Graphics Mode (normal 8x8) -----
print_string_gfx:
    push bp
    mov bp, sp
    
    push bx
    push cx
    push si
    
    mov dl, al
    
.char_loop:
    mov al, [si]
    cmp al, 0
    je .done
    
    call draw_char_gfx
    
    add bx, 8
    inc si
    jmp .char_loop
    
.done:
    pop si
    pop cx
    pop bx
    pop bp
    ret


; ----- Print String in Graphics Mode (2x scale) -----
print_string_gfx_2x:
    push bp
    mov bp, sp
    
    push bx
    push cx
    push si
    
    mov dl, al
    
.char_loop:
    mov al, [si]
    cmp al, 0
    je .done
    
    call draw_char_gfx_2x
    
    add bx, 16
    inc si
    jmp .char_loop
    
.done:
    pop si
    pop cx
    pop bx
    pop bp
    ret


; ----- Print String in Graphics Mode (0.5x scale - 4x4 pixels per char) -----
print_string_gfx_half:
    push bp
    mov bp, sp
    
    push bx                     ; Save starting X
    push cx                     ; Save starting Y
    push si                     ; Save string pointer
    
    mov dl, al                  ; DL = color (save it)
    
.char_loop:
    mov al, [si]                ; Load character
    cmp al, 0                   ; Check for null terminator
    je .done
    
    ; Draw this character
    call draw_char_gfx_half     ; Draw character (AL=char, BX=X, CX=Y, DL=color)
    
    add bx, 4                   ; Move to next character position (4 pixels wide for 0.5x)
    inc si                      ; Next character in string
    jmp .char_loop
    
.done:
    pop si
    pop cx
    pop bx
    pop bp
    ret


; ----- GET STRING INPUT FROM USER -----
get_string_input:
    push bp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov di, si
    xor dx, dx
    
.input_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 13
    je .done_input
    
    cmp al, 8
    je .handle_backspace
    
    cmp al, 32
    jl .input_loop
    cmp al, 126
    jg .input_loop
    
    cmp dx, 20
    jge .input_loop
    
    mov [di], al
    inc di
    inc dx
    
    push dx
    mov dl, COLOR_BRIGHT_YELLOW
    call draw_char_gfx
    add bx, 8
    pop dx
    
    jmp .input_loop
    
.handle_backspace:
    cmp dx, 0
    je .input_loop
    
    dec di
    dec dx
    mov byte [di], 0
    
    sub bx, 8
    push ax
    push si
    push dx
    mov si, 8
    mov dx, 8
    mov al, COLOR_DARK_GRAY
    call fill_rect
    pop dx
    pop si
    pop ax
    
    jmp .input_loop
    
.done_input:
    mov byte [di], 0
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret


; ----- FILL RECTANGLE -----
fill_rect:
    push bp                     ; Save base pointer
    mov bp, sp                  ; Set up stack frame
    
    ; Save all parameters
    push bx                     ; Save starting X
    push cx                     ; Save starting Y
    push dx                     ; Save width
    push si                     ; Save height
    push ax                     ; Save color
    
    ; Set ES to video memory segment
    mov ax, 0xA000
    mov es, ax
    
    pop ax                      ; Restore color
    pop si                      ; Restore height
    pop dx                      ; Restore width
    
.row_loop:
    cmp si, 0                   ; Check if height is 0
    je .done                    ; If so, we're done
    
    ; Calculate offset for current row: Y * 320 + X
    push ax                     ; Save color
    push dx                     ; Save width
    
    mov ax, cx                  ; AX = current Y
    push dx                     ; Save DX (will be used by MUL)
    mov dx, 320
    mul dx                      ; DX:AX = Y * 320
    pop dx                      ; Restore width
    add ax, bx                  ; AX = Y * 320 + X
    mov di, ax                  ; DI = offset
    
    pop dx                      ; Restore width
    pop ax                      ; Restore color
    
    ; Fill current row
    push cx                     ; Save Y coordinate
    push dx                     ; Save width
    mov cx, dx                  ; CX = width (number of pixels to draw)
    
    rep stosb                   ; Fill CX pixels with AL color
    
    pop dx                      ; Restore width
    pop cx                      ; Restore Y coordinate
    
    ; Move to next row
    inc cx                      ; Y++
    dec si                      ; Height--
    jmp .row_loop               ; Continue loop
    
.done:
    pop cx                      ; Restore starting Y
    pop bx                      ; Restore starting X
    pop bp                      ; Restore base pointer
    ret



; ----- DRAW RECTANGLE (for car drawing) -----

draw_rect:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, ax          ; SI = height counter
    mov di, dx          ; DI = current Y

.row_loop:
    cmp si, 0
    jle .done
    
    push cx             ; Save width
    push bx             ; Save start X
    mov dx, di          ; Current Y
    
.col_loop:
    cmp cx, 0
    jle .next_row
    
    push cx
    mov cx, bx          ; Current X
    mov al, [color]
    call put_pixel_2
    pop cx
    
    inc bx
    dec cx
    jmp .col_loop

.next_row:
    pop bx              ; Restore start X
    pop cx              ; Restore width
    inc di              ; Next Y
    dec si              ; Decrement height counter
    jmp .row_loop

.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

