import re
import random
import math

def generate_color(word):
    # Simple hash function to generate a unique color for each word
    hash_value = sum(ord(c) for c in word)
    hue = hash_value % 360
    saturation = 70 + (hash_value % 30)
    lightness = 40 + (hash_value % 30)
    return f"hsl({hue}, {saturation}%, {lightness}%)"

def colorize_text(text):
    words = re.findall(r'\b\w+\b', text)
    colorized_words = []
    for word in words:
        color = generate_color(word.lower())
        colorized_words.append(f'<span style="color: {color};">{word}</span>')
    return ' '.join(colorized_words)

def create_html(input_file, output_file, words_per_page=200):
    with open(input_file, 'r') as file:
        text = file.read()

    words = re.findall(r'\b\w+\b', text)
    pages = [words[i:i+words_per_page] for i in range(0, len(words), words_per_page)]

    html_content = '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Colorized Text</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                line-height: 1.6;
                margin: 0;
                padding: 20px;
                display: flex;
                flex-direction: column;
                align-items: center;
                min-height: 100vh;
            }
            #content {
                max-width: 800px;
                text-align: justify;
                margin-bottom: 20px;
            }
            #navigation {
                display: flex;
                justify-content: space-between;
                width: 200px;
            }
            button {
                padding: 5px 10px;
                font-size: 16px;
            }
        </style>
    </head>
    <body>
        <div id="content"></div>
        <div id="navigation">
            <button id="prev" onclick="changePage(-1)">Previous</button>
            <button id="next" onclick="changePage(1)">Next</button>
        </div>
        <script>
            const pages = [
    '''

    for page in pages:
        html_content += f"'{colorize_text(' '.join(page))}',\n"

    html_content += '''
            ];
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

            displayPage(currentPage);
        </script>
    </body>
    </html>
    '''

    with open(output_file, 'w') as file:
        file.write(html_content)

# Usage
input_file = 'input.txt'  # Replace with your input text file
output_file = 'output.html'  # The generated HTML file
create_html(input_file, output_file)
