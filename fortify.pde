// Braden Schneider
// CS30 Final Project - "Fortify"

import ddf.minim.*;
Minim minim;

// Game version
final String VERSION = "v1.2";

// Get user OS
String OS = System.getProperty("os.name").toLowerCase();

// Enables some debug features for use in development
boolean debug = false;

// Tracks the state of WASD keys
boolean[] wasd = new boolean[4];
final int CAMERA_SPEED = 15; // Camera move speed

// Manages background music
MusicManager backgroundMusic = new MusicManager();

// The action the player is currently doing in build mode. 0 for place tiles, 1 for remove, 2 for repair, -1 for none
// This is used to allow dragging to repeat an action
int buildAction = -1;

/*
Defines the properties of each tile, including image, health, type, etc. See Tile class for more info
 */
Tile[] tileDefinitions = {
  new Tile("goal_tower", -23, "goal", new int[] {100}),
  new Tile("short_mud_wall", -8, "static_ignores_projectiles", new int[] {7}),
  new Tile("tall_mud_wall", -15, "static", new int[] {10}),
  new Tile("short_wall", -8, "static_ignores_projectiles", new int[] {18}),
  new Tile("tall_wall", -15, "static", new int[] {24}),
  new Tile("archer_tower", -22, "turret", new int[] {12, 1, 6, 750}),
  new Tile("strong_archer_tower", -22, "turret", new int[] {18, 2, 7, 500})
};

// Friendly names for tiles, used for displaying on defense tile buttons
String[] tileNames = {
  "Goal Tower",
  "Short Mud Wall",
  "Tall Mud Wall",
  "Short Stone Wall",
  "Tall Stone Wall",
  "Archer Tower",
  "Strong Archer Tower"
};

// Prices of tiles, displayed on defense buttons
int[] tilePrices = {
  0, // There is an entry for goal tower even though the goal tower isn't purchasable, simply to keep array indexes the same as tileDefinitions
  5,
  10,
  10,
  15,
  25,
  60
};

// Various UI buttons
DefenseButton[] defenseButtons = new DefenseButton[tileDefinitions.length - 1];
BasicButton waveStartButton; // Button to start wave
BasicButton restartButton; // Button to restart after losing
BasicButton hideHowToPlayButton; // Button to hide how to play screen
BasicButton showHowToPlayButton; // Button to show how to play screen again

// Tooltip attributes. Tooltip is used for showing extra info on defenseButton hover.
float toolTipX = -999;
float toolTipY = -999;
float toolTipW = 0;
float toolTipH = 0;
String toolTipInfo = "Hello, World!\nFoo\nBar";

PFont dpComic; // The dpComic font

boolean isUIHovered = false; // Keeps track of if any UI elements are hovered, used to make sure that clicking UI will not place a defense

// Sounds!
AudioPlayer explosionSound;
AudioPlayer[] punchSounds = new AudioPlayer[5]; // Used when enemies damage defenses
AudioPlayer[] hurtSounds = new AudioPlayer[5];
AudioPlayer[] bowSounds = new AudioPlayer[3];
AudioPlayer buildMusic; // Background music for build phase
AudioPlayer fightMusic; // Background music for fight phase

// UI Colors

final color uiBackground = color(255, 160);
final color uiOutline = color(255);
final color uiHover = color(255);
final color uiHighlight = color(148, 128, 97);
final color uiTextColor = color(0);
final color uiSubtleTextColor = color(96);
final color uiSecondaryBackground = color(0, 160);
final color uiSecondaryOutline = color(0);
final color uiSecondaryTextColor = color(255);

// EXPERIMENTAL/UNFINISHED DARK THEME
/*
final color uiBackground = color(32, 160);
final color uiOutline = color(32);
final color uiHover = color(32);
final color uiHighlight = color(148, 128, 97);
final color uiTextColor = color(255);
final color uiSubtleTextColor = color(160);
final color uiSecondaryBackground = color(128, 196);
final color uiSecondaryOutline = color(128);
final color uiSecondaryTextColor = color(255);
*/
// All of these variables are given values in the resetGame() function!

TileMap defenses; // Tile map where the placed defenses are stored

Enemy[] enemies; // Array of enemies
int enemyCount; // Amount of enemies currently existing
int amountOfEnemiesSpawned; // Amount of enemies ever spawned in the wave
int nextEnemyIndex; // The index of enemies which should be overwritten on the next spawn

Projectile[] projectiles; // Array of projectiles
int projectileCount; // Amount of projectiles
int nextProjectileIndex; // The index of projectiles which should be overwritten the next time one is fired

Explosion[] explosions; // Array of explsion animations
int nextExplosionIndex; // The index of explosions which should be played next time an explosion is needed

// The tile the mouse is currently hovered over
int mouseTileX;
int mouseTileY;

float cameraX;
float cameraY;

// The X and Y coordinates of the tile the goal tile on the defenses tilemap
// Enemies will try to approach this tile
int goalTileX;
int goalTileY;

// Wave-related variables
int currentWave;
int waveState; // 0 is build phase, 1 is enemy attack phase
// Values for the current wave
int totalEnemies;
String[] enemyTypes;
int meleeDamage;
int rangeDamage;
float enemySpeed;
int rangeDistance;
int enemyHealth;
int meleeAttackCooldown;
int rangeAttackCooldown;
int killReward;
Timer enemySpawn;

int selectedTile; // The tile currently selected for build phase

int money; // Amount of money the player has

boolean lose; // Has the game been lost?

boolean showHowToPlay; // Show the 'how to play' dialogue?

void setup()
{
  println("Operating system is: \"" + OS + "\"");

  size(960, 540);
  surface.setResizable(true);
  surface.setTitle("Fortify (" + VERSION + ")");
  frameRate(60); // Lock frame rate in case the user has a high fps display
  pixelDensity(1);
  noSmooth(); // Makes upscaled images (ie pixel art) not blurry

  PImage appIcon = loadImage("app_icon.png");
  PImage appIconPadded = loadImage("app_icon_padded.png");

  // Set app icon
  if (OS.contains("mac"))
  {
    print("Using padded icon\n");
    surface.setIcon(appIconPadded);
  }
  else
  {
    surface.setIcon(appIcon);
  }

  // Load the images for all tiles
  for (int i = 0; i < tileDefinitions.length; i++)
  {
    tileDefinitions[i].loadImg();

    if (i > 0)
    {
      defenseButtons[i - 1] = new DefenseButton(i, 20 + (i - 1) * 150, height - 204);
    }
  }

  dpComic = createFont("dpcomic.ttf", 128, false);
  textFont(dpComic);

  resetGame(); // Set up variables

  // Set up some buttons
  waveStartButton = new BasicButton(20, 20, 480, 64, "Start Wave 1 >>", 1, 1);
  restartButton = new BasicButton(0, 125, 500, 64, "Try Again", 2, 2);
  hideHowToPlayButton = new BasicButton(0, 280, 500, 64, "Hide Tutorial", 2, 2);
  showHowToPlayButton = new BasicButton(20, 124, 80, 64, "?", 1, 1);

  // Load sounds
  minim = new Minim(this);

  explosionSound = minim.loadFile("sounds/explosion.wav");
  for (int i = 0; i < punchSounds.length; i++)
  {
    punchSounds[i] = minim.loadFile("sounds/punch" + i + ".wav");
  }
  for (int i = 0; i < hurtSounds.length; i++)
  {
    hurtSounds[i] = minim.loadFile("sounds/hurt" + i + ".wav");
  }
  for (int i = 0; i < bowSounds.length; i++)
  {
    bowSounds[i] = minim.loadFile("sounds/bow" + i + ".wav");
  }

  buildMusic = minim.loadFile("sounds/music_build.wav");
  fightMusic = minim.loadFile("sounds/music_fight.wav");

  // Makes lines not have rounded endpoints
  strokeCap(SQUARE);
}

void draw()
{
  background(#236419);

  // Update background music
  backgroundMusic.play();

  // Handle WASD camera movement
  if (wasd[0]) // W key
  {
    cameraY -= CAMERA_SPEED;
  }
  if (wasd[1]) // A key
  {
    cameraX -= CAMERA_SPEED;
  }
  if (wasd[2]) // S key
  {
    cameraY += CAMERA_SPEED;
  }
  if (wasd[3]) // D key
  {
    cameraX += CAMERA_SPEED;
  }

  translate(-cameraX, -cameraY);

  // Draw a box around the defenses tilemap
  noFill();
  strokeWeight(4);
  stroke(255, 32);
  rectMode(CORNER);
  rect(defenses.originX, defenses.originY, defenses.w * defenses.tileSize, defenses.h * defenses.tileSize);

  // Handle enemies
  int deadEnemyCount = 0; // Count how many enemies are dead. The wave will end when all enemies have been killed.
  for (int i = 0; i < enemyCount; i++)
  {
    enemies[i].move();
    enemies[i].display();

    if (!enemies[i].alive)
    {
      deadEnemyCount++;
    }
  }

  if (deadEnemyCount >= enemyCount && amountOfEnemiesSpawned >= totalEnemies) // All enemies are dead, and enemies are finished spawning
  {
    // Increment the wave, change to build mode
    currentWave++;
    waveState = 0;

    // Reset enemies
    enemyCount = 0;
    amountOfEnemiesSpawned = 0;
    nextEnemyIndex = 0;
    enemies = new Enemy[enemies.length];

    // Increase some values each wave
    totalEnemies = int(totalEnemies * 1.5);

    if (currentWave == 4) // Archers are added on the third wave
    {
      enemyTypes = (String[]) append(enemyTypes, "archer");
    }
    if (currentWave % 2 == 0) // Happens every even wave
    {
      enemyHealth++;
      if (killReward < 8)
      {
        killReward += 1;
      }
      meleeDamage++;
      rangeDamage++;
    }
    if (currentWave % 2 != 0) // Every odd wave
    {
      meleeAttackCooldown -= 100;
      rangeAttackCooldown -= 100;

      if (meleeAttackCooldown < 40)
      {
        meleeAttackCooldown = 40;
        rangeAttackCooldown = 40;
      }
    }
    // Every wave
    enemySpawn.finishedTime -= 125;

    if (enemySpawn.finishedTime < 40)
    {
      enemySpawn.finishedTime = 40;
    }

    enemySpeed += 0.75;

    if (enemySpeed > 10)
    {
      enemySpeed = 10;
    }
  }

  // Display defense tiles
  defenses.tick();
  defenses.display();

  // Display explosions
  for (int i = 0; i < explosions.length; i++)
  {
    explosions[i].animate();
  }

  // Handle projectiles
  for (int i = 0; i < projectileCount; i++)
  {
    projectiles[i].move();
    projectiles[i].display();
  }

  // Calculate the tile that the mouse is hovering
  if (mouseX < defenses.originX || mouseY < defenses.originY || isUIHovered || waveState == 1) // To avoid wierdness when the mouse is to the left or up from the tilemap's origin, set the tile position to (-1, -1)
  {
    mouseTileX = -1;
    mouseTileY = -1;
  } else
  {
    mouseTileX = roundToTile(mouseX + cameraX, true);
    mouseTileY = roundToTile(mouseY + cameraY, false);

    int tileIndex = defenses.getTile(mouseTileX, mouseTileY);

    if (tileIndex == -1) // If the hovered tile is empty (can place there)
    {
      // Draw a small 3x3 grid around the mouse cursor
      strokeWeight(4);
      stroke(uiBackground);
      float x = mouseTileX * defenses.tileSize + defenses.originX - defenses.tileSize;
      float y = mouseTileY * defenses.tileSize + defenses.originY - 2;
      line(x, y, x + defenses.tileSize * 3, y);
      x = mouseTileX * defenses.tileSize + defenses.originX - defenses.tileSize;
      y = mouseTileY * defenses.tileSize + defenses.originY + defenses.tileSize + 2;
      line(x, y, x + defenses.tileSize * 3, y);
      x = mouseTileX * defenses.tileSize + defenses.originX - 2;
      y = mouseTileY * defenses.tileSize + defenses.originY - defenses.tileSize;
      line(x, y, x, y + defenses.tileSize * 3);
      x = mouseTileX * defenses.tileSize + defenses.originX + defenses.tileSize + 2;
      y = mouseTileY * defenses.tileSize + defenses.originY - defenses.tileSize;
      line(x, y, x, y + defenses.tileSize * 3);

      // Draw a ghost of the tile about to be placed
      tint(255, 128);
      Tile tile = tileDefinitions[selectedTile];
      imageMode(CORNER);
      image(tile.img, mouseTileX * defenses.tileSize + defenses.originX, mouseTileY * defenses.tileSize + defenses.originY + tile.offsetY * (defenses.tileSize / tile.img.width), defenses.tileSize, (float) tile.img.height / tile.img.width * defenses.tileSize);
      tint(255);

      // Warn the player if the tile is too expensive to place
      if (money < tilePrices[selectedTile])
      {
        toolTipX = mouseX + 16;
        toolTipY = mouseY;
        toolTipW = 140;
        toolTipH = 24;
        
        toolTipInfo = "Too expensive!";
      }

      // Draw a ring around the tower's range
      if (tileDefinitions[selectedTile].type == "turret")
      {
        noFill();
        strokeWeight(4);
        stroke(uiBackground);
        ellipseMode(CENTER);

        int range = tileDefinitions[selectedTile].defenseValues[2] * defenses.tileSize * 2;

        ellipse(mouseTileX * defenses.tileSize + defenses.originX + defenses.tileSize/2, mouseTileY * defenses.tileSize + defenses.originY + defenses.tileSize/2, range, range);
      }

      // Place tiles
      if (buildAction == 0) // buildAction 0 is placing tiles
      {
        if (money >= tilePrices[selectedTile])
        {
          restartAudio(punchSounds[(int) random(punchSounds.length)]); // Punch sound is used for placing tiles

          defenses.setTile(mouseTileX, mouseTileY, selectedTile);
          money -= tilePrices[selectedTile];
        }
      }
    } else if (tileIndex > -1) // If the hovered tile isn't empty
    {
      defenses.highlightTile(mouseTileX, mouseTileY); // Highlight hovered tile in red

      if (tileDefinitions[tileIndex].type == "turret") // If hovering a turret, show its range
      {
        noFill();
        strokeWeight(4);
        stroke(uiBackground);
        ellipseMode(CENTER);

        int range = tileDefinitions[tileIndex].defenseValues[2] * defenses.tileSize * 2;

        ellipse(mouseTileX * defenses.tileSize + defenses.originX + defenses.tileSize/2, mouseTileY * defenses.tileSize + defenses.originY + defenses.tileSize/2, range, range);
      }

      int health = defenses.health[mouseTileX][mouseTileY]; // Get the health value of the hovered tile
      int maxHealth = tileDefinitions[tileIndex].defenseValues[0]; // Get the tile's max health
      int repairCost = tilePrices[tileIndex] - int((float) health / maxHealth * tilePrices[tileIndex]); // Calculate a repair cost based on how damaged the tile is

      // Remove/repair the tile. This cannot be done if the hovered tile is the goal tile (index 0).
      if (tileIndex != 0)
      {
        // Remove tiles
        if (buildAction == 1) // buildAction 1 is removing tiles
        {
          int refund = tilePrices[tileIndex] - repairCost; // Calculate refund based on how damaged the tile is
          money += refund;

          restartAudio(punchSounds[(int) random(punchSounds.length)]); // Punch sound for removing tile

          defenses.setTile(mouseTileX, mouseTileY, -1);
        }

        // Display repair cost if the tile is damaged
        if (health < maxHealth)
        {
          toolTipX = mouseX + 16;
          toolTipY = mouseY;
          toolTipW = 140;
          toolTipH = 40;
          
          if (repairCost <= money) // Can afford the repair
          {
            toolTipInfo = "Repair cost: " + repairCost + "\nRight click to repair";
          } 
          else // Cannot afford to repair
          {
            toolTipInfo = "Repair cost: " + repairCost + "\nToo expensive!";
          }

          // Repair tiles
          if (buildAction == 2) // buildAction 2 is repairing tiles
          {
            if (money >= repairCost)
            {
              restartAudio(punchSounds[(int) random(punchSounds.length)]); // Punch sound for repair

              money -= repairCost;
              defenses.health[mouseTileX][mouseTileY] = maxHealth;
            }
          }
        }
      }
      else // Display special goal tile tooltip
      {
        toolTipX = mouseX + 16;
        toolTipY = mouseY;
        toolTipW = 140;
        toolTipH = 56;
        
        toolTipInfo = "This is your castle.\nDefend it at all costs!\nHealth: " + defenses.health[mouseTileX][mouseTileY] + "/" + tileDefinitions[0].defenseValues[0];
      }
    }
  }

  // Spawn enemies
  if (waveState == 1 && enemySpawn.isFinished() && amountOfEnemiesSpawned < totalEnemies && !lose)
  {
    enemySpawn.start();

    int spawnEdge = (int) random(4); // Choose which screen edge to spawn the level on
    float x = 0;
    float y = 0;

    // Select x and y positions based on the chosen level edge
    if (spawnEdge == 0)
    {
      x = defenses.originX;
      y = random(defenses.originY, defenses.originY + defenses.tileSize * defenses.h);
    } else if (spawnEdge == 1)
    {
      x = defenses.originX + defenses.tileSize * defenses.w;
      y = random(defenses.originY, defenses.originY + defenses.tileSize * defenses.h);
    } else if (spawnEdge == 2)
    {
      x = random(defenses.originX, defenses.originX + defenses.tileSize * defenses.w);
      y = defenses.originY;
    } else if (spawnEdge == 3)
    {
      x = random(defenses.originX, defenses.originX + defenses.tileSize * defenses.w);
      y = defenses.originY + defenses.tileSize * defenses.h;
    }

    // Spawn the enemy
    String type = enemyTypes[(int) random(enemyTypes.length)];
    int damage = 0;
    int cooldown = 0;

    if (type == "archer")
    {
      damage = rangeDamage;
      cooldown = rangeAttackCooldown;
    } else if (type == "melee")
    {
      damage = meleeDamage;
      cooldown = meleeAttackCooldown;
    }

    enemies[nextEnemyIndex] = new Enemy(x, y, enemySpeed, enemyHealth, damage, cooldown, type, killReward, rangeDistance);

    amountOfEnemiesSpawned++;

    if (enemyCount < enemies.length)
    {
      enemyCount++;
    }

    nextEnemyIndex++;

    if (nextEnemyIndex >= enemies.length)
    {
      nextEnemyIndex = 0;
    }
  }

  // Reposition certain UI elements
  // Defense buttons
  for (int i = 0; i < defenseButtons.length; i++)
  {
    defenseButtons[i].x = 20 + i * 150;
    defenseButtons[i].y = height - 204;
  }
  
  // Get the x position that the defenseButtons end at, so we can check if there is an overlap with waveStartButton
  DefenseButton endButton = defenseButtons[defenseButtons.length - 1];
  float defenseButtonsEndX = endButton.x + endButton.W;
  
  if (width < defenseButtonsEndX + waveStartButton.w + waveStartButton.relativeX + 20)
  {
    // Place waveStartButton on top of the defenseButtons, justified left
    waveStartButton.xSnap = 0;
    waveStartButton.relativeY = 40 + endButton.H;
    
    // Place showHowToPlayButton to the right of waveStartButton
    showHowToPlayButton.xSnap = 0;
    showHowToPlayButton.relativeX = waveStartButton.relativeX + waveStartButton.w + 20;
    showHowToPlayButton.relativeY = waveStartButton.relativeY;
  }
  else
  {
    // Place waveStartButton beside the defenseButtons, justified right
    waveStartButton.xSnap = 1;
    waveStartButton.relativeY = 20;
    
    // Place showHowToPlayButton on top of waveStartButton
    showHowToPlayButton.xSnap = 1;
    showHowToPlayButton.relativeX = 20;
    showHowToPlayButton.relativeY = 124;
  }

  // Draw UI
  isUIHovered = false;

  translate(cameraX, cameraY); // Undo the translate from earlier (UI shouldn't move with the camera)

  // Build phase UI
  if (waveState == 0)
  {
    // Defense selector buttons
    for (int i = 0; i < defenseButtons.length; i++)
    {
      defenseButtons[i].checkForHover();
      defenseButtons[i].display();
    }

    // Wave start button
    waveStartButton.label = "Start Wave " + currentWave + " >>";
    waveStartButton.checkForHover();
    waveStartButton.display();

    // Show how to play button
    showHowToPlayButton.checkForHover();
    showHowToPlayButton.display();

    textSize(32);
    textAlign(RIGHT);
    fill(uiSecondaryTextColor);
    text(totalEnemies + " enemies will attack next wave!", width - 20, 40);

    if (currentWave == 4)
    {
      text("Archers will attack next wave! Tall walls recommended.", width - 20, 72);
    }
  } else if (waveState == 1)
  {
    // Draw wave progress bar
    rectMode(CORNER);

    strokeWeight(4);
    stroke(uiOutline);
    fill(uiBackground);
    rect(width - 500, 20, 480, 48); // Background

    noStroke();
    fill(uiHighlight);
    rect(width - 498, 22, map(amountOfEnemiesSpawned, 0, totalEnemies, 0, 476), 44); // Bar fill

    textSize(32);
    textAlign(RIGHT);
    fill(uiTextColor);
    text("Wave " + currentWave + " Progress: " + int((float) amountOfEnemiesSpawned / totalEnemies * 100) + "%", width - 28, 54);
  }

  textSize(64);
  textAlign(LEFT);
  fill(uiSecondaryTextColor);
  text("$" + money, 20, 64);

  // Draw lose screen (if game is lost)
  if (lose)
  {
    strokeWeight(4);
    stroke(uiSecondaryOutline);
    fill(uiSecondaryBackground);
    rectMode(CENTER);

    rect(width/2, height/2, 800, 500);

    textSize(64);
    textAlign(CENTER);
    fill(uiSecondaryTextColor);
    text("Game Over!", width/2, height/2 - 150);

    textSize(32);
    text("You made it to wave " + currentWave + ".\nGood job!", width/2, height/2);

    restartButton.checkForHover();
    restartButton.display();
  }

  // Draw how to play / tutorial screen
  if (showHowToPlay)
  {
    strokeWeight(4);
    stroke(uiSecondaryOutline);
    fill(uiSecondaryBackground);
    rectMode(CENTER);

    rect(width/2, height/2, 1200, 800);

    textSize(64);
    textAlign(CENTER);
    fill(uiSecondaryTextColor);
    text("Welcome to Fortify!", width/2, height/2 - 300);

    textSize(32);
    textAlign(LEFT);
    text(
      "You need to defend the castle in the middle of your screen. At the bottom-left of the screen,\nyou will see some walls and towers that you can use to defend with!\n" +
      "- Use left click to place & remove defenses.\n" +
      "- Make sure to place at least one archer tower, otherwise enemies will not be killed.\n" +
      "- Once you feel ready, press the button in the bottom-right of your screen to start the wave!\n" +
      "- Ranged enemies will not spawn on the first few waves, so don't worry about protecting\nagainst projectiles yet.\n" +
      "- If a defense gets damaged during a wave, you can right click on it to repair it after the\nwave ends.\n" +
      "- If your defense begins to exceed the screen space, you can use WASD to move the camera,\nand space to recenter.\n" +
      "- You can see useful info in the top-left and top-right corners of your screen.\n" +
      "- Press the ? button to open this window back up anytime.",
      width/2 - 580, height/2 - 230);

    hideHowToPlayButton.checkForHover();
    hideHowToPlayButton.display();
  }

  // Draw tooltip
  strokeWeight(4);
  stroke(uiSecondaryOutline);
  fill(uiSecondaryBackground);
  rectMode(CORNER);
  if (toolTipY + toolTipH > height)
  {
    toolTipY = height - toolTipH;
  }
  if (toolTipX + toolTipW > width)
  {
    toolTipX = width - toolTipW;
  }
  rect(toolTipX, toolTipY, toolTipW, toolTipH);
  
  textAlign(LEFT);
  textSize(16);
  fill(uiSecondaryTextColor);
  text(toolTipInfo, toolTipX + 8, toolTipY + 16);
  
  // Reset tooltip position
  toolTipX = -999;
  toolTipY = -999;
  
  // Draw debug menu
  if (debug)
  {
    textSize(32);
    textAlign(LEFT);
    fill(255, 255, 255, 128);
    String[] waveModes = {"build", "fight"};
    text(
      round(frameRate) + " fps"
      + "\ntower: " + tileDefinitions[selectedTile].imgName
      + "\nenemyCount: " + enemyCount
      + "\namountOfEnemiesSpawned: " + amountOfEnemiesSpawned
      + "\nwave phase: " + waveModes[waveState]
      + "\ntotalEnemies: " + totalEnemies
      + "\nmeleeDamage: " + meleeDamage
      + "\nrangeDamage: " + rangeDamage
      + "\nenemySpeed: " + enemySpeed
      + "\nrangeDistance: " + rangeDistance
      + "\nenemyHealth: " + enemyHealth
      + "\nmeleeAttackCooldown: " + meleeAttackCooldown
      + "\nrangeAttackCooldown: " + rangeAttackCooldown
      + "\nkillReward: " + killReward
      + "\nenemySpawn.finishedTime: " + enemySpawn.finishedTime
      + "\ncurrentWave: " + currentWave
      + "\nbuildAction: " + buildAction,
      0, 0 + 96
      );
  }
}

// Resets the game to default values
void resetGame()
{
  enemies = new Enemy[150];
  enemyCount = 0;
  amountOfEnemiesSpawned = 0;
  nextEnemyIndex = 0;

  projectiles = new Projectile[150];
  projectileCount = 0;
  nextProjectileIndex = 0;

  explosions = new Explosion[20];
  nextExplosionIndex = 0;
  for (int i = 0; i < explosions.length; i++)
  {
    explosions[i] = new Explosion();
  }

  defenses = new TileMap(0, 0, 64, 32, 32);
  goalTileX = int(defenses.w / 2);
  goalTileY = int(defenses.h / 2);
  defenses.setTile(goalTileX, goalTileY, 0); // Place the goal tile

  // Center camera
  cameraX = defenses.w * defenses.tileSize / 2 - width/2 + defenses.tileSize/2;
  cameraY = defenses.h * defenses.tileSize / 2 - height/2 + defenses.tileSize/2;

  currentWave = 1;
  waveState = 0; // 0 is build phase, 1 is enemy attack phase

  totalEnemies = 10;
  enemyTypes = new String[1];
  enemyTypes[0] = "melee";
  meleeDamage = 1;
  rangeDamage = 0;
  enemySpeed = 5;
  rangeDistance = 4;
  enemyHealth = 1;
  meleeAttackCooldown = 1000;
  rangeAttackCooldown = 1000;
  killReward = 3;
  enemySpawn = new Timer(1200);

  selectedTile = 1;

  money = 50;

  lose = false;
  showHowToPlay = true;
}

// Takes an x or y coordinate and rounds it to a tile coordinate
int roundToTile(float value, boolean isXCoord)
{
  float origin;

  if (isXCoord)
  {
    origin = defenses.originX;
  } else
  {
    origin = defenses.originY;
  }

  return floor((value - origin) / defenses.tileSize);
}

void spawnProjectile(Projectile projectile)
{
  projectiles[nextProjectileIndex] = projectile;

  if (projectileCount < projectiles.length)
  {
    projectileCount++;
  }

  nextProjectileIndex++;

  if (nextProjectileIndex >= projectiles.length)
  {
    nextProjectileIndex = 0;
  }
}

// Takes a point & a circle, and tests if they overlap
boolean isPointInCircle(float pointX, float pointY, float cirX, float cirY, float radius)
{
  return(dist(pointX, pointY, cirX, cirY) < radius);
}

// Place a defense when the mouse is pressed
void mousePressed()
{
  int tile = defenses.getTile(mouseTileX, mouseTileY);

  if (mouseButton == LEFT)
  {
    if (waveState == 0) // Build mode
    {
      if (tile == -1) // Place down a tile
      {
        buildAction = 0;
      } else if (tile > -1) // Delete an existing tile. This doesn't happen if the tile is 0, because that is the goal tile, which you can't delete.
      {
        buildAction = 1;
      }

      // Check if any defense buttons were clicked
      for (int i = 0; i < defenseButtons.length; i++)
      {
        if (defenseButtons[i].hovered)
        {
          selectedTile = defenseButtons[i].tileIndex;
        }
      }
      if (waveStartButton.hovered) // Start wave
      {
        waveState = 1;
        enemySpawn.start();
        showHowToPlay = false; // Just in case the tutorial is still up, hide it
      }
    }

    if (showHowToPlay)
    {
      if (hideHowToPlayButton.hovered)
      {
        showHowToPlay = false;
      }
    } else
    {
      if (showHowToPlayButton.hovered)
      {
        showHowToPlay = true;
      }
    }

    if (lose) // Reset the game if restart button is pressed
    {
      if (restartButton.hovered)
      {
        resetGame();
      }
    }
  } else if (mouseButton == RIGHT)
  {
    if (waveState == 0)
    {
      // Repair tiles on right click
      buildAction = 2;
    }
  }
}

void mouseReleased()
{
  buildAction = -1;
}

// Draws a health bar, centered on x, y
void drawHealthBar(float x, float y, int w, int h, int maxHealth, int currentHealth)
{
  rectMode(CENTER);
  noStroke();
  fill(uiSecondaryBackground);
  rect(x, y, w + 4, h);

  rectMode(CORNER);
  fill(map(currentHealth, 0, maxHealth, 255, 0), map(currentHealth, 0, maxHealth, 0, 255), 0);
  rect(x - w/2, y - h / 2 + 2, map(currentHealth, 0, maxHealth, 0, w), h - 4);
}

void keyPressed()
{
  if (key == ' ') // Center the camera on space clicked
  {
    cameraX = defenses.w * defenses.tileSize / 2 - width/2 + defenses.tileSize/2;
    cameraY = defenses.h * defenses.tileSize / 2 - height/2 + defenses.tileSize/2;
  } 
  else if (key == 'w')
  {
    wasd[0] = true;
  } 
  else if (key == 'a')
  {
    wasd[1] = true;
  } 
  else if (key == 's')
  {
    wasd[2] = true;
  } 
  else if (key == 'd')
  {
    wasd[3] = true;
  }
  else if (keyCode == 114) // F3 key
  {
    debug = !debug;
  }
}

void keyReleased()
{
  if (key == 'w')
  {
    wasd[0] = false;
  } 
  else if (key == 'a')
  {
    wasd[1] = false;
  } 
  else if (key == 's')
  {
    wasd[2] = false;
  } 
  else if (key == 'd')
  {
    wasd[3] = false;
  }
}

void restartAudio(AudioPlayer audio)
{
  audio.rewind();
  audio.play();
}