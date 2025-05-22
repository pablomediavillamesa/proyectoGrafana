
const canvas = document.getElementById("gameCanvas");
const ctx = canvas.getContext("2d");

const gridSize = 40;
const tileCount = canvas.width / gridSize;
let snake = [{ x: 10, y: 10 }];
let direction = { x: 0, y: 0 };
let food = { x: 5, y: 5 };
let score = 0;

function drawGame() {
    updateSnake();
    checkCollision();
    clearScreen();
    drawSnake();
    drawFood();
    updateScore();
}

function clearScreen() {
    ctx.fillStyle = "black";
    ctx.fillRect(0, 0, canvas.width, canvas.height);
}

function drawSnake() {
    ctx.fillStyle = "#0f0";
    snake.forEach(segment => {
        ctx.fillRect(segment.x * gridSize, segment.y * gridSize, gridSize - 2, gridSize - 2);
    });
}

function drawFood() {
    ctx.fillStyle = "red";
    ctx.fillRect(food.x * gridSize, food.y * gridSize, gridSize - 2, gridSize - 2);
}

function updateSnake() {
    const head = { x: snake[0].x + direction.x, y: snake[0].y + direction.y };
    snake.unshift(head);

    if (head.x === food.x && head.y === food.y) {
        score++;
        food = {
            x: Math.floor(Math.random() * tileCount),
            y: Math.floor(Math.random() * tileCount)
        };
    } else {
        snake.pop();
    }
}

function checkCollision() {
    const head = snake[0];

    if (head.x < 0 || head.x >= tileCount || head.y < 0 || head.y >= tileCount) {
        resetGame();
    }

    for (let i = 1; i < snake.length; i++) {
        if (head.x === snake[i].x && head.y === snake[i].y) {
            resetGame();
        }
    }
}

function updateScore() {
    document.getElementById("scoreValue").innerText = score;
}

function resetGame() {
    alert("Fin del juego. Puntuación: " + score);
    snake = [{ x: 10, y: 10 }];
    direction = { x: 0, y: 0 };
    score = 0;
}

document.addEventListener("keydown", e => {
    switch (e.key) {
        case "ArrowUp": if (direction.y === 0) direction = { x: 0, y: -1 }; break;
        case "ArrowDown": if (direction.y === 0) direction = { x: 0, y: 1 }; break;
        case "ArrowLeft": if (direction.x === 0) direction = { x: -1, y: 0 }; break;
        case "ArrowRight": if (direction.x === 0) direction = { x: 1, y: 0 }; break;
    }
});

setInterval(drawGame, 100);
