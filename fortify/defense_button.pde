// A button used during build phase, which lets you choose which defense tile to place
class DefenseButton
{
  float x, y;
  
  int tileIndex; // The index of tileDefinitions that this button selects
  Tile tile; // The Tile object that this button selects.
  
  // Hard-coded dimensions for all DefenseButtons
  final int W = 150;
  final int H = 225;
  
  boolean hovered = false;
  
  DefenseButton(int tempTileIndex, float tempX, float tempY)
  {
    x = tempX;
    y = tempY;
    
    tileIndex = tempTileIndex;
    tile = tileDefinitions[tileIndex];
  }
  
  void checkForHover()
  {
    hovered = (mouseX > x && mouseX < x + W && mouseY > y && mouseY < y + H);
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
    
    if (selectedTile == tileIndex)
    {
      fill(uiHover);
    }
    else if (hovered)
    {
      fill(uiHover);
    }
    else
    {
      fill(uiBackground);
    }
    
    rect(x, y, W, H);
    
    if (selectedTile == tileIndex)
    {
      stroke(uiHighlight);
      noFill();
      rect(x + 4, y + 4, W - 8, H - 8);
    }
    
    
    imageMode(CORNER);
    float imgHeight = (float) tile.img.height / tile.img.width * 48;
    image(tile.img, x + W/2 - 24, y + 8, 48, imgHeight);
    
    float textX = x + 8;
    float textY = y + imgHeight + 24;
    fill(0);
    textSize(16);
    textAlign(LEFT);
    text(tileNames[tileIndex], textX, textY);
    
    String info = "";
    if (tile.type == "static")
    {
      info = "- Blocks enemies &\nprojectiles";
    }
    else if (tile.type == "static_ignores_projectiles")
    {
      info = "- Blocks enemies\n- Projectiles fly over\nthis defense";
    }
    else if (tile.type == "turret")
    {
      info = "- Shoots at enemies\n- Deals " + tile.defenseValues[1] + " damage";
    }
    
    info = info + "\n- Has " + tile.defenseValues[0] + " health";
    
    fill(96);
    text(info, textX, textY + 16);
    
    fill(0);
    text("$" + tilePrices[tileIndex], textX, y + H - 8);
  }
}
