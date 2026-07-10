get println, read_file, write_file from std::io
get term_print, term_hide_cursor, term_show_cursor, term_poll, term_move, term_fg, term_bg, term_get_size, term_flush from std::term
get term_enter, term_clear, term_leave, term_read_key, term_move_right, term_move_left, term_move_up, term_move_down from std::term
get term_bold, term_reset_attr, term_reset_color, term_begin_sync, term_end_sync, term_dim from std::term
get arr_range, arr_push, arr_remove, arr_contains, arr_first, arr_last, len from std::array
get repeat, format, split from std::str
get mod, clamp from std::math
get rand_int, rand_int_range from std::random
get to_string, to_int, to_bool from std::types
get path_exists from std::path

// ---   globals   ---

dec bool texpl = false

// Legend for symbol indices:
// 0-3: Borders (Top-Left, Top-Right, Bottom-Left, Bottom-Right)
// 4-5: Lines (Horizontal, Vertical)
// 6-10: Entities (Wall, Player, Normal Enemy, Chaser Enemy, Wanderer Enemy)
// 11-14: Items/Hazards (Danger, Pellet, Powerup, Moving Target)
// 15: Screen Transitions (Sweep)
CONST arr[string] SYMBOLES_1 = ["┌", "┐", "└", "┘", "─", "│", "#", "@", "E", "C", "e", "x", "o", "!", "*", "█"]
CONST arr[string] SYMBOLES_2 = ["╭", "╮", "╰", "╯", "─", "│", "▓", "⬢", "⎔", "⌺", "⍵", "✜", "•", "◇", "✦", "░"]

// --- globals end ---

!#[test]
fn tests() {
    // checks for logic before going to init
    // mainly for imports
}

!#[init]
fn terminal() {
    term_enter()
    term_clear()
    term_hide_cursor()
}

// ---- data types ----

record Player {
    int x,
    int y,
    int score
}

tag EnemyType {
    Normal,
    Chaser,
    Wanderer
}

record Enemy {
    int x,
    int y,
    EnemyType type
}

record Target {
    int x,
    int y
}

record Stats {
    int best_level,
    int games,
    int wins,
    int losses,
    int streak,
}

tag GameResult {
    Win,
    Lose,
    Quit,
    Menu,
}

// ---- persistence ----

!#[init]
fn load_conf() {
    if path_exists("rlchase.conf") {
        dec string content = read_file("rlchase.conf")?
        dec arr[string] parts = split(content, ",")

        if parts.len() == 2 {
            if parts[0] == "smooth" {
                texpl = parts[1].to_bool()?
            }
        }
    }
}

!#[final]
fn save_conf() {
    dec string line = format("smooth,{}", texpl.to_string()?)
    write_file("rlchase.conf", line)?
}

// single save file: "best,games,wins,losses"
fn load_stats() -> Stats {
    if path_exists("rlchase.save") {
        dec string content = read_file("rlchase.save")?
        dec arr[string] parts = split(content, ",")

        if parts.len() == 5 {
            dec int best = parts[0].to_int()?
            dec int games = parts[1].to_int()?
            dec int wins = parts[2].to_int()?
            dec int losses = parts[3].to_int()?
            dec int streak = parts[4].to_int()?
            return Stats { best_level: best, games: games, wins: wins, losses: losses, streak: streak}
        }
    }

    return Stats { best_level: 1, games: 0, wins: 0, losses: 0, streak: 0 }
}

fn save_stats(Stats s) {
    dec string line = format("{},{},{},{},{}", s.best_level.to_string()?, s.games.to_string()?, s.wins.to_string()?, s.losses.to_string()?, s.streak.to_string()?)
    write_file("rlchase.save", line)?
}

// ---- color helpers ----

fn draw_char(int x, int y, string ch, string color) {
    term_move(x, y)
    term_fg(color)
    term_print(ch)
    term_reset_color()
}

fn draw_char_bold(int x, int y, string ch, string color) {
    term_move(x, y)
    term_fg(color)
    term_bold()
    term_print(ch)
    term_reset_attr()
    term_reset_color()
}

fn erase_char(int x, int y) {
    term_move(x, y)
    term_print(" ")
}

// ---- transition animation ----

fn transition_sweep(int max_x, int max_y) {
    dec int x = 1
    while x < max_x {
        term_begin_sync()
        dec int y = 1
        while y < max_y {
            term_move(x, y)
            term_fg("blue")
            term_dim()
            if !texpl {
                term_print("█")
            } else {
                term_print("░")
            }
            term_reset_attr()
            term_reset_color()
            y += 1
        }
        term_end_sync()
        term_poll(4)
        x += 1
    }
    term_clear()
}

// ---- ui helpers ----

fn resolve_symbole(int n) -> string {
    if texpl {
        return SYMBOLES_2[n]
    } else {
        return SYMBOLES_1[n]
    }
}

fn frame_this(string text) -> (arr[string], int) {
    dec int text_len = text.len()
    dec string upper = format("{}{}{}",resolve_symbole(0), resolve_symbole(4).repeat(text_len), resolve_symbole(1))
    dec string text = format("{}{}{}", resolve_symbole(5), text, resolve_symbole(5))
    dec string lower = format("{}{}{}", resolve_symbole(2), resolve_symbole(4).repeat(text_len), resolve_symbole(3))

    return ([upper, text, lower], text_len)
}

!#[init]
fn loading() {
    term_clear()

    dec arr[int] size = term_get_size()?
    dec int max_x, int max_y = (size[0], size[1])

    dec string loading_msg = " loading ... "
    dec arr[string] ft, int msg_len = frame_this(loading_msg)

    term_move(max_x - (msg_len + 4), max_y - 4)
    term_print(ft[0])
    term_move(max_x - (msg_len + 4), max_y - 3)
    term_print(ft[1])
    term_move(max_x - (msg_len + 4), max_y - 2)
    term_print(ft[2])
}

fn get_size(int max_x, int max_y) -> (arr[(int, int)], arr[(int, int)]) {
    dec arr[int] Xs = arr_range(0, max_x + 1, 1)
    dec arr[int] Ys = arr_range(0, max_y + 1, 1)

    dec arr[(int, int)] frame = []
    dec arr[(int, int)] body = []

    for x in Xs {
        for y in Ys {
            if x == 0 or y == 0 or x == max_x or y == max_y {
                frame = frame.arr_push((x, y))
            } else {
                body = body.arr_push((x, y))
            }
        }
    }

    return (frame, body)
}

fn draw_border(arr[(int, int)] frame, int max_x, int max_y) {
    term_fg("cyan")
    term_bold()
    for point in frame {
        term_move(point[0], point[1])
        if point[0] == 0 and point[1] == 0 {
            resolve_symbole(0).term_print()
        } else if point[0] == max_x and point[1] == 0 {
            resolve_symbole(1).term_print()
        } else if point[0] == 0 and point[1] == max_y {
            resolve_symbole(2).term_print()
        } else if point[0] == max_x and point[1] == max_y {
            resolve_symbole(3).term_print()
        } else if point[1] == 0 or point[1] == max_y {
            resolve_symbole(4).term_print()
        } else if point[0] == 0 or point[0] == max_x {
            resolve_symbole(5).term_print()
        }
    }
    term_reset_attr()
    term_reset_color()
}

fn draw_main_menu(int max_x, int max_y, Stats stats) -> (arr[int], arr[int], arr[int]) {
    dec int center_x = max_x / 2
    dec int center_y = max_y / 2

    dec string title = " rl chase "
    dec arr[string] ft_title, int title_len = frame_this(title)

    dec string best = format(" best level: {}  |  played: {}  wins: {}  losses: {} | streak: {} ", stats.best_level.to_string()?, stats.games.to_string()?, stats.wins.to_string()?, stats.losses.to_string()?, stats.streak.to_string()?)
    dec arr[string] ft_best, int best_len = frame_this(best)

    dec string start = " start "
    dec string exit = " exit  "
    dec string dot = " "
    dec string settings = " settings  "
    dec string s1 = " smooth "

    dec arr[string] ft_start, int start_len = frame_this(start)
    dec arr[string] ft_exit, int exit_len = frame_this(exit)
    dec arr[string] ft_dot, int dot_len = frame_this(dot)
    dec arr[string] ft_settings, int settings_len = frame_this(settings)
    dec arr[string] ft_s1, int s1_len = frame_this(s1)

    term_move(center_x - (title_len / 2), center_y - 1)
    term_fg("magenta")
    term_bold()
    term_print(ft_title[0])
    term_move(center_x - (title_len / 2), center_y)
    term_print(ft_title[1])
    term_move(center_x - (title_len / 2), center_y + 1)
    term_print(ft_title[2])
    term_reset_attr()
    term_reset_color()

    term_move(center_x - (best_len / 2), center_y + 2)
    term_fg("yellow")
    term_print(ft_best[1])
    term_reset_color()

    term_move(center_x - (start_len), center_y + 4)
    term_print(ft_start[0])
    term_move(center_x - (start_len), center_y + 5)
    term_print(ft_start[1])
    term_move(center_x - (start_len), center_y + 6)
    term_print(ft_start[2])
    // box
    dec int box_start_x = center_x - start_len - 3
    dec int box_start_y = center_y + 5
    term_move(box_start_x, box_start_y - 1)
    term_print(ft_dot[0])
    term_move(box_start_x, box_start_y)
    term_print(ft_dot[1])
    term_move(box_start_x, box_start_y + 1)
    term_print(ft_dot[2])

    term_move(center_x - (exit_len), center_y + 7)
    term_print(ft_exit[0])
    term_move(center_x - (exit_len), center_y + 8)
    term_print(ft_exit[1])
    term_move(center_x - (exit_len), center_y + 9)
    term_print(ft_exit[2])
    // box
    dec int box_exit_x = center_x - exit_len - 3
    dec int box_exit_y = center_y + 8
    term_move(box_exit_x, box_exit_y - 1)
    term_print(ft_dot[0])
    term_move(box_exit_x, box_exit_y)
    term_print(ft_dot[1])
    term_move(box_exit_x, box_exit_y + 1)
    term_print(ft_dot[2])

    // --- settings ---
    term_move(center_x + (settings_len + 3), center_y + 4)
    term_print(ft_settings[0])
    term_move(center_x + (settings_len + 3), center_y + 5)
    term_print(ft_settings[1])
    term_move(center_x + (settings_len + 3), center_y + 6)
    term_print(ft_settings[2])

    term_move(center_x + (settings_len + 6), center_y + 7)
    term_print(ft_s1[0])
    term_move(center_x + (settings_len + 6), center_y + 8)
    term_print(ft_s1[1])
    term_move(center_x + (settings_len + 6), center_y + 9)
    term_print(ft_s1[2])
    // box
    dec int box_s1_x = center_x + settings_len + 3
    dec int box_s1_y = center_y + 8
    term_move(box_s1_x, box_s1_y - 1)
    term_print(ft_dot[0])
    term_move(box_s1_x, box_s1_y)
    term_print(ft_dot[1])
    term_move(box_s1_x, box_s1_y + 1)
    term_print(ft_dot[2])

    // legend
    dec string legend = "arrows: move   enter/space: select   ctrl+c: back/quit"
    term_move(center_x - (legend.len() / 2), max_y - 2)
    term_fg("white")
    term_print(legend)
    term_reset_color()

    // in-game legend
    dec string legend2 = format("{} you   {}, {}, {} enemy   {} danger   {} wall   {} pellet   {} freeze   {} bonus",
        resolve_symbole(7), resolve_symbole(8), resolve_symbole(9), resolve_symbole(10),
        resolve_symbole(11), resolve_symbole(6), resolve_symbole(12), resolve_symbole(13), resolve_symbole(14))
    term_move(center_x - (legend2.len() / 2) + 5, max_y - 1)
    term_fg("white")
    term_print(legend2)
    term_reset_color()

    return ([box_start_x + 1, box_start_y], [box_exit_x + 1, box_exit_y], [box_s1_x + 1, box_s1_y])
}

// ---- gameplay helpers ----

fn is_wall(arr[(int, int)] cells, int x, int y) -> bool {
    for c in cells {
        if c[0] == x and c[1] == y {
            return true
        }
    }
    return false
}

fn density_cap(int max_x, int max_y, int divisor, int floor_val) -> int {
    dec int total_free = (max_x - 2) * (max_y - 2)
    dec int cap = total_free / divisor
    if cap < floor_val {
        return floor_val
    }
    return cap
}

fn make_walls(int max_x, int max_y, int level) -> arr[(int, int)] {
    dec arr[(int, int)] walls = []
    dec int wall_count = (10 + level * 4).clamp(4, density_cap(max_x, max_y, 4, 4))
    dec int placed = 0
    dec int attempts = 0
    dec int max_attempts = wall_count * 50 + 300

    while placed < wall_count and attempts < max_attempts {
        dec int wx = rand_int_range(1, max_x - 2)
        dec int wy = rand_int_range(1, max_y - 2)
        dec bool is_center = wx == max_x / 2 and wy == max_y / 2

        if !is_wall(walls, wx, wy) and !is_center {
            walls = walls.arr_push((wx, wy))
            placed = placed + 1
        }
        attempts = attempts + 1
    }

    return walls
}

fn make_danger(int max_x, int max_y, int level, arr[(int, int)] walls, int px, int py) -> arr[(int, int)] {
    dec arr[(int, int)] danger = []
    dec int danger_count = (3 + level * 2).clamp(2, density_cap(max_x, max_y, 8, 2))
    dec int placed = 0
    dec int attempts = 0
    dec int max_attempts = danger_count * 50 + 300

    while placed < danger_count and attempts < max_attempts {
        dec int dx = rand_int_range(1, max_x - 2)
        dec int dy = rand_int_range(1, max_y - 2)
        dec bool on_player = dx == px and dy == py

        if !is_wall(walls, dx, dy) and !is_wall(danger, dx, dy) and !on_player {
            danger = danger.arr_push((dx, dy))
            placed = placed + 1
        }
        attempts = attempts + 1
    }

    return danger
}

fn find_start_cell(int max_x, int max_y, arr[(int, int)] walls) -> (int, int) {
    dec int cx = max_x / 2
    dec int cy = max_y / 2
    dec int attempts = 0

    while is_wall(walls, cx, cy) and attempts < 500 {
        cx = rand_int_range(1, max_x - 1)
        cy = rand_int_range(1, max_y - 1)
        attempts = attempts + 1
    }

    return (cx, cy)
}

fn make_pellets(int max_x, int max_y, arr[(int, int)] walls, arr[(int, int)] danger, int px, int py, int count) -> arr[(int, int)] {
    dec arr[(int, int)] pellets = []
    dec int placed = 0
    dec int attempts = 0
    dec int max_attempts = count * 50 + 300

    while placed < count and attempts < max_attempts {
        dec int gx = rand_int_range(1, max_x - 2)
        dec int gy = rand_int_range(1, max_y - 2)
        dec bool on_player = gx == px and gy == py

        if !is_wall(walls, gx, gy) and !is_wall(danger, gx, gy) and !is_wall(pellets, gx, gy) and !on_player {
            pellets = pellets.arr_push((gx, gy))
            placed = placed + 1
        }
        attempts = attempts + 1
    }

    return pellets
}

fn spawn_one_pellet(int max_x, int max_y, arr[(int, int)] walls, arr[(int, int)] danger, arr[(int, int)] pellets, int px, int py) -> (int, int) {
    dec int gx = rand_int_range(1, max_x - 2)
    dec int gy = rand_int_range(1, max_y - 2)
    dec int attempts = 0

    while (is_wall(walls, gx, gy) or is_wall(danger, gx, gy) or is_wall(pellets, gx, gy) or (gx == px and gy == py)) and attempts < 500 {
        gx = rand_int_range(1, max_x - 2)
        gy = rand_int_range(1, max_y - 2)
        attempts = attempts + 1
    }

    return (gx, gy)
}

fn spawn_target(int max_x, int max_y, arr[(int, int)] walls, arr[(int, int)] danger, int px, int py) -> Target {
    dec int tx = rand_int_range(1, max_x - 2)
    dec int ty = rand_int_range(1, max_y - 2)
    dec int attempts = 0

    while (is_wall(walls, tx, ty) or is_wall(danger, tx, ty) or (tx == px and ty == py)) and attempts < 500 {
        tx = rand_int_range(1, max_x - 2)
        ty = rand_int_range(1, max_y - 2)
        attempts = attempts + 1
    }

    return Target { x: tx, y: ty }
}

fn make_powerups(int max_x, int max_y, arr[(int, int)] walls, arr[(int, int)] danger, int px, int py, int count) -> arr[(int, int)] {
    dec arr[(int, int)] powerups = []
    dec int placed = 0
    dec int attempts = 0
    dec int max_attempts = count * 50 + 300

    while placed < count and attempts < max_attempts {
        dec int gx = rand_int_range(1, max_x - 2)
        dec int gy = rand_int_range(1, max_y - 2)
        dec bool on_player = gx == px and gy == py

        if !is_wall(walls, gx, gy) and !is_wall(danger, gx, gy) and !is_wall(powerups, gx, gy) and !on_player {
            powerups = powerups.arr_push((gx, gy))
            placed = placed + 1
        }
        attempts = attempts + 1
    }

    return powerups
}

fn spawn_enemies(int max_x, int max_y, int level, arr[(int, int)] walls, arr[(int, int)] danger, int px, int py) -> arr[Enemy] {
    dec arr[Enemy] enemies = []
    dec int enemy_count = (1 + (level / 2)).clamp(1, density_cap(max_x, max_y, 20, 1) + 1)
    dec int placed = 0
    dec int attempts = 0
    dec int max_attempts = enemy_count * 50 + 300

    while placed < enemy_count and attempts < max_attempts {
        dec int ex = rand_int_range(1, max_x - 2)
        dec int ey = rand_int_range(1, max_y - 2)
        dec int etr = rand_int_range(1, 3)
        dec EnemyType et = EnemyType.Normal
        match etr {
            1 => { et = EnemyType.Normal }
            2 => { et = EnemyType.Chaser }
            3 => { et = EnemyType.Wanderer }
        }
        dec bool on_player = ex == px and ey == py
        dec bool too_close = (ex - px).clamp(-3, 3) == (ex - px) and (ey - py).clamp(-3, 3) == (ey - py)

        if !is_wall(walls, ex, ey) and !is_wall(danger, ex, ey) and !on_player and !too_close {
            enemies = enemies.arr_push(Enemy { x: ex, y: ey, type: et })
            placed = placed + 1
        }
        attempts = attempts + 1
    }

    return enemies
}

fn random_step(int x, int y, arr[(int, int)] walls, int max_x, int max_y) -> (int, int) {
    dec int dir = rand_int_range(0, 3)
    dec int nx = x
    dec int ny = y

    if dir == 0 {
        ny = (y - 1).clamp(1, max_y - 2)
    } else if dir == 1 {
        ny = (y + 1).clamp(1, max_y - 2)
    } else if dir == 2 {
        nx = (x - 1).clamp(1, max_x - 2)
    } else {
        nx = (x + 1).clamp(1, max_x - 2)
    }

    if is_wall(walls, nx, ny) {
        return (x, y)
    }
    return (nx, ny)
}

fn chase_step(int x, int y, int px, int py, arr[(int, int)] walls, int max_x, int max_y) -> (int, int) {
    dec int dx = px - x
    dec int dy = py - y

    dec int adx = dx
    if adx < 0 {
        adx = 0 - adx
    }
    dec int ady = dy
    if ady < 0 {
        ady = 0 - ady
    }

    dec int nx = x
    dec int ny = y

    if adx >= ady {
        if dx > 0 {
            nx = (x + 1).clamp(1, max_x - 2)
        } else if dx < 0 {
            nx = (x - 1).clamp(1, max_x - 2)
        }
        if is_wall(walls, nx, ny) {
            nx = x
            if dy > 0 {
                ny = (y + 1).clamp(1, max_y - 2)
            } else if dy < 0 {
                ny = (y - 1).clamp(1, max_y - 2)
            }
        }
    } else {
        if dy > 0 {
            ny = (y + 1).clamp(1, max_y - 2)
        } else if dy < 0 {
            ny = (y - 1).clamp(1, max_y - 2)
        }
        if is_wall(walls, nx, ny) {
            ny = y
            if dx > 0 {
                nx = (x + 1).clamp(1, max_x - 2)
            } else if dx < 0 {
                nx = (x - 1).clamp(1, max_x - 2)
            }
        }
    }

    if is_wall(walls, nx, ny) {
        return (x, y)
    }
    return (nx, ny)
}

fn move_enemies(arr[Enemy] enemies, arr[(int, int)] walls, int max_x, int max_y, int px, int py) -> arr[Enemy] {
    dec arr[Enemy] moved = []

    for e in enemies {
        dec int roll = rand_int_range(0, 9)
        dec int nx, int ny = (e.x, e.y)

        match e.type {
            EnemyType.Normal => {
                if roll < 7 {
                    dec int cx, int cy = chase_step(e.x, e.y, px, py, walls, max_x, max_y)
                    nx = cx
                    ny = cy
                } else {
                    dec int rx, int ry = random_step(e.x, e.y, walls, max_x, max_y)
                    nx = rx
                    ny = ry
                }
            }
            EnemyType.Chaser => {
                dec int cx, int cy = chase_step(e.x, e.y, px, py, walls, max_x, max_y)
                nx = cx
                ny = cy
            }
            EnemyType.Wanderer => {
                dec int rx, int ry = random_step(e.x, e.y, walls, max_x, max_y)
                nx = rx
                ny = ry
            }
        }

        moved = moved.arr_push(Enemy { x: nx, y: ny, type: e.type })
    }

    return moved
}

fn move_target(Target t, arr[(int, int)] walls, int max_x, int max_y) -> Target {
    dec int nx, int ny = random_step(t.x, t.y, walls, max_x, max_y)
    return Target { x: nx, y: ny }
}

fn enemy_hit(arr[Enemy] enemies, int px, int py) -> bool {
    for e in enemies {
        if e.x == px and e.y == py {
            return true
        }
    }
    return false
}

fn pellet_index(arr[(int, int)] pellets, int px, int py) -> int {
    dec int i = 0
    for p in pellets {
        if p[0] == px and p[1] == py {
            return i
        }
        i = i + 1
    }
    return -1
}

fn draw_walls(arr[(int, int)] walls) {
    for w in walls {
        draw_char(w[0], w[1], resolve_symbole(6), "white")
    }
}

fn draw_danger(arr[(int, int)] danger) {
    for d in danger {
        draw_char_bold(d[0], d[1], resolve_symbole(11), "red")
    }
}

fn draw_pellets(arr[(int, int)] pellets) {
    for p in pellets {
        draw_char(p[0], p[1], resolve_symbole(12), "green")
    }
}

fn draw_powerups(arr[(int, int)] powerups) {
    for u in powerups {
        draw_char_bold(u[0], u[1], resolve_symbole(13), "yellow")
    }
}

fn erase_enemies(arr[Enemy] enemies) {
    for e in enemies {
        erase_char(e.x, e.y)
    }
}

fn draw_enemies(arr[Enemy] enemies) {
    for e in enemies {
        match e.type {
            EnemyType.Normal => { draw_char_bold(e.x, e.y, resolve_symbole(8), "red") }
            EnemyType.Chaser => { draw_char_bold(e.x, e.y, resolve_symbole(9), "red") }
            EnemyType.Wanderer => { draw_char_bold(e.x, e.y, resolve_symbole(10), "red") }
        }
    }
}

fn draw_target(Target t) {
    draw_char_bold(t.x, t.y, resolve_symbole(14), "magenta")
}

fn erase_target(Target t) {
    erase_char(t.x, t.y)
}

fn draw_player(int x, int y) {
    draw_char_bold(x, y, resolve_symbole(7), "cyan")
}

fn draw_hud(int max_x, int max_y, int score, int goal_score, int level, int freeze_timer) {
    term_move(1, max_y + 1)
    term_fg("white")
    term_print(format("level {}   score: {} / {}   ", level.to_string()?, score.to_string()?, goal_score.to_string()?))
    term_reset_color()

    if freeze_timer > 0 {
        term_fg("blue")
        term_bold()
        term_print(format("FROZEN ({})   ", freeze_timer.to_string()?))
        term_reset_attr()
        term_reset_color()
    } else {
        term_print("             ")
    }

    term_fg("white")
    term_print("(Ctrl+M/M: menu)")
    term_reset_color()
}

// ---- game loop ----

fn game_loop(arr[(int,int)] frame, int max_x, int max_y, int level) -> GameResult {
    dec int goal_score = 8 + level * 4
    dec int pellet_count = 3
    dec int powerup_count = 2

    term_clear()
    draw_border(frame, max_x, max_y)

    dec arr[(int, int)] walls = make_walls(max_x, max_y, level)
    dec int start_x, int start_y = find_start_cell(max_x, max_y, walls)
    dec arr[(int, int)] danger = make_danger(max_x, max_y, level, walls, start_x, start_y)
    dec arr[Enemy] enemies = spawn_enemies(max_x, max_y, level, walls, danger, start_x, start_y)
    dec arr[(int, int)] pellets = make_pellets(max_x, max_y, walls, danger, start_x, start_y, pellet_count)
    dec arr[(int, int)] powerups = make_powerups(max_x, max_y, walls, danger, start_x, start_y, powerup_count)
    dec Target target = spawn_target(max_x, max_y, walls, danger, start_x, start_y)

    draw_walls(walls)
    draw_danger(danger)
    draw_pellets(pellets)
    draw_powerups(powerups)
    draw_target(target)
    draw_enemies(enemies)

    term_hide_cursor()
    dec Player p = Player { x: start_x, y: start_y, score: 0 }
    dec int freeze_timer = 0

    draw_player(p.x, p.y)
    draw_hud(max_x, max_y, p.score, goal_score, level, freeze_timer)

    while true {
        dec string key = term_read_key()?
        dec int nx = p.x
        dec int ny = p.y
        dec bool moved = false

        match key {
            "Up" => {
                ny = (p.y - 1).clamp(1, max_y - 2)
                moved = true
            }
            "Down" => {
                ny = (p.y + 1).clamp(1, max_y - 2)
                moved = true
            }
            "Left" => {
                nx = (p.x - 1).clamp(1, max_x - 2)
                moved = true
            }
            "Right" => {
                nx = (p.x + 1).clamp(1, max_x - 2)
                moved = true
            }
            "Char:m" => { return GameResult.Menu }
            "Ctrl:m" => { return GameResult.Menu }
            "Ctrl:c" => { return GameResult.Quit }
            _ => {}
        }

        if !is_wall(walls, nx, ny) {
            erase_char(p.x, p.y)
            p.x = nx
            p.y = ny
            draw_player(p.x, p.y)
        }

        if is_wall(danger, p.x, p.y) {
            return GameResult.Lose
        }

        // pellet pickup
        dec int hit_pellet = pellet_index(pellets, p.x, p.y)
        if hit_pellet >= 0 {
            pellets = pellets.arr_remove(hit_pellet)
            p.score = p.score + 1
            dec int new_px, int new_py = spawn_one_pellet(max_x, max_y, walls, danger, pellets, p.x, p.y)
            pellets = pellets.arr_push((new_px, new_py))
            draw_player(p.x, p.y)
        }

        // powerup pickup
        dec int hit_power = pellet_index(powerups, p.x, p.y)
        if hit_power >= 0 {
            powerups = powerups.arr_remove(hit_power)
            freeze_timer = 6
            draw_player(p.x, p.y)
        }

        // target pickup
        if p.x == target.x and p.y == target.y {
            p.score = p.score + 3
            erase_target(target)
            target = spawn_target(max_x, max_y, walls, danger, p.x, p.y)
            draw_player(p.x, p.y)
        }

        if p.score >= goal_score {
            return GameResult.Win
        }

        if moved {
            if freeze_timer > 0 {
                freeze_timer = freeze_timer - 1
            } else {
                erase_enemies(enemies)
                enemies = move_enemies(enemies, walls, max_x, max_y, p.x, p.y)
                draw_enemies(enemies)
            }

            erase_target(target)
            target = move_target(target, walls, max_x, max_y)
            draw_target(target)

            draw_player(p.x, p.y)
        }

        if enemy_hit(enemies, p.x, p.y) {
            return GameResult.Lose
        }

        draw_pellets(pellets)
        draw_powerups(powerups)
        draw_hud(max_x, max_y, p.score, goal_score, level, freeze_timer)
    }
}

fn show_win_screen(int max_x, int max_y, int level) {
    term_clear()
    dec int center_x = max_x / 2
    dec int center_y = max_y / 2

    dec string msg = format(" you win level {}! press any key ", level.to_string()?)
    dec arr[string] ft, int msg_len = frame_this(msg)
    term_move(center_x - (msg_len / 2), center_y - 1)
    term_fg("green")
    term_bold()
    term_print(ft[0])
    term_move(center_x - (msg_len / 2), center_y)
    term_print(ft[1])
    term_move(center_x - (msg_len / 2), center_y + 1)
    term_print(ft[2])
    term_reset_attr()
    term_reset_color()

    term_read_key()?
}

fn show_lose_screen(int max_x, int max_y, int level) {
    term_clear()
    dec int center_x = max_x / 2
    dec int center_y = max_y / 2

    dec string msg = format(" you died on level {}! press any key ", level.to_string()?)
    dec arr[string] ft, int msg_len = frame_this(msg)
    term_move(center_x - (msg_len / 2), center_y - 1)
    term_fg("red")
    term_bold()
    term_print(ft[0])
    term_move(center_x - (msg_len / 2), center_y)
    term_print(ft[1])
    term_move(center_x - (msg_len / 2), center_y + 1)
    term_print(ft[2])
    term_reset_attr()
    term_reset_color()

    term_read_key()?
}

fn main() {
    dec arr[int] size = term_get_size()?
    dec int max_x, int max_y = (size[0], size[1])

    dec arr[(int, int)] frame, arr[(int, int)] body = get_size(max_x, max_y)

    dec bool running = true
    dec int level = 1
    dec Stats stats = load_stats()

    while running {
        term_clear()
        draw_border(frame, max_x, max_y)
        dec arr[int] start_button, arr[int] exit_button, arr[int] s1_button = draw_main_menu(max_x - 2, max_y - 2, stats)

        dec bool in_menu = true
        dec int choice = 1
        dec int menu = 1
        dec int settings_choice = 1

        term_move(s1_button[0], s1_button[1])
        if texpl {
            term_print("x")
        } else {
            term_print(" ")
        }

        while in_menu {
            dec string key = term_read_key()?
            match key {
                "Up" => {
                    term_show_cursor()
                    if choice == 2 and menu == 1 {
                        term_move(start_button[0], start_button[1])
                        choice = 1
                    } else if menu == 2 {
                        term_move(s1_button[0], s1_button[1])
                        settings_choice = 1
                    }
                }

                "Down" => {
                    term_show_cursor()
                    if choice == 1 and menu == 1 {
                        term_move(exit_button[0], exit_button[1])
                        choice = 2
                    } else if menu == 2 {
                        term_move(s1_button[0], s1_button[1])
                        settings_choice = 1
                    }
                }

                "Left" => {
                    if menu == 1 {
                        menu = 2
                        term_move(s1_button[0], s1_button[1])
                    } else {
                        menu = 1
                        if choice == 1 {
                            term_move(start_button[0], start_button[1])
                        } else {
                            term_move(exit_button[0], exit_button[1])
                        }
                    }
                }

                "Right" => {
                    if menu == 2 {
                        menu = 1
                        if choice == 1 {
                            term_move(start_button[0], start_button[1])
                        } else {
                            term_move(exit_button[0], exit_button[1])
                        }
                    } else {
                        menu = 2
                        term_move(s1_button[0], s1_button[1])
                    }
                }

                "Char: " => {
                    if settings_choice == 1 and menu == 2 {
                        if !texpl {
                            term_print("x")
                            texpl = true
                            term_move(s1_button[0], s1_button[1])
                        } else {
                            term_print(" ")
                            texpl = false
                            term_move(s1_button[0], s1_button[1])
                        }
                    }

                    if (choice == 2) and menu == 1 {
                        running = false
                        in_menu = false
                    } else if (choice == 1) and menu == 1 {
                        in_menu = false
                        transition_sweep(max_x, max_y)
                        dec GameResult gresult = game_loop(frame, max_x, max_y, level)

                        if gresult == GameResult.Win {
                            stats.games = stats.games + 1
                            stats.wins = stats.wins + 1
                            level = level + 1
                            if level > stats.best_level {
                                stats.best_level = level
                            }
                            save_stats(stats)
                            transition_sweep(max_x, max_y)
                            show_win_screen(max_x, max_y, level - 1)
                        } else if gresult == GameResult.Lose {
                            stats.games = stats.games + 1
                            stats.losses = stats.losses + 1
                            save_stats(stats)
                            transition_sweep(max_x, max_y)
                            show_lose_screen(max_x, max_y, level)
                            level = 1
                        }
                        // Quit falls back to the menu keeping the current level, no stats change
                        transition_sweep(max_x, max_y)
                    }
                }
                "Enter" => {
                    if choice == 2 {
                        running = false
                        in_menu = false
                    } else if choice == 1 {
                        in_menu = false
                        transition_sweep(max_x, max_y)
                        dec GameResult gresult = game_loop(frame, max_x, max_y, level)

                        if gresult == GameResult.Quit {
                            running = false
                            in_menu = false
                            break
                        }

                        if gresult == GameResult.Win {
                            stats.games = stats.games + 1
                            stats.wins = stats.wins + 1
                            level = level + 1
                            if level > stats.best_level {
                                stats.best_level = level
                            }
                            save_stats(stats)
                            transition_sweep(max_x, max_y)
                            show_win_screen(max_x, max_y, level - 1)
                        } else if gresult == GameResult.Lose {
                            stats.games = stats.games + 1
                            stats.losses = stats.losses + 1
                            save_stats(stats)
                            transition_sweep(max_x, max_y)
                            show_lose_screen(max_x, max_y, level)
                            level = 1
                        }
                        transition_sweep(max_x, max_y)
                    }
                }

                "Ctrl:c" => {
                    running = false
                    in_menu = false
                }

                _ => { term_hide_cursor() }
            }
        }
    }
}

!#[final]
fn clean_up() {
    term_leave()
}
