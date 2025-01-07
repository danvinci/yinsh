# YINSH

Yinsh is an abstract strategy board game for two players, created by [Kris Burm](https://en.wikipedia.org/wiki/Kris_Burm). It is played on a hexagonal board where players place rings of their color. The objective is to create rows of five markers of the same color, while removing rings from the board to keep track of the score. Rings can only be moved when 'activated' by placing a same-color marker, which is left behind when the ring moves. 

When I started working on this project, I wanted to challenge myself in building it, and create an experience that doesn't require sign-ups: anyone can go to [yinsh.net](https://yinsh.net/) and start playing. This implementation supports any multiple-scoring cases, and handles pre-move scoring when opposite-color rows have been formed by the opponent.

&nbsp;

### Game rules
- The game starts with 5 rings placed by each player.
- Each player, in their own turn, can activate one of their rings by placing a same-color marker in it.
- An activated ring can the be moved, but only in straight lines.
- Rings can't move over other rings.
- Rings can move over markers, but must stop at the first empty slot right after.
- Once a ring is placed, all the hovered markers flip - changing their color.
- If a player gets five markers in a row of their color, they can remove them - as well as one of their rings to mark the score.
- The first to recover three rings wins - or just one ring in the 'quick version' variant of the game.
- More details can be found on the [rules webpage](https://www.gipf.com/yinsh/rules/rules.html) from the game inventor.

&nbsp;

![yinsh_play_server](https://github.com/danvinci/yinsh/assets/15657499/6034f54b-4b22-4559-ad0c-8ec9fd2ad4d9)

&nbsp;

### How to play
The game can be played against the server, or in two-players mode:
- Play > Invite a friend
- Copy the game ID code from the text console
- Pass it to the other player, that will use it to join 

&nbsp;

### Technical bits
I've built it using:
- JavaScript and the Canvas API for the game interface
- SolidJS for the navigation UI
- Julia for everything that runs server-side, including the adversarial 'AI': a minimax heuristic at depth-2
- Deployed using Docker, behind Cloudflare, at [yinsh.net](https://yinsh.net/)


### Improvement ideas
- Add support for touch events (enable to play on tablets)
- Make use of a (low-latency) database server-side (Redis/RocksDB?)
- Add a join by invite link functionality
- Replay/navigate game history in client 
- Make a mobile/tablet/app version
- Performance optimizations in server play
- Make anything exchanged with the client a parameter (eg. ids of markers/players/rings)
- Cleaner implementation of game_runner function
- Simplify state handling in interaction code
- Adding quick game option (first to score wins)
- Dark mode
- Play with strangers / match-making
- New end-game animations
- Smarter adversarial AI
- Got any? Feel free to share, just open an issue on this repo!

&nbsp;

### Credits
- Sounds (CC0 licensed) sourced from [freesound](https://freesound.org/)
- (some) icons (CC0 licensed) sourced from [SVGrepo](https://www.svgrepo.com/)
- Julia [repo](https://github.com/JuliaLang/julia)
- Pluto.jl [repo](https://github.com/fonsp/Pluto.jl)
- HTTP.jl [repo](https://github.com/JuliaWeb/HTTP.jl)
- JSON3.jl [repo](https://github.com/quinnj/JSON3.jl)
- Solid JS [repo](https://github.com/solidjs/solid)

&nbsp;
### License
This work is open-source and licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) - no commercial use is allowed.
