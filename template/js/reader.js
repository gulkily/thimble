let currentPage = 0;

function displayPage(pageNum) {
    document.getElementById('content').innerHTML = pages[pageNum];
    document.getElementById('prev').disabled = pageNum === 0;
    document.getElementById('next').disabled = pageNum === pages.length - 1;
}

function changePage(delta) {
    currentPage = Math.max(0, Math.min(currentPage + delta, pages.length - 1));
    displayPage(currentPage);
}

document.addEventListener('keydown', function(event) {
    if (event.key === 'ArrowLeft') {
        changePage(-1);
    } else if (event.key === 'ArrowRight') {
        changePage(1);
    }
});

displayPage(currentPage);
