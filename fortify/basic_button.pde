// A simple ('basic') button which does one action when clicked, and can keep track of if it is hovered.
class BasicButton
{
  float x, y;
  int w;
  int fontSize;
  String label; // Text displayed on the button
  
  boolean hovered = false;
  
  BasicButton(float tempX, float tempY, int tempW, int tempFontSize, String tempLabel)
  {
    x = tempX;
    y = tempY;
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
    
    rect(x, y, w, fontSize + 16);
    
    fill(0);
    textSize(fontSize);
    textAlign(CENTER);
    text(label, x + w/2, y + fontSize);
  }
}
