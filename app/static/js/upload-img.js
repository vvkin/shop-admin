'use strict';

const imgPreview = document.querySelector('.carousel-inner');
const imgInput = document.querySelector('#images');
const imgUpload = document.querySelector('#upload-img');

const refreshPreview = () => {
  while (imgPreview.lastElementChild) {
    imgPreview.removeChild(imgPreview.lastElementChild);
  }
};

const addSlideToPreview = (image) => {
  const slideItem = document.createElement('div');
  slideItem.classList.add('item');
  slideItem.appendChild(image);
  imgPreview.appendChild(slideItem);
  imgPreview.children[0].classList.add('active');
};

const readAndPreview = (file) => { 
  const reader = new FileReader();
  reader.addEventListener('load', () => {
    const image = new Image();
    image.title = file.name;
    image.src = reader.result;
    addSlideToPreview(image);
  });
  reader.readAsDataURL(file);
}

imgUpload.addEventListener('click', () => {
  imgInput.click();
});

imgInput.addEventListener('change', function() {
  const { files } =  this;
  if (files) {
    refreshPreview();
    for (const file of files) {
      readAndPreview(file);
    }
  }
});
