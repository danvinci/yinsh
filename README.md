# YINSH

Yinsh is an abstract strategy board game for two players, created by [Kris Burm](https://en.wikipedia.org/wiki/Kris_Burm). 
It's played on a hexagonal board, where players place rings of their color. The objective is to create rows of five markers of the same color, while removing rings to keep track of the score. 
Just visit [yinsh.net](https://yinsh.net/) to start playing. 

&nbsp;


### Building & Learning
I built this as a way to challenge myself, and create something complete yet minimal and intuitive - no accounts needed, just gameplay. 
Using minimal dependencies, I designed each part of the experience from the ground up: from drawing the board and UI elements to guide gameplay, to handling tricky scoring cases and building an adversarial AI. 
Starting with some working knowledge of Julia and JavaScript, I picked up everything else along the way.

&nbsp;


### Quick Start
- Play against the AI, or invite a friend
- For two-player games: get a game ID code and share it with your opponent
- Pick between random or manual rings setup

&nbsp;


### How to play
- Each player gets 5 rings
- On your turn: place a marker in one of your rings to activate it, then move that ring
- Rings can only move in straight lines
- Rings can't move over other rings
- Rings can move over markers, but must stop at the first empty slot right after 
- Moving a ring over markers will flip all the markers they pass over - changing their color
- Form rows of 5 markers to score: remove the row and one of your rings to mark the score
- The first to remove 3 rings wins (or just 1 ring in quick mode)
- More details on the [rules webpage](https://www.gipf.com/yinsh/rules/rules.html) from the game inventor

&nbsp;

<img width="1902" alt="setup" src="https://github.com/user-attachments/assets/3e37a8e4-5f45-4d72-b9f7-4d8064e32abd" />

&nbsp;

<img width="1901" alt="first_move" src="https://github.com/user-attachments/assets/ae12ae5e-0093-41ea-88a3-bc3b8d0f2742" />

&nbsp;

https://github.com/user-attachments/assets/4a56eeb7-40ad-4ef1-90dd-a9da41e1731e

&nbsp; 

### Technical Stack
- Frontend: JavaScript + Canvas + SolidJS
- Backend: Julia (including the adversarial AI, a minimax heuristic at depth-2)
- Deployment: Docker & NGiNX on a Hetzner VM + Cloudflare

&nbsp;


### Improvement ideas
- Dark mode
- Smarter adversarial AI
- Support for mobile/tablet
- User authentication & game history
- Add a join by invite link functionality
- Replay/navigate game history in client 
- Add quick game option (first to score wins)
- Play with strangers / match-making / tournaments
- New end-game animations

Got any? Just open an issue on this repo!

&nbsp;

### Credits
- Sounds sourced from [freesound](https://freesound.org/) (CC0)
- (some) icons sourced from [SVGrepo](https://www.svgrepo.com/) (CC0)
- Julia [repo](https://github.com/JuliaLang/julia)
- Pluto.jl [repo](https://github.com/fonsp/Pluto.jl)
- HTTP.jl [repo](https://github.com/JuliaWeb/HTTP.jl)
- JSON3.jl [repo](https://github.com/quinnj/JSON3.jl)
- Solid JS [repo](https://github.com/solidjs/solid)

&nbsp;

### License
This work is open-source and licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) - commercial use is not allowed.
