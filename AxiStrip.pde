/* free adaptation from the crazy job of ertdfgcvb
 https://github.com/ertdfgcvb/Genau
 */
Control axi;
ArrayList<Case> cases = new ArrayList<Case>();
int offsX = -1;      // offset of the first letter
int offsY = -1;
int charWidth = 18;  // width of the monospaced font
int lineHeight = 24; // font height plus leading
int scale = 25;      // extra scale
int nextX, nextY;    // current pos
int nConnect, nCases, marge = 20;
boolean merge, isRunning, work, cube, help;
PVector mrg = new PVector(5, 5);
PImage helpImg;
void setup() {
  //size(958, 480);//square
  size(958, 680);//A4
  axi = new Control(this);
  Serial p = axi.open();
  if (p == null) {
    println("Axidraw not found.");
    exit();               // No AxiDraw - no joy!
    return;
  }
  axi.motorSpeed(1200);     // A slow one
  axi.readPos();            // Read out the steps from the EBB, set internal pos[] accordingly;
  // this makes sure that the position is updated when re-launching the program
  // so a "reset" (via zero()) is not needed
  //axi.up();    // Force the pen to be "up"
  rectMode(CORNERS);
  //cases.add(new Case(0, 0, 0, 620, 0, 620, 420, 0, 420));//A5
  //cases.add(new Case(0, 0, 0, 420, 0, 420, 420, 0, 420));//carré 1
  //cases.add(new Case(1, 480, 0, 900, 0, 900, 420, 480, 420));//carré 2
  //cases.add(new Case(0, 0, 0, 430, 0, 430, 645, 0, 645));//rect 1 H
  //cases.add(new Case(1, 470, 0, 900, 0, 900, 645, 470, 645));//rect 2 H
  //cases.add(new Case(0, 0, 0, 900, 0, 900, 645, 0, 645));//big case
  //cases.add(new Case(0, 0, 0, 860, 0, 860, 610, 0, 610));//big case A5
  cases.add(new Case(0, 0, 0, 900, 0, 900, 610, 0, 610));//A4
  // 3 strips 18x9
  //cases.add(new Case(0, 0, 0, 612, 0, 612, 288, 0, 288));
  //cases.add(new Case(1, 0, 357, 612, 357, 612, 645, 0, 645));
  //cases.add(new Case(2, 632, 0, 920, 0, 920, 612, 632, 612));
  helpImg = loadImage("help.png");
}
void draw() {
  // axi.version();
  // axi.querysteps();      // Uncomment for some extra info in the console
  // axi.queryMotor();
  // axi.queryPen();
  messageLoop(axi.port);
  String out = "";
  out += "pos[]: " + axi.x() + "," + axi.y() + " (steps)\n";
  out += "time: " + millis() + "ms\n";
  out += "idle: " + (axi.idle()) + "\n";
  if (!axi.enabled()) {
    out += "\nManually move the pen\nto the top left corner... \n\nPress F1 again when done.";
    background(220, 60, 60);
  } else if (merge) background(200, 220, 200);
  else background(255);
  translate(marge, marge);
  for (Case cas : cases) cas.display();
  noStroke();
  if (axi.pen()==0) fill(25, 236, 21);
  else fill(225, 30, 30);
  ellipse(nextX/scale, nextY/scale, 12, 12);
  if (help) image(helpImg, 120, -20);
  else {
    fill(0);
    textSize(20);
    text("press 'h' for help", 760, 640);
  }
  if (work && !axi.checkMotors() && frameCount%30==0) plotLine();
}
void mousePressed() {
  if (mouseButton == RIGHT && merge) for (int j=0; j<cases.size(); j++) if (cases.get(j).getPos()>0) {
    if (nConnect==j) {
      cases.remove(j);
      reloadCases();
    } else merge(j);
  }
  if (mouseButton == LEFT) for (int i=0; i<cases.size(); i++) if (cases.get(i).getPos()>0) cases.get(i).createCase(i);
}
void merge(int id) {
  float x0 = (cases.get(id).getC(0).x);
  float x1 = (cases.get(id).getC(1).x);
  float y0 = (cases.get(id).getC(0).y);
  float y1 = (cases.get(id).getC(3).y);
  if (x0 ==cases.get(nConnect).getC(0).x && x1==cases.get(nConnect).getC(1).x) {
    y0 = int(min(cases.get(id).getC(0).y, cases.get(nConnect).getC(0).y));
    y1 = int(max(cases.get(id).getC(3).y, cases.get(nConnect).getC(3).y));
    cases.add(new Case(nCases, x0, y0, x1, y0, x1, y1, x0, y1));
    removeCases(id);
  } else if (y0==cases.get(nConnect).getC(0).y && y1==cases.get(nConnect).getC(3).y) {
    x0 = int(min(cases.get(id).getC(0).x, cases.get(nConnect).getC(0).x));
    x1 = int(max(cases.get(id).getC(1).x, cases.get(nConnect).getC(1).x));
    cases.add(new Case(nCases, x0, y0, x1, y0, x1, y1, x0, y1));
    removeCases(id);
  }
}
void removeCases(int d) {
  if (nConnect>d) nConnect--;
  cases.remove(d);
  cases.remove(nConnect);
  reloadCases();
}
void reloadCases() {
  for (int i=0; i<cases.size(); i++) cases.get(i).setId(i);
  nCases = cases.size();
}
void keyPressed() {
  int stepsH = 300; //charWidth * scale;
  int stepsV = 300; //lineHeight * scale;
  if (keyCode == RIGHT) {
    if (!axi.idle()) return;
    axi.move(stepsH, 0);
    nextX += stepsH;            // CAUTION: probably needs a better check
  } else if (keyCode == LEFT && nextX>0) {
    if (!axi.idle()) return;
    axi.move(-stepsH, 0);
    nextX -= stepsH;
  } else if (keyCode == UP && nextY>0) {
    if (!axi.idle()) return;
    axi.move(0, -stepsV);
    nextY -= stepsV;
  } else if (keyCode == DOWN) {
    if (!axi.idle()) return;
    axi.move(0, stepsV);
    nextY += stepsV;
  } else if (key== 'a') {   //  manually reset the AxiDraw, press again to set "Zero"
    if (axi.enabled()) {
      axi.up();                // force the pen up
      axi.off();
      offsX = -1;                // reset the typewriter's offset
    } else {
      axi.on();
      axi.zero();
    }
  } else if (key=='c') goComics();
  else if (keyCode==9) switchMarge();
  else if (key=='k') axi.checkPen();
  else if (key=='g') axi.checkMotors();
  else if (key=='t') axi.toggle();
  else if (key=='h') help =! help;
  else if (key=='s') {
    axi.up();
    axi.stop();
  } else if (key==ENTER) {
    merge =! merge;
    cube = false;
  } else if (key=='²' || key=='@') cube =! cube;
  else if (key == ' ') {
    if (axi.pen() == Control.UP) axi.down();
    else axi.up();
  } else if (key =='m') {
    if (offsX == -1) setOffset();
    nextX = offsX;
    nextY += stepsV;
    axi.moveTo(nextX, nextY);
  }
}
// A dirty little method to set the "upper left" corner of the typewriter
void setOffset() {
  offsX = axi.x();
  offsY = axi.y();
  nextX = offsX;
  nextY = offsY;
}
