#include <Keyboard.h>

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
  static const uint8_t BUFFER_SIZE = 3;

  if (Serial.available() > 0)
  {
    char buffer[BUFFER_SIZE] = {0};
    uint8_t readBytes = Serial.readBytes(buffer, BUFFER_SIZE);

    if (readBytes != BUFFER_SIZE)
      return;

    if (buffer[0] != PREAMBLE)
      return;

     gModifier = buffer[1];
     pressKey(buffer[2]);
  }  
}
