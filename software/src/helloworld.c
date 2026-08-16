#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"

#include "lw_usb/project_config.h"
#include "lw_usb/MAX3421E.h"
#include "lw_usb/transfer.h"

#define MARIO_IP_BASE   XPAR_MARIO_CONTROLLER_0_AXI_BASEADDR

#define REG_CAMERA_X    0   // slv_reg0
#define REG_MARIO_Y     4   // slv_reg1
#define REG_SPRITE_ID   8   // slv_reg2
#define REG_MUSHROOM_X_0      12
#define REG_MUSHROOM_Y_0      16
#define REG_MUSHROOM_ACTIVE_0 20
#define REG_MUSHROOM_DIR_0    24
#define REG_MUSHROOM_X_1      28
#define REG_MUSHROOM_Y_1      32
#define REG_MUSHROOM_ACTIVE_1 36
#define REG_MUSHROOM_DIR_1    40
#define REG_MUSHROOM_X_2      44
#define REG_MUSHROOM_Y_2      48
#define REG_MUSHROOM_ACTIVE_2 52
#define REG_MUSHROOM_DIR_2    56
#define REG_MUSHROOM_X_3      60
#define REG_MUSHROOM_Y_3      64
#define REG_MUSHROOM_ACTIVE_3 68
#define REG_MUSHROOM_DIR_3    72
#define REG_MUSHROOM_X_4      76
#define REG_MUSHROOM_Y_4      80
#define REG_MUSHROOM_ACTIVE_4 84
#define REG_MUSHROOM_DIR_4    88
#define REG_SCORE  92  // slv_reg23
#define REG_PROGRESS  96  // slv_reg24
#define REG_GAME_STATE  100  // slv_reg25
#define REG_SFX_TRIGGER 104  // slv_reg26


#define GAME_STATE_PLAYING  0
#define GAME_STATE_FAILED   1
#define GAME_STATE_COMPLETE 2
#define GAME_STATE_MENU     3


uint32_t game_state = GAME_STATE_MENU;
uint32_t game_state_timer = 0;
#define GAME_STATE_DISPLAY_FRAMES 180



// bits[1:0] = frame index, bit[2] = horizontal flip
#define IDLE            0   // 0b000
#define WALK1           1   // 0b001
#define WALK2           2   // 0b010
#define JUMP            3   // 0b011
#define FLIP_BIT        4   // 0b100

#define KEY_A           0x04
#define KEY_D           0x07
#define KEY_W           0x1A
#define KEY_P           0x13
#define KEY_R           0x15

#define ANIM_THRESHOLD  3       // frames between walk-cycle toggles
#define CAMERA_SPEED    4      // px/frame horizontal scroll


#define FP_SHIFT        8
#define FP(x)           ((int)((x) * (1 << FP_SHIFT)))


#define JUMP_VELOCITY   FP(-15.0f)   // initial vy when jump starts (negative = up)
#define GRAVITY         FP(1.1250f)   // added to vy each frame
#define MAX_FALL        FP(10.0f)    // terminal velocity (downward)

#define TILEMAP_BASE  (MARIO_IP_BASE + 0x400)
#define SCREEN_WIDTH     640
#define MAP_COLS         256
#define MAP_PIXEL_WIDTH  (MAP_COLS * 32)   // 8192
#define MAX_CAMERA_X     (MAP_PIXEL_WIDTH - SCREEN_WIDTH)  // 7552
#define MAP_ROWS      15

#define TILE_SKY          2
#define TILE_GROUND       0
#define TILE_PLATFORM     1
#define TILE_CLOUD_LEFT   3
#define TILE_CLOUD_RIGHT  4
#define TILE_COIN        5
#define TILE_MUSHROOM    6
#define TILE_FLAGPOLE    7
#define TILE_FLAGTOP     8

#define MARIO_WIDTH   30
#define MARIO_HEIGHT  32
#define MARIO_SCREEN_X 320

#define MAX_MUSHROOMS 50

typedef struct {
    int col;
    int row;
    int x_px;
    int home_x_px;
    int dir;
    int active;
    int flip_timer;  // counts frames
    int flip;        // current flip state 0 or 1
} Mushroom;

Mushroom mushrooms[MAX_MUSHROOMS];
int mushroom_count = 0;
uint32_t frame = 0;

static uint8_t tilemap[MAP_ROWS][MAP_COLS];
uint32_t score = 0;

static inline uint8_t get_tile(int col, int row) {
    if (col < 0 || col >= MAP_COLS || row < 0 || row >= MAP_ROWS)
        return TILE_SKY;
    uint32_t word_offset = (uint32_t)(row * MAP_COLS + col);
    return tilemap[row][col];
}

static inline void set_tile(int col, int row, uint8_t tile_id) {
    tilemap[row][col] = tile_id;  // ADD THIS LINE
    uint32_t word_offset = (uint32_t)(row * MAP_COLS + col);
    Xil_Out32(TILEMAP_BASE + word_offset * 4, (uint32_t)tile_id);
}

static inline int is_solid(uint8_t tile) {
    return tile == TILE_GROUND || tile == TILE_PLATFORM;
}

void add_mushroom(int col, int row) {
    mushrooms[mushroom_count].col      = col;
    mushrooms[mushroom_count].row      = row;
    mushrooms[mushroom_count].x_px     = col * 32;
    mushrooms[mushroom_count].home_x_px = col * 32;
    mushrooms[mushroom_count].dir      = 1;
    mushrooms[mushroom_count].active   = 1;
    mushrooms[mushroom_count].flip_timer = 0;
    mushrooms[mushroom_count].flip       = 0;
    mushroom_count++;
}

#define MUSHROOM_SPEED 2

void update_mushrooms() {
    for (int i = 0; i < mushroom_count; i++) {
        if (!mushrooms[i].active) continue;

        int new_x = mushrooms[i].x_px + mushrooms[i].dir * MUSHROOM_SPEED;

        // Reverse if 3 tiles from home in either direction
        int dist_from_home = new_x - mushrooms[i].home_x_px;
        if (dist_from_home >= 96 || dist_from_home <= -96) {
            mushrooms[i].dir *= -1;
            new_x = mushrooms[i].x_px + mushrooms[i].dir * MUSHROOM_SPEED;
            if (new_x - mushrooms[i].home_x_px > 96)
                new_x = mushrooms[i].home_x_px + 96;
            if (new_x - mushrooms[i].home_x_px < -96)
                new_x = mushrooms[i].home_x_px - 96;
        }

        int check_col = (mushrooms[i].dir == 1) ? (new_x + 32) / 32 : new_x / 32;
        int wall_ahead  = is_solid(get_tile(check_col, mushrooms[i].row));
        int floor_ahead = is_solid(get_tile(check_col, mushrooms[i].row + 1));
        if (wall_ahead || !floor_ahead) {
            mushrooms[i].dir *= -1;
            new_x = mushrooms[i].x_px + mushrooms[i].dir * MUSHROOM_SPEED;
        }

        mushrooms[i].flip_timer++;
        if (mushrooms[i].flip_timer >= 8) {
            mushrooms[i].flip ^= 1;
            mushrooms[i].flip_timer = 0;
        }

        mushrooms[i].x_px = new_x;

    }
}

void handle_item_collisions(int mario_y_px, int mario_vy_fp, uint32_t *camera_x,
                             int *mario_y_fp, int *mario_vy_fp_out, int *on_ground) {
    int mario_world_x = (int)(*camera_x) + MARIO_SCREEN_X - 16;
    int left_x  = mario_world_x - MARIO_WIDTH / 2;
    int right_x = mario_world_x + MARIO_WIDTH / 2 - 1;
    int top_y   = mario_y_px;
    int bot_y   = mario_y_px + MARIO_HEIGHT - 1;

    int tile_left  = left_x  / 32;
    int tile_right = right_x / 32;
    int tile_top   = top_y   / 32;
    int tile_bot   = bot_y   / 32;

    // Coin interactions
    for (int c = tile_left; c <= tile_right; c++) {
        for (int r = tile_top; r <= tile_bot; r++) {
            if (get_tile(c, r) == TILE_COIN) {
                set_tile(c, r, TILE_SKY);
                score += 10;
                xil_printf("Score: %d\n\r", score);
                Xil_Out32(MARIO_IP_BASE + REG_SFX_TRIGGER, 1);  // coin sound
            }
        }
    }

    // Mushroom interactions
    for (int i = 0; i < mushroom_count; i++) {
        if (!mushrooms[i].active) continue;

        int mush_left  = mushrooms[i].x_px - 32;
        int mush_right = mushrooms[i].x_px;
        int mush_top   = mushrooms[i].row * 32;
        int mush_bot   = mush_top + 31;

        if (right_x >= mush_left && left_x <= mush_right &&
            bot_y  >= mush_top  && top_y  <= mush_bot) {

        	if (mario_vy_fp > 0 && bot_y >= mush_top && bot_y <= mush_top + 12) {
                // Stomp
                mushrooms[i].active = 0;
                score += 30;
                Xil_Out32(MARIO_IP_BASE + REG_SFX_TRIGGER, 2);  // stomp sound
                *mario_vy_fp_out = FP(-8.0f);
                *on_ground = 0;
            } else {
            	// Side hit
            	game_state = GAME_STATE_FAILED;
            	game_state_timer = GAME_STATE_DISPLAY_FRAMES;
            	*camera_x = 0;
            	*mario_y_fp = ((12 * 32) - MARIO_HEIGHT) << FP_SHIFT;
            	*mario_vy_fp_out = 0;
            	*on_ground = 1;
            }
            return;
        }
    }
}

void load_level() {
    // Fill everything with sky first
    for (int r = 0; r < MAP_ROWS; r++)
        for (int c = 0; c < MAP_COLS; c++)
            set_tile(c, r, TILE_SKY);


    // Ground row at the bottom
    for (int c = 0; c < MAP_COLS; c++) {
        set_tile(c, 14, TILE_GROUND);
    	set_tile(c, 13, TILE_GROUND);
        set_tile(c, 12, TILE_GROUND);
    }

    // Platforms
    for (int c = 15; c <= 18; c++)  set_tile(c, 11, TILE_PLATFORM);
    for (int c = 21; c <= 24; c++) set_tile(c, 8,  TILE_PLATFORM);
    for (int c = 26; c <= 29; c++) set_tile(c, 9,  TILE_PLATFORM);
    for (int c = 40; c <= 45; c++) set_tile(c, 11,  TILE_PLATFORM);
    for (int c = 41; c <= 45; c++) set_tile(c, 10,  TILE_PLATFORM);
    for (int c = 42; c <= 45; c++) set_tile(c, 9,  TILE_PLATFORM);
    for (int c = 43; c <= 46; c++) set_tile(c, 8,  TILE_PLATFORM);
    for (int c = 44; c <= 47; c++) set_tile(c, 7,  TILE_PLATFORM);
    for (int c = 45; c <= 48; c++) set_tile(c, 6,  TILE_PLATFORM);
    for (int c = 55; c <= 58; c++) set_tile(c, 9,  TILE_PLATFORM);
    for (int c = 62; c <= 62; c++) set_tile(c, 8,  TILE_PLATFORM);
    for (int c = 67; c <= 70; c++) set_tile(c, 7,  TILE_PLATFORM);
    for (int c = 80; c <= 83; c++) set_tile(c, 10,  TILE_PLATFORM);
    for (int c = 87; c <= 94; c++) set_tile(c, 9,  TILE_PLATFORM);
    for (int c = 97; c <= 104; c++) set_tile(c, 7,  TILE_PLATFORM);
    for (int c = 107; c <= 107; c++) set_tile(c, 5,  TILE_PLATFORM);
    for (int c = 110; c <= 110; c++) set_tile(c, 9,  TILE_PLATFORM);
    for (int c = 113; c <= 113; c++) set_tile(c, 7,  TILE_PLATFORM);
    for (int c = 116; c <= 116; c++) set_tile(c, 5,  TILE_PLATFORM);
    for (int c = 120; c <= 120; c++) set_tile(c, 3,  TILE_PLATFORM);
    for (int c = 135; c <= 138; c++)  set_tile(c, 11, TILE_PLATFORM);
	for (int c = 141; c <= 144; c++) set_tile(c, 8,  TILE_PLATFORM);
	for (int c = 146; c <= 149; c++) set_tile(c, 9,  TILE_PLATFORM);
	for (int c = 160; c <= 165; c++) set_tile(c, 11,  TILE_PLATFORM);
	for (int c = 161; c <= 165; c++) set_tile(c, 10,  TILE_PLATFORM);
	for (int c = 162; c <= 165; c++) set_tile(c, 9,  TILE_PLATFORM);
	for (int c = 163; c <= 166; c++) set_tile(c, 8,  TILE_PLATFORM);
	for (int c = 164; c <= 167; c++) set_tile(c, 7,  TILE_PLATFORM);
	for (int c = 165; c <= 168; c++) set_tile(c, 6,  TILE_PLATFORM);
	for (int c = 175; c <= 178; c++) set_tile(c, 9,  TILE_PLATFORM);
	for (int c = 182; c <= 182; c++) set_tile(c, 8,  TILE_PLATFORM);
	for (int c = 187; c <= 190; c++) set_tile(c, 7,  TILE_PLATFORM);
	for (int c = 200; c <= 203; c++) set_tile(c, 10,  TILE_PLATFORM);
	for (int c = 207; c <= 214; c++) set_tile(c, 9,  TILE_PLATFORM);
	for (int c = 217; c <= 224; c++) set_tile(c, 7,  TILE_PLATFORM);
	for (int c = 227; c <= 227; c++) set_tile(c, 5,  TILE_PLATFORM);
	for (int c = 230; c <= 230; c++) set_tile(c, 9,  TILE_PLATFORM);
	for (int c = 233; c <= 233; c++) set_tile(c, 7,  TILE_PLATFORM);
	for (int c = 236; c <= 236; c++) set_tile(c, 5,  TILE_PLATFORM);
	for (int c = 240; c <= 240; c++) set_tile(c, 3,  TILE_PLATFORM);






    // Clouds (pairs of left+right)
    set_tile(3,  3, TILE_CLOUD_LEFT);  set_tile(4,  3, TILE_CLOUD_RIGHT);
    set_tile(10, 2, TILE_CLOUD_LEFT);  set_tile(11, 2, TILE_CLOUD_RIGHT);

    set_tile(17,  5, TILE_CLOUD_LEFT);  set_tile(18,  5, TILE_CLOUD_RIGHT);
    set_tile(24, 4, TILE_CLOUD_LEFT);  set_tile(25, 4, TILE_CLOUD_RIGHT);

    set_tile(30,  3, TILE_CLOUD_LEFT);  set_tile(31,  3, TILE_CLOUD_RIGHT);
    set_tile(35, 2, TILE_CLOUD_LEFT);  set_tile(36, 2, TILE_CLOUD_RIGHT);

    set_tile(45,  5, TILE_CLOUD_LEFT);  set_tile(46,  5, TILE_CLOUD_RIGHT);
    set_tile(51, 3, TILE_CLOUD_LEFT);  set_tile(52, 3, TILE_CLOUD_RIGHT);

    set_tile(60,  3, TILE_CLOUD_LEFT);  set_tile(61,  3, TILE_CLOUD_RIGHT);
    set_tile(70, 2, TILE_CLOUD_LEFT);  set_tile(71, 2, TILE_CLOUD_RIGHT);

    set_tile(82,  5, TILE_CLOUD_LEFT);  set_tile(83,  5, TILE_CLOUD_RIGHT);
    set_tile(90, 3, TILE_CLOUD_LEFT);  set_tile(91, 3, TILE_CLOUD_RIGHT);

    set_tile(100,  5, TILE_CLOUD_LEFT);  set_tile(101,  5, TILE_CLOUD_RIGHT);
    set_tile(107, 2, TILE_CLOUD_LEFT);  set_tile(108, 2, TILE_CLOUD_RIGHT);

    set_tile(115,  3, TILE_CLOUD_LEFT);  set_tile(116,  3, TILE_CLOUD_RIGHT);
    set_tile(124, 2, TILE_CLOUD_LEFT);  set_tile(125, 2, TILE_CLOUD_RIGHT);

	set_tile(130, 2, TILE_CLOUD_LEFT);  set_tile(131, 2, TILE_CLOUD_RIGHT);

	set_tile(137,  5, TILE_CLOUD_LEFT);  set_tile(138,  5, TILE_CLOUD_RIGHT);
	set_tile(144, 4, TILE_CLOUD_LEFT);  set_tile(145, 4, TILE_CLOUD_RIGHT);

	set_tile(150,  3, TILE_CLOUD_LEFT);  set_tile(151,  3, TILE_CLOUD_RIGHT);
	set_tile(155, 2, TILE_CLOUD_LEFT);  set_tile(156, 2, TILE_CLOUD_RIGHT);

	set_tile(165,  5, TILE_CLOUD_LEFT);  set_tile(166,  5, TILE_CLOUD_RIGHT);
	set_tile(171, 3, TILE_CLOUD_LEFT);  set_tile(172, 3, TILE_CLOUD_RIGHT);

	set_tile(180,  3, TILE_CLOUD_LEFT);  set_tile(181,  3, TILE_CLOUD_RIGHT);
	set_tile(190, 2, TILE_CLOUD_LEFT);  set_tile(191, 2, TILE_CLOUD_RIGHT);

	set_tile(202,  5, TILE_CLOUD_LEFT);  set_tile(203,  5, TILE_CLOUD_RIGHT);
	set_tile(210, 3, TILE_CLOUD_LEFT);  set_tile(211, 3, TILE_CLOUD_RIGHT);

	set_tile(220,  5, TILE_CLOUD_LEFT);  set_tile(221,  5, TILE_CLOUD_RIGHT);
	set_tile(227, 2, TILE_CLOUD_LEFT);  set_tile(228, 2, TILE_CLOUD_RIGHT);

	set_tile(235,  3, TILE_CLOUD_LEFT);  set_tile(236,  3, TILE_CLOUD_RIGHT);
	set_tile(244, 2, TILE_CLOUD_LEFT);  set_tile(245, 2, TILE_CLOUD_RIGHT);

    // Coins
    for (int c = 15; c <= 18; c++)  set_tile(c, 10, TILE_COIN);
	for (int c = 21; c <= 24; c++) set_tile(c, 7,  TILE_COIN);
	for (int c = 26; c <= 29; c++) set_tile(c, 8,  TILE_COIN);
	for (int c = 55; c <= 58; c++) set_tile(c, 8,  TILE_COIN);
	for (int c = 62; c <= 62; c++) set_tile(c, 7,  TILE_COIN);
	for (int c = 67; c <= 70; c++) set_tile(c, 6,  TILE_COIN);
	for (int c = 80; c <= 83; c++) set_tile(c, 9,  TILE_COIN);
	for (int c = 87; c <= 94; c++) set_tile(c, 8,  TILE_COIN);
	for (int c = 97; c <= 104; c++) set_tile(c, 6,  TILE_COIN);
	for (int c = 107; c <= 107; c++) set_tile(c, 4,  TILE_COIN);
	for (int c = 110; c <= 110; c++) set_tile(c, 8,  TILE_COIN);
	for (int c = 113; c <= 113; c++) set_tile(c, 6,  TILE_COIN);
	for (int c = 116; c <= 116; c++) set_tile(c, 4,  TILE_COIN);
	for (int c = 120; c <= 120; c++) set_tile(c, 2,  TILE_COIN);
	for (int c = 135; c <= 138; c++)  set_tile(c, 10, TILE_COIN);
	for (int c = 141; c <= 144; c++) set_tile(c, 7,  TILE_COIN);
	for (int c = 146; c <= 149; c++) set_tile(c, 8,  TILE_COIN);
	for (int c = 175; c <= 178; c++) set_tile(c, 8,  TILE_COIN);
	for (int c = 182; c <= 182; c++) set_tile(c, 7,  TILE_COIN);
	for (int c = 187; c <= 190; c++) set_tile(c, 6,  TILE_COIN);
	for (int c = 200; c <= 203; c++) set_tile(c, 9,  TILE_COIN);
	for (int c = 207; c <= 214; c++) set_tile(c, 8,  TILE_COIN);
	for (int c = 217; c <= 224; c++) set_tile(c, 6,  TILE_COIN);
	for (int c = 227; c <= 227; c++) set_tile(c, 4,  TILE_COIN);
	for (int c = 230; c <= 230; c++) set_tile(c, 8,  TILE_COIN);
	for (int c = 233; c <= 233; c++) set_tile(c, 6,  TILE_COIN);
	for (int c = 236; c <= 236; c++) set_tile(c, 4,  TILE_COIN);
	for (int c = 240; c <= 240; c++) set_tile(c, 2,  TILE_COIN);
    set_tile(120, 8, TILE_COIN);
    set_tile(120, 7, TILE_COIN);
    set_tile(120, 6, TILE_COIN);
    set_tile(120, 5, TILE_COIN);

    set_tile(240, 7, TILE_COIN);
    set_tile(240, 6, TILE_COIN);
    set_tile(240, 5, TILE_COIN);
    set_tile(245, 6, TILE_COIN);
    set_tile(245, 5, TILE_COIN);

    // Mushrooms
    add_mushroom(25, 7);
    add_mushroom(19, 10);
    add_mushroom(25, 11);
    add_mushroom(29, 11);
    add_mushroom(35, 11);
    add_mushroom(49, 5);
    add_mushroom(55, 11);
    add_mushroom(59, 11);
    add_mushroom(63, 11);
    add_mushroom(68, 11);
    add_mushroom(70, 11);
    add_mushroom(78, 11);
    add_mushroom(84, 9);
    add_mushroom(93, 8);
    add_mushroom(100, 11);
    add_mushroom(103, 6);

    add_mushroom(145, 7);
    add_mushroom(139, 10);
    add_mushroom(145, 11);
    add_mushroom(149, 11);
    add_mushroom(155, 11);
    add_mushroom(169, 5);
    add_mushroom(175, 11);
    add_mushroom(179, 11);
    add_mushroom(183, 11);
    add_mushroom(188, 11);
    add_mushroom(190, 11);
    add_mushroom(198, 11);
    add_mushroom(204, 9);
    add_mushroom(213, 8);
    add_mushroom(220, 11);
    add_mushroom(223, 6);
    add_mushroom(230, 11);
    add_mushroom(240, 11);
    add_mushroom(245, 11);









    // Flagpoles
    set_tile(245, 11, TILE_FLAGPOLE);
    set_tile(245, 10, TILE_FLAGPOLE);
    set_tile(245, 9, TILE_FLAGPOLE);
    set_tile(245, 8, TILE_FLAGPOLE);

    // Flagtop
    set_tile(245, 7, TILE_FLAGTOP);

}

int main()
{
    xil_printf("Microblaze reset\n\r");
    init_platform();
    xil_printf("Platform Init Done\n\r");

    MAX3421E_init();
    USB_init();
    xil_printf("USB Init Done\n\r");
    load_level();


    xil_printf("load_level done\n\r");
    xil_printf("set_tile(0,14) addr=0x%08X offset=%d\n\r",
    	TILEMAP_BASE + (14 * MAP_COLS + 0) * 4,
		14 * MAP_COLS + 0);
    xil_printf("set_tile(0,0) addr=0x%08X offset=%d\n\r",
        TILEMAP_BASE + (0 * MAP_COLS + 0) * 4,
        0 * MAP_COLS + 0);

    uint32_t camera_x = 0;

    int mario_y_fp = ((12 * 32) - MARIO_HEIGHT) << FP_SHIFT;
    int mario_vy_fp    = 0;
    int on_ground      = 1;

    uint8_t sprite_id  = IDLE;

    int key_right = 0;
    int key_left  = 0;
    int key_jump  = 0;
    int prev_jump = 0;

    uint32_t anim_timer  = 0;
    int      prev_moving = 0;

    int facing_left = 0;

    BOOT_KBD_REPORT kbd_report;
    xil_printf("Mario ready.  A=left  D=right  W=jump\n\r");



    while (1) {
    	if (game_state == GAME_STATE_PLAYING) {
    	        update_mushrooms();
    	}
    	frame++;
        MAX3421E_Task();
        USB_Task();

        if (GetUsbTaskState() == USB_STATE_RUNNING) {
            BYTE rcode = kbdPoll(&kbd_report);
            if (rcode == 0) {
                key_right = 0;
                key_left  = 0;
                key_jump  = 0;
                for (int i = 0; i < 6; i++) {
                    BYTE k = kbd_report.keycode[i];
                    if (k == KEY_D) key_right = 1;
                    if (k == KEY_A) key_left  = 1;
                    if (k == KEY_W) key_jump  = 1;
                    if (k == KEY_P && game_state == GAME_STATE_MENU) {
						game_state = GAME_STATE_PLAYING;
					}
					if (k == KEY_R) {
						// Reset everything
						game_state       = GAME_STATE_MENU;
						camera_x         = 0;
						mario_y_fp       = ((12 * 32) - MARIO_HEIGHT) << FP_SHIFT;
						mario_vy_fp      = 0;
						on_ground        = 1;
						score            = 0;
						game_state_timer = 0;
						facing_left      = 0;
						sprite_id        = IDLE;
						// Reset all mushrooms
						for (int i = 0; i < mushroom_count; i++) {
							mushrooms[i].x_px    = mushrooms[i].home_x_px;
							mushrooms[i].active  = 1;
							mushrooms[i].dir     = 1;
							mushrooms[i].flip    = 0;
							mushrooms[i].flip_timer = 0;
						}
						// Reload coins
						mushroom_count = 0;
						load_level();
					}
                }
            }
        } else {
            usleep(1000);
        }

        if (game_state != GAME_STATE_PLAYING) {
			key_right = 0;
			key_left  = 0;
			key_jump  = 0;
		}

        if (key_right) facing_left = 0;
        if (key_left)  facing_left = 1;

        int moving = key_right || key_left;

        // Apply gravity first
        if (!on_ground) {
            mario_vy_fp += GRAVITY;
            if (mario_vy_fp > MAX_FALL)
                mario_vy_fp = MAX_FALL;
            mario_y_fp += mario_vy_fp;
        }
        else {
        	mario_y_fp += FP(1.0f);
        }

        int mario_y_px = mario_y_fp >> FP_SHIFT;

        // Mario world position
        int mario_world_x = (int)camera_x + MARIO_SCREEN_X - 16; // shift collision right by one tile
        int left_x  = mario_world_x - MARIO_WIDTH / 2;
        int right_x = mario_world_x + MARIO_WIDTH / 2 - 1;
        int top_y   = mario_y_px;
        int bot_y   = mario_y_px + MARIO_HEIGHT - 1;
        int tile_left  = left_x  / 32;
        int tile_right = right_x / 32;
        int tile_top   = top_y   / 32;
        int tile_bot   = bot_y   / 32;

        handle_item_collisions(mario_y_px, mario_vy_fp, &camera_x, &mario_y_fp, &mario_vy_fp, &on_ground);

        // Ground/platform collision - check below feet
        on_ground = 0;
        if (mario_vy_fp >= 0) {
            if (is_solid(get_tile(tile_left,  tile_bot)) ||
                is_solid(get_tile(tile_right, tile_bot))) {
                mario_y_fp  = ((tile_bot * 32) - MARIO_HEIGHT) << FP_SHIFT;
                mario_vy_fp = 0;
                on_ground   = 1;
                mario_y_px  = mario_y_fp >> FP_SHIFT;
            }
        }

        // Ceiling collision - check above head
        if (mario_vy_fp < 0) {
            if (is_solid(get_tile(tile_left,  tile_top)) ||
                is_solid(get_tile(tile_right, tile_top))) {
                mario_vy_fp = 0;
                mario_y_fp  = ((tile_top + 1) * 32) << FP_SHIFT;
                mario_y_px  = mario_y_fp >> FP_SHIFT;
            }
        }

        // Recompute tile coords after vertical resolution
        tile_left  = left_x  / 32;
        tile_right = right_x / 32;
        tile_top   = mario_y_px / 32;
        tile_bot   = (mario_y_px + MARIO_HEIGHT - 1) / 32;

        // Right wall collision
		if (key_right) {
			int tile_top_inset = (mario_y_px + 2) / 32;
			int tile_bot_inset = (mario_y_px + MARIO_HEIGHT - 3) / 32;
			if (is_solid(get_tile(tile_right, tile_top_inset)) ||
				is_solid(get_tile(tile_right, tile_bot_inset))) {
				key_right = 0;
			}
		}
		if (key_left) {
			int tile_top_inset = (mario_y_px + 2) / 32;
			int tile_bot_inset = (mario_y_px + MARIO_HEIGHT - 3) / 32;
			if (is_solid(get_tile(tile_left, tile_top_inset)) ||
				is_solid(get_tile(tile_left, tile_bot_inset))) {
				key_left = 0;
			}
		}

		// Check if Mario touched flagpole
		int mario_world_col = ((int)camera_x + MARIO_SCREEN_X - 16) / 32;
		int mario_tile_row  = mario_y_px / 32;
		for (int r = mario_tile_row; r <= mario_tile_row + 1; r++) {
		    if (get_tile(mario_world_col, r) == TILE_FLAGPOLE ||
		        get_tile(mario_world_col, r) == TILE_FLAGTOP) {
		        game_state = GAME_STATE_COMPLETE;
		        game_state_timer = GAME_STATE_DISPLAY_FRAMES;
		    }
		}

		// Count down game state timer
		if (game_state_timer > 0) {
		    game_state_timer--;
		    if (game_state_timer == 0)
		        game_state = GAME_STATE_PLAYING;
		}

		// Camera movement after collision
		if (key_right) {
			if (camera_x + CAMERA_SPEED <= MAX_CAMERA_X)
				camera_x += CAMERA_SPEED;
		}
		if (key_left) {
			if (camera_x >= (uint32_t)CAMERA_SPEED)
				camera_x -= CAMERA_SPEED;
			else
				camera_x = 0;
		}

        // Jump
        if (key_jump && !prev_jump && on_ground) {
            mario_vy_fp = JUMP_VELOCITY;
            on_ground   = 0;
        }
        prev_jump = key_jump;

        if (!on_ground) {
            sprite_id  = facing_left ? (FLIP_BIT | JUMP) : JUMP;
            anim_timer = 0;

        } else if (moving) {
            if (!prev_moving) {
                sprite_id  = facing_left ? (FLIP_BIT | WALK1) : WALK1;
                anim_timer = 0;
            } else {
                anim_timer++;
                if (anim_timer >= ANIM_THRESHOLD) {
                    uint8_t anim_frame = (sprite_id & 0x03) == WALK1 ? WALK2 : WALK1;
                    sprite_id  = facing_left ? (FLIP_BIT | anim_frame) : anim_frame;
                    anim_timer = 0;
                }
            }

        } else {
            sprite_id  = facing_left ? (FLIP_BIT | IDLE) : IDLE;
            anim_timer = 0;
        }

        prev_moving = moving;


        Xil_Out32(MARIO_IP_BASE + REG_CAMERA_X,  camera_x);
        Xil_Out32(MARIO_IP_BASE + REG_MARIO_Y,   (uint32_t)mario_y_px);
        Xil_Out32(MARIO_IP_BASE + REG_SPRITE_ID, (uint32_t)sprite_id);

        int on_screen[5] = {-1, -1, -1, -1, -1};
        int found = 0;
        for (int i = 0; i < mushroom_count && found < 5; i++) {
            if (!mushrooms[i].active) continue;
            int screen_x = mushrooms[i].x_px - (int)camera_x;
            if (screen_x >= -32 && screen_x <= 640) {
                on_screen[found++] = i;
            }
        }

        uint32_t reg_x[]      = {REG_MUSHROOM_X_0,      REG_MUSHROOM_X_1,      REG_MUSHROOM_X_2,      REG_MUSHROOM_X_3,      REG_MUSHROOM_X_4};
        uint32_t reg_y[]      = {REG_MUSHROOM_Y_0,      REG_MUSHROOM_Y_1,      REG_MUSHROOM_Y_2,      REG_MUSHROOM_Y_3,      REG_MUSHROOM_Y_4};
        uint32_t reg_active[] = {REG_MUSHROOM_ACTIVE_0, REG_MUSHROOM_ACTIVE_1, REG_MUSHROOM_ACTIVE_2, REG_MUSHROOM_ACTIVE_3, REG_MUSHROOM_ACTIVE_4};
        uint32_t reg_dir[]    = {REG_MUSHROOM_DIR_0,    REG_MUSHROOM_DIR_1,    REG_MUSHROOM_DIR_2,    REG_MUSHROOM_DIR_3,    REG_MUSHROOM_DIR_4};

        for (int s = 0; s < 5; s++) {
            int idx = on_screen[s];
            if (idx >= 0) {
                Xil_Out32(MARIO_IP_BASE + reg_x[s],      (uint32_t)mushrooms[idx].x_px);
                Xil_Out32(MARIO_IP_BASE + reg_y[s],      (uint32_t)(mushrooms[idx].row * 32));
                Xil_Out32(MARIO_IP_BASE + reg_active[s], 1);
                Xil_Out32(MARIO_IP_BASE + reg_dir[s],    mushrooms[idx].flip);
            } else {
                Xil_Out32(MARIO_IP_BASE + reg_active[s], 0);
            }
        }
        Xil_Out32(MARIO_IP_BASE + REG_SCORE, score);
        uint32_t progress = (uint32_t)((mario_world_col * 100) / 235);

        Xil_Out32(MARIO_IP_BASE + REG_PROGRESS, progress);
        Xil_Out32(MARIO_IP_BASE + REG_GAME_STATE, game_state);

        Xil_Out32(MARIO_IP_BASE + REG_SFX_TRIGGER, 0);  // clear trigger every frame


        usleep(16666);
    }

    cleanup_platform();
    return 0;
}
