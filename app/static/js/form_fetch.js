document.addEventListener('DOMContentLoaded', async function() {
    const baseUrl = 'http://' + document.domain + ':' + location.port + '/admin/products/';
    const preview = document.querySelector('.carousel-inner');
    const primaryKey = document.querySelector('.product-add').dataset.pk;
    const response = await fetch(baseUrl + '_get/' + primaryKey);

    if (response.ok) {
        let data = await response.json(); let targetElement;
        
        for (let key of Object.keys(data)) {
            targetElement = document.querySelector(`#${key}`);
            if (key == 'unit_price') {
                targetElement.value = (+data[key]).toFixed(3);
            } else {
                targetElement.value = data[key];
            }
        }

        data = await (await fetch(baseUrl + 'images/_get/' + primaryKey)).json();
        const images = data.images;
        if (images.length > 0) {
            preview.removeChild(preview.children[0]);
            for(img of images) {
                addToCarousel(img);
            }
        }
    } else {
        console.log('something went wrong...');
    }   

    function addToCarousel(src) {
        const slideItem = document.createElement('div');
        slideItem.classList.add('item');
        const img = document.createElement('img');
        img.src = src;
        slideItem.appendChild(img);
        preview.appendChild(slideItem);
        preview.children[0].classList.add('active');
    }
});


