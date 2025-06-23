class Enemy
{
  float x, y;
  int health; // Current health 
  float speed; // How fast this enemy moves
  int maxHealth; // Maximum/starting health
  int damage; // Amount of damage this enemy deals
  int rangeDistance; // The distance that the enemy can shoot from (if it is a ranged type, for example an archer)
  
  String type; // Enemy type. "melee" or "archer"
  
  int reward; // Amount of money earned when this enemy dies
  
  Timer cooldown;
  
  float angle; // The angle this enemy moves along
  boolean alive = true; // Is this enemy alive?
  
  // Position the enemy is targetting
  float targetX;
  float targetY;
  
  float goalTargetX = goalTileX * defenses.tileSize + defenses.tileSize/2;
  float goalTargetY = goalTileY * defenses.tileSize + defenses.tileSize/2;
  
  // Load images
  PImage bodyImage = loadImage("images/enemy.png");
  PImage bowImage = loadImage("images/bow.png");
  PImage swordImage = loadImage("images/sword.png");
  
  Enemy(float tempX, float tempY, float tempSpeed, int tempMaxHealth, int tempDamage, int tempCooldown, String tempType, int tempReward, int tempRangeDistance)
  {
    x = tempX;
    y = tempY;
    speed = tempSpeed;
    maxHealth = tempMaxHealth;
    health = maxHealth;
    damage = tempDamage;
    type = tempType;
    reward = tempReward;
    rangeDistance = tempRangeDistance;
    cooldown = new Timer(tempCooldown);
    
    cooldown.start();
    
    targetX = goalTargetX;
    targetY = goalTargetY;
  }
  
  void move()
  {
    if (!alive || lose) // Do not move if dead or game is over
    {
      return;
    }
    
    float moveX = 0;
    float moveY = 0;
    
    // Once the target has been destroyed, switch back to attacking the goal tile
    if (defenses.getTile(roundToTile(targetX, true), roundToTile(targetY, false)) == -1)
    {
      targetX = goalTargetX;
      targetY = goalTargetY;
    }
    
    // Calculate movement direction
    if (!(type == "archer" && dist(x, y, targetX, targetY) < defenses.tileSize * rangeDistance)) // If the enemy is an archer, and within5 tiles of the goal, it won't move
    {
      angle = atan((y - targetY) / (x - targetX));
    
      // If the enemy is right of the target, the angle must rotate by PI to be aligned
      if (targetX < x)
      {
        angle += PI;
      }
      
      moveX = cos(angle);
      moveY = sin(angle);
    }
    
    // Test if moving in this way would intersect a tile
    float testX = x + moveX * speed + moveX * 24;
    float testY = y + moveY * speed + moveY * 24;
    
    boolean canMoveX = false;
    boolean canMoveY = false;
    
    // If not intersecting, move!
    if (defenses.getTile(roundToTile(testX, true), roundToTile(y, false)) == -1)
    {
      x += moveX * speed;
      canMoveX = true;
    }
    if (defenses.getTile(roundToTile(x, true), roundToTile(testY, false)) == -1)
    {
      y += moveY * speed;
      canMoveY = true;
    }
    
    // If the enemy is hitting a tile, start destroying it.
    // This will only trigger if the cooldown timer is finished
    if (((!canMoveX || moveX == 0) || (!canMoveY || moveY == 0)) && cooldown.isFinished())
    {
      int tileToDamageX;
      int tileToDamageY;
      
      cooldown.start();
      // If the enemy is stuck in a corner, it will randomly damage either the tile above or below
      if (!canMoveX && !canMoveY)
      {
        if ((int) random(2) == 0)
        {
          tileToDamageX = roundToTile(testX, true);
          tileToDamageY = roundToTile(y, false);
        }
        else
        {
          tileToDamageX = roundToTile(x, true);
          tileToDamageY = roundToTile(testY, false);
        }
      }
      else // If not on a corner, just damage the tile it's moving towards
      {
        tileToDamageX = roundToTile(testX, true);
        tileToDamageY = roundToTile(testY, false);
      }
      
      if (type == "melee")
      {
        defenses.damageTile(tileToDamageX, tileToDamageY, damage);
      }
      else if (type == "archer") // Shoot projectile
      {
        restartAudio(bowSounds[(int) random(bowSounds.length)]);
        spawnProjectile(new Projectile(x, y, 20, targetX, targetY, 0, damage, x, y));
        
        // If the archer is stuck against a tile that it cannot hit with arrows (a short wall), deal one damage to the wall to avoid being perminantly stuck
        if (defenses.getTile(tileToDamageX, tileToDamageY) > -1 && tileDefinitions[defenses.getTile(tileToDamageX, tileToDamageY)].type == "static_ignores_projectiles")
        {
          defenses.damageTile(tileToDamageX, tileToDamageY, 1);
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
    
    translate(x, y);
    rotate(angle);
    
    imageMode(CENTER);
    image(bodyImage, 0, 0, 48, 48);
    
    if (type == "melee")
    {
      rotate(PI/2);
      image(swordImage, 38, -12, 20, 48);
      rotate(-PI/2);
    }
    else if (type == "archer")
    {
      image(bowImage, 42, 0, 20, 48);
    }
    
    // Undo translate & rotate
    rotate(-angle);
    translate(-x, -y);
    
    if (health < maxHealth)
    {
      drawHealthBar(x, y - 32, 24, 12, maxHealth, health);
    }
  }
  
  void applyDamage(int damageToApply, float attackerX, float attackerY)
  {
    restartAudio(hurtSounds[(int) random(hurtSounds.length)]);
    
    health -= damageToApply;
    if (health <= 0)
    {
      alive = false;
      money += reward;
    }
    
    // Start attacking the attacker, if this enemy is currently aiming for the goal
    if (targetX == goalTargetX && targetY == goalTargetY)
    {
      targetX = attackerX;
      targetY = attackerY;
    }
  }
}
