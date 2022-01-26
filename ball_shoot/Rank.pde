class Rank {
  ArrayList<Integer> rank_id;
  ArrayList<Integer> rank_no;
  ArrayList<Integer> rank_score;
  ArrayList<String> rank_date;
  int ranker;
  Rank() {
    rank_id=new ArrayList<Integer>();
    rank_no=new ArrayList<Integer>();
    rank_score=new ArrayList<Integer>();
    rank_date=new ArrayList<String>();
    ranker=0;
  }
  void write(int a) {
    textSize(20);
    text("rank      score                   date           ", width/2, 200);

    for (int i= 0; i<rank_id.size(); i++) {
      text("    "+rank_no.get(i)+"        "+rank_score.get(i)+"        "+rank_date.get(i), width/2, 250+50*i);
      if (rank_id.get(i)==a)ranker=250+50*i;
    }
  }
}
