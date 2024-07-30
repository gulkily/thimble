import re
import random
import math
import argparse
from collections import Counter

def generate_color(word):
    hash_value = sum(ord(c) for c in word)
    hue = hash_value % 360
    saturation = 60 + (hash_value % 30)
    lightness = 30 + (hash_value % 20)
    return f"hsl({hue}, {saturation}%, {lightness}%)"

def is_important_word(word, word_counts):
    stopwords = set(['the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'])
    return word.lower() not in stopwords and word_counts[word.lower()] > 1

def colorize_text(text, word_counts):
    words = re.findall(r'\b\w+\b', text)
    colorized_words = []
    for word in words:
        if is_important_word(word, word_counts):
            color = generate_color(word.lower())
            colorized_words.append(f'<span style="color: {color};">{word}</span>')
        else:
            colorized_words.append(word)
    return ' '.join(colorized_words)

def create_html(input_file, output_file, words_per_page=200):
    with open(input_file, 'r') as file:
        text = file.read()

    words = re.findall(r'\b\w+\b', text)
    word_counts = Counter(word.lower() for word in words)
    pages = [words[i:i+words_per_page] for i in range(0, len(words), words_per_page)]

    with open('template/html/reader.html', 'r') as template_file:
        html_template = template_file.read()

    with open('template/css/reader.css', 'r') as css_file:
        css_content = css_file.read()

    with open('template/js/reader.js', 'r') as js_file:
        js_content = js_file.read()

    colorized_pages = [colorize_text(' '.join(page), word_counts) for page in pages]
    pages_json = ',\n'.join(f"'{page}'" for page in colorized_pages)

    html_content = html_template.replace('{{STYLES}}', css_content)
    html_content = html_content.replace('{{SCRIPT}}', js_content)
    html_content = html_content.replace('{{PAGES}}', pages_json)

    with open(output_file, 'w') as file:
        file.write(html_content)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert text file to colorized HTML")
    parser.add_argument("-i", "--input", default="input.txt", help="Input text file")
    parser.add_argument("-o", "--output", default="reader.html", help="Output HTML file")
    args = parser.parse_args()

    create_html(args.input, args.output)