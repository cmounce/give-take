*GiveTake* is a 30-bit-wide keyed pseudorandom permutation, designed for efficient implementation in the ZZT-OOP scripting language.

If that's confusing, think of it like a cipher that encrypts 30-bit messages. A 30-bit number goes in, plus an encryption key, and some other 30-bit number comes out.

Running `./generate.rb 'some arbitrary key'` will generate ZZT-OOP code for computing *GiveTake*, with the given key baked into the generated code. Note that although *GiveTake* is invertible, `./generate.rb` only generates code for the forward permutation.

*GiveTake* gets its name from ZZT-OOP's math instructions: the language was never meant to do any heavy numerical work, so it only has two math commands: `#give` (addition) and `#take` (subtract-or-branch).

I make no claim that *GiveTake* is secure. In fact, I will claim the opposite! 30 bits is ridiculously small, which raises the danger of statistical attacks. The exact danger depends on how you use it, of course, but you should really use something different if you're doing anything serious.

However, if your use case is something silly (e.g., generating game passwords), and an attacker would have an easier way in than cryptanalysis (e.g., reverse-engineering your code), then *GiveTake* might not be the weakest link in your chain of security.
