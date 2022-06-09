/**
 * A simple wrapper of EiBotBoard commands for quick sketches with an AxiDraw. 
 * Most of the methods are just wrappers around the EBB serial commands.
 * There is not much abstraction: 
 * the movement and position units are just 1/16 motor steps (int). 80 steps = 1mm.
 * 
 * Main methods: 
 *   Control.move(dx, dy)
 *   Control.moveTo(x, y)
 *   Control.up()
 *   Control.down()
 *   Control.on()
 *   Control.off()
 *   Control.zero()
 *   Control.x();
 *   Control.y();
 *
 * EiBotBoard commands reference: 
 * http://evil-mad.github.io/EggBot/ebb.html
 *
 * NOTE: Tested only on an AxiDraw v2
 * 
 * @author Andreas Gysin
 */
import processing.serial.*;
class Control {
    public int penStatus = UP;                   // current status
    public Serial port;  
    public Echo echo;
    public PVector pos = new PVector();
    final private int MOTOR_STEPS = 1;           // hardcoded at 1/16. Always.
    final public static int UP   = 0;            // pen status up   (1 for up is equivalent of QP)
    final public static int DOWN = 1;            // pen status down (0 for up is equivalent of QP)
    private int delayAfterRaising;               // pen delay in ms
    private int delayAfterLowering;              // pen delay in ms
    private int motorSpeed;                      // motor speed for both steppers [1-5]
    private int penUpValue;                      // servo max for raised pen  [1..65535] 
    private int penDownValue;                    // servo min for lowered pen [1..65535]                
    private int[] min = new int[]{0, 0};         // asbolute minimum x,y in steps
    private int[] max = new int[]{24000, 17000}; // absolute maximum x,y in steps (around 24000, 17000 for AxiDraw v2)
    private int _time;                           // time we are allowed to begin the next movement (when the current move will be complete).
    private int _timeAccumulator;                // accumluates the millis for each move and each delay, can be resetted with resetTime() 
    private boolean enabled = true;              // motor status (internal)
    private PApplet parent;                      // Refernece to the main PApplet (mainly for serial stuff) 
    Control(PApplet parent) {
        this.parent = parent;                      // Keep track of the PApplet: needed for serial setup
        echo = new Echo(null);                     // Echo keeps track of all the EBB commands and also act as a dummy port 
        servo(23000, 25000);                       // Servo min max
        motorSpeed(1500);                          // Set the motor speed    
        servoDelay(900, 1200);                      // Delay before rising and before lowering the pen                    
        addTime(0);                                // Reset the timer
        echo.enableBuffer();                       // Enable the internal "echo": all EBB commands are stored in a string 
        on();                                      // Enable motors and force step size to 1/16
    }
    /**
     * Sets the steps per second 
     *
     * @param Integer s The number of steps.
     */
    void motorSpeed(int s) {
        motorSpeed = constrain(s, 100, 5000);
        println("motorSpeed = " + motorSpeed);
    }
    /**
     * Sets the delay after raising and lowering the pen: 
     * the pen needs some time and you don't want to move it while it's getting in position
     *
     * @param Integer beforeRaise, beforeLower
     */
    void servoDelay(int raise, int lower) {
        delayAfterRaising = max(0, raise);
        delayAfterLowering = max(0, lower);
        println("delayAfterRaising  = " + delayAfterRaising);
        println("delayAfterLowering = " + delayAfterLowering);
    }
    /**
     * Configure servo down / up limits (and speed).
     * With an up value of ~26700 the servo arm is vertical up.
     * NOTE: down should be smaller than up.
     *
     * @params Integer down, up 
     */
    // Configure servo limits (and speed):
    void servo(int down, int up) {
        penUpValue   = constrain(up, 1, 65535);
        penDownValue = constrain(down, 1, 65535);
        echo.write("SC,5," + penUpValue + "\r");    // SC,5,servo_max   (1 to 65535, def: 16000), sets the "Pen UP"   position    
        echo.write("SC,4," + penDownValue + "\r");  // SC,4,servo_min   (1 to 65535, def: 12000), sets the "Pen DOWN" position
        echo.write("SC,10,65535\r");                // SC,10,servo_rate (0 to 65535, def: ?????), sets the servo speed
        println("penUpValue   = " + penUpValue);
        println("penDownValue = " + penDownValue);
    }
    public void toggle(){
        echo.write("toggle,m,"+"\r");
    }
    /**
     * Queries the step position and sets the return values into pos[]. 
     * Works only when a correct manual reset has been done.
     */
    public void readPos() {
        print("Querying Step position... ");
        if (port == null || !port.active()) {
            println("port not open!");
            return;
        }
        delay(100);
        port.clear();
        port.write("QS\r");
        delay(100);
        while (port.available () > 0) {
            String buf = port.readStringUntil('\n');    
            if (buf != null) {
                String[] p = buf.trim().split(",");
                if (p.length != 2) continue; // probably an "OK" string or something else...
                int mx = parseInt(p[0]); // stepper steps
                int my = parseInt(p[1]); 
                pos.set((mx + my) / 2, (mx - my) / 2);  // convert stepper steps to pen steps (mixed axis) 
                println("response: " + buf.trim());
                println("Position (pos[]) set to: " + pos.x + "," + pos.y + " (mixed axis)");
            }
        }
    }
    /**
     * Marks the current pen location as (0,0) in step coordinates. 
     * Is usually combined (called after) with doManualReset().
     * NOTE: Manually move the motor carriage to the upper left corner before calling this command.
     */
    void zero() {
        nextX = 0;
        nextY = 0;
        pos.set(0, 0);
        int delay = move(50, 50);     // add a micro offset for precision!
        delay(delay + 20);            // wait before resetting...
        echo.write("CS\r");            
        pos.set(0, 0);
        echo.clear();                 // clear the buffers... makes sense after a reset.
        _time = 0;                    // reset the "timer"
        _timeAccumulator = 0;
        addTime(0);
    }  
    int[] pos() {
        return new int[]{int(pos.x), int(pos.y)};
    }
    int x() {
        return int(pos.x);
    }
    int y() {
        return int(pos.y);
    }
    private void addTime(int t) {
        _time = millis() + t;
        _timeAccumulator += t;
    }
    public int approxTime() {
        return _timeAccumulator;  // TODO...
    }

    public void resetTime() {
        _timeAccumulator = 0;     // TODO...
    }
    /**
     * Rises the pen
     *
     * @param Boolean force when true bypasses the isDown test. Useful for initial reset.
     */
    int down(boolean force) {
        if (penStatus == UP || force) {
            echo.write("SP,0," + delayAfterRaising + "\r");           
            penStatus = DOWN;
            addTime(delayAfterRaising);
            return delayAfterRaising;
        }
        return 0;
    }
    /**
     * Rises the pen
     */
    int down() {
        return down(false);
    }
    /**
     * Lowers the pen
     */
    int up() {
        if (penStatus == DOWN) {      
            echo.write("SP,1," + delayAfterLowering + "\r"); 
            penStatus = UP;
            addTime(delayAfterLowering);
            return delayAfterLowering;
        }
        return 0;
    }  
    /**
     * Move dx,dy (delta) steps.
     * NOTE: the XM command is used for mixed axis plooters (AxiDraw)... won't work for the EggBot
     *
     * @param dx, dy amount of steps for both motors.
     * @return Integer Evaluation of elapsed time. 
     */
    int move(int dx, int dy) {
        int mx = constrain(dx, min[0] - int(pos.x), max[0] - int(pos.x));
        int my = constrain(dy, min[1] - int(pos.y), max[1] - int(pos.y));
        int travelTime = 0; // motor travel time in millis (max of x or y)
        if ((mx != 0) || (my != 0)) {   
            pos.set(pos.x+mx, pos.y+my);
            travelTime = int( 1540.0 * max(abs(mx), abs(my)) / motorSpeed);
            //println(mx+" "+travelTime+" "+);
           // travelTime = max(travelTime, 1);
            addTime(travelTime);
            echo.write("XM," + travelTime + "," + mx + "," + my + "\r");
        }
        return travelTime;
    }
    /**
     * Move to x,y in absolute steps (based on pos[], and assumes the AxiDraw has been resetted)
     * 
     * @param x, y final step positions for both motors.
     * @return Integer Evaluation of elapsed time. 
     */
    int moveTo(int x, int y) {    
        return move(x - int(pos.x), y - int(pos.y));
    }
    /**
     * Checks if the AxiDraw is currently moving (steppers / servo ).
     * NOTE: this is based on an estimate of accumulated time... also considers delays.
     *
     * @return Boolean 
     */
    boolean idle() {    
        return _time > millis() == false;
    }
    /**
     * Returns the motor state...
     * By default we assume this has been done prior startup.
     *
     * @return Boolean 
     */
    boolean enabled() {
        return enabled;
    }
    /**
     * Used to check the pen position.
     *
     * @return Boolean 
     */
    int pen() {
        return penStatus;
    }
    void setPenStatus(int p) {
        penStatus = p;
    }
    void checkPen() {
        echo.write("QP\r");
    }
    PVector getPos(){
        return pos;
    }
    /**
     * De-energize both motors.
     */
    void off() {       
        echo.write("EM,0,0\r");
        enabled = false;
    }
    void on() {
        echo.write("EM," + MOTOR_STEPS + "\r");
        enabled = true;
    }
    /**
     * Stop both motors.
     */
    void stop() {
        echo.write("ES\r");      // stop!
        currentCase = nCases;
        currentBord = 7;
        work = false;
        print("abord");
    }
    boolean checkMotors() {
        echo.write("QM\r");
        return isRunning;
    }
    /**
     * RESPONSE: QM,CommandStatus,Motor1Status,Motor2Status,FIFOStatus<NL><CR>
     * Use this command to see what the EBB is currently doing.
     * It will return the current state of the 'motion system', 
     * each motor's current state, and the state of the FIFO.
     * - CommandStatus is nonzero if any "motion commands" are presently executing, and zero otherwise.
     * - Motor1Status is 1 if motor 1 is currently moving, and 0 if it is idle.
     * - Motor2Status is 1 if motor 2 is currently moving, and 0 if it is idle.
     * - FIFOStatus is non zero if the FIFO is not empty, and 0 if the FIFO is empty.
     */
    void queryMotor() {
        if (port == null || !port.active()) return;
        port.write("QM\r");
    }
    /**
     * RESPONSE: PenStatus<NL><CR>OK<NL><CR>
     * This command queries the EBB for the current pen state. 
     * It will return PenStatus of 1 if the pen is up and 0 if the pen is down. 
     * If a pen up/down command is pending in the FIFO, 
     * it will only report the new state of the pen after the pen move has been started.
     * NOTE: the above is pasted from the EBB manual and is currently not correct: 1 is down, 0 is up
     */
    void queryPen() {
        if (port == null || !port.active()) return;
        port.write("QP\r");
    }
    /**
     * RESPONSE: GlobalMotor1StepPosition,GlobalMotor2StepPosition<NL><CR>OK<CR><NL>
     * This command prints out the current Motor 1 and Motor 2 global step positions. 
     * Each of these positions is a 32 bit signed integer, that keeps track of the positions of each axis. 
     * The CS command can be used to set these positions to zero.
     * Every time a step is taken, the appropriate global step position is incremented 
     * or decrimented depnding on the direction of that step.
     * The global step positions can be be queried even while the motors are stepping, 
     * and it will be accurate the instant that the command is executed, 
     * but the values will change as soon as the next step is taken. 
     * It is normally good practice to wait until stepping motion is complete 
     * (you can use the QM command to check if the motors have stopped moving) before checking the current positions.
     */
    void querySteps() {
        if (port == null || !port.active()) return;
        port.write("QS\r");
    }
    /**
     * RESPONSE: EBBv13_and_above EB Firmware Version 2.4.2<NL><CR> (or similar)
     */
    void version() {
        if (port == null || !port.active()) return;
        port.write("V\r");
    }
    /**
     * Tries to opens a port
     */
    public Serial open() {
        port = scanSerial(parent);    
        if (port != null) {
            echo.setPort(port);
            echo.enablePort();
        }
        return port;
    }
    /**
     * Closes the port
     */
    void close() {
        port.clear(); 
        port.stop();
        port = null;
    }
    /**
     * Helper function: scans all the serial ports abailable trough Serial.list()
     * and tries to determine if if there is an AxiDraw connected.
     * NOTE: Tested only on macOS.
     *
     * @return Serial An open port if detected, otherwise null.
     */
    Serial scanSerial(PApplet parent) {
        final int RATE = 115200; //38400;
        Serial p = null;
        String[] ports = Serial.list();
        for (int i=0; i<ports.length; i++) {
            try {
                p = new Serial(parent, ports[i], RATE);
            }
            catch (Exception e) {
                println("Serial port " + ports[i] + " could not be initialized... Skipping.");
                continue;
            }
            print("Looking for EBB on port: " + ports[i] + "... ");
            p.clear();
            p.write("V\r");   // request the version string
            delay(100);          // give it some breath...

            while (p.available () > 0) {
                String buf = p.readString();
                if (buf != null && buf.contains("EBB")) {
                    println("Found!");
                    println("Version string: " + trim(buf));
                    return p;
                }
            }
            p.clear();
            p.stop();
            p = null;
            println("EBB not detected.");
        }
        return null;
    } 
    /** 
     * A wrapper for the serial port.
     * Attempts to record some of the EBB commands... coul be useufl for preview, etaxi.
     */
    private class Echo {
        Serial port;
        String buffer;
        boolean portEnabled = true;
        boolean bufferEnabled = false;
        public Echo(Serial p) {
            setPort(p);
            clear();
        }
        void setPort(Serial p) {
            this.port = p;
        }
        void clear() {
            if (port != null && port.active()) port.clear();
            buffer = "";
        }
        void write(String str) {
            if (portEnabled && port != null && port.active()) {
                port.write(str);
            }
            if (bufferEnabled) {
                buffer += str;
            }
        }
        void enablePort(boolean e) {
            if (port != null) {
                portEnabled = e;
            }
        }
        void enablePort() {
            enablePort(true);
        }  
        void disablePort() {
            enablePort(false);
        }
        void enableBuffer(boolean e) {
            bufferEnabled = e;
        }
        void enableBuffer() {
            enableBuffer(true);
        }  
        void disableBuffer() {
            enableBuffer(false);
        }
    }
}
