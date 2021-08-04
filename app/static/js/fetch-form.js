'use strict';

const baseUrl = `http://${location.host}/admin/products`;
const preview = document.querySelector('.carousel-inner');
const primaryKey = document.querySelector('.product-add').dataset.pk;

const addToCarousel = (src) => {
  const slideItem = document.createElement('div');
  const img = document.createElement('img');
  img.src = src;
  slideItem.classList.add('item');
  slideItem.appendChild(img);
  preview.appendChild(slideItem);
  preview.children[0].classList.add('active');
};

const fetchForm = async () => {
  const response = await fetch(`${baseUrl}/_get/${primaryKey}`);
  if (!response.ok) return;

  const data = await response.json();
  for (const key in data) {
    const target = document.querySelector(`#${key}`);
    const value = data[key];
    target.value = (key === 'unit_price') ? (+value).toFixed(3) : value;
  }
};

const fetchImages = async () => {
  const response = await fetch(`${baseUrl}/images/_get/${primaryKey}`);
  if (!response.ok) return;

  const { images } = await response.json();
  if (images.length) {
    preview.removeChild(preview.children[0]);
    images.forEach(addToCarousel);
  }
};

fetchForm();
fetchImages();