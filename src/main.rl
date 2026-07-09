get println from std::io
get term_print, term_hide_cursor, term_show_cursor, term_poll, term_move, term_fg, term_bg, term_get_size, term_flush from std::term
get term_enter, term_clear, term_leave, term_read_key, term_move_right, term_move_left, term_move_up, term_move_down from std::term
get arr_range, arr_push, arr_remove, arr_contains, arr_first, arr_last, len from std::array
get repeat, format from std::str
get mod from std::math
get rand_int, rand_int_range from std::random

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

    term_move(max_x - (msg_len + 4) ,max_y - 4)
    term_print(ft[0])
    term_move(max_x - (msg_len + 4) ,max_y - 3)
    term_print(ft[1])
    term_move(max_x - (msg_len + 4) ,max_y - 2)
    term_print(ft[2])
}

fn get_size(int max_x, int max_y) -> (arr[(int, int)], arr[(int, int)]) {
    dec arr[int] Xs = arr_range(0, max_x + 1, 1)
    dec arr[int] Ys = arr_range(0, max_y + 1 , 1)

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

fn draw_main_menu(int max_x, int max_y) -> (arr[int], arr[int]) {
    dec int center_x = max_x / 2
    dec int center_y = max_y / 2

    dec string title = " rl game "
    dec arr[string] ft_title, int title_len = frame_this(title)

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

    term_move(center_x - (start_len), center_y + 3)
    term_print(ft_start[0])
    term_move(center_x - (start_len), center_y + 4)
    term_print(ft_start[1])
    term_move(center_x - (start_len), center_y + 5)
    term_print(ft_start[2])
    // box
    dec int box_start_x = center_x - start_len - 3
    dec int box_start_y = center_y + 4
    term_move(box_start_x, box_start_y - 1)
    term_print(ft_dot[0])
    term_move(box_start_x, box_start_y)
    term_print(ft_dot[1])
    term_move(box_start_x, box_start_y + 1)
    term_print(ft_dot[2])

    term_move(center_x - (exit_len), center_y + 6)
    term_print(ft_exit[0])
    term_move(center_x - (exit_len), center_y + 7)
    term_print(ft_exit[1])
    term_move(center_x - (exit_len), center_y + 8)
    term_print(ft_exit[2])
    // box
    dec int box_exit_x = center_x - exit_len - 3
    dec int box_exit_y = center_y + 7
    term_move(box_exit_x, box_exit_y - 1)
    term_print(ft_dot[0])
    term_move(box_exit_x, box_exit_y)
    term_print(ft_dot[1])
    term_move(box_exit_x, box_exit_y + 1)
    term_print(ft_dot[2])

    return ([box_start_x + 1, box_start_y], [box_exit_x + 1, box_exit_y])
}

fn game_loop(arr[(int,int)] frame, int max_x, int max_y) {
    term_clear()
    draw_border(frame, max_x, max_y)

    term_hide_cursor()
    dec int prev_x = max_x / 2
    dec int prev_y = max_y / 2

    term_move(prev_x, prev_y)
    term_print("@")

    while true {
        dec string key = term_read_key()?
        match key {
            "Up" => {
                term_move(prev_x , prev_y)
                term_print(" ")
                term_move_up(0)
                term_print("@")
                prev_y -= 1
            }

            "Down" => {
                term_move(prev_x, prev_y)
                term_print(" ")
                term_move_down(0)
                term_print("@")
                prev_y += 1
            }

            "Left" => {
                term_move(prev_x, prev_y)
                term_print(" ")
                term_move_left(0)
                term_print("@")
                prev_x -= 1
            }

            "Right" => {
                term_move(prev_x, prev_y)
                term_print(" ")
                term_move_right(0)
                term_print("@")
                prev_x += 1
            }

            "Ctrl:c" => {
                break
            }
        }
    }

}


fn main() {
    dec arr[int] size = term_get_size()?
    dec int max_x, int max_y = (size[0], size[1])

    dec arr[(int, int)] frame, arr[(int, int)] body = get_size(max_x, max_y)

    term_clear()
    draw_border(frame, max_x, max_y)
    dec arr[int] start_button, arr[int] exit_button = draw_main_menu(max_x - 2, max_y - 2)

    dec bool running = true
    dec int choice = 0
    while running {
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
                } else if choice == 1 {
                    running = false
                    game_loop(frame, max_x, max_y)
                }
            }
            "Enter" => {
                if choice == 2 {
                    running = false
                } else if choice == 1 {
                    running = false
                    game_loop(frame, max_x, max_y)
                }
            }

            "Ctrl:c" => {
                break
            }

            _ => {println(key)}
        }
    }
}

!#[final]
fn clean_up() {
    term_leave()
}
