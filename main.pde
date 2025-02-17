import processing.serial.*;
import pt.citar.diablu.processing.mindset.*;

import processing.sound.*;

import ddf.minim.*;

// STATE CONTROL VARIABLES

// state variable dictating the current screen:
// 0 - start screen
// 1 - prompt screen
// 2 - showcase
int state = 0;
int start;
int prev = 0;

// transition modifiers
int ease = 0;
int LOAD_IN = 50;

// INPUT CONTROLLER VARIABLES

// this is the only port that works for me so you might need to test
// which port your system defaults to:
// https://download.neurosky.com/public/Products/MindWave%20Mobile%202/MindWave%20Mobile%202%20Quick%20Start%20Guide.pdf
String SERIAL_PORT = "COM4";
MindSet mindSet;
eventSampler attentionSampler;
eventSampler meditationSampler;

PImage sig0, sig1, sig2, sig3, sigCon;
int lastSig=0;
boolean mindPress = false;

String story="";
String[] words;
eventSampler keySampler;

int RECORD_LENGTH = 30000;

int barX, barY, barWidth, barHeight;
int scrollX, scrollY, sWidth, sHeight;
boolean scrollDrag = false;
int initX;

// AUDIO OUTPUT VARIABLES

Sound s;
Minim music;
AudioPlayer ambient;
SoundFile NOTE, piano, harp, light, marimba, medium, strings;

// DISPLAY VARIABLES

String[] prompts = {"someone you love dearly <3","something that fills you with happiness :)","something really funny!","something amazingly beautiful~"};
//String[] prompts = {"the making of this project ;)"};
String prompt;

ArrayList<Particle> particles;
float effectChance = 20;

int inc;
float delta;
int growth;

color colorBG = color(0, 0, 0);
color colorBG2 = color(0, 0, 0);
color LIGHT, LIGHT2, DARK, DARK2;
//59 + ((59 + (23 * 60)) * 60) = the length of a day :)
float DAY = 86399;

void setup() {
  surface.setTitle("Assignment 3");
  //fullScreen();
  size(800, 600);
  colorMode(HSB, 360, 100, 100);
  // change color mode and then set magics
  LIGHT = color(314, 45, 100);
  LIGHT2 = color(214, 45, 100);
  DARK = color(256, 80, 50);
  DARK2 = color(230, 100, 13);
  surface.setResizable(true);

  // EEG??? WOWIE!
  mindSet = new MindSet(this, SERIAL_PORT);
  sig0 = loadImage("mindwave/nosignal_v1.png");
  sig1 = loadImage("mindwave/connecting1_v1.png");
  sig2 = loadImage("mindwave/connecting2_v1.png");
  sig3 = loadImage("mindwave/connecting3_v1.png");
  sigCon = loadImage("mindwave/connected_v1.png");

  // And some recording samplers
  prompt = prompts[int(random(0,prompts.length))];
  attentionSampler = new eventSampler();
  meditationSampler = new eventSampler();
  keySampler = new eventSampler();

  // audio setup
  music = new Minim(this);
  ambient = music.loadFile("audio/ambient.mp3", 1024);
  ambient.setGain(-20);

  // ASCII piano setup
  s = new Sound(this);
  s.volume(0.35);
  piano = new SoundFile(this, "audio/piano.mp3");
  harp = new SoundFile(this, "audio/harp.aif");
  light = new SoundFile(this, "audio/light.aif");
  marimba = new SoundFile(this, "audio/marimba.aif");
  strings = new SoundFile(this, "audio/strings.aif");
  NOTE = piano;

  // instantiate scrollbar
  barX = width/4;
  barY = height*15/16;
  barWidth = width/2;
  barHeight = height/32;
  sWidth = barHeight;
  sHeight = barHeight;
  scrollX = barX+(int)((effectChance/100)*barWidth);
  scrollY = barY;

  //millis
  start = millis();
}

int evalTime() {
  // calculate user clock time to update background color
  // modify "low channel" audio based on time
  int time = second() + ((minute() + (hour() * 60)) * 60);
  // dawn
  if (time>18000 && time<25200) {
    colorBG = lerpColor(DARK, LIGHT, map(time, 18000, 25200, 0.0, 1.0));
    colorBG2 = lerpColor(DARK2, LIGHT2, map(time, 18000, 25200, 0.0, 1.0));
  }
  // day
  else if (time>=25200 && time<=64800) {
    colorBG = LIGHT;
    colorBG2 = LIGHT2;
  }
  // dusk
  else if (time>64800 && time<72000) {
    colorBG = lerpColor(LIGHT, DARK, map(time, 68400, 72000, 0.0, 1.0));
    colorBG2 = lerpColor(LIGHT2, DARK2, map(time, 68400, 72000, 0.0, 1.0));
  }
  // night
  else {
    colorBG = DARK;
    colorBG2 = DARK2;
  }

  return time;
}

void draw() {
  // ease transitions
  if (ease<LOAD_IN) {
    ease++;
  }
  // day/night cycle the background
  float time = evalTime();
  background(colorBG);
  for (int i = 0; i<height; i++) {
    color gradient = lerpColor(colorBG, colorBG2, map(i, 0, height, 0.0, 1.0));
    stroke(gradient);
    line(0, i, width, i);
  }

  // update visual based on program state
  // start screen
  if (state==0) {
    drawStartScreen();
  }
  // give a silly lil prompt and begin recording data.
  // the headset has specialized instructions to only record longform time-series data from this state.
  else if (state==1) {
    drawPromptScreen();
    //time has elapsed and its time to visualize
    if (millis()-start>RECORD_LENGTH) {
      processData();
      state=2;
      start=millis();
      //prepare transformations
      ambient.loop();
      particles = new ArrayList<Particle>();
    }
    drawTimer();
  } else if (state==2) {
    // set-up the nondeterministic display loop because millis() is STUPID
    int now = (millis()-start) % RECORD_LENGTH;
    if (prev>now) {
      attentionSampler.rewind();
      meditationSampler.rewind();
      keySampler.rewind();
    }
    loopDisplay(now);
    prev=now;
  }
  // shit hit the fan
  else {
    exit();
  }
  
  // draw connection widget
  drawSignal(lastSig);
}

// display EEG connection state
void drawSignal(int sig){
  // 200 is signal not found
  if(sig==200){
    image(sig0,10,10,40,40);
  }
  // the next three are naive interpretations of poorSignal readings
  else if(sig>150){
    image(sig1,10,10,40,40);
  }
  else if(sig>100){
    image(sig2,10,10,40,40);
  }
  else if(sig>0){
    image(sig3,10,10,40,40);
  }
  // 0 is fully connected
   else if(sig==0){
    image(sigCon,10,10,40,40);
  }
}

// MindWave helpers:
// void poorSignalEvent(int sig)
// void attentionEvent(int attentionLevel)
// void meditationEvent(int meditationLevel)
// void blinkEvent(???)
// void eegEvent(int delta, int theta, int low_alpha, int high_alpha, int low_beta
//               int high_beta, int low_gamma, int mid_gamma)
// void rawEvent(???)
// purely for the sake of displaying/debugging connection state.
public void poorSignalEvent(int sig){
  println(sig);
  lastSig = sig;
}

public void attentionEvent(int attentionLevel) {
  if (state==1) {
    attentionSampler.add(attentionLevel, millis()-start);
  }
  if (state==2 && mindPress) {
    //scrollX = (int)map(attentionLevel,0,100,barX,barX+barWidth-sWidth);
    if(attentionLevel<20){
      NOTE=light;
    }
    else if(attentionLevel<40){
      NOTE=harp;
    }
    else if(attentionLevel<60){
      NOTE=strings;
    }
    else if(attentionLevel<80){
      NOTE=marimba;
    }
    else{
      NOTE=piano;
    }
  }
}

public void meditationEvent(int meditationLevel) {
  if (state==1) {
    meditationSampler.add(meditationLevel, millis()-start);
  }
}

void exit() {
  println("please have a wonderful rest of your day, goodbye!");
  mindSet.quit();
  ambient.close();
  super.exit();
}
