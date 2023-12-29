# Yinsh

Yinsh is an abstract strategy board game for two players, created by [Kris Burm](https://en.wikipedia.org/wiki/Kris_Burm). It is played on a hexagonal board where players place rings of their color. The objective is to create rows of five markers of the same color, while removing rings from the board to keep track of the score. Rings can only be moved when 'activated' by placing a same-color marker, which is left behind when the ring moves. 

## Game rules
- The game starts with 5 rings placed for each player
- Each player, in their own turn, can activate one of their rings by placing a same-color marker in it
- An activated ring can only move in straight lines (see visual cues)
- Rings can't move over other rings
- Rings can move over markers, but must stop at the first empty slot afterwards
- Once a ring is placed, all the hovered markers flip - changing their color
- If you get five same-color markers in a row (of your color), you can remove them as well as a ring of your choice to mark your score
- The first to recover three rings wins, or just one ring in the 'quick version' variant of the game

## Technical bits
I built a digital version from scratch, using:
- JavaScript and the Canvas API for the game interface
- SolidJS for the navigation UI
- Julia for the game server and adversarial AI, which you can see an example of below:


![yinsh_edit_opt](https://github.com/danvinci/yinsh/assets/15657499/20dca6f6-c764-47a3-ac8b-8ababccaefd8)


The game can be played in two-players mode at [yinsh.net](https://yinsh.net/): 
- Start a new game
- Grab the game ID code from the console log
- Pass it to the other player, that will need to pick the "Play with a friend > Join with code" option

## Work to be done
- Making a proper UI to eliminate use of the console log
- Responsive canvas resizing
- Add a join by invite link functionality
- Restore AI server (not working due to breaking API changes)
- Handle game ending
- Handle special edge cases (eg. adversarial scoring > markers selection)
- Adding quick game option (first to score wins)
- Add controls for game settings (mode, sounds)
- Make the AI less aggressive/dumb and more organic

## Credits
- (some) Sounds by https://freesound.org/people/ProjectsU012/

## License
Work is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)
