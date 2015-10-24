'use strict';

let Mode = require('./mode').Mode;

let Pixi = require('pixi.js');

let slowclap = new Mode("Slow Clap", "Slow Clap (GIF example)");
slowclap.container = new Pixi.Container();

// we need to load the spritesheet once so do it on load.
let setupMovie = () => {

  let frames = [];
  for (var i = 0; i < 7; i++) {
    let val = i < 10 ? '0' + i : i;
    frames.push(Pixi.Texture.fromFrame('citizen-kane-clapping_0' + val + '.png'));
  }

  let movie = new Pixi.extras.MovieClip(frames);
  let scale = new Pixi.Point(192 / movie.width,
                             320 / movie.height);
  movie.position.set(0);
  movie.anchor.set(0);
  movie.scale = scale;
  movie.animationSpeed = 0.5;
  movie.play();

  slowclap.container.addChild(movie);
};

Pixi.loader.add('spritesheet', 'static/images/slow-clap.json').load(setupMovie);

slowclap.start = function(renderer) {

  let update = () => {
    renderer.render(this.container);
    this.renderID = requestAnimationFrame(update);
  };

  this.renderID = requestAnimationFrame(update);
};

slowclap.stop = function() {
  cancelAnimationFrame(this.renderID);
};

module.exports = slowclap;
