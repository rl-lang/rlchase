get println from std::io
get term_print, term_hide_cursor, term_show_cursor, term_poll, term_move, term_fg, term_bg, term_get_size, term_flush from std::term
get term_enter, term_clear, term_leave, term_read_key, term_move_right, term_move_left, term_move_up, term_move_down from std::term
get arr_range, arr_push, arr_remove, arr_contains, arr_first, arr_last, len from std::array
get repeat, format from std::str
get mod, clamp from std::math
get rand_int, rand_int_range from std::random
get to_string, to_int from std::types
get path_exists from std::path

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

record Enemy {
    int x,
    int y
}

tag GameResult {
    Win,
    Lose,
    Quit
}

// ---- persistence ----

fn load_best_level() -> int {
    if path_exists("rlgame.game_data") {
        dec string content = read_file("rlgame.game_data")?
        dec int parsed = content.to_int()?
        return parsed
    }
    return 1
}

fn save_best_level(int level) {
    write_file("rlgame.game_data", level.to_string()?)?
}

// ---- ui helpers ----

fn frame_this(string text) -> (arr[string], int) {
    dec int text_len = text.len()
    dec string upper = format("┌{}┐", "─".repeat(text_len))
    dec string text = format("│{}│", text)
    dec string lower = format("└{}┘", "─".repeat(text_len))

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
    for point in frame {
        term_move(point[0], point[1])
        if point[0] == 0 and point[1] == 0 {
            term_print("┌")
        } else if point[0] == max_x and point[1] == 0 {
            term_print("┐")
        } else if point[0] == 0 and point[1] == max_y {
            term_print("└")
        } else if point[0] == max_x and point[1] == max_y {
            term_print("┘")
        } else if point[1] == 0 or point[1] == max_y {
            term_print("─")
        } else if point[0] == 0 or point[0] == max_x {
            term_print("│")
        }
    }
}

fn draw_main_menu(int max_x, int max_y, int best_level) -> (arr[int], arr[int]) {
    dec int center_x = max_x / 2
    dec int center_y = max_y / 2

    dec string title = " rl game "
    dec arr[string] ft_title, int title_len = frame_this(title)

    dec string best = format(" best level: {} ", best_level.to_string()?)
    dec arr[string] ft_best, int best_len = frame_this(best)

    dec string start = " start "
    dec string exit = " exit  "
    dec string dot = " "

    dec arr[string] ft_start, int start_len = frame_this(start)
    dec arr[string] ft_exit, int exit_len = frame_this(exit)
    dec arr[string] ft_dot, int dot_len = frame_this(dot)

    term_move(center_x - (title_len / 2), center_y - 1)
    term_print(ft_title[0])
    term_move(center_x - (title_len / 2), center_y)
    term_print(ft_title[1])
    term_move(center_x - (title_len / 2), center_y + 1)
    term_print(ft_title[2])

    term_move(center_x - (best_len / 2), center_y + 2)
    term_print(ft_best[1])

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

    return ([box_start_x + 1, box_start_y], [box_exit_x + 1, box_exit_y])
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

fn make_walls(int max_x, int max_y, int level) -> arr[(int, int)] {
    dec arr[(int, int)] walls = []
    dec int wall_count = 10 + level * 4
    dec int placed = 0

    while placed < wall_count {
        dec int wx = rand_int_range(1, max_x - 2)
        dec int wy = rand_int_range(1, max_y - 2)
        dec bool is_center = wx == max_x / 2 and wy == max_y / 2

        if !is_wall(walls, wx, wy) and !is_center {
            walls = walls.arr_push((wx, wy))
            placed = placed + 1
        }
    }

    return walls
}

fn make_danger(int max_x, int max_y, int level, arr[(int, int)] walls, int px, int py) -> arr[(int, int)] {
    dec arr[(int, int)] danger = []
    dec int danger_count = 3 + level * 2
    dec int placed = 0

    while placed < danger_count {
        dec int dx = rand_int_range(1, max_x - 2)
        dec int dy = rand_int_range(1, max_y - 2)
        dec bool on_player = dx == px and dy == py

        if !is_wall(walls, dx, dy) and !is_wall(danger, dx, dy) and !on_player {
            danger = danger.arr_push((dx, dy))
            placed = placed + 1
        }
    }

    return danger
}

fn find_start_cell(int max_x, int max_y, arr[(int, int)] walls) -> (int, int) {
    dec int cx = max_x / 2
    dec int cy = max_y / 2

    while is_wall(walls, cx, cy) {
        cx = rand_int_range(1, max_x - 1)
        cy = rand_int_range(1, max_y - 1)
    }

    return (cx, cy)
}

fn spawn_goal(int max_x, int max_y, arr[(int, int)] walls, arr[(int, int)] danger, int px, int py) -> (int, int) {
    dec int gx = rand_int_range(1, max_x - 2)
    dec int gy = rand_int_range(1, max_y - 2)

    while is_wall(walls, gx, gy) or is_wall(danger, gx, gy) or (gx == px and gy == py) {
        gx = rand_int_range(1, max_x - 1)
        gy = rand_int_range(1, max_y - 1)
    }

    return (gx, gy)
}

fn spawn_enemies(int max_x, int max_y, int level, arr[(int, int)] walls, arr[(int, int)] danger, int px, int py) -> arr[Enemy] {
    dec arr[Enemy] enemies = []
    dec int enemy_count = 1 + (level / 2)
    dec int placed = 0

    while placed < enemy_count {
        dec int ex = rand_int_range(1, max_x - 2)
        dec int ey = rand_int_range(1, max_y - 2)
        dec bool on_player = ex == px and ey == py
        dec bool too_close = (ex - px).clamp(-3, 3) == (ex - px) and (ey - py).clamp(-3, 3) == (ey - py)

        if !is_wall(walls, ex, ey) and !is_wall(danger, ex, ey) and !on_player and !too_close {
            enemies = enemies.arr_push(Enemy { x: ex, y: ey })
            placed = placed + 1
        }
    }

    return enemies
}

fn move_enemies(arr[Enemy] enemies, arr[(int, int)] walls, int max_x, int max_y) -> arr[Enemy] {
    dec arr[Enemy] moved = []

    for e in enemies {
        dec int dir = rand_int_range(0, 3)
        dec int nx = e.x
        dec int ny = e.y

        if dir == 0 {
            ny = (e.y - 1).clamp(1, max_y - 2)
        } else if dir == 1 {
            ny = (e.y + 1).clamp(1, max_y - 2)
        } else if dir == 2 {
            nx = (e.x - 1).clamp(1, max_x - 2)
        } else {
            nx = (e.x + 1).clamp(1, max_x - 2)
        }

        if is_wall(walls, nx, ny) {
            moved = moved.arr_push(Enemy { x: e.x, y: e.y })
        } else {
            moved = moved.arr_push(Enemy { x: nx, y: ny })
        }
    }

    return moved
}

fn enemy_hit(arr[Enemy] enemies, int px, int py) -> bool {
    for e in enemies {
        if e.x == px and e.y == py {
            return true
        }
    }
    return false
}

fn draw_walls(arr[(int, int)] walls) {
    for w in walls {
        term_move(w[0], w[1])
        term_print("#")
    }
}

fn draw_danger(arr[(int, int)] danger) {
    for d in danger {
        term_move(d[0], d[1])
        term_print("x")
    }
}

fn erase_enemies(arr[Enemy] enemies) {
    for e in enemies {
        term_move(e.x, e.y)
        term_print(" ")
    }
}

fn draw_enemies(arr[Enemy] enemies) {
    for e in enemies {
        term_move(e.x, e.y)
        term_print("E")
    }
}

fn draw_hud(int max_x, int max_y, int score, int goal_score, int level) {
    term_move(1, max_y + 1)
    term_print(format("level {}   score: {} / {}   (Ctrl+C to return to menu)   ", level.to_string()?, score.to_string()?, goal_score.to_string()?))
}

// ---- game loop ----

fn game_loop(arr[(int,int)] frame, int max_x, int max_y, int level) -> GameResult {
    dec int goal_score = 2 + level

    term_clear()
    draw_border(frame, max_x, max_y)

    dec arr[(int, int)] walls = make_walls(max_x, max_y, level)
    dec int start_x, int start_y = find_start_cell(max_x, max_y, walls)
    dec arr[(int, int)] danger = make_danger(max_x, max_y, level, walls, start_x, start_y)
    dec arr[Enemy] enemies = spawn_enemies(max_x, max_y, level, walls, danger, start_x, start_y)

    draw_walls(walls)
    draw_danger(danger)
    draw_enemies(enemies)

    term_hide_cursor()
    dec Player p = Player { x: start_x, y: start_y, score: 0 }

    dec int goal_x, int goal_y = spawn_goal(max_x, max_y, walls, danger, p.x, p.y)

    term_move(p.x, p.y)
    term_print("@")
    term_move(goal_x, goal_y)
    term_print("*")
    draw_hud(max_x, max_y, p.score, goal_score, level)

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
            "Ctrl:c" => { return GameResult.Quit }
            _ => {}
        }

        if !is_wall(walls, nx, ny) {
            term_move(p.x, p.y)
            term_print(" ")
            p.x = nx
            p.y = ny
            term_move(p.x, p.y)
            term_print("@")
        }

        if is_wall(danger, p.x, p.y) {
            return GameResult.Lose
        }

        if moved {
            erase_enemies(enemies)
            enemies = move_enemies(enemies, walls, max_x, max_y)
            draw_enemies(enemies)
            term_move(p.x, p.y)
            term_print("@")
        }

        if enemy_hit(enemies, p.x, p.y) {
            return GameResult.Lose
        }

        if p.x == goal_x and p.y == goal_y {
            p.score = p.score + 1

            if p.score >= goal_score {
                return GameResult.Win
            }

            dec int new_goal_x, int new_goal_y = spawn_goal(max_x, max_y, walls, danger, p.x, p.y)
            goal_x = new_goal_x
            goal_y = new_goal_y
            term_move(goal_x, goal_y)
            term_print("*")
        }

        draw_hud(max_x, max_y, p.score, goal_score, level)
    }
}

fn show_win_screen(int max_x, int max_y) {
    term_clear()
    dec int center_x = max_x / 2
    dec int center_y = max_y / 2

    dec arr[string] ft, int msg_len = frame_this(" you win! press any key ")
    term_move(center_x - (msg_len / 2), center_y - 1)
    term_print(ft[0])
    term_move(center_x - (msg_len / 2), center_y)
    term_print(ft[1])
    term_move(center_x - (msg_len / 2), center_y + 1)
    term_print(ft[2])

    term_read_key()?
}

fn show_lose_screen(int max_x, int max_y) {
    term_clear()
    dec int center_x = max_x / 2
    dec int center_y = max_y / 2

    dec arr[string] ft, int msg_len = frame_this(" you died! press any key ")
    term_move(center_x - (msg_len / 2), center_y - 1)
    term_print(ft[0])
    term_move(center_x - (msg_len / 2), center_y)
    term_print(ft[1])
    term_move(center_x - (msg_len / 2), center_y + 1)
    term_print(ft[2])

    term_read_key()?
}

fn main() {
    dec arr[int] size = term_get_size()?
    dec int max_x, int max_y = (size[0], size[1])

    dec arr[(int, int)] frame, arr[(int, int)] body = get_size(max_x, max_y)

    dec bool running = true
    dec int level = 1
    dec int best_level = load_best_level()

    while running {
        term_clear()
        draw_border(frame, max_x, max_y)
        dec arr[int] start_button, arr[int] exit_button = draw_main_menu(max_x - 2, max_y - 2, best_level)

        dec bool in_menu = true
        dec int choice = 0
        while in_menu {
            dec string key = term_read_key()?
            term_show_cursor()
            match key {
                "Up" => {
                    if choice == 0 or choice == 2 {
                        term_move(start_button[0], start_button[1])
                        choice = 1
                    }
                }

                "Down" => {
                    if choice == 0 or choice == 1 {
                        term_move(exit_button[0], exit_button[1])
                        choice = 2
                    }
                }

                "Char: " => {
                    if choice == 2 {
                        running = false
                        in_menu = false
                    } else if choice == 1 {
                        in_menu = false
                        dec GameResult gresult = game_loop(frame, max_x, max_y, level)
                        if gresult == GameResult.Win {
                            level = level + 1
                            show_win_screen(max_x, max_y)
                        } else if gresult == GameResult.Lose {
                            level = 1
                            show_lose_screen(max_x, max_y)
                        }
                        // Quit falls back to the menu keeping the current level
                    }
                }
                "Enter" => {
                    if choice == 2 {
                        running = false
                        in_menu = false
                    } else if choice == 1 {
                        in_menu = false
                        dec GameResult gresult = game_loop(frame, max_x, max_y, level)
                        if gresult == GameResult.Win {
                            level = level + 1
                            show_win_screen(max_x, max_y)
                        } else if gresult == GameResult.Lose {
                            level = 1
                            show_lose_screen(max_x, max_y)
                        }
                    }
                }

                "Ctrl:c" => {
                    running = false
                    in_menu = false
                }

                _ => { }
            }
        }
    }
}

!#[final]
fn clean_up() {
    term_leave()
}
