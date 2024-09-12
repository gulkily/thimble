const content = `{{content}}`;
const paragraphs = content.split('</p>').filter(p => p.trim() !== '').map(p => p + '</p>');
let currentIndex = 0;

function updateContent() {
	document.getElementById('previous').innerHTML = currentIndex > 0 ? paragraphs[currentIndex - 1] : '';
	document.getElementById('current').innerHTML = paragraphs[currentIndex];
	document.getElementById('next').innerHTML = currentIndex < paragraphs.length - 1 ? paragraphs[currentIndex + 1] : '';
}

function nextPage() {
	if (currentIndex < paragraphs.length - 1) {
		currentIndex++;
		updateContent();
	}
}

function previousPage() {
	if (currentIndex > 0) {
		currentIndex--;
		updateContent();
	}
}

document.addEventListener('keydown', (event) => {
	if (event.key === 'ArrowRight') {
		nextPage();
	} else if (event.key === 'ArrowLeft') {
		previousPage();
	}
});

updateContent();