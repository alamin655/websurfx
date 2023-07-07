/**
 * Selects the input element for search
 * @type {HTMLInputElement}
 */
const searchBox = document.querySelector('input');

/**
 * Redirects the user to the search results page with the query parameter
 */
function searchWeb() {
  const query = searchBox.value.trim();
  if (query) {
    window.location.href = `search?q=${encodeURIComponent(query)}`;
  }
}

// Adds an event listener to the search box for the 'keyup' event
searchBox.addEventListener('keyup', (e) => {
  // If the 'Enter' key is pressed, call the searchWeb function
  if (e.key === 'Enter') {
    searchWeb();
  }
});
