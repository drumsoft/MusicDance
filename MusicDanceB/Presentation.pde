import processing.video.*;

class Presentation {
  PresentationPage[] pages = new PresentationPage[]{
    new PresentationPageImage("slides01.png"),
    new PresentationPageImage("slides02.png"),
    new PresentationPageImage("slides03.png"),
    new PresentationPageImage("slides04.png"),
    new PresentationPageImage("slides05.png"),
    new PresentationPageImage("slides06.png"),
    new PresentationPageImage("slides07.png"),
    new PresentationPageImageAndMovie("slides08.png", "musicDanceBeta.mp4", 440, 240, 520, 390),
    new PresentationPageImage("slides09.png"),
    new PresentationPageImage("slides10.png")
  };
  int max;
  
  int cursor;
  boolean isVisible;
  float x, y, width, height;
  PresentationPage prevImage, currentImage, nextImage;
  
  Presentation(float x, float y, float width, float height) {
    for (int i = 0; i < pages.length; i++) {
      pages[i].setSize(x, y, width, height);
    }
    
    max = pages.length;
    cursor = 0;
    isVisible = false;
    
    prepareImage(0);
  }
  
  void draw() {
    if (!isVisible) return;
    if (currentImage != null) {
      currentImage.draw();
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
      currentImage.stop();
      cursor++;
      prepareImage(1);
      currentImage.start();
    }
  }
  void prev() {
    if (!isVisible) return;
    if (cursor > 0 && prevImage.isLoaded()) {
      currentImage.stop();
      cursor--;
      prepareImage(-1);
      currentImage.start();
    }
  }
  
  void show() {
    if (!isVisible) {
      currentImage.start();
      isVisible = true;
    }
  }
  void hide() {
    if (isVisible) {
      currentImage.stop();
      isVisible = false;
    }
  }
  void toggle() {
    if (isVisible) {
      hide();
    } else {
      show();
    }
  }
  
  // ------------------------------------
  abstract class PresentationPage {
    float x, y, width, height;
    String type;
    PresentationPage() {
    }
    void setSize(float x, float y, float width, float height) {
      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
    }
    abstract void load();
    abstract void unload();
    abstract boolean isLoaded();
    abstract void start();
    abstract void stop();
    abstract void draw();
  }
  
  class PresentationPageImage extends PresentationPage {
    String filename;
    PImage img;
    PresentationPageImage(String filename) {
      super();
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
    void start() {}
    void stop() {}
    void draw() {
      if (img != null && img.width > 0) {
        image(img, x, y, width, height);
      }
    }
  }
  
  class PresentationPageImageAndMovie extends PresentationPageImage {
    String movieName;
    Movie movie;
    float mx, my, mwidth, mheight;
    float dx, dy, dwidth, dheight;
    boolean sizeDecided = false;
    PresentationPageImageAndMovie(String imageName, String movieName, float mx, float my, float mwidth, float mheight) {
      super(imageName);
      this.type = "ImageAndMovie";
      this.movieName = movieName;
      this.mx = mx; this.my = my; this.mwidth = mwidth; this.mheight = mheight;
      
      movie = new Movie(theApplet, movieName);
      movie.stop();
    }
    void load() {
      super.load();
    }
    void unload() {
      super.unload();
    }
    boolean isLoaded() {
      return super.isLoaded();
    }
    void start() {
      movie.loop();
    }
    void stop() {
      movie.pause();
    }
    void draw() {
      super.draw();
      if (movie != null && img.width > 0) {
        if (!sizeDecided) {
          dx = x + mx * width / img.width;
          dy = y + my * height / img.height;
          dwidth = mwidth * width / img.width;
          dheight = mheight * height / img.height;
          sizeDecided = true;
        }
        image(movie, dx, dy, dwidth, dheight);
      }
    }
  }
  
}
