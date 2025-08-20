; ====================================================================
; ADVANCED MAPPING ALGORITHMS
; ====================================================================
; File: advanced_mapping.asm
; Description: Advanced mapping and navigation algorithms for the robot
; ====================================================================

.include "mapping_definitions.inc"

; ====================================================================
; ADVANCED MAPPING ROUTINES
; ====================================================================

; Frontier-based exploration algorithm
FRONTIER_EXPLORATION:
    ; Find unexplored areas adjacent to known areas
    rcall FIND_FRONTIERS
    
    ; Select the nearest frontier
    rcall SELECT_NEAREST_FRONTIER
    
    ; Plan path to selected frontier
    rcall PLAN_PATH_TO_FRONTIER
    
    ; Execute the planned path
    rcall EXECUTE_PLANNED_PATH
    
    ret

FIND_FRONTIERS:
    ; Scan the map array for frontier cells
    ; A frontier is an unvisited cell adjacent to a visited cell
    
    ldi ZH, high(map_array)
    ldi ZL, low(map_array)
    ldi YH, high(frontier_list)
    ldi YL, low(frontier_list)
    
    clr temp                   ; Row counter
    clr temp2                  ; Column counter
    clr r25                    ; Frontier count
    
FRONTIER_ROW_LOOP:
    clr temp2                  ; Reset column counter
    
FRONTIER_COL_LOOP:
    ; Load current cell
    rcall GET_MAP_CELL         ; Returns cell value in r24
    
    ; Check if cell is unvisited
    sbrc r24, MAP_VISITED
    rjmp FRONTIER_NEXT_COL     ; Skip if already visited
    
    ; Check if any adjacent cell is visited
    rcall CHECK_ADJACENT_VISITED
    cpi r24, 1
    brne FRONTIER_NEXT_COL     ; Skip if no adjacent visited cells
    
    ; This is a frontier - add to list
    rcall ADD_TO_FRONTIER_LIST
    
FRONTIER_NEXT_COL:
    inc temp2                  ; Next column
    cpi temp2, MAP_SIZE
    brlo FRONTIER_COL_LOOP
    
    inc temp                   ; Next row
    cpi temp, MAP_SIZE
    brlo FRONTIER_ROW_LOOP
    
    ret

CHECK_ADJACENT_VISITED:
    ; Check if any of the 4 adjacent cells are visited
    ; Input: temp = row, temp2 = column
    ; Output: r24 = 1 if any adjacent is visited, 0 otherwise
    
    clr r24                    ; Assume no adjacent visited
    
    ; Check North (row-1)
    cpi temp, 0
    breq CHECK_EAST            ; Skip if at top edge
    push temp
    dec temp
    rcall GET_MAP_CELL
    sbrc r24, MAP_VISITED
    ldi r24, 1                 ; Found visited adjacent
    pop temp
    cpi r24, 1
    breq CHECK_ADJACENT_END
    
CHECK_EAST:
    ; Check East (col+1)
    mov r26, temp2
    inc r26
    cpi r26, MAP_SIZE
    brsh CHECK_SOUTH           ; Skip if at right edge
    push temp2
    mov temp2, r26
    rcall GET_MAP_CELL
    sbrc r24, MAP_VISITED
    ldi r24, 1
    pop temp2
    cpi r24, 1
    breq CHECK_ADJACENT_END
    
CHECK_SOUTH:
    ; Check South (row+1)
    mov r26, temp
    inc r26
    cpi r26, MAP_SIZE
    brsh CHECK_WEST            ; Skip if at bottom edge
    push temp
    mov temp, r26
    rcall GET_MAP_CELL
    sbrc r24, MAP_VISITED
    ldi r24, 1
    pop temp
    cpi r24, 1
    breq CHECK_ADJACENT_END
    
CHECK_WEST:
    ; Check West (col-1)
    cpi temp2, 0
    breq CHECK_ADJACENT_END    ; Skip if at left edge
    push temp2
    dec temp2
    rcall GET_MAP_CELL
    sbrc r24, MAP_VISITED
    ldi r24, 1
    pop temp2
    
CHECK_ADJACENT_END:
    ret

GET_MAP_CELL:
    ; Get map cell value at position (temp, temp2)
    ; Output: r24 = cell value
    
    ; Calculate array index: index = row * MAP_SIZE + col
    mov r26, temp
    ldi r27, MAP_SIZE
    mul r26, r27               ; Result in r1:r0
    add r0, temp2
    adc r1, r1                 ; Add carry
    
    ; Load from map array
    ldi ZH, high(map_array)
    ldi ZL, low(map_array)
    add ZL, r0
    adc ZH, r1
    
    ld r24, Z
    ret

SET_MAP_CELL:
    ; Set map cell value at position (temp, temp2)
    ; Input: r24 = cell value to set
    
    ; Calculate array index
    mov r26, temp
    ldi r27, MAP_SIZE
    mul r26, r27
    add r0, temp2
    adc r1, r1
    
    ; Store to map array
    ldi ZH, high(map_array)
    ldi ZL, low(map_array)
    add ZL, r0
    adc ZH, r1
    
    st Z, r24
    ret

ADD_TO_FRONTIER_LIST:
    ; Add current position to frontier list
    ; Store row in first byte, column in second byte
    
    st Y+, temp                ; Store row
    st Y+, temp2               ; Store column
    inc r25                    ; Increment frontier count
    
    ret

SELECT_NEAREST_FRONTIER:
    ; Select the nearest frontier to current position
    ; Uses Manhattan distance for simplicity
    
    cpi r25, 0
    breq NO_FRONTIERS          ; No frontiers available
    
    ldi ZH, high(frontier_list)
    ldi ZL, low(frontier_list)
    
    ldi r26, 255               ; Initialize minimum distance
    clr r27                    ; Selected frontier index
    clr temp                   ; Current frontier index
    
FRONTIER_SELECT_LOOP:
    ; Load frontier coordinates
    ld r28, Z+                 ; Frontier row
    ld r29, Z+                 ; Frontier column
    
    ; Calculate Manhattan distance
    rcall CALCULATE_MANHATTAN_DISTANCE
    ; Distance returned in r24
    
    ; Compare with current minimum
    cp r24, r26
    brsh FRONTIER_SELECT_NEXT
    
    ; New minimum found
    mov r26, r24               ; Update minimum distance
    mov r27, temp              ; Update selected index
    
FRONTIER_SELECT_NEXT:
    inc temp
    cp temp, r25
    brlo FRONTIER_SELECT_LOOP
    
    ; Store selected frontier coordinates
    mov temp, r27              ; Selected index
    lsl temp                   ; Multiply by 2 (2 bytes per frontier)
    
    ldi ZH, high(frontier_list)
    ldi ZL, low(frontier_list)
    add ZL, temp
    adc ZH, r1
    
    ld target_row, Z+
    ld target_col, Z+
    
    ret
    
NO_FRONTIERS:
    ; No frontiers available - exploration complete
    ldi r24, 0xFF              ; Signal completion
    ret

CALCULATE_MANHATTAN_DISTANCE:
    ; Calculate Manhattan distance between current position and (r28, r29)
    ; Output: r24 = distance
    
    ; Distance = |current_row - target_row| + |current_col - target_col|
    
    ; Calculate row difference
    mov r24, robot_y
    sub r24, r28
    brpl POSITIVE_ROW
    neg r24                    ; Make positive
    
POSITIVE_ROW:
    ; Calculate column difference
    mov r26, robot_x
    sub r26, r29
    brpl POSITIVE_COL
    neg r26                    ; Make positive
    
POSITIVE_COL:
    ; Add both differences
    add r24, r26
    
    ret

; ====================================================================
; PATH PLANNING ROUTINES
; ====================================================================

PLAN_PATH_TO_FRONTIER:
    ; Simple path planning using wall-following algorithm
    ; More sophisticated algorithms like A* could be implemented
    
    ; Calculate direction to target
    rcall CALCULATE_TARGET_DIRECTION
    
    ; Plan movement sequence
    rcall GENERATE_MOVEMENT_SEQUENCE
    
    ret

CALCULATE_TARGET_DIRECTION:
    ; Calculate general direction to target
    ; Returns preferred direction in r24
    
    ; Compare positions
    mov temp, target_row
    sub temp, robot_y          ; Row difference
    mov temp2, target_col
    sub temp2, robot_x         ; Column difference
    
    ; Determine primary direction
    mov r26, temp
    sbrc r26, 7                ; Check sign bit
    neg r26                    ; Make positive
    mov r27, temp2
    sbrc r27, 7
    neg r27
    
    ; Choose direction based on larger difference
    cp r26, r27
    brlo HORIZONTAL_PRIORITY
    
VERTICAL_PRIORITY:
    ; Vertical movement is priority
    tst temp
    brmi PREFER_NORTH
    ldi r24, DIR_SOUTH
    rjmp CALC_DIR_END
PREFER_NORTH:
    ldi r24, DIR_NORTH
    rjmp CALC_DIR_END
    
HORIZONTAL_PRIORITY:
    ; Horizontal movement is priority
    tst temp2
    brmi PREFER_WEST
    ldi r24, DIR_EAST
    rjmp CALC_DIR_END
PREFER_WEST:
    ldi r24, DIR_WEST
    
CALC_DIR_END:
    mov preferred_direction, r24
    ret

GENERATE_MOVEMENT_SEQUENCE:
    ; Generate a sequence of movements to reach target
    ; This is a simplified implementation
    
    ldi ZH, high(movement_sequence)
    ldi ZL, low(movement_sequence)
    clr movement_count
    
    ; Add movements based on preferred direction
    ; This should be more sophisticated in a real implementation
    
    ldi temp, CMD_SCAN
    st Z+, temp
    inc movement_count
    
    mov temp, preferred_direction
    rcall DIRECTION_TO_MOVEMENT
    st Z+, temp
    inc movement_count
    
    ldi temp, CMD_FORWARD
    st Z+, temp
    inc movement_count
    
    ret

DIRECTION_TO_MOVEMENT:
    ; Convert direction to movement command
    ; Input: temp = direction
    ; Output: temp = movement command
    
    cpi temp, DIR_NORTH
    breq DIR_TO_MOV_NORTH
    cpi temp, DIR_EAST
    breq DIR_TO_MOV_EAST
    cpi temp, DIR_SOUTH
    breq DIR_TO_MOV_SOUTH
    ; DIR_WEST
    ldi temp, CMD_TURN_LEFT    ; Assuming current direction is north
    ret
    
DIR_TO_MOV_NORTH:
    ldi temp, CMD_FORWARD      ; Assuming current direction is north
    ret
DIR_TO_MOV_EAST:
    ldi temp, CMD_TURN_RIGHT
    ret
DIR_TO_MOV_SOUTH:
    ldi temp, CMD_TURN_RIGHT   ; Two right turns for 180
    ret

EXECUTE_PLANNED_PATH:
    ; Execute the planned movement sequence
    
    ldi ZH, high(movement_sequence)
    ldi ZL, low(movement_sequence)
    clr temp                   ; Movement index
    
EXECUTE_PATH_LOOP:
    ; Load next movement command
    ld temp2, Z+
    
    ; Execute movement
    rcall EXECUTE_MOVEMENT_COMMAND
    
    ; Check for obstacles and adjust if necessary
    rcall CHECK_PATH_CLEAR
    cpi r24, 0
    breq PATH_BLOCKED
    
    inc temp
    cp temp, movement_count
    brlo EXECUTE_PATH_LOOP
    
    ret
    
PATH_BLOCKED:
    ; Path is blocked - need to replan
    rcall OBSTACLE_AVOIDANCE
    ret

EXECUTE_MOVEMENT_COMMAND:
    ; Execute a single movement command
    ; Input: temp2 = command
    
    cpi temp2, CMD_FORWARD
    breq EXEC_FORWARD
    cpi temp2, CMD_TURN_LEFT
    breq EXEC_TURN_LEFT
    cpi temp2, CMD_TURN_RIGHT
    breq EXEC_TURN_RIGHT
    cpi temp2, CMD_SCAN
    breq EXEC_SCAN
    ret                        ; Unknown command
    
EXEC_FORWARD:
    rcall MOVE_FORWARD
    ret
EXEC_TURN_LEFT:
    rcall TURN_LEFT
    ret
EXEC_TURN_RIGHT:
    rcall TURN_RIGHT
    ret
EXEC_SCAN:
    rcall SCAN_360
    ret

CHECK_PATH_CLEAR:
    ; Check if path ahead is clear
    ; Output: r24 = 1 if clear, 0 if blocked
    
    rcall MEASURE_DISTANCE
    cpi distance_low, MIN_SAFE_DISTANCE
    brlo PATH_NOT_CLEAR
    
    ldi r24, 1                 ; Path is clear
    ret
    
PATH_NOT_CLEAR:
    clr r24                    ; Path is blocked
    ret

OBSTACLE_AVOIDANCE:
    ; Simple obstacle avoidance when planned path is blocked
    
    ; Try turning right first
    rcall TURN_RIGHT
    rcall CHECK_PATH_CLEAR
    cpi r24, 1
    breq OBSTACLE_AVOIDED
    
    ; Try turning left (180 degrees from original)
    rcall TURN_LEFT
    rcall TURN_LEFT
    rcall CHECK_PATH_CLEAR
    cpi r24, 1
    breq OBSTACLE_AVOIDED
    
    ; Try backward (full 180 from right turn)
    rcall TURN_LEFT
    rcall TURN_LEFT
    
OBSTACLE_AVOIDED:
    ret

; ====================================================================
; SRAM VARIABLES FOR ADVANCED MAPPING
; ====================================================================
.dseg

frontier_list: .byte 64        ; List of frontier cells (row, col pairs)
movement_sequence: .byte 32    ; Planned movement sequence
movement_count: .byte 1        ; Number of movements in sequence
target_row: .byte 1           ; Target row coordinate
target_col: .byte 1           ; Target column coordinate
preferred_direction: .byte 1   ; Preferred movement direction
exploration_complete: .byte 1  ; Flag indicating exploration is done
