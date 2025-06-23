// A button used during build phase, which lets you choose which defense tile to place
class DefenseButton
{
  float x, y;
  
  int tileIndex; // The index of tileDefinitions that this button selects
  Tile tile; // The Tile object that this button selects.
  
  // Hard-coded dimensions for all DefenseButtons
  final int W = 150;
  final int H = 184;
  
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
    hovered = (mouseX > x - 1 && mouseX < x + W && mouseY > y && mouseY < y + H);
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
    
    
    imageMode(CENTER);
    float imgHeight = (float) tile.img.height / tile.img.width * 48;
    image(tile.img, x + W/2, y + H/2, 48, imgHeight);
    
    fill(uiTextColor);
    textSize(16);
    textAlign(CENTER);
    text(tileNames[tileIndex], x + W/2, y + 24);
    
    fill(uiSubtleTextColor);
    textAlign(RIGHT);
    text("$" + tilePrices[tileIndex], x + W - 14, y + H - 14);
    
    textAlign(LEFT);
    text(tile.defenseValues[0] + " HP", x + 14, y + H - 14);
    
    // Draw the tooltip
    if (hovered)
    {
      toolTipX = mouseX + 16;
      toolTipY = mouseY;
      toolTipW = W;
      
      int lineCount = 0; // Amount of lines of text in the tooltip
      
      if (tile.type == "static")
      {
        toolTipInfo = "- Blocks enemies &\nprojectiles.";
        lineCount = 2;
      }
      else if (tile.type == "static_ignores_projectiles")
      {
        toolTipInfo = "- Blocks enemies only.\n- Projectiles will fly\nover this wall.";
        lineCount = 3;
      }
      else if (tile.type == "turret")
      {
        toolTipInfo = "- Shoots at enemies.\n- Damage: " + tile.defenseValues[1] + " HP\n- Range: " + tile.defenseValues[2] + " tiles\n- Firerate: " + (int) (((float) 1000/tile.defenseValues[3]) * 60) + "/min";
        lineCount = 4;
      }
      
      toolTipH = lineCount * 16 + 8;
    }
  }
}
