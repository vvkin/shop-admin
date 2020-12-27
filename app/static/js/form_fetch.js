document.addEventListener('DOMContentLoaded', async function() {
    const url = 'http://' + document.domain + ':' + location.port + '/admin/products/_get/';
    const primaryKey = document.querySelector('.product-add').dataset.pk;
    const response = await fetch(url + primaryKey);
    
    if (response.ok) {
        const form = document.querySelector('#product-form');
        data = await response.json(); let targetElement;

        for (let key of Object.keys(data)) {
            targetElement = document.querySelector(`#${key}`);
            targetElement.value = data[key];
        }
    } else {
        console.log('something went wrong...');
    }   
});


