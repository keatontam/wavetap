// class for visually displaying recorded data as an ephemeral particle
class Particle{
  String msg;
  int x,y,size;
  int life,age;
  int h,s,b,a;
  float angle, speed;
  Particle(int hue, int sat, int bri, String str, float sizeMod){
    msg=str;
    x = int(random(0,width));
    y = int(random(0,height));
    size = int(random(10,sizeMod+10));
    h = hue;
    s = sat;
    b = bri;
    a = 0;
    angle=random(0,360);
    speed=random(0,0.5);
    life = (int)random(10,300);
    age = life;
  }
  
  void update(){
    age--;
    if(age>life/2){
      a+=256/(life/2);
    }
    else{
      a-=256/(life/2);
    }
    angle+=speed;
  }
  
  void display(){
    pushMatrix();
    fill(h,s,b,a);
    textSize(size);
    translate(x,y);
    rotate(radians(angle));
    text(msg,0,0);
    popMatrix();
  }
}
