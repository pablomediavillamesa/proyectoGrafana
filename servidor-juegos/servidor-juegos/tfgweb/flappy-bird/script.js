// Configuración inicial del canvas y variables de juego
var ctx = myCanvas.getContext("2d");
var FPS = 40;
var jump_amount = -10;        // Altura del salto
var max_fall_speed = 10;      // Velocidad máxima de caída
var acceleration = 1;         // Aceleración por gravedad
var pipe_speed = -2;          // Velocidad de los tubos
var game_mode = "prestart";   // Estados: prestart, running, over
var time_game_last_running;
var bottom_bar_offset = 0;
var pipes = [];
var scoreSent = false;        // Controla el envío de la puntuación

// Clase para representar sprites del juego (pájaro, tubos, etc.)
function MySprite(img_url) {
  this.x = 0;
  this.y = 0;
  this.visible = true;
  this.velocity_x = 0;
  this.velocity_y = 0;
  this.MyImg = new Image();
  this.MyImg.src = img_url || "";
  this.angle = 0;
  this.flipV = false;
  this.flipH = false;
}

// Método para dibujar y actualizar cada sprite
MySprite.prototype.Do_Frame_Things = function () {
  ctx.save();
  ctx.translate(this.x + this.MyImg.width / 2, this.y + this.MyImg.height / 2);
  ctx.rotate((this.angle * Math.PI) / 180);
  if (this.flipV) ctx.scale(1, -1);
  if (this.flipH) ctx.scale(-1, 1);
  if (this.visible) ctx.drawImage(this.MyImg, -this.MyImg.width / 2, -this.MyImg.height / 2);
  this.x += this.velocity_x;
  this.y += this.velocity_y;
  ctx.restore();
};

// Función para verificar colisiones entre sprites
function ImagesTouching(thing1, thing2) {
  if (!thing1.visible || !thing2.visible) return false;
  return !(thing1.x >= thing2.x + thing2.MyImg.width || thing1.x + thing1.MyImg.width <= thing2.x ||
           thing1.y >= thing2.y + thing2.MyImg.height || thing1.y + thing1.MyImg.height <= thing2.y);
}

// Función que maneja la entrada del jugador (solo tecla espacio)
function Got_Player_Input(e) {
  if (e.code === 'Space') {
    switch (game_mode) {
      case "prestart":
        game_mode = "running";
        fetch('/metrics_logger.php?game=flappy&event=start'); // Métrica de inicio
        break;
      case "running":
        bird.velocity_y = jump_amount; // Hace saltar al pájaro
        break;
      case "over":
        if (new Date() - time_game_last_running > 1000) {
          reset_game();
          game_mode = "running";
          fetch('/metrics_logger.php?game=flappy&event=start'); // Métrica de reinicio
        }
        break;
    }
  }
  e.preventDefault();
}
addEventListener("keydown", Got_Player_Input);

// Función que aplica la gravedad y revisa los límites del canvas
function make_bird_slow_and_fall() {
  if (bird.velocity_y < max_fall_speed) bird.velocity_y += acceleration;
  if (bird.y > myCanvas.height - bird.MyImg.height || bird.y < 0 - bird.MyImg.height) {
    bird.velocity_y = 0;
    game_mode = "over";
  }
}

// Añade pares de tubos en la posición dada
function add_pipe(x_pos, top_of_gap, gap_width) {
  var top_pipe = new MySprite(pipe_piece.src); top_pipe.x = x_pos; top_pipe.y = top_of_gap - pipe_piece.height; top_pipe.velocity_x = pipe_speed; pipes.push(top_pipe);
  var bottom_pipe = new MySprite(pipe_piece.src); bottom_pipe.flipV = true; bottom_pipe.x = x_pos; bottom_pipe.y = top_of_gap + gap_width; bottom_pipe.velocity_x = pipe_speed; pipes.push(bottom_pipe);
}

// Cambia la inclinación del pájaro según su velocidad
function make_bird_tilt_appropriately() {
  bird.angle = bird.velocity_y < 0 ? -15 : Math.min(bird.angle + 4, 70);
}

// Muestra todos los tubos en pantalla
function show_the_pipes() { pipes.forEach(pipe => pipe.Do_Frame_Things()); }

// Verifica si el pájaro colisiona con algún tubo
function check_for_end_game() { pipes.forEach(pipe => { if (ImagesTouching(bird, pipe)) game_mode = "over"; }); }

// Muestra instrucciones iniciales
function display_intro_instructions() {
  ctx.font = "25px Arial"; ctx.fillStyle = "white"; ctx.textAlign = "center";
  ctx.fillText("Presiona ESPACIO para comenzar", myCanvas.width / 2, myCanvas.height / 4);
}

// Muestra Game Over y puntuación
function display_game_over() {
  var score = pipes.reduce((s, pipe) => (pipe.x < bird.x ? s + 5 : s), 0);
  if (!scoreSent) { fetch('/metrics_logger.php?game=flappy&event=score&score=' + score); scoreSent = true; }
  ctx.font = "30px Arial"; ctx.fillStyle = "red"; ctx.textAlign = "center";
  ctx.fillText("Game Over", myCanvas.width / 2, 100);
  ctx.fillText("Score: " + score, myCanvas.width / 2, 150);
  ctx.font = "20px Arial"; ctx.fillText("Presiona ESPACIO para reiniciar", myCanvas.width / 2, 300);
}

// Muestra la barra inferior en movimiento
function display_bar_running_along_bottom() {
  if (bottom_bar_offset < -23) bottom_bar_offset = 0;
  ctx.drawImage(bottom_bar, bottom_bar_offset, myCanvas.height - bottom_bar.height);
}

// Reinicia el juego
function reset_game() { bird.y = myCanvas.height / 2; bird.angle = 0; pipes = []; add_all_my_pipes(); scoreSent = false; }

// Añade múltiples tubos para formar el escenario
function add_all_my_pipes() {
  const positions = [[500, 100, 140],[800, 50, 140],[1000, 250, 140],[1200, 150, 120],[1600, 100, 120],[1800, 150, 120],
  [2000, 200, 120],[2200, 250, 120],[2400, 30, 100],[2700, 300, 100],[3000, 100, 80],[3300, 250, 80],[3600, 50, 60]];
  positions.forEach(p => add_pipe(...p));
  var finish_line = new MySprite("http://s2js.com/img/etc/flappyend.png"); finish_line.x = 3900; finish_line.velocity_x = pipe_speed; pipes.push(finish_line);
}

// Carga de imágenes
var pipe_piece = new Image(); pipe_piece.onload = add_all_my_pipes; pipe_piece.src = "http://s2js.com/img/etc/flappypipe.png";
var bottom_bar = new Image(); bottom_bar.src = "http://s2js.com/img/etc/flappybottom.png";
var bird = new MySprite("http://s2js.com/img/etc/flappybird.png"); bird.x = myCanvas.width / 3; bird.y = myCanvas.height / 2;

// 🚀 Bucle principal del juego
function Do_a_Frame() {
  ctx.fillStyle = "#b3e5fc"; // Fondo azul cielo pálido
  ctx.fillRect(0, 0, myCanvas.width, myCanvas.height);
  bird.Do_Frame_Things(); display_bar_running_along_bottom();
  switch (game_mode) {
    case "prestart": display_intro_instructions(); break;
    case "running": time_game_last_running = new Date(); bottom_bar_offset += pipe_speed; show_the_pipes(); make_bird_tilt_appropriately(); make_bird_slow_and_fall(); check_for_end_game(); break;
    case "over": make_bird_slow_and_fall(); display_game_over(); break;
  }
}

setInterval(Do_a_Frame, 1000 / FPS);
