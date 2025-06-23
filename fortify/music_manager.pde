// Object to manage playing of background music 
class MusicManager
{
  int prevWaveState = -1; // waveState on previous frame
  
  // Manage background music
  void play()
  {
    if (prevWaveState != waveState)
    {
      if (waveState == 0) // Build mode
      {
        buildMusic.loop();
        fightMusic.rewind();
        fightMusic.pause();
      }
      else if (waveState == 1) // Fight mode
      {
        fightMusic.loop();
        buildMusic.rewind();
        buildMusic.pause();
      }
      
      prevWaveState = waveState;
    }
  }
}
