class Timer
{
  int startTime; // The system time when the timer started
  int finishedTime; // The amount of time that must pass before the timer ends, in ms
  
  Timer(int tempFinishedTime)
  {
    finishedTime = tempFinishedTime;
  }
  
  void start()
  {
    startTime = millis();
  }
  
  boolean isFinished()
  {
    int passedTime = millis() - startTime;
    
    return (passedTime > finishedTime);
  }
}
