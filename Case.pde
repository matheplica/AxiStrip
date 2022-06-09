int currentCase, currentBord, stepBord;
void goComics() {
    cases.size();
    nextCase();
    work = true;
}
void plotLine() {
    if (stepBord==1) axi.down();
    if (stepBord==5) {
        cases.get(currentCase).setDone();
        nextCase();
    } else {
        goNextBord();
        stepBord++;
    }
    delay(956);
}
void goNextBord() {
    nextX = int(cases.get(currentCase).getC((currentBord+stepBord)%4).x*scale);
    nextY = int(cases.get(currentCase).getC((currentBord+stepBord)%4).y*scale);
    axi.moveTo(nextX, nextY);
}
void nextCase() {
    axi.up();
    float shorter = 120000.0;
    for (int i=0; i<cases.size(); i++) {
        if (!cases.get(i).isDone()) {
            for (int j=0; j<4; j++) {
                float dist = dist(axi.getPos().x, axi.getPos().y, cases.get(i).getC(j).x*scale, cases.get(i).getC(j).y*scale);
                if (dist<shorter) {
                    shorter = dist;
                    currentCase = i;
                    currentBord = j;
                    stepBord = 0;
                }
            }
        }
    }  
}
void switchMarge() {
    if (mrg.x==5) mrg.mult(3);
    else mrg.div(3);
}
class Case {
    PVector[] corner = new PVector[4];
    PVector center, tCenter, v31, v32, h31, h32;
    int pos, id, start;
    boolean connect, done;
    Case(int id, PVector p1, PVector p2, PVector p3, PVector p4) {
        this.id = id;
        corner[0] = new PVector(p1.x, p1.y);
        corner[1] = new PVector(p2.x, p2.y);
        corner[2] = new PVector(p3.x, p3.y);
        corner[3] = new PVector(p4.x, p4.y);
        center = new PVector();
        center.set(PVector.add(corner[0], corner[2]).div(2));
        tCenter = new PVector(center.x, center.y);
        create3();
    }
    Case(int id, float p1x, float p1y, float p2x, float p2y, float p3x, float p3y, float p4x, float p4y) {
        this.id = id;
        corner[0] = new PVector(p1x, p1y);
        corner[1] = new PVector(p2x, p2y);
        corner[2] = new PVector(p3x, p3y);
        corner[3] = new PVector(p4x, p4y);
        center = new PVector();
        center.set(PVector.add(corner[0], corner[2]).div(2));
        tCenter = new PVector(center.x, center.y);
        create3();
    }
    void create3() {
        v31 = PVector.lerp(corner[0], corner[1], 0.333333333);
        v32 = PVector.lerp(corner[0], corner[1], 0.666666666);
        h31 = PVector.lerp(corner[0], corner[3], 0.333333333);
        h32 = PVector.lerp(corner[0], corner[3], 0.666666666);
    }
    PVector getC(int c) {
        return corner[c];
    }
    void setId(int d) {
        id = d;
    }
    void createCase(int r) {
        tCenter.set(center);
        if (cube) {
            if (pos==1) create3V(r);
            else if (pos>=2) create3H(r);
        } else if (merge) nConnect = r;
        else if (pos==1) createVCases(r);
        else if (pos==2) createHCases(r);
        else if (pos==3) createQuad(r);
    }
    void create3V(int r) {
        v31.sub(mrg.x, 0);
        cases.add(new Case(nCases, corner[0], v31, new PVector(v31.x, corner[3].y), new PVector(corner[0].x, corner[3].y)));
        v31.add(new PVector(mrg.x, 0).mult(2));
        v32.sub(mrg.x, 0);
        cases.add(new Case(nCases+1, v31, v32, new PVector(v32.x, corner[3].y), new PVector(v31.x, corner[3].y)));
        v32.add(new PVector(mrg.x, 0).mult(2));
        cases.add(new Case(nCases+2, v32, new PVector(corner[1].x, v32.y), new PVector(corner[1].x, corner[2].y), new PVector(v32.x, corner[2].y)));
        cases.remove(r);
        reloadCases();
    }
    void create3H(int r) {
        h31.sub(0, mrg.y);
        cases.add(new Case(nCases, corner[0], corner[1], new PVector(corner[1].x, h31.y), h31));
        h31.add(new PVector(0, mrg.y).mult(2));
        h32.sub(0, mrg.y);
        cases.add(new Case(nCases+1, h31, new PVector(corner[1].x, h31.y), new PVector(corner[1].x, h32.y), h32));
        h32.add(new PVector(0, mrg.y).mult(2));
        cases.add(new Case(nCases+2, h32, new PVector(corner[1].x, h32.y), new PVector(corner[1].x, corner[2].y), corner[3]));
        cases.remove(r);
        reloadCases();
    }
    void createHCases(int r) {
        tCenter.sub(mrg);
        cases.add(new Case(nCases, corner[0], corner[1], new PVector(corner[1].x, tCenter.y), new PVector(corner[0].x, tCenter.y)));
        tCenter.add(new PVector(mrg.x, mrg.y).mult(2));
        cases.add(new Case(nCases+1, new PVector(corner[0].x, tCenter.y), new PVector(corner[1].x, tCenter.y), corner[2], corner[3]));
        cases.remove(r);
        reloadCases();
    }
    void createVCases(int r) {
        tCenter.sub(mrg);
        cases.add(new Case(nCases, corner[0], new PVector(tCenter.x, corner[0].y), new PVector(tCenter.x, corner[3].y), corner[3]));
        tCenter.add(new PVector(mrg.x, mrg.y).mult(2));
        cases.add(new Case(nCases+1, new PVector(tCenter.x, corner[1].y), corner[1], corner[2], new PVector(tCenter.x, corner[2].y)));
        cases.remove(r);
        reloadCases();
    }
    void createQuad(int r) {
        tCenter.sub(mrg);
        cases.add(new Case(nCases, corner[0], new PVector(tCenter.x, corner[0].y), tCenter, new PVector(corner[0].x, tCenter.y)));
        tCenter.add(new PVector(mrg.x, 0).mult(2));
        cases.add(new Case(nCases+1, new PVector(tCenter.x, corner[1].y), corner[1], new PVector(corner[1].x, tCenter.y), tCenter));
        tCenter.add(new PVector(0, mrg.y).mult(2));
        cases.add(new Case(nCases+2, tCenter, new PVector(corner[2].x, tCenter.y), corner[2], new PVector(tCenter.x, corner[2].y)));
        tCenter.sub(new PVector(mrg.x, 0).mult(2));
        cases.add(new Case(nCases+3, new PVector(corner[3].x, tCenter.y), tCenter, new PVector(tCenter.x, corner[3].y), corner[3]));
        cases.remove(r);
        reloadCases();
    }
    void display() {
        mousePos();
        if(done) fill(196, 160);
        else noFill();
        stroke(0);
        if (merge) {
            if (nConnect==id) fill(80, 120, 200);
            else if (pos>0) fill(205, 120, 220);
        } else if (cube) {
            if (pos==1) {
                line(v31.x-mrg.x, corner[0].y, v31.x-mrg.x, corner[3].y);
                line(v32.x-mrg.x, corner[0].y, v32.x-mrg.x, corner[3].y);
                line(v31.x+mrg.x, corner[0].y, v31.x+mrg.x, corner[3].y);
                line(v32.x+mrg.x, corner[0].y, v32.x+mrg.x, corner[3].y);
            } else if (pos>=2) {
                line(corner[0].x, h31.y-mrg.y, corner[1].x, h31.y-mrg.y);
                line(corner[0].x, h32.y-mrg.y, corner[1].x, h32.y-mrg.y);
                line(corner[0].x, h31.y+mrg.y, corner[1].x, h31.y+mrg.y);
                line(corner[0].x, h32.y+mrg.y, corner[1].x, h32.y+mrg.y);
            }
        } else {
            if (pos==1 || pos==3) {
                line(center.x-mrg.x, corner[0].y, center.x-mrg.x, corner[2].y);
                line(center.x+mrg.x, corner[0].y, center.x+mrg.x, corner[2].y);
            }
            if (pos>=2) {
                line(corner[0].x, center.y-mrg.x, corner[1].x, center.y-mrg.x);
                line(corner[0].x, center.y+mrg.x, corner[1].x, center.y+mrg.x);
            }
        }
        quad(corner[0].x, corner[0].y, corner[1].x, corner[1].y, corner[2].x, corner[2].y, corner[3].x, corner[3].y);
    }
    void setDone() {
        done = true;
    }
    boolean isDone() {
        return done;
    }
    void mousePos() {
        pos = 0;
        if (mouseX>corner[0].x && mouseY>corner[0].y && mouseX<center.x && mouseY<corner[3].y) pos = 1;
        else if (mouseX>center.x && mouseY>corner[1].y && mouseX<corner[1].x && mouseY<center.y) pos = 2;
        else if (mouseX>center.x && mouseY<corner[2].y && mouseX<corner[1].x && mouseY>center.y) pos = 3;
    }
    int getPos() {
        return pos;
    }
}
