# Bohr automaton

([GDSE GameJam 2014][1] submission from [Anko][2])

Theme-words: **Heights**, **Automation**, **Destroy**

![screenshot][3]

### [Play it][4] | [Browse code][5]
<br />

It's a web-based puzzle game; inspired by [Niels Bohr][6]'s electron [energy level][7] theory.


## How to play

**Aim**: Destroy red anti-electrons around your atom, by touching them with blue electrons.

**Controls**: Arrange the blue electrons with drag-and-drop, then click the nucleus (center circle) to set them off moving automatically. Click on the nucleus again to reset. To skip between levels, click the little level indicators around the nucleus.

**Rules**: (The level progression is structured as a tutorial.) Electrons move clockwise along their orbits. Each has a "spin" (direction indicated by icon), which determines whether it stays at the same orbit height (square), rises by one every step (up arrow) or drops by one every step (down arrow). Electrons disappear if they go above the highest orbit or lower than the lowest. When an electron destroys an anti-electron, it absorbs its spin.


## Tech overview

Written in [LiveScript][8] in a [functional programming][9] style. [SVG][10]-rendered with the [D3.js][11] data-vis library. Sound effects from [Bfxr][12], ending jingle rendered in [SunVox][13], played in the browser (optionally) through [WebAudio][14].

## Compiling/Running

Just `npm install` in the root directory.

You'll need [Node.js][15] and basic UNIX utilities (`make` and `cp`). The game will build itself into `static/`, where you can then run a webserver (e.g. [with Python][16]).

I haven't tried building it on Windows, but the `makefile` should give you an idea of how to piece together the commands you need to build it yourself. Email me if you get stuck.

[ISC-licensed][17].


[1]: http://meta.gamedev.stackexchange.com/questions/1794/anniversary-game-jam-2014
[2]: http://gamedev.stackexchange.com/users/7804/anko
[3]: https://cloud.githubusercontent.com/assets/5231746/4873861/a2a70a3e-622a-11e4-953b-3ed302c79b13.png
[4]: http://cyan.io/bohr-automaton/
[5]: https://github.com/anko/Bohr-Automaton
[6]: http://en.wikipedia.org/wiki/Niels_Bohr
[7]: https://en.wikipedia.org/wiki/Energy_level
[8]: http://livescript.net/
[9]: http://en.wikipedia.org/wiki/Functional_programming
[10]: http://en.wikipedia.org/wiki/Scalable_Vector_Graphics
[11]: http://d3js.org/
[12]: http://www.bfxr.net/
[13]: http://www.warmplace.ru/soft/sunvox/
[14]: http://webaudio.github.io/web-audio-api/
[15]: http://nodejs.org/
[16]: http://stackoverflow.com/questions/7943751/what-is-the-python3-equivalent-of-python-m-simplehttpserver)
[17]: http://en.wikipedia.org/wiki/ISC_license
