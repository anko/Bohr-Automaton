require! d3

console.log "Hi, I'm alive."

width  = 500px
height = 500px

game-svg = d3.select \body .select \#game .append \svg
  .attr { width, height }

game-svg.append \circle .attr cx : width/2 cy : height/2 r : 25 .style fill : \cyan
