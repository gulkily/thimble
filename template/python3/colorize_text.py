import sys
import os
import re
from collections import Counter
import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize, sent_tokenize
import random
import colorsys

# Download required NLTK data
nltk.download('punkt')
nltk.download('stopwords')

def generate_color():
	h = random.random()
	s = 0.5 + random.random() * 0.5
	v = 0.5 + random.random() * 0.3
	r, g, b = [int(x * 255) for x in colorsys.hsv_to_rgb(h, s, v)]
	return f"#{r:02x}{g:02x}{b:02x}"

def process_text(input_file):
	with open(input_file, 'r', encoding='utf-8') as f:
		text = f.read()

	sentences = sent_tokenize(text)
	words = word_tokenize(text.lower())
	stop_words = set(stopwords.words('english'))
	words = [word for word in words if word.isalnum() and word not in stop_words]

	word_freq = Counter(words)
	total_words = len(words)
	important_words = set([word for word, count in word_freq.items() if count / total_words > 0.001])

	word_colors = {word: generate_color() for word in important_words}
	sentence_colors = [generate_color() for _ in sentences]

	processed_sentences = []
	for sentence, bg_color in zip(sentences, sentence_colors):
		words = word_tokenize(sentence)
		processed_words = []
		for word in words:
			if word.lower() in important_words:
				color = word_colors[word.lower()]
				processed_words.append(f'<span style="color: {color}">{word}</span>')
			else:
				processed_words.append(word)
		processed_sentence = ' '.join(processed_words)
		processed_sentences.append(f'<p style="background-color: {bg_color}">{processed_sentence}</p>')

	return processed_sentences

def generate_html(processed_sentences, output_file):
	script_dir = os.path.dirname(os.path.abspath(__file__))
	
	with open(os.path.join(script_dir, 'template/html/reader.html'), 'r') as f:
		html_template = f.read()
	
	with open(os.path.join(script_dir, 'template/js/reader.js'), 'r') as f:
		js_content = f.read()
	
	with open(os.path.join(script_dir, 'template/css/reader.css'), 'r') as f:
		css_content = f.read()

	content = ''.join(processed_sentences)
	html_output = html_template.replace('{{content}}', content)
	html_output = html_output.replace('{{js_content}}', js_content)
	html_output = html_output.replace('{{css_content}}', css_content)

	with open(output_file, 'w', encoding='utf-8') as f:
		f.write(html_output)

if __name__ == "__main__":
	if len(sys.argv) < 2:
		print("Usage: python script.py input_file [output_file]")
		sys.exit(1)

	input_file = sys.argv[1]
	output_file = sys.argv[2] if len(sys.argv) > 2 else 'output.html'

	processed_sentences = process_text(input_file)
	generate_html(processed_sentences, output_file)
	print(f"HTML file generated: {output_file}")