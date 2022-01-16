use std::process::{Command, Stdio};
use std::io::{BufReader, BufRead, Write};

fn main() {
    let child_process = Command::new("python3")
        .arg("./temp_source/helloworld.py")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .expect("python script failed to start");
    let buf_reader = BufReader::new(child_process.stdout.unwrap());
    let mut child_stdin = child_process.stdin.unwrap();
    child_stdin.write(b"hello from rust\n").unwrap();
    for line in buf_reader.lines() {
        println!("rust received: {}", line.unwrap());
    }
}
