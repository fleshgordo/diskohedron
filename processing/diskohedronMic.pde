import processing.serial.*;
import ddf.minim.*;

Minim minim;
AudioInput in;

float maxDelta=0;
float oldDelta=0;
float accel=0;

RangeInt sinusRange = new RangeInt("sinusRange",-20,20);
RangeInt bufferSpread = new RangeInt("bufferSpread",1,16);
RangeInt baseBright = new RangeInt("baseBright",30,70);
RangeInt waveStrength = new RangeInt("waveStrength",0,60);
RangeInt deltaRange = new RangeInt("deltaRange",10,55);
RangeInt rotSpeed = new RangeInt("rotSpeed",-30,30);

Serial myPort;  // Create object from Serial class
int val;        // Data received from the serial port

byte[] byteArr = new byte[32];
int[] lampIndex = new int[32];
int brighti=60;
float cc=0.0;

RangeInt mode= new RangeInt("mode",0,1);
int maxmode=1;

void setup() 
{
  
  size(200, 400);
  frameRate(45);
  minim = new Minim(this);

  sinusRange.val=10;
  sinusRange.loopMe=true;
  baseBright.val=70;
  waveStrength.val=30;
  bufferSpread.loopMe=true;
  mode.loopMe=true;
  rotSpeed.loopMe=true;

  // I know that the first port in the serial list on my mac
  // is always my  FTDI adaptor, so I open Serial.list()[0].
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 115200);
  in = minim.getLineIn(Minim.MONO, 32*16);
  for(int i=0;i<lampIndex.length;i++){
    lampIndex[i]=i;
  }
}

public void shuffleLamps(){
  for(int i=0;i<lampIndex.length;i++){
    int swap = lampIndex[i];
    int rand = (int)random(lampIndex.length);
    lampIndex[i]=lampIndex[rand];
    lampIndex[rand]=swap;
  }
}

void draw() {
  
  cc+=(float)mouseY/900.0f;
  cc+=rotSpeed.val/5.0f;
 
  if(maxDelta>deltaRange.val){
    //dush=true;
    println("peak reached ("+maxDelta+")");
    float newAccel=maxDelta/200.0f;
    if(newAccel>accel){
      accel=newAccel;
    }
    
  }else{
    accel-=0.002;
    if(accel<0)accel=0;
  }
  //println(accel);
  cc+=accel;
  
  oldDelta=maxDelta;
  maxDelta=0;
  brighti--;
  if(brighti<=10)brighti=99;

  background(255);
  // draw the waveforms
  for(int i = 0; i < in.bufferSize() - 1; i++)
  {
    if(i>=1){
      maxDelta+= abs(in.left.get(i) - in.left.get(i-1));
    }
    
    if(i<32*bufferSpread.val){
      
      float wave = (in.left.get(i)+1.0f/2.0f);
      int brt = ((int)(baseBright.val+wave*(float)waveStrength.val));
      
      
      
      if(mode.val==1){
        wave = abs(in.left.get(i));
        brt = ((int)((baseBright.val+30)-wave*90.0f));
      }
      
      float sinus = (sin((float)i/8.0f+cc)+1.0f)/2.0f;
      brt+=sinus*(float)sinusRange.val;
      
      if(brt>109)brt=109;
      if(brt<10)brt=10;
    
      
      byteArr[lampIndex[i/bufferSpread.val]]=(byte)(brt);
      
    }
    line(i, 50 + in.left.get(i)*50, i+1, 50 + in.left.get(i+1)*50);
    line(i, 150 + in.right.get(i)*50, i+1, 150 + in.right.get(i+1)*50);
  }
  
  //println(maxDelta);
  
  
  
  if (mouseOverRect() == true) {  // If mouse is over square,
    fill(204);                    // change color and
    myPort.write(byteArr);              // send an H to indicate mouse is over square
  //println(byteArr);
    //myPort.write('2');
  } 
  else {                        // If mouse is not over square,
    fill(0);                      // change color and
    myPort.write(byteArr);              // send an H to indicate mouse is over square
    //myPort.write('v');              // send an L otherwise
  }
  rect(50, 50, 100, 100);         // Draw a square
}

boolean mouseOverRect() { // Test if mouse is over square
  return ((mouseX >= 50) && (mouseX <= 150) && (mouseY >= 50) && (mouseY <= 150));
}



void stop()
{
  // always close Minim audio classes when you are done with them
  in.close();
  minim.stop();
  
  super.stop();
}

void keyReleased(){
  if ( key == 'x' ){
    mode.next();
  }
  if ( key == 'y' ){
    mode.previous();
  }
  
  if(key=='s'){
    sinusRange.next();
  }
  if(key=='a'){
    sinusRange.previous();
  }
  
  if(key=='w'){
    //bufferSpread.twice();
    bufferSpread.next();
  }
  if(key=='q'){
    bufferSpread.previous();
  }
  
  
  if(key=='v'){
    baseBright.next();
  }
  if(key=='c'){
    baseBright.previous();
  }
  
  if(key=='f'){
    waveStrength.next();
  }
  if(key=='d'){
    waveStrength.previous();
  }
  
  if(key=='r'){
    deltaRange.next();
  }
  if(key=='e'){
    deltaRange.previous();
  }

  if(key=='n'){
    rotSpeed.next();
  }
  if(key=='b'){
    rotSpeed.previous();
  }
  
  if(key=='p'){
    shuffleLamps();
    println(lampIndex);
  }
}

class RangeInt{
  int val=0;
  int minim=0;
  int maxim=10;
  String name="";
  boolean loopMe=false;
  
  public RangeInt(String name,int minim,int maxim){
    this.name=name;
    this.minim=minim;
    this.maxim=maxim;
    this.val=maxim-((maxim-minim)/2);
    println("min:"+minim+" max:"+maxim+" val:"+val);
  }
  
  public void trace(){
    println(name+"\t["+minim+"]\t"+val+"\t["+maxim+"]");
  }
  
  public int next(){
    val++;
    if(val>maxim){
      if(loopMe)
        val=minim;
      else
        val=maxim;
    }
    trace();
    return val;
  }
  
  public int previous(){
    val--;
    if(val<minim){
      if(loopMe)
        val=maxim;
      else
        val=minim;
    }
    trace();
    return val;
  }
  
  public int twice(){
    val*=2;
    if(val>maxim)val=minim;
    println(val);
    return val;
  }
  
  public int half(){
    val/=2;
    if(val<minim)val=maxim;
    println(val);
    return val;
  }
  
}
/*
  // Wiring/Arduino code:
 // Read data from the serial and turn ON or OFF a light depending on the value
 
 char val; // Data received from the serial port
 int ledPin = 4; // Set the pin to digital I/O 4
 
 void setup() {
 pinMode(ledPin, OUTPUT); // Set pin as OUTPUT
 Serial.begin(9600); // Start serial communication at 9600 bps
 }
 
 void loop() {
 if (Serial.available()) { // If data is available to read,
 val = Serial.read(); // read it and store it in val
 }
 if (val == 'H') { // If H was received
 digitalWrite(ledPin, HIGH); // turn the LED on
 } else {
 digitalWrite(ledPin, LOW); // Otherwise turn it OFF
 }
 delay(100); // Wait 100 milliseconds for next reading
 }
 
 */
