class Projectile
{
  float x, y;
  float velocityX, velocityY;
  float angle; // Projectile travels along this angle, and the velocities above are calculated from one velocity parameter below
  int owner; // Who shot this projectile? 0 == shot by an enemy, will damage tiles. 1 == shot by tower, will damage enemies.
  int damage; // Damage this projectile will deal
  
  // Position of the object that shot this projectile
  float ownerX;
  float ownerY;
  
  boolean alive = true;
  
  PImage img = loadImage("images/arrow.png"); // Arrow image
  
  Projectile(float tempX, float tempY, float velocity, float targetX, float targetY, int tempOwner, int tempDamage, float tempOwnerX, float tempOwnerY)
  {
    x = tempX;
    y = tempY;
    
    angle = atan((y - targetY) / (x - targetX));
    
    // If the projectile is right of the target, the angle must rotate by PI to be aligned
    if (targetX < x)
    {
      angle += PI;
    }
    
    velocityX = cos(angle) * velocity;
    velocityY = sin(angle) * velocity;
    
    owner = tempOwner;
    damage = tempDamage;
    
    ownerX = tempOwnerX;
    ownerY = tempOwnerY;
  }
  
  void move()
  {
    if (!alive || lose) // Do not move if dead or game is over
    {
      return;
    }
    
    x += velocityX;
    y += velocityY;
    
    if (owner == 0) // Hit tiles
    {
      int tileIndex = defenses.getTile(roundToTile(x, true), roundToTile(y, false));
      if (tileIndex > -1)
      {
        if (tileDefinitions[tileIndex].type != "static_ignores_projectiles") // Ignore tiles which are immune to projectiles
        {
          defenses.damageTile(roundToTile(x, true), roundToTile(y, false), damage);
          alive = false;
        }
      }
    }
    else if (owner == 1) // Hit enemies
    {
      for (int i = 0; i < enemyCount; i++)
      {
        if (enemies[i].alive && isPointInCircle(x, y, enemies[i].x, enemies[i].y, 24))
        {
          enemies[i].applyDamage(damage, ownerX, ownerY); // Damage the enemy
          alive = false;
        }
      }
    }
  }
  
  void display()
  {
    if (!alive)
    {
      return;
    }
    
    // Translate so the rotation with be centered
    translate(x, y);
    rotate(angle);
    
    // Draw the projectile
    imageMode(CENTER);
    image(img, 0, 0, 32, 12);
    
    // Undo the translate and rotation
    rotate(-angle);
    translate(-x, -y);
  }
}
