# Yinsh

Yinsh is an abstract strategy board game for two players, created by Kris Burm. It is played on a hexagonal board where players place rings of their color. The objective is to create rows of five markers of the same color, while removing rings from the board to keep track of the score. Rings can only be moved when 'activated' by placing a same-color marker, which is left behind when the ring moves. The first to recover three rings wins, or one in the quick version.

## Technical bits
I built a digital version from scratch, using:
- JavaScript and the Canvas API for the game interface
- SolidJS for the navigation UI
- Julia for the game server and adversarial AI, which you can see an example of below:


![yinsh_edit_opt](https://github.com/danvinci/yinsh/assets/15657499/20dca6f6-c764-47a3-ac8b-8ababccaefd8)


The game can be played in two-players mode at [yinsh.net](https://yinsh.net/): you'll need to grab the game ID from the code inspector and pass it to the other player.

## Work in progress
- Making a proper UI to eliminate use of the inspector
- Restore AI server (not working due to breaking API changes)
- Handle game ending
- Handle special edge cases (eg. adversarial scoring > markers selection)
- Adding quick game option (first to score wins)

## License
Work is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)
