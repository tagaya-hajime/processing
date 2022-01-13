import fisica.*; //<>//
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
Connection con = null;
Statement  stm = null;
DateTimeFormatter dtf = null;
//矢印を管理するクラス
Arrow arrow;
//ランキングを実装するクラス
Rank rank;

//fisica
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

int countraws;
int finish =0;

void setup()
{


  dtf = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm");
  //DBファイルはスケッチフォルダに生成する
  String dbName = sketchPath("rank.db");

  //DBをOPENする
  dbOpen(dbName );

  countraws =countraws();
  countraws++;


  frameRate(60);
  textAlign(CENTER);
  size(900, 1000);

  //rankを作る
  rank = new Rank();

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
    rect(100, 0, 700, 800);
    fill(255);
    textSize(60);
    text("TOTAL SCORE:"+total, width/2, 100);
    if (finish==0) {
      addDB();//データを書き込む
      getranking();
    }
    rank.write(countraws);
    if(rank.ranker!=0)text("new!→", 230, rank.ranker);    
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


//usedb
void addDB() {
  finish  =1;

  LocalDateTime  ldt  =  LocalDateTime.now();
  String dateTime = ldt.format( dtf );

  String sql = "INSERT INTO TEST( _id, _total, _datetime) "
    + "VALUES( ?, ?, ? )";

  println(countraws);
  println(total);
  println(dateTime);

  try {

    PreparedStatement pstm = con.prepareStatement( sql );
    pstm.setInt( 1, countraws );
    pstm.setInt( 2, total );
    pstm.setString( 3, dateTime);    
    pstm.executeUpdate();    
    pstm.close();
  } 
  catch( SQLException e ) {
    e.printStackTrace();
  }
}
int countraws() {
  PreparedStatement psm = null;

  try {

    String sql = "SELECT COUNT(*) FROM test ";
    psm = con.prepareStatement( sql ); 

    //検索する
    ResultSet rs = psm.executeQuery();

    int raws = rs.getInt(1);


    return raws;
  } 
  catch( SQLException e ) {
    e.printStackTrace();
    return 999;
  }
}

void getranking() {
  PreparedStatement psm = null;
  try {

    String sql = "SELECT _ID ,RANK() OVER(ORDER BY _TOTAL DESC) ,_TOTAL,_DATETIME FROM test LIMIT 5";
    psm = con.prepareStatement( sql ); 

    //検索する
    ResultSet rs = psm.executeQuery();

    while (rs.next()) {
      rank.rank_id.add(rs.getInt(1));
      rank.rank_no.add(rs.getInt(2));
      rank.rank_score.add(rs.getInt(3));
      rank.rank_date.add(rs.getString(4));
    }
  } 
  catch( SQLException e ) {
    e.printStackTrace();
  }
}


//db open&close
void dbOpen( String dbName ) {
  try {
    //JDBCドライバを明示的にロードする
    Class.forName("org.sqlite.JDBC");

    //DBをOPENする
    con = DriverManager.getConnection( "jdbc:sqlite:" + dbName );

    stm = con.createStatement();
    stm.close();

    String sql = "CREATE TABLE IF NOT EXISTS test( "
      + "_id INTEGER PRIMARY KEY," 
      + "_total INTEGER,"
      + "_datetime TEXT  )";

    stm.executeUpdate( sql );
    stm.close();
  } 
  catch( ClassNotFoundException e) {
    e.printStackTrace();
  } 
  catch ( SQLException e ) {
    e.printStackTrace();
  }
}
void dbClose() {  
  try {
    if ( con != null ) {
      //DBをクローズする
      con.close();
      con = null;
    }
  } 
  catch ( SQLException e ) {
    e.printStackTrace();
  }
}
