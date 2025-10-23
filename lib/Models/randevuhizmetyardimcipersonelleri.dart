class RandevuHizmetYardimciPersonelleri{
  final String randevuhizmetid;
  final Map<String, dynamic> yardimcipersonel;
  final String index;

  Map<String, dynamic> toJson() {
    return {


      'randevuhizmetid':randevuhizmetid,
      'yardimcipersonel':yardimcipersonel,
      'index':index



    };
  }

  RandevuHizmetYardimciPersonelleri(this.randevuhizmetid, this.yardimcipersonel,this.index);
}