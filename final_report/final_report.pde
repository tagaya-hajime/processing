import fisica.*;  //<>//
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

//DBへの接続情報
Connection con = null;
DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm");
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
int width_velocity =15;
int height_velocity=-15;
//スコアの合計
int total=0;
//データベースのIDの最大値を取得する
int countraws;
//ゲームの終了を判断する
int finish =0;

void setup()
{
  frameRate(120);
  textAlign(CENTER);
  size(900, 1000);

  //DBをOPENする
  dbOpen(sketchPath("rank.db"));
  //IDの最大値＋１を取得する
  countraws =idmax();
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
  ball.setDensity(30);
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
    pin.setDensity(15);
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

  //ゲーム中
  if (set<match) {
    arrow.draw();
  //ゲーム後
  } else {
    fill(255, 0, 0);
    rect(100, 0, 700, 700);
    fill(255);
    textSize(60);
    text("TOTAL SCORE:"+total, width/2, 100);
    //ゲーム終了後一度だけ実行する
    if (finish==0) {
      addDB();//データを書き込む
      getranking();//ランキングを取得する
    }
    //ランキングを表示
    rank.write(countraws);
    //今回の結果がランクインしたら実行
    if (rank.ranker!=0)text("new!→", 230, rank.ranker);
  }
  //スピードが遅くなるとリセット（まだ動かしていない時は除く）
  if ((abs(ball.getVelocityX())<25&&abs(ball.getVelocityY())<25)&&abs(ball.getVelocityX())+abs(ball.getVelocityY())!=0) {
    resetadaptor();
  //外側に出てもリセット
  } else if (ball.getY()<-100) {
    resetadaptor();
  }
}

//セットごとの処理とりまとめ
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
      pin.setDensity(15);
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

//ゲーム結果をDBに格納する
void addDB() {
  finish =1;
  LocalDateTime ldt = LocalDateTime.now();
  String dateTime = ldt.format( dtf );
  try {
    String sql_insert = "INSERT INTO TEST( _id, _total, _datetime) "
      + "VALUES( ?, ?, ? )";
    PreparedStatement psm = con.prepareStatement( sql_insert );
    psm.setInt( 1, countraws );
    psm.setInt( 2, total );
    psm.setString( 3, dateTime);    
    psm.executeUpdate();    
    psm.close();
  } 
  catch( SQLException e ) {
    e.printStackTrace();
  }
}

//IDの最大値を取り出す
int idmax() {
  try {
    String sql_idget = "SELECT MAX(_ID)FROM test ";
    PreparedStatement psm= con.prepareStatement(sql_idget ); 
    ResultSet rs = psm.executeQuery();
    int raws = rs.getInt(1);
    raws++;
    return raws;
  } 
  catch( SQLException e ) {
    e.printStackTrace();
    return 999;
  }
}

//ランキングの取得
void getranking() {
  try {
    String sql_rankget = "SELECT _ID ,RANK() OVER(ORDER BY _TOTAL DESC) ,_TOTAL,_DATETIME FROM test LIMIT 9";
    PreparedStatement psm  = con.prepareStatement( sql_rankget ); 
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

//db open
void dbOpen( String dbName ) {
  try {
    Class.forName("org.sqlite.JDBC");

    //DBをOPENする
    con = DriverManager.getConnection( "jdbc:sqlite:" + dbName );
    Statement  stm  = con.createStatement();
    String sql_open = "CREATE TABLE IF NOT EXISTS test( "
      + "_id INTEGER PRIMARY KEY," 
      + "_total INTEGER,"
      + "_datetime TEXT  )";
    stm.executeUpdate( sql_open );
    stm.close();
  } 
  catch( ClassNotFoundException e) {
    e.printStackTrace();
  } 
  catch ( SQLException e ) {
    e.printStackTrace();
  }
}

//エンターキーで矢印をストップ
void keyPressed() {
  if (keyCode == ENTER) {
    arrow.mode++;
  }
}
