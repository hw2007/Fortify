// This class does nothing on its own, it only stores information to be used by TileMap
class Tile
{
  String imgName; // Name of the image used for the tile
  
  PImage img; // Image object for rendering
  int offsetY; // A y offset to apply when this tile is rendered, measuring in pixels on the tile
  
  String type;
  /*
  The avilable tile types are:
  static - A tile which does nothing except take damage, eg walls
  static_ignores_projectiles - Same as static, but arrows will fly over instead of damaging this tile.
  turret - A tile which shoots projectiles at the nearest enemy, within a specified range
  goal - The center of the base which the player must protect, and enemies try to reach and destroy. Destruction of this tile ends the game.
  */
  int[] defenseValues; // Any values relating to the behaviour of this defense is stored here
                      // Ex. health, damage delt if the tower is offensive, range of tower, etc
  /*
  DEFENSEVALUES DOCUMENTATION
  [0] is always health, and is used by all defenses
  [1] is the damage a defense deals
  [2] is the range of a turret
  [3] is the attack cooldown of a turret
  */
  
  Tile(String tempImgName, int tempOffsetY, String tempType, int[] tempDefenseValues)
  {
    imgName = tempImgName;
    offsetY = tempOffsetY;
    
    type = tempType;
    defenseValues = tempDefenseValues;
  }
  
  // Load the img from imgName
  void loadImg()
  {
    img = loadImage("data/tiles/" + imgName + ".png");
  }
}
