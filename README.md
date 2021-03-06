# Bohr automaton

([GDSE Anniversary Game Jam 2014][1] submission from [Anko][2]; written in 3 days)

Theme-words: **Heights**, **Automation**, **Destroy**

![screenshot][3]

### [Play it][4] | [Browse code][5]
(Tested in Chrome/Chromium. Others may have rendering bugs.)
<br />

It's a web-based puzzle game; inspired by [Niels Bohr][6]'s electron [energy level][7] theory.


## How to play

**Aim**: Destroy red anti-electrons around your atom, by touching them with electrons.

**Controls**: Arrange the green electrons with drag-and-drop, then click the nucleus (center circle) to set them off moving automatically. Click on the nucleus again to reset. To skip between levels, click the little level indicators around the nucleus.

**Rules**: (The levels are tutorial-like, so maybe just play it.) Electrons move clockwise along their orbits. Each has a "spin" (direction indicated by icon), which determines whether it stays at the same orbit height (square), rises by one every step (up arrow) or drops by one every step (down arrow). Electrons disappear if they go above the highest orbit or lower than the lowest. When an electron destroys an anti-electron, it absorbs its spin and starts moving in that way.


## Tech overview

Written in [LiveScript][8] in a [functional programming][9] style. [SVG][10]-rendered with the [D3.js][11] data-vis library. Sound effects from [Bfxr][12], ending jingle rendered in [SunVox][13], played in the browser (optionally) through [WebAudio][14].

The `client.ls`-file contains all the interesting parts. I tried to keep it legible and commented, but there's only so much you can do in a weekend. :)

## Compiling/Running

Just `npm install` in the root directory.

You'll need [Node.js][15] and basic UNIX utilities (`make` and `cp`). The game will build itself into `static/`, where you can then run a webserver (e.g. [with Python][16]), then open the game in a browser—preferably Chrome or Chromium (mobile is good too).

I haven't tried building it on Windows, but the `makefile` should give you an idea of how to piece together the commands you need to build it yourself. Email me if you get stuck.

If you're on a UNIX-like with `inotify`-support in your kernel (newest Linuxes do), then `make watch` is a handy helper: It waits for changes to the LiveScript code and recompiles it to JavaScript automatically whenever the file changes.

License is [ISC][17].


[1]: http://meta.gamedev.stackexchange.com/questions/1794/anniversary-game-jam-2014
[2]: http://gamedev.stackexchange.com/users/7804/anko
[3]: https://cloud.githubusercontent.com/assets/5231746/4877072/3c75a0f6-62dc-11e4-8e63-2538a1a4de21.png
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
