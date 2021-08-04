'use strict';

const baseUrl = `http://${location.host}/admin/products`;
const paginationLinks = document.querySelectorAll('.pagination a');
const deleteControls= document.querySelectorAll('span.delete');

for (const link of paginationLinks) {
  if (link.href === baseUrl) {
    link.href += '?page=1';
  }
}

for (const control of deleteControls) {
  control.addEventListener('click', async () => {
    const primaryKey = control.dataset.pk;
    const response = await fetch(`${baseUrl}/delete/${primaryKey}`);
    if (response.ok) control.closest('tr').remove();
  });
}
