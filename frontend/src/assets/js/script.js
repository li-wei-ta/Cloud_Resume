// Smooth scrolling for navigation
$('.navbar').on('click', 'a[href^="#"]', function (event) {
    event.preventDefault();

    $('html, body').animate({
        scrollTop: $($.attr(this, 'href')).offset().top
    }, 500);
});

const apiUrl = 'https://qr56mfcbve.execute-api.ca-central-1.amazonaws.com/prod/visitors'; 

async function fetchCounter() {
    try {
        const response = await fetch(apiUrl);
        const data = await response.json();
        document.getElementById('visitor-counter').textContent = data.new_count; 
    } catch (error) {
        console.error('Error fetching counter:', error);
    }
}

// Call the counter function when the page loads
fetchCounter();
