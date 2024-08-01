document.addEventListener('click', function(e) {
    if(e.target && e.target.classList.contains('expand-link')) {
        e.preventDefault();
        var messageId = e.target.getAttribute('data-message-id');
        var fullMessage = document.getElementById('full-message-' + messageId);
        if(fullMessage.style.display === 'none') {
            fullMessage.style.display = 'block';
            e.target.textContent = 'Show Less';
        } else {
            fullMessage.style.display = 'none';
            e.target.textContent = 'Show More';
        }
    }
});
