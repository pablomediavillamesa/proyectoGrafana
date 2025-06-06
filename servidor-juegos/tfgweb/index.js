function vote(game, event) {
    fetch(`/metrics_likes_logger.php?game=${game}&event=${event}`);
}

document.querySelector('.game-card:nth-child(1) .like').addEventListener('click', function() {
    vote('flappy', 'like');
});
document.querySelector('.game-card:nth-child(1) .dislike').addEventListener('click', function() {
    vote('flappy', 'dislike');
});
document.querySelector('.game-card:nth-child(2) .like').addEventListener('click', function() {
    vote('fruit', 'like');
});
document.querySelector('.game-card:nth-child(2) .dislike').addEventListener('click', function() {
    vote('fruit', 'dislike');
});
