import fisica.*; //<>//

Arrow arrow;

FWorld world;
FCircle ball;
FBox pins[];
FBox pin;

//現在何試合目か
int set =0;
//全部で何試合か
int match = 10;
//pinの本数
int pin_number =10;
//ゲームごとのスコア
int[] score={0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
//最初の位置、ゲーム後の位置
PVector[][] def_position;
PVector[][] result;
//arrowの変形するスピード
int width_velocity =25;
int height_velocity=-30;
//スコアの合計
int total=0;

void setup()
{
  frameRate(60);
  textAlign(CENTER);
  size(900, 1000);


  //arrowを作る
  arrow = new Arrow(450, 900, 450, 300, color(255, 50, 50), 0);

  //worldを作る
  Fisica.init(this);
  world = new FWorld();
  world.setGravity(0, 0);

  //ballをつくる
  ball = new FCircle(50);
  ball.setPosition(width/2, 900);
  ball.setFill(50, 200, 255);
  ball.setNoStroke();
  ball.setRestitution(0.2);
  ball.setDensity(50);
  ball.setDamping(1);
  ball.setGrabbable(true);
  world.add(ball);

  //もともとのpinの場所(最初にすべてのゲーム分生成する)
  def_position=new PVector[10][];
  for (int i=0; i<match; i++) {
    def_position[i] = new PVector[10];
    for (int j=0; j<pin_number; j++) {
      def_position[i][j]=new PVector(random(330, 570), random(30, 400));
    }
  }

  //プレイ後のpinの場所
  result=new PVector[10][];
  for (int i=0; i<match; i++) {
    result[i] = new PVector[10];
    for (int j=0; j<pin_number; j++) {
      result[i][j]=new PVector(0, 0);
    }
  }

  //pinを作る
  pins = new FBox[10];
  for (int i=0; i<pins.length; i++) {
    pin = new FBox(30, 30);
    pin.setFill(255, 255, 255);
    pin.setNoStroke();
    pin.setPosition(def_position[0][i].x, def_position[0][i].y);
    pin.setDensity(20);
    world.add(pin);
    pins[i]=pin;
  }
}

void draw()
{
  //背景色
  background(0);

  //ステージ作成
  fill(255, 200, 0);
  rect(width/3, 0, width/3, height);
  for (int i=1; i<=10; i++) {
    line(width/3+(width/30*i), 0, width/3+(width/30*i), height);
  }

  //スコアボード
  fill(255);
  for (int i=0; score.length>i; i++) {
    textSize(16);
    text("game" +(i+1) +":", 650, 200+70*i);
    textSize(30);
    text(score[i], 700, 230+70*i);
  }

  arrow.mode();



  world.step();
  world.draw();

  if (set<match) {
    arrow.draw();
  } else {
    fill(255, 0, 0);
    rect(100, 0, 700, 150);
    fill(255);
    textSize(60);
    text("TOTAL SCORE:"+total, width/2, 100);
  }
  //スピードが遅くなるとリセット（まだ動かしていない時は除く）
  if ((abs(ball.getVelocityX())<25&&abs(ball.getVelocityY())<25)&&abs(ball.getVelocityX())+abs(ball.getVelocityY())!=0) {
    resetadaptor();
  } else if (ball.getY()<-100) {
    resetadaptor();
  }
}


//ゲームごとの処理とりまとめ
void resetadaptor() {
  ballreset();
  arrowreset();
  setresult();
  pinreset();
  score();
}
//ボールの位置をリセット
void ballreset() {
  ball.setVelocity(0, 0);
  ball.setPosition(width/2, 900);
}
//矢印の向きをリセット
void arrowreset() {
  arrow.mode=0;
  arrow.position.x=450;
  arrow.to.x=450;
  arrow.to.y=300;
}
//ピンの位置を登録
void setresult() {
  //現在のセットのピンの位置をresultに収納して、消去する
  for (int i=0; i<pins.length; i++) {
    result[set][i]=new PVector(pins[i].getX(), pins[i].getY());
    world.remove(pins[i]);
  }
}
//ピンの位置をリセット
void pinreset() {
  //新しくピンを作る
  pins = new FBox[10];
  for (int i=0; i<pins.length; i++) {
    if (set<9) {
      pin = new FBox(30, 30);
      pin.setPosition(def_position[set+1][i].x, def_position[set+1][i].y);
      pin.setNoStroke();
      pin.setDensity(5);
      pin.setFill(255, 255, 255);
      world.add(pin);
      pins[i]=pin;
    } else {
      world.remove(ball);
    }
  }
}
//現在のセットのスコアを計算して格納する
void score() {
  int sum = 0;
  for (int j = 0; pin_number>j; j++) {
    sum +=PVector.dist(def_position[set][j], result[set][j]);
  }
  score[set]=sum;
  total+=sum;
  set++;
}

void keyPressed() {
  if (keyCode == ENTER) {
    textSize(16);
    text("Xv:"+ball.getVelocityX(), 100, height/2);
    text("Yv:"+ball.getVelocityY(), 100, height/2+50);
    text("X:"+mouseX, 100, height/2+100);
    text("Y:"+mouseY, 100, height/2+150);
    text("set:"+set, 100, height/2+200);
  }
}
void mousePressed() {
  arrow.mode++;
}
