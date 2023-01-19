#[Data-mining

]#


import strutils, httpClient
import tables
import g_options
#import os, times


const
  versionfl = 0.2

type
  DocType* = enum
    docHtml
    docText


var debugbo: bool = false

template log(messagest: string) =
  # replacement for echo that is only evaluated when debugbo = true
  if debugbo: 
    echo messagest


proc getWebSite*(addresst: string): string = 
  var 
    client = newHttpClient()
    sitest: string = ""
  try:
    if len(addresst) > 3:
      sitest = client.getContent(addresst)
  
  except ValueError:
    let errob = getCurrentException()
    echo "\p-----address error -----" 
    echo "For address: " & addresst
    echo "An wrongly formatted address has been supplied;"
    echo "Cannot retrieve website."
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    #echo repr(errob) 
    echo "----End error-----\p"

  except HttpRequestError:
    let errob = getCurrentException()
    echo "\p-----address error -----" 
    echo "For address: " & addresst
    echo "A correctly formatted but non-existant address has been supplied;"
    echo "Cannot retrieve website."
    echo "System-error-description:"
    echo errob.name
    echo errob.msg
    #echo repr(errob) 
    echo "----End error-----\p"

  except:
    let errob = getCurrentException()
    echo "\p******* Unanticipated error *******" 
    echo "For address: " & addresst
    echo errob.name
    echo errob.msg
    #echo repr(errob) 
    echo "\p****End exception****\p"
  finally:
    result = sitest




proc getWebSiteAsync(addresst: string): string = 
  # experimental - in progress
  var client = newHttpClient()
  result = client.getContent(addresst)




proc getSubstringPositions*(stringst, subst: string):seq[int] = 
  #[
  Return positions of all occurrences of the substring in the string 
  and put them in a list of integers. Zero-based.
  ]#

#  echo stringst
#  echo subst

  var 
    subpositionsq: seq[int] = @[]
    fragmentsq: seq[string]
    occurit, posit: int


  fragmentsq = stringst.split(subst)
#  echo fragmentsq
  posit = 0    # needy for zero-basing
  occurit = stringst.count(subst)
#  echo "occurit= " & $occurit
  for i in 1 .. occurit:
  #  echo "i=" & $i
    posit += len(fragmentsq[i-1])
  #  echo "posit=" & $posit
    subpositionsq.add(posit)
    posit += len(subst)  
#  echo subpositionsq
  
  return subpositionsq



proc pairChainsAreValid(startchainsq, endchainsq: seq[int]): bool = 
  #[ For some functions of the form getData*** it is 
      needy to determine if the sequences (chains) of the start-tag
      and the end-tag are valid. That means:
      -1- the chain-lengths are equal
      -2- there are no overlaps:
        b(n) < e(n)
        b(n+1) > e(n)
   ]#
  var 
    indexit, endtagposit, former_endtagposit: int

  indexit = 0
  former_endtagposit = -1
  result = true
  if startchainsq.len == endchainsq.len:
    # continue second validation
    for startposit in startchainsq:
      endtagposit = endchainsq[indexit]
      if startposit > endtagposit:
        result = false
        break
      if startposit < former_endtagposit:
        result = false
        break
      former_endtagposit = endtagposit
      indexit += 1
  else:
    result = false




proc getDataSeqClean(tekst, starttagst, endtagst:string): seq[string] = 
  #[ 
  If the pair-chains are valid (local well-formedness) then 
  get the data between the tag-pair starttag and endtag for all 
  occurrences of the pair, and put them in a sequence. (zero-based)
  If the pair-chains are invalid or if there are no pair-occurences, 
  return an empty sequence @[]

  Call like: getDataSeqClean(sometext, "<tr>", "</tr>")
   ]#


  var
    startpositsq, endpositsq: seq[int]
    starttagposit, endtagposit, indexit: int
    intertagst: string
    datasq: seq[string] = @[]


  log("****************")
  log(tekst)
  log(starttagst & " - " & endtagst)
  startpositsq = getSubstringPositions(tekst, starttagst)
  log("startpositsq = " & $startpositsq)
  endpositsq = getSubstringPositions(tekst, endtagst)
  log("endpositsq = " & $endpositsq)

  if pairChainsAreValid(startpositsq, endpositsq):
    indexit = 0
    for item in startpositsq:
      # build the data-sequence
      starttagposit = startpositsq[indexit]
      endtagposit = endpositsq[indexit]
      intertagst = tekst[starttagposit + len(starttagst) .. endtagposit - 1]
      datasq.add(intertagst)
      indexit += 1

  result = datasq




proc getDataSeqDirty(tekst, starttagst, endtagst:string): seq[string] = 
  #[ 
  If the pair-chains are NOT valid then 
  begin from the starttags and from there see if an endtag can be found
  before the new starttag appears. If yes put the intertag-data in the
  sequence, otherwise move on. (zero-based)
  If there are no pair-occurences, return an empty sequence @[]
  
  Works for mal-formed data but SLOWER than the clean variant.

  Call like: getDataSeqDirty(sometext, "<tr>", "</tr>")
   ]#


  var
    startpositsq: seq[int]
    endtagposit, indexit, startseqlengthit: int
    intertagst: string
    datasq: seq[string] = @[]


  log("****************")
  log(tekst)
  log(starttagst & " - " & endtagst)
  startpositsq = getSubstringPositions(tekst, starttagst)
  log("startpositsq = " & $startpositsq)

  startseqlengthit = startpositsq.len

  indexit = 0

  for starttagposit in startpositsq:
    # search if endtag exists before next starttag
    endtagposit = find(tekst, endtagst, starttagposit + len(starttagst))
    if endtagposit != -1:
      if indexit + 1 < startseqlengthit:
        if endtagposit < startpositsq[indexit + 1]:
          intertagst = tekst[starttagposit + len(starttagst) .. endtagposit - 1]
          datasq.add(intertagst)
      else:   # last one reached; adding without test
        intertagst = tekst[starttagposit + len(starttagst) .. endtagposit - 1]
        datasq.add(intertagst)        
    else:   # without endtag nothing to clip anymore
      break
    indexit += 1
  result = datasq



proc getBaseFromWebAddress2(webaddresst: string, expandparentbo: bool = false): string = 
#[ 
  Non-expanded full base: http://www.x.nl/a/b/c/blah.html  becomes  http://www.x.nl
  Expand to parent: http://www.x.nl/a/b/c/blah.html  becomes  http://www.x.nla/b/c
 ]#

  var 
    addressq: seq[string]
    basewebaddresst, expanded_addresst: string
    tbo: bool = false
    countit: int = 0

  # firstly chop the address up on the slashes
  addressq = webaddresst.split("/")
  # if tbo: echo addressq

  if not expandparentbo:
    # then restore it for the first 3 parts
    for partst in addressq:
      countit += 1
      if countit < 4:
        basewebaddresst &= partst & "/"
    basewebaddresst = basewebaddresst[0 .. len(basewebaddresst) - 2]
    result = basewebaddresst
  elif expandparentbo:
    # then restore it for all but the last part
    addressq.del(len(addressq) - 1)
    for partst in addressq:
      expanded_addresst &= partst & "/"
    expanded_addresst = expanded_addresst[0 .. len(expanded_addresst) - 2]
    result = expanded_addresst

  


proc convertWebLinksToAbsolute(childweblinkst, parentweblinkst: string): string = 
  #[ 
  Convert the relative child-weblink to absolute based on the given
  parent-link and the relativity-type.
   ]#

  var
    firstcharst, base_addresst, expanded_addresst: string

  base_addresst = getBaseFromWebAddress2(parentweblinkst)
  expanded_addresst = getBaseFromWebAddress2(parentweblinkst, true)

  if childweblinkst.len > 1:
    firstcharst = childweblinkst[0..1]

    case firstcharst:
    of "ht":    # allready absolute
      result = childweblinkst
    of "//":    # scheme-relative (current mode of http or https)
      result = replace(childweblinkst, "//", "https://")
    else:
      case firstcharst[0..0]:
      of "/":   # base-relative (abc.com)
        result = base_addresst & childweblinkst
      else:   # parent-relative (abc.com/something)
        result = expanded_addresst & "/" & childweblinkst
  else:
    result = childweblinkst


proc substringsInString(stringst: string, substringsq: seq[string]): bool = 
  # At least one of the substring in substringsq must be present to return true
  # requires strutils / sequtils ??

  var presentbo: bool = false

  for subst in substringsq:  
      if subst in stringst:
        presentbo = true
        break

  result = presentbo


proc linkIsPresent(childlinkst: string, weblinksq: var seq[array[5, string]]): bool = 
  result = false
  for item in weblinksq:
    if childlinkst == item[2]:
      result = true
      break

#[ 
proc getChildLinks_old*(parentweblinkst: string, maxdepthit, curdepthit, linknumit: int, 
                      weblinksq: var seq[array[5, string]]): int = 
  #[ 
  Get all the weblinks of the page parentweblinkst and put them in the var 
  weblinksq of the form @[[parentlink, curdepth, childlink, childtitle]]
  The var weblinksq must be externally created before being called.
  The proc is recurrent and maxdepthit determines the maximal parsing-depth.
  Depth is one-based.
  link1, depth, link2, title2, indexnr
  ADAP HIS:
  ADAP FUT:
  -see below
  ]#

  var 
    sitest = getWebSite(parentweblinkst)
    datasq, frag_onesq, frag_twosq, attribsq: seq[string]
    link_onest, link_twost, templinkst, titlest, parent_titlest: string
    linkcountit, subcountit: int
    not_in_childlinksq: seq[string]


  not_in_childlinksq = getValList(readOptionFromFile("subs-not-in-childlinks", optValueList))
  datasq = getDataSeqClean(sitest, "<a ", "</a>")

  # if the website is mal-formed get the data dirtyly..
  if datasq == @[]:
    echo "Non-xml acquisition.."
    datasq = getDataSeqDirty(sitest, "<a ", "</a>")


 #[ 
  # future-approach? Then can also get weblink directly
  datasq = getDataSequence(sitest, "<a ", "</a>") 
 ]#


  link_onest = parentweblinkst

  if curdepthit <= 1:
    parent_titlest = getTitleFromWebsite2(sitest)
    weblinksq.add(["Parent has no parent", "0", link_onest, parent_titlest, "0"])

  if datasq.len > 0:
    linkcountit = linknumit
    for itemst in datasq:
      # parse the data-sequence for title and link2
      frag_onesq = itemst.split('>', 1)
      titlest = frag_onesq[1]
      frag_twosq = frag_onesq[0].split(' ')
      for attribst in frag_twosq:
        attribsq = attribst.split('=')
        if attribsq[0] == "href":
          templinkst = attribsq[1].strip(chars = {'"'})
          link_twost = convertWebLinksToAbsolute(templinkst, parentweblinkst)

      if not substringsInString(link_twost, not_in_childlinksq):
        if not linkIsPresent(link_twost, weblinksq):
          weblinksq.add([link_onest, $curdepthit, link_twost, titlest, $linkcountit])
          linkcountit += 1
      #echo link_twost

      # call recurrently
      try:
        if curdepthit < maxdepthit:
          linkcountit = getChildLinks_old(link_twost, maxdepthit, curdepthit + 1, linkcountit, weblinksq)

      except:
        let errob = getCurrentException()
        echo "\p******* Unanticipated error ******* \p" 
        echo repr(errob) & "\p****End exception****\p"

  result = linkcountit

 ]#



proc multiplyString(stringst: string, timesit: int): string = 

  # m times 3 becomes mmm  
  var newstringst: string

  for it in 1..timesit:
    newstringst &= stringst

  result = newstringst



proc removeSingleStrings(tekst: string, removablesq: seq[string]): string =

  var 
    vtekst: string
  vtekst = tekst

  for subst in removablesq:
    vtekst = vtekst.replace(subst, "")

  result = vtekst


proc removeDuplicateStrings(tekst: string, removablesq: seq[string]): string =
#[ 
&nbsp;
 ]#

  var
    vtekst, foursubst, threesubst, twosubst, nsubst, msubst: string

  vtekst = tekst

  for subst in removablesq:
    msubst = multiplyString(subst, 20)
    nsubst = multiplyString(subst, 10)
    twosubst = subst & subst
    threesubst = twosubst & subst
    foursubst = threesubst & subst
    vtekst = vtekst.replace(msubst, subst)
    vtekst = vtekst.replace(nsubst, subst)
    vtekst = vtekst.replace(foursubst, subst)
    vtekst = vtekst.replace(threesubst, subst)
    vtekst = vtekst.replace(twosubst, subst)

  result = vtekst




proc getInnerText2*(tekst: string, maxitemcountit: int = -1): string =
  #[ 
  Generic text-extraction of website.
  Based on getDataSeqDirty(tekst, ">", "<")

  ADAP FUT
  -better clean up of page-breaks etc.
   ]#

  var
    datasq: seq[string]
    newtekst, itemst: string
    itemcountit: int = 1

  datasq = getDataSeqDirty(tekst, ">", "<")

  # filter and concatenate elems
  for elem in datasq:
    if not ('{' in elem):   # filter out script
      if itemcountit <= maxitemcountit or maxitemcountit == -1:
        newtekst &= elem
      itemcountit += 1

  newtekst = removeSingleStrings(newtekst, @["&nbsp;", "&nbsp"])
  newtekst = removeDuplicateStrings(newtekst, @[" ", "\n", "\t","\c", "\c\n" ,"\n ", "\t\n", "\t\c", "\t \n"])

  result = newtekst



proc calcWordFrequencies*(input_tekst:string, wordlengthit:int, skiplistsq: seq[string], 
                    useHtmlBreaksbo:bool, topcountit: int = 10000):string = 
  #[ 
  Create a list of word-frequencies in html (useHtmlBreaksbo = true) or normal text.
  Only add words with a length > wordlenghit
  Limit the list-length to topcountit (like top 10)
   ]#

  var
    wordsq, allwordssq: seq[string]
    output_tekst, tempst:string
    indexit: int = 0


  wordsq = input_tekst.split(" ")
  for wordst in wordsq:
    tempst = removeSingleStrings(wordst, @[" ", "\p", "\t", "\c"])
    if len(tempst) >= wordlengthit:
      if not (tempst in skiplistsq):
        allwordssq.add(tempst)


  # echo allwordssq
  # echo "\p"
  var wordcountta = toCountTable(allwordssq)
  wordcountta.sort()
  # echo wordcountta
  # echo "\p"

  for k, v in wordcountta.pairs:
    if indexit < topcountit:
      if useHtmlBreaksbo:
        output_tekst &= k & " - " & $v & "<br>"
      else:
        output_tekst &= k & " - " & $v & "\p"
    else:
      break
    indexit += 1

  result = output_tekst



proc calcCumulFrequencies*(input_tekst:string, wordlengthit:int, skiplistsq: seq[string],
                              globwordsq: var seq[string]) = 

  #[ 
  Possible future addition to add cumulative freqs.
  I may also abort this path and implement the cumulatives thru the planned later 
  database-implementation.
  Only add words with a length > wordlenghit
   ]#

  var
    wordsq: seq[string]
    output_tekst, tempst:string


  wordsq = input_tekst.split(" ")
  for wordst in wordsq:
    tempst = removeSingleStrings(wordst, @[" ", "\p", "\t", "\c"])
    if len(tempst) >= wordlengthit:
      if not (tempst in skiplistsq):
        globwordsq.add(tempst)



proc getDataSequence*(link_or_tekst, starttagst, endtagst:string): seq[string] = 
  #[  
  Get the data-sequence, either cleanly or dirtyly.
  Input either a weblink or the previously retrieved website.
  If no pair-occurence can be found, then return an empty
  sequence: @[]

   ]#

  var 
    datasq: seq[string]
    tekst: string

  if link_or_tekst.len >= 4:
    if link_or_tekst[0..3] == "http":
      tekst = getWebSite(link_or_tekst)
    else:
      tekst = link_or_tekst


  datasq = getDataSeqClean(tekst, starttagst, endtagst)

  # if the website is mal-formed get the data dirtyly..
  if datasq == @[]:
    #echo "Non-xml acquisition.."
    datasq = getDataSeqDirty(tekst, starttagst, endtagst)

  result = datasq



proc getDataBetweenTags2*(link_or_tekst, starttagst, endtagst:string, 
                                      occurit: int): string = 
#[ 
  Get the data between the tag-pair starttag and endtag for 
  the occurit-th occurrence of the pair. (ONE-BASED)
 ]#

  var
    datasq: seq[string]
    lengthit: int

  datasq = getDataSequence(link_or_tekst, starttagst, endtagst)
  lengthit = datasq.len

  if lengthit == 0:
    result = "pair_not_found"
  else:
    if occurit > lengthit:
      result = "occurrence_not_found"
    else:
      result = datasq[occurit - 1]




proc getTitleFromWebsite2*(webaddresst:string): string =

  var resultst: string
  resultst = getDataBetweenTags2(webaddresst, "<title>", "</title>", 1)
  if "not_found" in resultst:
    result = ""
  else:
    result = resultst



proc getChildLinks*(parentweblinkst: string, maxdepthit, curdepthit, linknumit: int, 
            excludesubstringsq:seq[string]= @[], weblinksq: var seq[array[5, string]]): int = 
  #[ 
  Get all the weblinks of the page parentweblinkst and put them in the var 
  weblinksq of the form @[[parentlink, curdepth, childlink, childtitle, indexnr]]
  The var weblinksq must be externally created before being called.
  The proc is recurrent and maxdepthit determines the maximal parsing-depth.
  MaxDepth 0 means only retrieve the parent, Maxdepth 1 means the (first order) children.
  Call with curdepth = 1

  Fields of weblinksq:
  link1, depth, link2, title2, indexnr
  ADAP HIS:
  ADAP FUT:
  -see below
  ]#

  var 
    sitest = getWebSite(parentweblinkst)
    datasq, frag_onesq, frag_twosq, attribsq: seq[string]
    link_onest, link_twost, templinkst, titlest, parent_titlest: string
    linkcountit, subcountit: int


  datasq = getDataSeqClean(sitest, "<a ", "</a>")

  # if the website is mal-formed get the data dirtyly..
  if datasq == @[]:
    #echo "Non-xml acquisition.."
    datasq = getDataSeqDirty(sitest, "<a ", "</a>")

  echo linknumit

 #[ 
  # future-approach? Then can also get weblink directly
  datasq = getDataSequence(sitest, "<a ", "</a>") 
 ]#

  linkcountit = 0
  link_onest = parentweblinkst

  if curdepthit <= 1:
    parent_titlest = getTitleFromWebsite2(sitest)
    weblinksq.add(["Parent has no parent", "0", link_onest, parent_titlest, "0"])

  if datasq.len > 0 and maxdepthit > 0:
    linkcountit = linknumit
    for itemst in datasq:
      # parse the data-sequence for title and link2
      frag_onesq = itemst.split('>', 1)
      titlest = frag_onesq[1]
      frag_twosq = frag_onesq[0].split(' ')
      for attribst in frag_twosq:
        attribsq = attribst.split('=')
        if attribsq[0] == "href":
          templinkst = attribsq[1].strip(chars = {'"'})
          link_twost = convertWebLinksToAbsolute(templinkst, parentweblinkst)

      if not substringsInString(link_twost, excludesubstringsq):
        if not linkIsPresent(link_twost, weblinksq):
          weblinksq.add([link_onest, $curdepthit, link_twost, titlest, $linkcountit])
          linkcountit += 1
      #echo link_twost

      # call recurrently
      try:
        if curdepthit < maxdepthit:
          linkcountit = getChildLinks(link_twost, maxdepthit, curdepthit + 1, linkcountit, 
                                          excludesubstringsq, weblinksq)

      except:
        let errob = getCurrentException()
        echo "\p******* Unanticipated error ******* \p" 
        echo repr(errob) & "\p****End exception****\p"

  result = linkcountit



proc countWords*(tekst: string): int =
  var wordsq: seq[string]
  wordsq = tekst.splitWhitespace()
  result = wordsq.len



proc getTagContent*(link_or_tekst, startpartst, endpartst: string): seq[string] = 
  #[ 
    Retrieve a sequence of content-data between pairs of startpartst 
    and endpartst. 
   ]#

  var
    datasq, frag_onesq, listsq: seq[string]
    tempst, contentst: string
  datasq = getDataSequence(link_or_tekst, startpartst, endpartst)

  listsq = @[]
  if datasq.len > 0:
    for itemst in datasq:
      #echo itemst
      #echo "------------"
      # parse the data-sequence for the content between > and <
      if '>' in itemst:
        frag_onesq = itemst.split('>', 1)
        tempst = frag_onesq[1]
      else:
        tempst = itemst

      if ('>' in tempst) and ('<' in tempst):
        contentst = getInnerText2(tempst)
      else: 
        contentst = tempst

      if contentst.len > 0:
        listsq.add(contentst)
    #echo "========="
  result = listsq



proc enlistSequenceToDoc*(sequensq: seq[string], output_doc: DocType, 
                          maxlineit: int): string = 
  # Create a listing-doc from a sequence of string in the desired format DocType
  # with maximum line-size maxlineit.

  var
    itemcountit: int = 1
    list: string = ""

  for itemst in sequensq:
    if itemcountit <= maxlineit:
      if output_doc == docHtml:
        list &= "- " & itemst & "<br>\p"
      elif output_doc == docText:
        list &= itemst & "\p"
      itemcountit += 1

  result = list




proc getHtmlHeaders*(link_or_tekst: string, output_doc: DocType, 
                  maxlineit: int): string = 

  var
    datasq, frag_onesq: seq[string]
    tempst, contentst, depthst, list, first: string
    it, itemcountit: int

  datasq = getDataSequence(link_or_tekst, "<h", "</h")
  if datasq.len > 0:
    itemcountit = 1
    for itemst in datasq:

      if itemst.len > 0:
        first = itemst[0..0]
        for it in 1..6:
          if first == $it:
            #echo "*********"
            #echo itemst
            #echo "------------"

            # parse the data-sequence for the content between > and <
            if '>' in itemst:
              frag_onesq = itemst.split('>', 1)
              tempst = frag_onesq[1]
            else:
              tempst = itemst

            if ('>' in tempst) and ('<' in tempst):
              contentst = getInnerText2(tempst, 1)
            else: 
              contentst = tempst

            if itemcountit <= maxlineit:
              if contentst.len > 0:

                if output_doc == docHtml:
                  list &= multiplyString("&nbsp", 3*(it - 1)) & contentst & "<br>\p"
                elif output_doc == docText:
                  list &= multiplyString(" ", 3*(it - 1)) & contentst & "\p"                

            itemcountit += 1

  result = list




when isMainModule:
#[ 
  # TEST: getDataSeqClean
  var 
    mydatasq: seq[string]
    sitest = getWebSite("https://en.wikipedia.org/wiki/Well-formed_element")
  mydatasq =  getDataSeqClean(sitest, "<a ", "</a>")
  for item in mydatasq:
    echo item
  echo "-------------"
  echo mydatasq.len
 ]#

#[ 
  # TEST: getDataSeqDirty

  var 
    mydatasq: seq[string]
    sitest = getWebSite("https://en.wikipedia.org/wiki/Well-formed_element")
  mydatasq =  getDataSeqDirty(sitest, ">", "<")
  for item in mydatasq:
    echo "-", item,"-"
  echo "-------------"
  echo mydatasq.len
 ]#

  #[
  # TEST: getChildLinks
  var datasq: seq[array[5, string]] = @[]
  #getChildLinks("https://www.bibliotecapleyades.net/esp_lemuria.htm", 1, 1, datasq)
  echo getChildLinks("https://en.wikipedia.org/wiki/Well-formed_element", 1, 1, 1, datasq)
  echo "----------------------------"
  for item in datasq:
    echo item
  ]#

#[ 
 echo getBaseFromWebAddress2("http://www.x.nl/a/b/c/blah.html", true)
 ]#


#[ ]# 
  # TEST: getInnerText2 or calcWordFrequencies or countWords
  var 
    sitest = getWebSite("https://www.bibliotecapleyades.net/sumer_anunnaki/esp_sumer_annunaki11.htm")
    #sitest = getWebSite("https://www.bibliotecapleyades.net/atlantida_mu/esp_lemuria_11.htm")
    #sitest = getWebSite("https://www.nrc.nl/nieuws/2022/12/26/oostenrijk-het-russische-vliegdekschip-in-europa-a4152600")

  echo "-------------"
  #sitest = "bla>eerste<blubla>tweede<prrrrr>derde<hophop"
  #echo getInnerText2(sitest, 1)
  echo calcWordFrequencies(getInnerText2(sitest), 7, @["pietje", "jantje"], false, 20)
  #echo countWords(getInnerText2(sitest))
  
#[ 
calcWordFrequencies*(input_tekst:string, wordlengthit:int, skiplistsq: seq[string], 
                    useHtmlBreaksbo:bool, topcountit: int = 10000)
 ]#

 #echo multiplyString("m", 3)

#[ 
  # TEST: removeDuplicateStrings
  var st = "a     b\n \n\nxx \n   y   \tz"
  echo st 
  echo removeDuplicateStrings(st, @["\n ", " ", "\p", "\t"])
 ]#

 #echo getWebSite("www.voetbal.com/")

  #echo getTitleFromWebsite2("https://nl.wikipedia.org/wiki/Nim_(spel)")

  #echo getHtmlHeaders("https://en.wikipedia.org/wiki/Well-formed_element")
  #echo getHtmlHeaders("https://nl.wikipedia.org/wiki/1961", docText, 1000)

