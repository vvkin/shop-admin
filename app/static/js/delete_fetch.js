const url = 'http://' + document.domain + ':' + location.port + '/admin/products/delete/';

document.querySelectorAll('span.delete').forEach(element => {
    element.addEventListener('click', () => {
        const primaryKey = element.dataset.pk;
        fetch(url + primaryKey);
        console.log(url+primaryKey);
        element.closest('tr').remove();
    });
});
