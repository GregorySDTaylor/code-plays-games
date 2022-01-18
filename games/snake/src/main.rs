use rand::{Rng, SeedableRng};
use rand_pcg::Pcg64;
use std::convert::TryFrom;
use std::env;
use std::io;
use std::mem;
use std::str::FromStr;

fn main() {
    let mut args = env::args();
    args.next();
    let size_x = args
        .next()
        .map(|x| {
            x.parse::<isize>()
                .expect(&format!("failed to parse x size input: {}", x))
        })
        .unwrap_or(8);
    let size_y = args
        .next()
        .map(|y| {
            y.parse::<isize>()
                .expect(&format!("failed to parse y size input: {}", y))
        })
        .unwrap_or(8);
    let seed = args
        .next()
        .map(|s| {
            s.parse::<u64>()
                .expect(&format!("failed to parse seed input: {}", s))
        })
        .unwrap_or(0);
    let mut snake_game = SnakeGame::generate(size_x, size_y, seed);
    let mut input_reader = InputReader {
        buffer: String::new(),
    };
    loop {
        match snake_game.state {
            State::Active => println!("{}", snake_game.serialize()),
            State::Win => {
                println!("You win!");
                break;
            }
            State::Lose => {
                println!("You lose!");
                break;
            }
        }
        let input = input_reader.read();
        snake_game.update(input);
    }
}

struct InputReader {
    buffer: String,
}

impl InputReader {
    fn read(&mut self) -> Direction {
        self.buffer.clear();
        io::stdin()
            .read_line(&mut self.buffer)
            .expect("failed to read stdin");
        return Direction::from_str(self.buffer.trim()).expect("failed to parse input");
    }
}

trait Serialize {
    fn serialize(&self) -> String;
}

struct SnakeGame {
    size: Vector,
    prey: Vector,
    snake: Snake,
    rng: Pcg64,
    empty: Vec<Vector>,
    state: State,
    max_size: usize,
}

impl SnakeGame {
    fn generate(size_x: isize, size_y: isize, seed: u64) -> SnakeGame {
        let max_size = usize::try_from(size_x * size_y).expect("invalid size bounds");
        let mut empty: Vec<Vector> = Vec::with_capacity(max_size);
        for x in 0..size_x {
            for y in 0..size_y {
                empty.push(Vector { x: x, y: y });
            }
        }
        let mut seeded_rng = Pcg64::seed_from_u64(seed);
        let prey = empty.swap_remove(seeded_rng.gen_range(0..empty.len()));
        let head = empty.swap_remove(seeded_rng.gen_range(0..empty.len()));
        let mut directions = vec![
            Direction::Up,
            Direction::Right,
            Direction::Down,
            Direction::Left,
        ];
        let mut body = vec![];
        while body.len() == 0 {
            let direction = directions.swap_remove(seeded_rng.gen_range(0..directions.len()));
            let potential_body = head.adjacent(direction);
            if potential_body != prey
                && potential_body.x >= 0
                && potential_body.x < size_x
                && potential_body.y >= 0
                && potential_body.y < size_y
            {
                body.push(potential_body);
            }
        }
        let game_state = SnakeGame {
            size: Vector {
                x: size_x,
                y: size_y,
            },
            prey: prey,
            snake: Snake {
                head: head,
                body: body,
            },
            rng: seeded_rng,
            empty: empty,
            state: State::Active,
            max_size: max_size
        };
        return game_state;
    }

    fn update(&mut self, input: Direction) -> () {
        let next_vector = self.snake.head.adjacent(input);
        if next_vector.x < 0
            || next_vector.x >= self.size.x
            || next_vector.y < 0
            || next_vector.y >= self.size.y
            || self.snake.body.contains(&next_vector)
        {
            self.state = State::Lose;
        } else if next_vector == self.prey {
            if self.snake.body.len() == self.max_size-2 {
                self.state = State::Win;
            } else {
                let next_prey = self
                    .empty
                    .swap_remove(self.rng.gen_range(0..self.empty.len()));
                let old_prey = mem::replace(&mut self.prey, next_prey);
                let old_head = mem::replace(&mut self.snake.head, old_prey);
                self.snake.body.insert(0, old_head);
            }
        } else {
            let old_tail = self.snake.body.remove(self.snake.body.len() - 1);
            self.empty.push(old_tail);
            let old_head = mem::replace(&mut self.snake.head, next_vector);
            self.snake.body.insert(0, old_head);
            self.empty.swap_remove(
                self.empty
                    .iter()
                    .position(|e| e == &self.snake.head)
                    .expect("empty vector not found"),
            );
        }
    }
}

impl Serialize for SnakeGame {
    fn serialize(&self) -> String {
        return format!(
            "{}{}{}",
            self.size.serialize(),
            self.prey.serialize(),
            self.snake.serialize()
        );
    }
}

#[derive(PartialEq, Eq, Hash)]
struct Vector {
    x: isize,
    y: isize,
}

impl Vector {
    fn adjacent(&self, direction: Direction) -> Vector {
        match direction {
            Direction::Up => Vector {
                x: self.x,
                y: self.y + 1,
            },
            Direction::Right => Vector {
                x: self.x + 1,
                y: self.y,
            },
            Direction::Down => Vector {
                x: self.x,
                y: self.y - 1,
            },
            Direction::Left => Vector {
                x: self.x - 1,
                y: self.y,
            },
        }
    }
}

impl Serialize for Vector {
    fn serialize(&self) -> String {
        return format!("({},{})", self.x, self.y);
    }
}

struct Snake {
    head: Vector,
    body: Vec<Vector>,
}

impl Serialize for Snake {
    fn serialize(&self) -> String {
        return format!(
            "{{{}[{}]}}",
            self.head.serialize(),
            self.body
                .iter()
                .map(|vector| vector.serialize())
                .collect::<String>()
        );
    }
}

enum State {
    Active,
    Win,
    Lose,
}

enum Direction {
    Up,
    Right,
    Down,
    Left,
}

impl FromStr for Direction {
    type Err = String;
    fn from_str(input: &str) -> Result<Direction, String> {
        match input {
            "u" => Ok(Direction::Up),
            "r" => Ok(Direction::Right),
            "d" => Ok(Direction::Down),
            "l" => Ok(Direction::Left),
            _ => Err(format!(
                "failed to convert string: {} to Direction, valid values are u, r, d, l",
                input
            )),
        }
    }
}
