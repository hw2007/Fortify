// A simple animated explosion, used when a tile gets destroyed
class Explosion
{
  float x, y = 0;
  int frame = 0; // The frame the animation is currently on
  Timer frameTime = new Timer(100); // Amount of time (ms) between frames
  boolean finished = false; // Is the animation finished?
  
  String[] frameNames = { // File names of each frame, without file extension
    "explosion-01",
    "explosion-02",
    "explosion-03",
    "explosion-04",
    "explosion-05"
  };
  
  PImage[] frames = new PImage[frameNames.length];
  
  Explosion()
  {
    // Load frames
    for (int i = 0; i < frames.length; i++)
    {
      frames[i] = loadImage("images/" + frameNames[i] + ".png");
    }
  }
  
  void animate()
  {
    if (finished) // Do not draw if finished
    {
      return;
    }
    
    imageMode(CENTER);
    image(frames[frame], x, y, 64, 64); // Draw the region of the image which cooresponds to the current frame
    
    if (frameTime.isFinished())
    {
      frame++; // Move ahead one frame
      
      if (frame < frames.length) // Check if the animation is not over
      {
        frameTime.start();
      }
      else // Else, if it is over
      {
        finished = true;
      }
    }
  }
  
  void start(float tempX, float tempY)
  {
    x = tempX;
    y = tempY;
    
    frame = 0;
    finished = false;
    
    frameTime.start();
  }
}
