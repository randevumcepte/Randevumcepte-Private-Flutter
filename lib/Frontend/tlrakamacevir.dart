double tlyirakamacevir(String tl)
{
  tl = tl.replaceAll(".", "");
  tl = tl.replaceAll(",", ".");

  return double.parse(tl);
}