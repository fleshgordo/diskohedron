// set pin numbers:

//output 1,5,3,4
#include <math.h>
#include <TimerOne.h>
#include <TimerThree.h>


// output 4
//int lampe [] = {34, 32, 38, 36, 42, 40, 44, 46};
// output 3
//int lampe [] = {24, 21, 26, 20, 28, 19, 30, 18};
// output 6
//int lampe [] = {22, 23, 49, 48, 51, 50, 53, 52};
// output 1
//int lampe [] = {9, 10, 8, 11, 7, 12, 6, 13};
// output5 
//int lampe [] = {45, 47, 33, 35, 37, 39, 41, 43};


//int lampe [] = {9, 10, 8, 11, 7, 12, 6, 13, 45, 47, 33, 35, 37, 39, 41, 43, 24, 21, 26, 20, 28, 19, 30, 18, 34, 32, 38, 36, 42, 40, 44, 46};



volatile const int lampe [] = {  9, 10, 8, 11, 7, 12, 6, 13,
                  24, 26, 21, 20, 28, 19, 30, 18,
                  32, 38, 36, 40, 42, 39, 41, 43,
                  45, 47, 33, 35, 37, 44, 46, 34 
                };
                
/*
int lampe [] = {  
                  45, 47, 33, 35, 37, 44, 46, 34,
                  32, 38, 36, 40, 42, 39, 41, 43,
                  9, 10, 8, 11, 7, 12, 6, 13,
                  24, 26, 21, 20, 28, 19, 30, 18
                };
*/                

volatile int dim [] =  {99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99};
//int dim2 [] =  {99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99};

volatile int wait [] =  {99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99};

/*
const int pause[] ={  10,10,10,15,10,10,20,20,
                20,45,30,30,50,50,50,65,
                55,60,20,30,50,50,50,50,
                50,50,50,50,50,50,50,50
              };*/

volatile int numBulbs=32;
//volatile float bright[] =  {67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67};
//volatile float decr[] =  {67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67};
volatile int bright=67;
volatile int toBright=67;

volatile int decr=-15;
volatile int toDecr=-15;

volatile float speedi=0.013;
volatile float toSpeed=speedi;

int heartbeat=0;

volatile boolean fire[32];
volatile int z=0;

long bfire = B00000000;
float sine[515];

const int freqStep = 75;    // Set the delay for the frequency of power (65 for 60Hz, 78 for 50Hz) per step (using 128 steps)

boolean switcher=false;
boolean strobe=false;

int strobeCount=0;
int strobeFreq=2;

/** logic variables */
float count=2*PI;

int fadeSpeed=50;


void setup() {
  Serial.begin(115200);
  setupSine();
  for (int i = 0;i<numBulbs; i++) {
    fire[i]=false;
    pinMode(lampe[i], OUTPUT);  
    digitalWrite(lampe[i],LOW); 
  }
  attachInterrupt(1, zero_cross_detect, RISING);   // Attach an Interupt to Pin 2 (interupt 0) for Zero Cross Detection
  //Timer1.initialize(freqStep);
  //Timer1.setPeriod(freqStep);
  //Timer1.attachInterrupt(dim_check);
  Timer3.initialize(freqStep);
  Timer3.setPeriod(freqStep);
  Timer3.attachInterrupt(dim_check2);
}

/** function to be fired at the zero crossing */
void zero_cross_detect() {
  if(strobe){
    if(switcher){
      blitz(switcher);
      switcher=false;
    }else{
      strobeCount++;
      if(strobeCount%strobeFreq==0){
        blitz(switcher);
        switcher=true;
      }
    }
  }else{
    calcSine();
    //blitz();
  }
   z = 0;
}

/** Function will fire the triac at the proper time */
void dim_check() {
   for(int k=0;k<numBulbs;k+=2) {
     if(fire[k]){
       if(z>=dim[k]){
          digitalWrite(lampe[k], HIGH);    // Fire the Triac mid-phase
          fire[k]=false;
          wait[k]=0;
       }
     }else{
       wait[k]++;
       if(wait[k]==3){
         digitalWrite(lampe[k], LOW);
       }
     }
   }
   z++;
}

/** Function will fire the triac at the proper time */
void dim_check2() {
   for(int k=0;k<numBulbs;k++) {
     if(z>=dim[k]){
       if(fire[k]){
         digitalWrite(lampe[k], HIGH);    // Fire the Triac mid-phase
         fire[k]=false;
         wait[k]=0;
       }else{
         wait[k]++;
         if(wait[k]==1){
           dim[k]=500;
           digitalWrite(lampe[k], LOW);
         }
       }
     }
   }
   z++;
}


void loop()
{
  checkInput();
}

void blitz(boolean blitzer){
  if(blitzer){
    for (int i=0;i<numBulbs; i++) {
      fire[i]=true;
      dim[i]=bright;
    }
  }else{
    for (int i=0;i<numBulbs; i++) {
      fire[i]=true;
      dim[i]=67;
    }
  }
}


void calcSine(){
  heartbeat++;
  
  float fspots=10.0;
  float sinus=10.0;
  
  if(heartbeat%fadeSpeed==0){
    if(speedi<toSpeed){
      speedi+=0.01;//speedi+=1/fadeSpeed;
    }else if(speedi>toSpeed){
      speedi-=0.01;//speedi-=1/fadeSpeed;
    }
    
    if(decr<toDecr){
      decr++;//decr+=1/fadeSpeed;
    }else if(decr>toDecr){
      decr--;//decr-=1/fadeSpeed;
    }
    
    if(bright<toBright){
      bright++;//bright+=1/fadeSpeed;
    }else if(bright>toBright){
      bright--;//bright-=1/fadeSpeed;
    }
    
  }
  count+=speedi;
  //Serial.println(((int)bright));
  
  //decr+=  (((toDecr-decr))/fadeSpeed);
  //bright+= (((toBright-bright)) /fadeSpeed);
  for (int i=0;i<numBulbs; i++) {
    fire[i]=true;
    float ff=2*PI;
    if(i<8)ff=PI/2;
    else if(i<16)ff=PI;
    else if(i<24)ff=PI*3/2;
    sinus = sinus0to1( count+ff+((float)i/3.0) );
    sinus*=sinus;
    
    sinus*=(20.0+decr);
    //if(sinus<5)sinus=5;
    dim[i]=(bright-sinus);
    //dim[i]=bright+random(10);
  }
}
/** initialize sine lookup table (sine LUT) */
void setupSine(){
  for(int n=0;n<514;n++){
    sine[n] = (sin(2.0*PI*((float)n/512.0))+1.0) / 2.0;
  }
}

/** get sine from lookuptable between 0 and 2*PI */
float sinus0to1(float val){
  float si = fmod(val,2*PI);
  return sine[round(si*(512.0/(2.0*PI)))];
}

/** check for control messages from serial/USB port */
void checkInput(){
  int testi=0;
  testi = Serial.read();
  if(testi==49){/*numBulbs--;*/Serial.println(numBulbs);}
  else if(testi==50){/*numBulbs++;*/Serial.println(numBulbs);}
  else if(testi==51){toBright--;Serial.println(bright);}
  else if(testi==52){toBright++;Serial.println(bright);}
  else if(testi==53){toDecr--;Serial.println(decr);}
  else if(testi==54){toDecr++;Serial.println(decr);}
  else if(testi==55){strobeFreq--;Serial.println(strobeFreq);}
  else if(testi==56){strobeFreq++;Serial.println(strobeFreq);}
  else if(testi==57){strobe=!strobe;Serial.println(strobe);}
  else if(testi=='y'){toSpeed-=0.01456;Serial.println(speedi);}
  else if(testi=='x'){toSpeed+=0.01456;Serial.println(speedi);}
  
  else if(testi=='0'){ strobe=false; toBright=67; toDecr=-20; fadeSpeed=1; toSpeed=0.013;}
  else if(testi=='f'){ strobe=false; toBright=67; toDecr=-20; fadeSpeed=20; toSpeed=0.013;}

  else if(testi=='v'){ strobe=false; toBright=50; toDecr=-5; fadeSpeed=24; toSpeed=0.023;}
  else if(testi=='n'){ strobe=false; toBright=69; toDecr=21; fadeSpeed=64; toSpeed=1.123;}
  else if(testi=='b'){ strobe=true;  toBright=74; strobeFreq=14;fadeSpeed=14; toDecr=5; toSpeed=0.123;}
  else if(testi=='m'){ strobe=false; toBright=70; toDecr=7; fadeSpeed=7; toSpeed=0.4;}
  else if(testi=='k'){ strobe=false; toBright=50; toDecr=-42; fadeSpeed=8; toSpeed=0.23;}
  
  else if(testi=='r'){ strobe=false; toBright=50; toDecr=-45; fadeSpeed=8; toSpeed=0.23;}
  
  
}
