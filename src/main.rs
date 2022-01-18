use std::io::{BufRead, BufReader, Write};
use std::process::{Command, Stdio};
use std::thread;
use ansi_term::Colour;

fn main() {
    println!("starting a new snake game...");

    let game_process = Command::new("./games/snake/target/release/snake")
        .arg("2")
        .arg("2")
        .arg("2")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .expect("game_process failed to start");
    let mut game_reader = BufReader::new(
        game_process
            .stdout
            .expect("failed to get game_process stdout"),
    );
    let mut game_stdin = game_process
        .stdin
        .expect("failed to get game_process stdin");

    let player_process = Command::new("python3")
        .arg("-u")
        .arg("./players/snake/hardcoded/hardcoded.py")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .expect("player_process failed to start");
    let mut player_reader = BufReader::new(
        player_process
            .stdout
            .expect("failed to get game_process stdout"),
    );
    let mut player_stdin = player_process
        .stdin
        .expect("failed to get game_process stdin");

    // TODO player color and executor icon

    let game_publisher = thread::spawn(move || {
        let mut buffer = String::new();
        loop {
            buffer.clear();
            let read_size = game_reader.read_line(&mut buffer).expect("failed to read game stdout");
            print!("{} ", Colour::Red.paint(""));
            if read_size == 0 {
                println!("stdout pipe closed");
                break;
            } else {
                print!("{}", buffer);
                player_stdin.write(buffer.as_bytes()).expect("failed to write to player stdin");
            }
        }
    });

    let player_publisher = thread::spawn(move || {
        let mut buffer = String::new();
        loop {
            buffer.clear();
            let read_size = player_reader.read_line(&mut buffer).expect("failed to read player stdout");
            print!("{} ", Colour::Blue.paint(""));
            if read_size == 0 {
                println!("stdout pipe closed");
                break;
            } else {
                print!("{}", buffer);
                game_stdin.write(buffer.as_bytes()).expect("failed to write to game stdin");
            }
        }
    });

    game_publisher.join().unwrap();
    player_publisher.join().unwrap();
}
