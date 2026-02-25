import gleeunit
import neon/ssl

pub fn main() -> Nil {
  let assert Ok(Nil) = ssl.start()

  gleeunit.main()
}
