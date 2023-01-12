import std/[random]
import strutils
import g_mine


#[ say something ]#


randomize()


proc genTabId*(): string = 
  # 9 zeros is maximal int size, otherwise use int64
  let idst = $rand(1000000000)
  result = idst


proc getIntroText*(tekst: string, sizeit: int): string =
  var lenghit: int
  lenghit = tekst.len
  if lenghit > sizeit:
    result = tekst[0..sizeit]
  else:
    result = tekst[0..lenghit - 1]



proc getTagContent_old(link_or_tekst, startpartst, endpartst: string, 
                            maxlineit: int): string = 
  #[ 
    Retrieve a sequence of content-data between pairs of startpartst 
    and endpartst. 
   ]#
  var
    datasq, frag_onesq: seq[string]
    tempst, contentst, list: string
    itemcountit: int
  datasq = getDataSequence(link_or_tekst, startpartst, endpartst)

  list = ""
  if datasq.len > 0:
    itemcountit = 1
    for itemst in datasq:
      echo itemst
      echo "------------"
      # parse the data-sequence for the content between > and <
      frag_onesq = itemst.split('>', 1)
      tempst = frag_onesq[1]
      if ('>' in tempst) and ('<' in tempst):
        contentst = getInnerText2(tempst)
      else: 
        contentst = tempst

      if itemcountit <= maxlineit:
        if contentst != "":
          list &= contentst & "<br>\p"
      itemcountit += 1
    echo "========="
  result = list



proc getContentList*(link_or_tekst, startpartst, endpartst: string, 
                      output_doc: DocType, maxlineit: int): string =
  #[ 
    Create a list of content-data between pairs of startpartst 
    and endpartst. 
   ]#

  result = enlistSequenceToDoc(getTagContent(link_or_tekst, startpartst, endpartst), 
                        output_doc, maxlineit)



when isMainModule:
  #echo genTabId()
  var linkst = "https://www.bibliotecapleyades.net/vida_alien/xenology/papers_xeno/galacticempires.htm"
  echo "********"
  #echo getTagContent_old(linkst, "<font size", "</font>", 100)
  echo getContentList(linkst, "990012", "</font>", docHtml, 100)
