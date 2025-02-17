void keyPressed(){
  if(state==0){
    ease = 0;
    state=1;
    start = millis();
  }
  else if(state==1){
    if(key == BACKSPACE){
      if(story.length()>0){
        story=story.substring(0,story.length()-1);
      }
    }
    else if(key != CODED){
      story+=key;
    }
    keySampler.add(keyCode,millis()-start);
    
  }
}

// START SCREEN (STATE 0)

void drawStartScreen(){
  fill(0,0,100,map(ease,0,LOAD_IN,0,255));
  textAlign(CENTER);
  textSize(40);
  text("Press Any Key To Begin",width/2,height/2);
}

// RECORDER (STATE 1)

// this will draw the prompt
void drawPromptScreen(){
  fill(0,0,0,map(ease,0,LOAD_IN,0,100));
  rect(width/4,height/20,width/2,height/8,20);
  rect(width/8,height/5,width*3/4,height*3/4,20);
  fill(0,0,100,map(ease,0,LOAD_IN,0,255));
  textAlign(CENTER);
  textSize(18);
  text("Tell me about something... \n\nor just relax, and let your mind run free...",width/2,height/8-20);
  fill(60,100,100,map(ease,0,LOAD_IN,0,255));
  text(prompt,width/2,height/8);
  // visualize the current user input
  fill(0,0,100,map(ease,0,LOAD_IN,0,255));
  textAlign(LEFT);
  textSize(18);
  text(story,width/8+20,height/5+20,width*3/4-30,height*3/5+60);
  
}

void drawTimer(){
  fill(0,0,100,255);
  textAlign(CENTER);
  textSize(20);
  text(str((RECORD_LENGTH-(millis()-start))/1000),8*width/10,9*height/10);
}

// VISUALIZER (STATE 2)
// split the text data into an array of words to produce as particles
// append a copy of the initial headsets reading at the maximum timestamp to stabilize interpolation loop
void processData(){
  words = splitTokens(story," .,/;[]\"\\\n\t");
  attentionSampler.add(attentionSampler.samples.get(0),RECORD_LENGTH);
  meditationSampler.add(meditationSampler.samples.get(0),RECORD_LENGTH);
  keySampler.add(-1,RECORD_LENGTH);
}

// this will loop the results of state2
// This is the DO EVERYTHING function of this assessment so the meat of the transformations is here!
// I'll make sure to comment step by step because the logic is quite complicated for very few lines of code.
// [now] is the current timestamp of the program runtime in ms (millis()), the problem is that this timekeeping method is absolutely HORRIBLE for realtime playback
void loopDisplay(int now){
  // get the three linearly modeled samples based on data from respective listeners
  // because now = millis() has very unpredictable steps, if we want to loop the recorded samples for the user, we are going to do some very fast and dirty linear modeling on
  // our mindwave samples
  // for our keycode -> musical keyboard time series, we don't need to interpolate keystrokes, so we just want to replay the keycode as a musical note whenever there is a
  // nearby timestamp, that is the difference between hasSample(int ts) and interpolateSample(int ts).
  int att = attentionSampler.interpolateSample(now);
  int med = meditationSampler.interpolateSample(now);
  int kc = keySampler.hasSample(now);
  
  if(kc!=-1){
    // now...
    // HOLY SONIC MATHEMATICS
    // SO BASICALLY: The way rate works in the sound default library is that rate affects the frequency/duration of the note
    // originally the plan was to have 8 sound files and divide up the 256 valid ASCII keystrokes into 32 octaves. The problem is u start to get hella corrupted
    // SO I DID SOME RESEARACH AND FOUND THAT A HALFTONE IS A ROUGHLY 6% FREQUENCY INCREASE LOGARITHMICALLY
    // SO YOU CAN (roughly) PLAY ALL 256 POSSIBLE "TONES" WITH ONLY A SINGLE NOTE FILE, BY CORRELATING KEYCODES TO EXPONENTIAL POWERS OF 1.06 
    // we zero the model with kc=-70 which centers the keyboard roughly around the alphanumeric keycodes so that the majority of expected input data 
    // doesn't lose too much audio quality to the low or high ends.
    // unfortunately, despite all our efforts, this generally sounds really awful. But, learning experience for next time.
    // this would likely work better if we hashmapped the QWERTY keyboard to tones that made sense, 
    // but this (int kc -> int exponent -> Sound NOTE) can sometimes be quite cool if we make sure it doesn't overpower the background ambient track
    // ^ which is what i did as a concession
    NOTE.play(pow(1.06,kc-70),0.00);
  }
  
  stroke(255,255);
  fill(255,255);
  int i=1;
  // the background ambient music track is volume adjusted based on the linearly modeled meditation values in-time. 
  // I didn't want to make it completely silent with 0 meditation because the "keyboard piano" is quite jarring alone
  // read above for why the keycode mapping for pitches is a bit auditorily strange.
  ambient.setGain(map(med,0,100,-20,60));
  //s.volume(map(att,0,100,0,0.50));
  // add a little glowing visual indicator representing the headset outputs of attention and meditation hybridized
  // I removed a pulse effect on the orb because it created too much conflicting noise with the interpolated model.
  radialGlow(width/2,height/2,1+med*5,15);
  
  // Then, because the text data would've kinda been wasted, I wanted the words people say to float in and out of the consciousness.
  // originally, this was also going to be dictated in waves by attention/meditation, but since we need something to be adjustable in post-processing, i added a kinda
  // boring slider here. I might add a way to control it with the brain helmet, but i need to see how that'd work.
  
  // purge dead particles to preserve performance
  for(i=particles.size()-1;i>=0;i--){
    if (particles.get(i).age<=0){
      particles.remove(i);
    }  
  }
  // attempt to roll a new particle on each frame.
  // particles hue and size are roughly affected by the attention model
  if(words.length>0 && random(0,100)<effectChance){
    float hue = map(att,0,100,0,250);
    String msg = words[(int)random(0,words.length)];
    particles.add(new Particle(int(hue),100,100,msg,att));
  }
  // draw particles
  for (Particle p : particles){
    p.update();
    p.display();
  }
  
  // update particle chance if the scrollbar has moved
  effectChance = 100*(scrollX-barX)/(barWidth-sWidth);
  drawScrollbar();
}

void radialGlow(int x, int y, float size, int steps){
  pushMatrix();
  noStroke();
  for(int i=0;i<size;i=i+steps){
    fill(0,0,100,i);
    ellipse(x,y,size-i,size-i);
  }
  popMatrix();
}

void mousePressed(){
  if(state == 2){
    mindHold();
    scrollHold();
  }
}

void mouseReleased(){
  if(state == 2){
    mindReleased();
    scrollReleased();
  }
}

void mouseDragged(){
  if(state == 2){
    scrollDragged();
  }
}

void mindHold(){
  if(mouseX >= 10 && mouseX <= 40 &&
     mouseY >= 10 && mouseY <= 40){
    mindPress = true;  
  }
}

void mindReleased(){
  mindPress = false;
}

void scrollHold() {
  // dragging the scrollbar?
  if(mouseX >= scrollX && mouseX <= scrollX+sWidth &&
     mouseY >= scrollY && mouseY <= scrollY+sHeight){
    initX = mouseX;
    scrollDrag = true;
  }
}

void scrollReleased(){
  scrollDrag = false;
}

void scrollDragged() {
  if (scrollDrag && scrollX >= barX && scrollX <= barX+barWidth-sWidth) {
      scrollX = constrain(scrollX+(mouseX-initX),barX,barX+barWidth-sWidth);
      initX=mouseX;
  }
}

void drawScrollbar(){
  stroke(200);
  fill(255);
  rect(barX,barY,barWidth,barHeight);
  fill(0);
  rect(scrollX,scrollY,sWidth,sHeight);
  textAlign(LEFT);
  textSize(14);
  text("Particle Chance: "+(int)effectChance+"% per Frame",barX,barY-10);
}

//void drawPause(){
//  if(life>0){
//    float alpha = map(life,0,20,0,255);
//    stroke(0,0,255,alpha);
//    fill(0,0,255,alpha);
//    if(pause){
//      triangle((width/2)+40,height/2,(width/2)-20,(height/2)-30,(width/2)-20,(height/2)+30);
//    }
//    else{
//      rect((width/2)-20,(height/2)-25,15,45);
//      rect((width/2)+10,(height/2)-25,15,45);
//    }
//    life--;
//  }
//}
