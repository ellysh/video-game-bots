#include <Keyboard.h>

enum State
{
  WAIT,
  PREAMBLE_RECV,
  MODIFIER_RECV
};

State gState = WAIT;
char gModifier = 0;

void setup()
{
  Serial.begin(9600);
  Keyboard.begin();
}

void pressKey(char key)
{
  if (gModifier != 0 )
  {
    Keyboard.press(gModifier);
  }
  Keyboard.write(key);
  Keyboard.releaseAll();
}

void loop()
{
  static const char PREAMBLE = 0xDC;
  
  if (Serial.available() > 0)
  {
    char key = Serial.read();

    if ((key == PREAMBLE) && (gState == WAIT))
    {
      gState = PREAMBLE_RECV;
      return;
    }

    if (gState == PREAMBLE_RECV)
    {
      gState = MODIFIER_RECV;
      gModifier = key;
      return;
    }

    if  (gState == MODIFIER_RECV)
    {
      gState = WAIT;
      pressKey(key);
      return;
    }
  }  
}
