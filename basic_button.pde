// A simple ('basic') button which does one action when clicked, and can keep track of if it is hovered.
class BasicButton
{
  float relativeX, relativeY; // Relative x & y (see xSnap, ySnap)
  float x, y; // Actual computed x & y values
  int xSnap, ySnap; // Which side of the screen are relative x and y relative to? 0 = left/top, 1 = right/bottom, 2 = center
  int w;
  int fontSize;
  String label; // Text displayed on the button
  
  boolean hovered = false;
  
  
  BasicButton(float tempX, float tempY, int tempW, int tempFontSize, String tempLabel, int tempXSnap, int tempYSnap)
  {
    relativeX = tempX;
    relativeY = tempY;
    xSnap = tempXSnap;
    ySnap = tempYSnap;
    w = tempW;
    fontSize = tempFontSize;
    label = tempLabel;
  }
  
  void checkForHover()
  {
    hovered = (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + fontSize + 16);
    if (hovered)
    {
      isUIHovered = true; // When this is true, clicking won't place a tile and instead will activate a button
    }
  }
  
  void display()
  {
    rectMode(CORNER);
    strokeWeight(4);
    stroke(uiOutline);
    
    if (hovered)
    {
      fill(uiHover);
    }
    else
    {
      fill(uiBackground);
    }
    
    // Compute real x & y values based on relative & snap
    if (xSnap == 0)
    {
      x = relativeX;
    }
    else if (xSnap == 1)
    {
      x = width - relativeX - w;
    }
    else if (xSnap == 2)
    {
      x = width/2 + relativeX - w/2;
    }
    
    if (ySnap == 0)
    {
      y = relativeY;
    }
    else if (ySnap == 1)
    {
      y = height - relativeY - (fontSize + 16);
    }
    else if (ySnap == 2)
    {
      y = height/2 + relativeY - (fontSize + 16)/2;
    }
    
    rect(x, y, w, fontSize + 16);
    
    fill(uiTextColor);
    textSize(fontSize);
    textAlign(CENTER);
    text(label, x + w/2, y + fontSize);
  }
}
