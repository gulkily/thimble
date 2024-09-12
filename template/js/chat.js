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

function NewChat() {
	// Get form elements
	var form = document.querySelector('form[action="/chat.html"]');
	var messageInput = form.querySelector('textarea[name="message"]');
	var authorInput = form.querySelector('input[name="author"]');

	// Get form data
	var message = messageInput.value;
	var author = authorInput.value;

	// Create FormData object
	var formData = new FormData(form);

	// Create and send XHR request
	var xhr = new XMLHttpRequest();
	xhr.open('POST', '/chat.html', true);
	xhr.onload = function() {
		if (xhr.status === 200) {
			// Request successful, add the message to the chat
			var timestamp = new Date().toLocaleString(); // You might want to get this from the server response
			var addMessageToChatResult = AddMessageToChat(author, timestamp, message);

			// Clear the message input
			messageInput.value = '';
		} else {
			console.error('Request failed. Status:', xhr.status);
		}
	};
	xhr.onerror = function() {
		console.error('Request failed. Network error.');
	};
	xhr.send(formData);

	// Prevent form from submitting normally
	return false;
}

function AddMessageToChat (author, timestamp, content, full_content, expand_link, hashtags) {
	if (document && document.getElementById) {
		var chatMessages = document.getElementById('chat-messages');

		if (chatMessages) {
			var newMessage = document.createElement('div');
			newMessage.setAttribute('class', 'message');

			// Create message header
			var messageHeader = document.createElement('div');
			messageHeader.setAttribute('class', 'message-header');

			var authorSpan = document.createElement('span');
			authorSpan.setAttribute('class', 'author');
			authorSpan.textContent = author;

			var timestampSpan = document.createElement('span');
			timestampSpan.setAttribute('class', 'timestamp');
			timestampSpan.textContent = timestamp;

			messageHeader.appendChild(authorSpan);
			messageHeader.appendChild(timestampSpan);

			// Create message content
			var messageContent = document.createElement('div');
			messageContent.setAttribute('class', 'message-content');
			messageContent.textContent = content;

			// Append elements to newMessage
			newMessage.appendChild(messageHeader);
			newMessage.appendChild(messageContent);

			// Add full_content if provided
			if (full_content) {
				var fullContentDiv = document.createElement('div');
				fullContentDiv.innerHTML = full_content;
				newMessage.appendChild(fullContentDiv);
			}

			// Add expand_link if provided
			if (expand_link) {
				var expandLinkDiv = document.createElement('div');
				expandLinkDiv.innerHTML = expand_link;
				newMessage.appendChild(expandLinkDiv);
			}

			// Add hashtags if provided
			if (hashtags) {
				var hashtagsDiv = document.createElement('div');
				hashtagsDiv.setAttribute('class', 'message-hashtags');
				hashtagsDiv.textContent = hashtags;
				newMessage.appendChild(hashtagsDiv);
			}

			// Append the new message to chat-messages
			chatMessages.appendChild(newMessage);
		} else {
			console.error("Element with id 'chat-messages' not found");
		}
	} else {
		console.error("Document or getElementById not supported");
	}
}

function PingUrl (url, ele) { // loads arbitrary url via image or xhr
// compatible with most js
	//alert('DEBUG: PingUrl() begins');

	// another option below
	// var img = document.createElement('img');
	// img.setAttribute("src", url);
	// document.body.appendChild(img);

	if (!ele) {
		ele = 0;
	}

	if (!url) {
		// #todo more sanity here
		//alert('DEBUG: PingUrl: warning: url was FALSE');
		return '';
	}

	//alert('DEBUG: PingUrl: url = ' + url);

	if (window.XMLHttpRequest) {
		//alert('DEBUG: PingUrl: window.XMLHttpRequest was true');

		var xmlhttp;
		if (window.xmlhttp) {
			xmlhttp = window.xmlhttp;
		} else {
			window.xmlhttp = new XMLHttpRequest();
			xmlhttp = window.xmlhttp;
		}

		if ((window.GetPrefs) && GetPrefs('show_admin')) {
			// skip callback to save resources
		} else {
			xmlhttp.onreadystatechange = window.PingUrlCallback;
		}

		xmlhttp.open("HEAD", url, true);
		//xmlhttp.timeout = 5000; //#xhr.timeout
		xmlhttp.send();

		return false;
	} else {
		//alert('DEBUG: PingUrl: using image method, no xhr here');

		if (document.images) {
			//alert('DEBUG: PingUrl: document.images was true');
			if (document.images.length) {
				// use last image on page, if possible. this should be the special pixel image.
				var img = document.images[document.images.length - 1];

				if (img) {
					img.setAttribute("src", url);
					return false;
				}
			} else {
				var img = document.images[0];

				if (img) {
					img.setAttribute("src", url);
					return false;
				}
			}
		} else {
			//alert('DEBUG: PingUrl: warning: document.images was FALSE');
		}
	}

	return true;
} // PingUrl()