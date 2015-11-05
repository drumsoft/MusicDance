class Presentation {
  PresentationPage[] pages = new PresentationPage[]{
    new PresentationPageImage("slides01.png"),
    new PresentationPageImage("slides02.png"),
    new PresentationPageImage("slides03.png"),
    new PresentationPageImage("slides04.png"),
    new PresentationPageImage("slides05.png"),
    new PresentationPageImage("slides06.png"),
    new PresentationPageImage("slides07.png"),
    new PresentationPageImage("slides08.png"),
    new PresentationPageImage("slides09.png"),
    new PresentationPageImage("slides10.png")
  };
  int max;
  
  int cursor;
  boolean isVisible;
  float x, y, width, height;
  PresentationPage prevImage, currentImage, nextImage;
  
  Presentation(float x, float y, float width, float height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    
    max = pages.length;
    cursor = 0;
    isVisible = false;
    
    prepareImage(0);
  }
  
  void draw() {
    if (!isVisible) return;
    if (currentImage != null) {
      currentImage.draw(x, y, width, height);
    }
  }
  
  void prepareImage(int step) {
    if (step == 1) {
      if (prevImage != null) prevImage.unload();
      prevImage = currentImage;
      currentImage = nextImage;
      nextImage = cursor + 1 < max ? pages[cursor + 1] : null;
      if (nextImage != null) nextImage.load();
    } else if (step == -1) {
      if (nextImage != null) nextImage.unload();
      nextImage = currentImage;
      currentImage = prevImage;
      prevImage = cursor > 0 ? pages[cursor - 1] : null;
      if (prevImage != null) prevImage.load();
    } else if (step == 0) {
      if (currentImage == null) currentImage = pages[cursor];
      if (currentImage != null && !currentImage.isLoaded()) currentImage.load();
      if (cursor > 0 && prevImage == null) prevImage = pages[cursor - 1];
      if (prevImage != null && !prevImage.isLoaded()) prevImage.load();
      if (cursor + 1 < max && nextImage == null) nextImage = pages[cursor + 1];
      if (nextImage != null && !nextImage.isLoaded()) nextImage.load();
    }
  }
  
  void next() {
    if (!isVisible) return;
    if (cursor + 1 < max && nextImage.isLoaded()) {
      cursor++;
      prepareImage(1);
    }
  }
  void prev() {
    if (!isVisible) return;
    if (cursor > 0 && prevImage.isLoaded()) {
      cursor--;
      prepareImage(-1);
    }
  }
  
  void show() {
    isVisible = true;
  }
  void hide() {
    isVisible = false;
  }
  void toggle() {
    isVisible = !isVisible;
  }
  
  // ------------------------------------
  abstract class PresentationPage {
    String type;
    String filename;
    PresentationPage() {
    }
    abstract void load();
    abstract void unload();
    abstract boolean isLoaded();
    abstract void draw(float  x, float  y, float  width, float  height);
  }
  
  class PresentationPageImage extends PresentationPage {
    PImage img;
    PresentationPageImage(String filename) {
      this.type = "Image";
      this.filename = filename;
    }
    void load() {
      img = requestImage(filename);
    }
    void unload() {
      img = null;
    }
    boolean isLoaded() {
      return img != null && img.width > 0;
    }
    void draw(float x, float y, float width, float height) {
      if (img != null && img.width > 0) {
        image(img, x, y, width, height);
      }
    }
  }
  
}
