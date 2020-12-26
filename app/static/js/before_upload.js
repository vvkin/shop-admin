document.addEventListener('DOMContentLoaded', function() {
  const preview = document.querySelector('.carousel-inner');
  const imagesInput = document.querySelector('#images');
  const UploadImg = document.querySelector('#upload-img');

  UploadImg.addEventListener('click', () => {
    imagesInput.click();
  });

  imagesInput.addEventListener('change', function() {
    if (this.files) {
      refreshPreview()
      for (let file of this.files) {
        readAndPreview(file);
      }
    }
  });

  function refreshPreview() {
    while (preview.lastElementChild) {
      preview.removeChild(preview.lastElementChild);
    }
  }

  function addSlideToPreview(image) {
    const slideItem = document.createElement('div');
    slideItem.classList.add('item');
    slideItem.appendChild(image);
    preview.appendChild(slideItem);
    preview.children[0].classList.add('active');
  }
  
  function readAndPreview(file) { 
    const reader = new FileReader();
    
    reader.addEventListener('load', function() {
      const image = new Image();
      image.title = file.name;
      image.src = this.result;
      addSlideToPreview(image);
    });
    reader.readAsDataURL(file);
  }
});