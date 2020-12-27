document.addEventListener('DOMContentLoaded', async function() {
    const url = 'http://' + document.domain + ':' + location.port + '/admin/products/delete/';
    const paginationLinks = document.querySelectorAll('.pagination a');

    console.log(paginationLinks);

    document.querySelectorAll('span.delete').forEach(element => {
        element.addEventListener('click', () => {
            const primaryKey = element.dataset.pk;
            fetch(url + primaryKey);
            console.log(url+primaryKey);
            element.closest('tr').remove();
        });
    });

    for (let link of paginationLinks) {
        if (link.href == 'http://' + document.domain + ':' + location.port + '/admin/products') {
            link.href += '?page=1'
        }
    }
});


