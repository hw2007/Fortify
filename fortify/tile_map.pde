// Class for a grid of tiles (a 'tile map'). This is where all of the placed defenses are stored, rendered, and processed.
class TileMap
{
  float originX, originY; // Origin point (top-left) of the tilemap
  int tileSize; // Width & height of a single tile
  int w, h; // Measured in tiles
  
  int[][] tiles; // Stores all the tiles in the tilemap, as indexes of the tileDefinitions array
  int[][] health; // Stores heath of tiles
  
  // x, y of tile that is highlighted (Used for red effect to show which tile will be destroyed)
  int highlightedX = 0;
  int highlightedY = 0;
  
  TileMap(float tempX, float tempY, int tempTileSize, int tempW, int tempH)
  {
    originX = tempX;
    originY = tempY;
    tileSize = tempTileSize;
    w = tempW;
    h = tempH;
    
    // Setup empty tiles
    tiles = new int[w][h];
    health = new int[w][h];
    
    for (int y = 0; y < h; y++)
    {
      for (int x = 0; x < w; x++)
      {
        setTile(x, y, -1); // '-1' is a blank tile
                           // setTile also sets the health
      }
    }
  }
  
  // Draw tiles & health bars
  void display()
  {
    imageMode(CORNER);
    fill(255);
    textSize(16);
    
    // Draw all the tile images
    for (int y = 0; y < h; y++)
    {
      for (int x = 0; x < w; x++)
      { 
        int tileIndex = getTile(x, y); // Get the tile index at x, y
        
        // Index -1 is a blank tile
        if (tileIndex > -1)
        {
          Tile tile = tileDefinitions[tiles[x][y]];
          
          if (highlightedX == x && highlightedY == y)
          {
            tint(#FF8E8E);
          }
          
          image(tile.img, x * tileSize + originX, y * tileSize + originY + tile.offsetY * (tileSize / tile.img.width), tileSize, (float) tile.img.height / tile.img.width * tileSize);
          tint(255);
        }
      }
    }
    
    // Draw health bars
    for (int y = 0; y < h; y++)
    {
      for (int x = 0; x < w; x++)
      { 
        int tileIndex = getTile(x, y); // Get the tile index at x, y
        
        // Index -1 is a blank tile
        if (tileIndex > -1)
        {
          Tile tile = tileDefinitions[tiles[x][y]];
          // Draw a health bar for this tile
          int maxHealth = tile.defenseValues[0];
          if (health[x][y] < maxHealth)
          {
            drawHealthBar(x * tileSize + originX + tileSize/2, y * tileSize + originY - 8, 24, 12, maxHealth, health[x][y]);
          }
        }
      }
    }
    
    // Reset the highlight
    highlightedX = -1;
    highlightedY = -1;
  }
  
  // Handles all sorts of processing for tiles. Mainly makes towers shoot.
  void tick()
  {
     // Check if the goal tile has been destroyed
    if (getTile(goalTileX, goalTileY) == -1)
    {
      lose = true;
    }
    
    if (lose)
    {
      return; // Do not tick if the game is over
    }
    
    for (int y = 0; y < h; y++)
    {
      for (int x = 0; x < w; x++)
      {
        if (getTile(x, y) > -1)
        {
          Tile tile = tileDefinitions[getTile(x, y)];
          
          if (tile.type == "turret")
          {
            int damage = tile.defenseValues[1]; // Grab the damage value of this turret
            
            // Stores the shortest distance to an enemy found
            float shortestDistance = 999999; // Start with a very large value so that any enemy would be closer
            int nearestEnemyIndex = -1; // Index of enemies array where the nearest enemy is
            
            for (int i = 0; i < enemyCount; i++)
            {
              if (enemies[i].alive)
              {
                float distance = dist(enemies[i].x, enemies[i].y, x * tileSize + originX, y * tileSize + originY);
              
                if (distance < shortestDistance)
                {
                  shortestDistance = distance;
                  nearestEnemyIndex = i;
                }
              }
            }
            
            // defenseValues[2] is the range of this tower in tiles 
            // defenseValues[3] is the cooldown of the tower (time between shots)
                                                                                                // Adding x * y so that all towers don't shoot at once
            if (shortestDistance < tile.defenseValues[2] * tileSize && nearestEnemyIndex != -1 && (frameCount + x * y) % ((float) tile.defenseValues[3]/1000 * 60) == 0)
            {
              // Play bow sound
              bowSounds[(int) random(bowSounds.length)].play();
              // Spawn the projectile
              Enemy targetEnemy = enemies[nearestEnemyIndex];
              spawnProjectile(new Projectile(x * tileSize + originX + tileSize/2, y * tileSize + originY + tileSize/2, 20, targetEnemy.x, targetEnemy.y, 1, damage, x * tileSize + originX + tileSize/2, y * tileSize + originY + tileSize/2));
            }
          }
        }
      }
    }
  }
  
  void setTile(int x, int y, int tile)
  {
    if (x >= 0 && y >= 0 && x <= w - 1 && y <= h - 1)
    {
      tiles[x][y] = tile;
      
      if (tile != -1)
      {
        health[x][y] = tileDefinitions[tile].defenseValues[0]; // Get the max health of the placed tile
      }
      else
      {
        health[x][y] = 0;
      }
    }
  }
  
  // Used to ask which tile is at a specific coordinate
  int getTile(int x, int y)
  {
    if (x >= 0 && y >= 0 && x <= w - 1 && y <= h - 1)
    {
      return tiles[x][y];
    }
    else
    {
      return -2; // -2 will indicate that the requested tile is out of bounds
    }
  }
  
  void damageTile(int x, int y, int damage)
  {
    if (getTile(x, y) == -1) // Empty tiles don't get damaged
    {
      return;
    }
    
    punchSounds[(int) random(punchSounds.length)].play();
    
    health[x][y] -= damage; // Damage the tile
    
    if (health[x][y] <= 0)
    {
      health[x][y] = 0;
      setTile(x, y, -1);
      
      // Create an explosion effect
      explosions[nextExplosionIndex].start(x * tileSize + originX + tileSize/2, y * tileSize + originY + tileSize/2);
      nextExplosionIndex++;
      
      if (nextExplosionIndex >= explosions.length)
      {
        nextExplosionIndex = 0;
      }
      
      // Explosion sound
      explosionSound.play();
    }
  }
  
  void highlightTile(int x, int y)
  {
    highlightedX = x;
    highlightedY = y;
  }
}
