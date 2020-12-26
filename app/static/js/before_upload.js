function readURL(input) {
    if (input.files && input.files[0]) {
      var reader = new FileReader();
      
      reader.onload = (e) => {
        document.querySelector('#img-preview').setAttribute('src', e.target.result);
      }
      
      reader.readAsDataURL(input.files[0]); // convert to base64 string
    }
}

document.querySelector('#images').onchange = function() {
    readURL(this);
};