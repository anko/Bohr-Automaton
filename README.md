# Bohr automaton

([GDSE GameJam 2014][1] submission from [Anko][2])

Theme-words: **Heights**, **Automation**, **Destroy**

![screenshot](https://cloud.githubusercontent.com/assets/5231746/4873861/a2a70a3e-622a-11e4-953b-3ed302c79b13.png)

### [Play it](http://cyan.io/bohr-automaton/) | [Browse code](https://github.com/anko/Bohr-Automaton)
<br />

It's a web-based puzzle game; inspired by [Niels Bohr](http://en.wikipedia.org/wiki/Niels_Bohr)'s electron [energy level](https://en.wikipedia.org/wiki/Energy_level) theory.


## How to play

**Aim**: Destroy red anti-electrons around your atom, by touching them with blue electrons.

**Controls**: Arrange the blue electrons with drag-and-drop, then click the nucleus (center circle) to set them off moving automatically. Click on the nucleus again to reset. To skip between levels, click the little level indicators around the nucleus.

**Rules**: (The level progression is structured as a tutorial.) Electrons move clockwise along their orbits. Each has a "spin" (direction indicated by icon), which determines whether it stays at the same orbit height (square), rises by one every step (up arrow) or drops by one every step (down arrow). Electrons disappear if they go above the highest orbit or lower than the lowest. When an electron destroys an anti-electron, it absorbs its spin.


## Tech overview

Written in [LiveScript](http://livescript.net/) in a [functional programming](http://en.wikipedia.org/wiki/Functional_programming) style. [SVG](http://en.wikipedia.org/wiki/Scalable_Vector_Graphics)-rendered with the [D3.js](http://d3js.org/) data-vis library. Sound effects from [Bfxr](http://www.bfxr.net/), ending jingle rendered in [SunVox](http://www.warmplace.ru/soft/sunvox/), played in the browser (optionally) through [WebAudio](http://webaudio.github.io/web-audio-api/).

## Compiling/Running

To build it, you'll need Node.js and standard UNIX utilities (`make` and `ln`). Just run `npm install` in the root directory. The site will build itself into `static/`, in which you can then run a webserver (e.g. [with Python](http://stackoverflow.com/questions/7943751/what-is-the-python3-equivalent-of-python-m-simplehttpserver)).

I haven't tested this on Windows, but if you look at the `makefile` you should be able to piece together what commands you need to run yourself. Email me if you get stuck.

I might get around to putting it online somewhere eventually.


[1]: http://meta.gamedev.stackexchange.com/questions/1794/anniversary-game-jam-2014
[2]: http://gamedev.stackexchange.com/users/7804/anko
