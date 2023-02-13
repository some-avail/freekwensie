

#[ Sample-project "controls" to learn how to use jester, moustachu and
g_html_json (html-elements generated from a json-definition-file).

Beware of the fact  that there are two kinds of variables:
-moustachu-variables in the html-code, in which the generated html-controls are 
substituted. Designated with {{}} or {{{}}}. Sometimes two braces are enough,
but it is saver to use three to avoid premature evaluation.
-control-variables used by jester. Jester reads control-states and puts them 
in either of two variables (i dont know if they are fully equivalent):
* variables like @"controlname"
* request.params["controlname"]

Do not use global vars  or otherwise you can not compile for multi-threading
with switch --threads:on
The trick is to put your globals in a proc thence they are no globals 
anymore. But you cannot store a global in a proc so retrieve them from a 
file. When you only read from the files no-problemo but if you write you 
might get problems because of the shared data corruption; that is different 
threads writing and expecting different data.
See also the module freek_loadjson.nim
Currently --threads :on does NOT compile (by design) for the app is 
at this moment meant as a single-user-app. Their is howuever full data-
separation between users and tabs.



ADAP HIS
-change static_config and calls

ADAP NOW

]#


import jester, moustachu, times, json, os, tables, db_sqlite
import strutils
import nimclipboard/libclipboard
import freek_loadjson, freek_logic
import g_database, g_templates,  g_db2json, g_json_plus
import g_mine, g_options, g_cookie, g_tools
from g_html_json import nil




const 
  versionfl:float = 0.75
  project_prefikst* = "freek"
  appnamebriefst = "FK"
  appnamenormalst = "Freekwensie"
  appnamelongst = "Website-profiler"
  appnamesuffikst = " using word-frequencies"
  # Make sure to get/show all elements that you are referring to, 
  # or crashes may occur
  showelems = g_html_json.showEntryFilterRadio

  #firstelems_pathst = @["all web-pages", "first web-page", "web-elements fp"]

#[ 
  Below solution:
  - is temporary
  - is multi-user-enabled
  - but provides no garbage-collection
 ]#

var
  datasqta = initTable[string, seq[array[5, string]]]()
  globwordsqta = initTable[string, seq[string]]()
  portnumberit: int = parseInt(readOptionFromFile("port-number", optValue))


settings:
  port = Port(portnumberit)



proc showPage(par_innervarob, par_outervarob: var Context, 
            sequencest: string = "", custominnerhtmlst:string=""): string = 

  var innerhtmlst:string
  if custominnerhtmlst == "":
    innerhtmlst = render(readFile(project_prefikst & "_inner" & sequencest & ".html") , par_innervarob)    
  else:
    innerhtmlst = custominnerhtmlst
  par_outervarob["controls-group"] = innerhtmlst

  return render(readFile(project_prefikst & "_outer.html"), par_outervarob)



  # sleep 1000
  # echo "hai"
  # echo $now()



routes:

  get "/":
    resp "Type: localhost:" & $portnumberit & "/" & project_prefikst

  get "/freek":

  # hard code because following does not work:
  # get ("/" & project_prefikst):

    var
      statustekst:string
      innervarob: Context = newContext()  # inner html insertions
      outervarob: Context = newContext()   # outer html insertions

    var initialjnob = freek_loadjson.readInitialNode(project_prefikst)
    outervarob["sequence_nr"] = ""

    innervarob["statustext"] = """OK"""
    innervarob["newtab"] = "_self"
    outervarob["version"] = $versionfl
    outervarob["loadtime"] ="Page-load: " & $now()
    outervarob["namenormal"] = appnamenormalst
    outervarob["namelong"] = appnamelongst
    outervarob["namesuffix"] = appnamesuffikst
    outervarob["pagetitle"] = appnamenormalst & " _ " & appnamelongst & appnamesuffikst   
    outervarob["project_prefix"] = project_prefikst

    innervarob["project_prefix"] = project_prefikst  

    innervarob["sel_depth"] = g_html_json.setDropDown(initialjnob, "sel_parsing_depth", "1", 1)
    innervarob["sel_number_results"] = g_html_json.setDropDown(initialjnob, "sel_number_results", 
                                                                  "10", 1)

    innervarob["check_show"] = g_html_json.setCheckBoxSet(initialjnob, "check_show_pre-results", 
                                                    @["default"])
    innervarob["set_nr"] = "1"

    innervarob["pasted_text"] = readOptionFromFile("pastebox-default", optValue)
    innervarob["check_globfreqlist"] = g_html_json.setCheckBoxSet(initialjnob, "check_globfreqlist", 
                                                        @["default"], true)

    innervarob["sel_noise_words"] = g_html_json.setDropDown(initialjnob, "sel_noise_words", 
                                              "noise_words_english_generic.dat", 5)

    resp showPage(innervarob, outervarob)



  post "/freek":

    var
      statustekst, righttekst, tempst:string
      innervarob: Context = newContext()  # inner html insertions
      outervarob: Context = newContext()   # outer html insertions
      cookievaluest, locationst, mousvarnamest: string
      funcpartsta =  initOrderedTable[string, string]()
      firstelems_pathsq: seq[string] = @["all web-pages", "first web-page", "web-elements fp", "your-element"]
      gui_jnob: JsonNode
      clipob = clipboard_new(nil)
      tabidst, resultst, freqlist, sitest, parent_titlest, child_titlest, innertekst, reversest: string
      extra_list, button_nekst, button_prevst, nav_noticest: string
      linkcountit, setsizeit, setcountit, itemstartit, itemendit, getchildscountit: int
      excludesubsq, includesubsq: seq[string]
      weblinkst, globfreqtablest: string
      seqcountit: int
      calcglobalfreqsbo: bool = false
      # skip-list created from file:
      skiplisq: seq[string] = convertFileToSequence(@"sel_noise_words", ">>>")
      # options:
      fqwordlenghit = parseInt(readOptionFromFile("freq-word-length", optValue))
      fqlistlengthit = parseInt(readOptionFromFile("freq-list-length", optValue))
      maxcontentitemsit =  parseInt(readOptionFromFile("max-content-items", optValue))
      maxheaderitemsit =  parseInt(readOptionFromFile("max-header-items", optValue))
      introtextsizit = parseInt(readOptionFromFile("intro-text-char-number", optValue))
      targetwindowst = readOptionFromFile("target-window", optValue)


    # first version of html, css-sheet, script and json-file
    outervarob["sequence_nr"] = ""


    when persisttype == persistNot:
      gui_jnob = readInitialNode(project_prefikst, "")
    else:
      when persisttype == persistOnDisk: 
        if theTimeIsRight():
          deleteExpiredFromAccessBook()
      if len(@"tab_ID") == 0:
        tabidst = genTabId()
      else:
        tabidst = @"tab_ID"

      gui_jnob = readStoredNode(tabidst, project_prefikst, "")
      innervarob["tab_id"] = tabidst


    innervarob["newtab"] = "_self"
    outervarob["version"] = $versionfl
    outervarob["loadtime"] ="Page-load: " & $now()
    outervarob["namenormal"] = appnamenormalst
    outervarob["namelong"] = appnamelongst
    outervarob["namesuffix"] = appnamesuffikst
    outervarob["pagetitle"] = appnamelongst & appnamesuffikst
    outervarob["project_prefix"] = project_prefikst

    innervarob["project_prefix"] = project_prefikst  

    # ==========non-standard code starting here===========

    innervarob["sel_depth"] = g_html_json.setDropDown(gui_jnob, "sel_parsing_depth", 
                                                        @"sel_parsing_depth", 1)

    innervarob["sel_number_results"] = g_html_json.setDropDown(gui_jnob, "sel_number_results", 
                                                        @"sel_number_results", 1)

    innervarob["check_show"] = g_html_json.setCheckBoxSet(gui_jnob, "check_show_pre-results", 
                                                    @[@"chkshow_preresults"])

    innervarob["pasted_text"] = @"pasted_link"
    innervarob["statustext"] = "..."
    innervarob["set_nr"] = @"set_nr"
    innervarob["startpart"] = @"custom_start"
    innervarob["endpart"] = @"custom_end"
    innervarob["seekbox"] = @"seekbox"
    innervarob["check_globfreqlist"] = g_html_json.setCheckBoxSet(gui_jnob, "check_globfreqlist", 
                                                    @[@"chkCalcGlobFreqs"], true)


    innervarob["sel_noise_words"] = g_html_json.setDropDown(gui_jnob, "sel_noise_words", 
                                                              @"sel_noise_words", 5)

    innervarob["include_in_lnx"] = @"includable"
    innervarob["exclude_from_lnx"] = @"excludable"

#[ 
    if @"curaction" in ["pasting..", "changing link..", "entering terms.."]:
      # (re)set the dataseq which will hold the mined weblinks for the specific tabID
      if datasqta.hasKey(tabidst):
        datasqta[tabidst] = @[]
      else:
        datasqta.add(tabidst, @[])

      # reset the global word-store (to create later global word-freqs)
      if globwordsqta.hasKey(tabidst):
        globwordsqta[tabidst] = @[]
      else:
        globwordsqta.add(tabidst, @[])
 ]#

    if @"curaction" == "pasting..":
      outervarob["pagetitle"] = appnamelongst & appnamesuffikst    
      innervarob["pasted_text"] = $clipob.clipboard_text()
      innervarob["statustext"] = "Pasting ready."

#[ 
    if @"curaction" == "changing link..":
      innervarob["statustext"] = "Link changed and updated."

    if @"curaction" == "entering terms..":
      innervarob["statustext"] = "Search terms entered."
 ]#


    if @"curaction" == "retrieving..":
      # (re)set the dataseq which will hold the mined weblinks for the specific tabID
      if datasqta.hasKey(tabidst):
        datasqta[tabidst] = @[]
      else:
        datasqta.add(tabidst, @[])

      # reset the global word-store (to create later global word-freqs)
      if globwordsqta.hasKey(tabidst):
        globwordsqta[tabidst] = @[]
      else:
        globwordsqta.add(tabidst, @[])

      weblinkst = @"pasted_link" & createSearchString(@"seekbox")
      sitest = getWebSite(weblinkst)
      parent_titlest = getTitleFromWebsite2(weblinkst)
      outervarob["pagetitle"] = appnamebriefst & "_LNX_" & parent_titlest & "  -- " & appnamenormalst
      includesubsq = split(@"includable", ",,")
      excludesubsq = split(@"excludable", ",,") & getValList(readOptionFromFile("subs-not-in-childlinks", optValueList))
      if sitest != "":
        getchildscountit = getChildLinks(weblinkst, parseint(@"sel_parsing_depth"), 1, 1, 
                                          includesubsq, excludesubsq ,datasqta[tabidst])
        if @"chkshow_preresults" == "chkshow_preresults":
          resultst = "<table id=\"weblinks_table\">\p"
          for item in datasqta[tabidst]:
            resultst &= "<tr>\p"
            reversest = ""
            seqcountit = 0
            for datum in item:
              if seqcountit == 2:
                reversest = "<td><a href=\"" & datum & "\" target=\"" & targetwindowst & "\">" & datum & "</a></td>\p" & reversest
              else:
                reversest = "<td>" & datum & "</td>\p" & reversest
              seqcountit += 1
            resultst &= reversest
            resultst &= "</tr>\p"

          resultst &= "</table>\p"
          innervarob["results_list"] = resultst

        innervarob["statustext"] = $len(datasqta[tabidst]) & " weblinks retrieved.."
      else:
        innervarob["statustext"] = "Could not acquire website.."



    if @"curaction" == "profiling..":
      if @"chkCalcGlobFreqs" == "chkCalcGlobFreqs": calcglobalfreqsbo = true
      button_nekst = "<button name=\"butNext\" class=\"allbuttons but_prev_next\" type=\"button\" onclick=\"getNextSet()\">Next set</button>"
      button_prevst = "<button name=\"butPrev\" class=\"allbuttons but_prev_next\" type=\"button\" onclick=\"getPrevSet()\">Previous set</button>"
      weblinkst = @"pasted_link" & createSearchString(@"seekbox")      
      parent_titlest = getTitleFromWebsite2(weblinkst)
      outervarob["pagetitle"] = appnamebriefst & "_" & parent_titlest & "  -- " & appnamenormalst
      linkcountit = 1
      setsizeit = parseint(@"sel_number_results")
      setcountit = parseint(@"set_nr") - 1
      itemstartit = (setcountit * setsizeit) + 1
      itemendit  = (setcountit + 1) * setsizeit
      nav_noticest = "<center>" & button_prevst & "Results from " & $itemstartit & " thru " & $itemendit & button_nekst & "</center><br><br>\p"

      for item in datasqta[tabidst]:
        if linkcountit >= itemstartit and linkcountit <= itemendit:        
          sitest = getWebSite(item[2])
          innertekst = getInnerText2(sitest)
          child_titlest = getTitleFromWebsite2(item[2])
          if sitest != "":
            echo "Retrieving nr... " & $item[4]
            freqlist = calcWordFrequencies(innertekst, fqwordlenghit, skiplisq, true, fqlistlengthit)
            if calcglobalfreqsbo: calcCumulFrequencies(innertekst, fqwordlenghit, skiplisq, globwordsqta[tabidst])
            resultst &= "<table>\p"
            resultst &= "<tr>\p"
            resultst &= "<td id=\"first_row_prof_table\" colspan=\"2\">" & child_titlest & "<br>" & item[3] & "</td>\p"
            resultst &= "<td id=\"freq_col_prof_table\" rowspan=\"5\">" & freqlist & "</td>\p"
            if @"custom_start" != "" and @"custom_end" != "":
              extra_list = getContentList(sitest, @"custom_start", @"custom_end", docHtml, maxcontentitemsit)
            else:
              extra_list = getHtmlHeaders(sitest, docHtml, maxheaderitemsit)

            if extra_list.len > 0:
              resultst &= "<td id=\"extra_col_prof_table\" rowspan=\"5\">" & extra_list & "</td>\p"                

            resultst &= "<tr>\p"
            resultst &= "<td colspan=\"2\"><a href=\"" & item[2] & "\" target=\"" & targetwindowst & "\">" & item[2] & "</a></td>\p"
            resultst &= "</tr>\p"

            resultst &= "<tr>\p"
            resultst &= "<td colspan=\"2\">" & getIntroText(innertekst, introtextsizit) & "</td>\p"
            resultst &= "</tr>\p"

            resultst &= "<tr>\p"
            resultst &= "<td>Depth = " & item[1] & 
                        "<br>Word-count = " & $countWords(innertekst) & "</td>\p"
            resultst &= "<td>Link-count = " & $count(sitest, "<a ") & 
                          "<br>Image-count = " & $count(sitest, "<img ") & "</td>\p"
            resultst &= "</tr>\p"

            resultst &= "<tr>\p"
            resultst &= "<td>" & item[4] & "</td>\p"
            resultst &= "<td>" & item[0] & "</td>\p"
            resultst &= "</tr>\p"

            resultst &= "</table><br><br>\p"

        linkcountit += 1


      if calcglobalfreqsbo:
        globfreqtablest = createFreqTableFromWordList(globwordsqta[tabidst], 6, 20)
        resultst = nav_noticest & globfreqtablest & resultst & nav_noticest
      else:
        resultst = nav_noticest & resultst & nav_noticest

      innervarob["results_list"] = resultst
      innervarob["statustext"] = "Results " & $itemstartit & " thru " & $itemendit & 
                          " shown of " & $len(datasqta[tabidst]) & " retrieved weblinks.."


    # =================ns code ending here =====================

    # A server-function may have been called from client-side (browser-javascript) by
    # preparing a cookie for the server (that is here) to pick up and execute.
    # (what i call a cookie-tunnel)
    if request.cookies.haskey(project_prefikst & "_run_function"):
      cookievaluest = request.cookies[project_prefikst & "_run_function"]
      if cookievaluest != "DISABLED":
        funcpartsta = getFuncParts(cookievaluest) 
        locationst = funcpartsta["location"]  # innerhtml-page or outerhtml-page
        mousvarnamest = funcpartsta["mousvarname"]

        if locationst == "inner":
          innervarob[mousvarnamest] = runFunctionFromClient(funcpartsta, gui_jnob)
        elif locationst == "outer":
          outervarob[mousvarnamest] = runFunctionFromClient(funcpartsta, gui_jnob)

    when persisttype != persistNot:
      writeStoredNode(tabidst, gui_jnob)

    resp showPage(innervarob, outervarob, "")



  get "/noisework":
    var
      statustekst:string
      innervarob: Context = newContext()  # inner html insertions
      outervarob: Context = newContext()   # outer html insertions

    var initialjnob = freek_loadjson.readInitialNode(project_prefikst, "03")
    outervarob["sequence_nr"] = "03"

    innervarob["statustext"] = """OK"""
    innervarob["newtab"] = "_self"
    outervarob["version"] = $versionfl
    outervarob["loadtime"] ="Page-load: " & $now()
    outervarob["namenormal"] = appnamenormalst
    outervarob["namelong"] = appnamelongst
    outervarob["namesuffix"] = appnamesuffikst
    outervarob["pagetitle"] = appnamenormalst & " _ " & appnamelongst & appnamesuffikst   
    outervarob["project_prefix"] = project_prefikst

    innervarob["project_prefix"] = project_prefikst  

    innervarob["sel_noise_sources"] = g_html_json.setDropDown(initialjnob, "sel_noise_sources", 
                                              "", 5)

    innervarob["sel_noise_words"] = g_html_json.setDropDown(initialjnob, "sel_noise_words", 
                                              "", 5)

    innervarob["info_update"] = """Pre-warning: generation will overwrite current words-file; 
          copy it to keep it. <br><br>A noise-words-file is needed to exclude all noise-words like 
          'the' or 'have' from the frequency-list. It is generated from the noise-sources-file 
          with the same suffix. Create a noise-sources-file, refresh, set the parameters, run pre-calc and 
          when OK run Generate. Refresh page to reload the file-listings. See wiki for further 
          information."""

    innervarob["fraction"] = "0.5"
    innervarob["max_links"] = "10"


    resp showPage(innervarob, outervarob, "03")



  post "/noisework":
    var
      statustekst:string
      innervarob: Context = newContext()  # inner html insertions
      outervarob: Context = newContext()   # outer html insertions

      cookievaluest, locationst, mousvarnamest: string
      funcpartsta =  initOrderedTable[string, string]()
      firstelems_pathsq: seq[string] = @["all web-pages", "first web-page", "web-elements fp", "your-element"]
      gui_jnob: JsonNode
      clipob = clipboard_new(nil)
      tabidst, infost: string



    when persisttype == persistNot:
      gui_jnob = readInitialNode(project_prefikst, "03")
    else:
      when persisttype == persistOnDisk: 
        if theTimeIsRight():
          deleteExpiredFromAccessBook()
      if len(@"tab_ID") == 0:
        tabidst = genTabId()
      else:
        tabidst = @"tab_ID"

      gui_jnob = readStoredNode(tabidst, project_prefikst, "03")
      innervarob["tab_id"] = tabidst


    outervarob["sequence_nr"] = "03"

    innervarob["newtab"] = "_self"
    outervarob["version"] = $versionfl
    outervarob["loadtime"] ="Page-load: " & $now()
    outervarob["namenormal"] = appnamenormalst
    outervarob["namelong"] = appnamelongst
    outervarob["namesuffix"] = appnamesuffikst
    outervarob["pagetitle"] = appnamelongst & appnamesuffikst
    outervarob["project_prefix"] = project_prefikst

    innervarob["project_prefix"] = project_prefikst  

    # ==========non-standard code starting here===========
    innervarob["sel_noise_sources"] = g_html_json.setDropDown(gui_jnob, "sel_noise_sources", 
                                                              @"sel_noise_sources", 5)

    innervarob["sel_noise_words"] = g_html_json.setDropDown(gui_jnob, "sel_noise_words", 
                                                              @"sel_noise_words", 5)

    innervarob["fraction"] = @"fraction"
    innervarob["max_links"] = @"max_links"

    if @"curaction" == "calculating..":
      infost = noiseVarMessages(@"sel_noise_sources", @"fraction", @"max_links")
      if infost == "":
        infost = createNoiseWordsList(@"sel_noise_sources", parseFloat(@"fraction"), parseInt(@"max_links"), true)

      innervarob["info_update"] = infost


    if @"curaction" == "generating..":
      infost = noiseVarMessages(@"sel_noise_sources", @"fraction", @"max_links")
      if infost == "":
        infost = createNoiseWordsList(@"sel_noise_sources", parseFloat(@"fraction"), parseInt(@"max_links"), false)

      innervarob["info_update"] = infost


    # ==========non-standard code ending here===========
  
    # A server-function may have been called from client-side (browser-javascript) by
    # preparing a cookie for the server (that is here) to pick up and execute.
    # (what i call a cookie-tunnel)
    if request.cookies.haskey(project_prefikst & "_run_function"):
      cookievaluest = request.cookies[project_prefikst & "_run_function"]
      if cookievaluest != "DISABLED":
        funcpartsta = getFuncParts(cookievaluest) 
        locationst = funcpartsta["location"]  # innerhtml-page or outerhtml-page
        mousvarnamest = funcpartsta["mousvarname"]

        if locationst == "inner":
          innervarob[mousvarnamest] = runFunctionFromClient(funcpartsta, gui_jnob)
        elif locationst == "outer":
          outervarob[mousvarnamest] = runFunctionFromClient(funcpartsta, gui_jnob)

    when persisttype != persistNot:
      writeStoredNode(tabidst, gui_jnob)

    resp showPage(innervarob, outervarob, "03")


  get "/datawork":

  # hard code because following does not work:
  # get ("/" & project_prefikst):

    var
      statustekst:string
      innervarob: Context = newContext()  # inner html insertions
      outervarob: Context = newContext()   # outer html insertions


    # datawork is defined as second version of innerhtml, css-sheet, script and json-file
    var initialjnob = freek_loadjson.readInitialNode(project_prefikst, "02")
    outervarob["sequence_nr"] = "02"


    innervarob["statustext"] = """OK"""

    innervarob["newtab"] = "_self"
    outervarob["version"] = $versionfl
    outervarob["loadtime"] ="Page-load: " & $now()
    outervarob["namenormal"] = appnamenormalst
    outervarob["namelong"] = appnamelongst
    outervarob["namesuffix"] = appnamesuffikst
    outervarob["pagetitle"] = appnamelongst & appnamesuffikst   
    outervarob["project_prefix"] = project_prefikst

    innervarob["project_prefix"] = project_prefikst  
    #innervarob["dropdown1"] = g_html_json.setDropDown(initialjnob, "dropdownname_01", "", 1)
    innervarob["dropdown1"] = g_html_json.setDropDown(initialjnob, "All_tables", "", 1)

    innervarob["table01"] = g_html_json.setTableBasic(initialjnob, "table_01")

    resp showPage(innervarob, outervarob, "02")



  post "/datawork":

    var
      statustekst, righttekst, tempst:string
      innervarob: Context = newContext()  # inner html insertions
      outervarob: Context = newContext()   # outer html insertions
      cookievaluest, locationst, mousvarnamest: string
      funcpartsta =  initOrderedTable[string, string]()
      firstelems_pathsq: seq[string] = @["all web-pages", "first web-page", "web-elements fp", "your-element"]
      gui_jnob: JsonNode
      recordsq: seq[Row] = @[]
      id_fieldst, fieldnamest, id_valuest, id_typest, tabidst, filternamest, filtervaluest: string
      colcountit, countit, addcountit: int
      fieldtypesq, fieldvaluesq, filtersq: seq[array[2, string]] = @[]
      filtervaluesq: seq[string] = @[]
      tablechangedbo: bool = false


    # second version of html, css-sheet, script and json-file
    outervarob["sequence_nr"] = "02"

    when persisttype == persistNot:
      gui_jnob = readInitialNode(project_prefikst, "02")
    else:
      when persisttype == persistOnDisk: 
        if theTimeIsRight():
          deleteExpiredFromAccessBook()
      if len(@"tab_ID") == 0:
        tabidst = genTabId()
      else:
        tabidst = @"tab_ID"

      gui_jnob = readStoredNode(tabidst, project_prefikst, "02")
      innervarob["tab_id"] = tabidst



    innervarob["newtab"] = "_self"
    outervarob["version"] = $versionfl
    outervarob["loadtime"] ="Page-load: " & $now()

    outervarob["namenormal"] = appnamenormalst
    outervarob["namelong"] = appnamelongst
    outervarob["namesuffix"] = appnamesuffikst
    outervarob["pagetitle"] = appnamelongst & appnamesuffikst   
    outervarob["project_prefix"] = project_prefikst     


    innervarob["project_prefix"] = project_prefikst  
    innervarob["linkcolor"] = "red"

    #echo gui_jnob
    innervarob["dropdown1"] = g_html_json.setDropDown(gui_jnob, "All_tables", 
                                                          @"All_tables", 1)

    #righttekst = "The value of dropdownname_01 = " & @"dropdownname_01"
    #innervarob["righttext"] = righttekst

    firstelems_pathsq = replaceLastItemOfSeq(firstelems_pathsq, "basic tables fp")

    #delete old table-data from jsonnode
    when persisttype != persistNot:
      pruneJnodesFromTree(gui_jnob, firstelems_pathsq, getAllUserTables())


    #echo @"All_tables"
    fieldtypesq = getFieldAndTypeList(@"All_tables")
    id_fieldst = fieldtypesq[0][0]
    id_typest = fieldtypesq[0][1]
    fieldvaluesq = fieldtypesq
    #echo id_fieldst



    if @"curaction" == "new table..":
      innervarob["statustext"] = readFromParams("sqlite_master", @["sql"], compString, 
                                          @[["name", @"All_tables"]])[0][0]
      tablechangedbo = true

    #echo "~~~~~~~~~~~~~~~"
    addcountit = 0
    # Collect filter-values
    # Sample the var fieldtypesq to create filtersq for the filter-values
    # to (re)query thru createHtmlTableNodeFromDB
    if not tablechangedbo:   # only in the second pass when stuff has been created
      colcountit = getColumnCount(@"All_tables")
      #echo "colcountit: ", colcountit
      for countit in 1..colcountit:
        filternamest = "filter_" & $countit
        if request.params.haskey(filternamest):     # needy for colcount-changes with new table-load
          filtervaluest = request.params[filternamest]

          if filtervaluest.len > 0:
            filtersq.add(["",""])
            filtersq[addcountit][0] = fieldtypesq[countit - 1][0]
            filtersq[addcountit][1] = filtervaluest
            addcountit += 1

            #echo filtersq
            #echo filternamest
            #echo filtervaluesq
            #echo "countit: ", countit
            #echo "addcountit: ", addcountit
            #echo "============"

          # also needy for setTable to restore the filter-values
          filtervaluesq.add(filtervaluest)


    if @"curaction" in ["saving..", "deleting.."]:
      # Reuse the var fieldvaluesq and overwrite the second field 'type' for the data-values
      colcountit = getColumnCount(@"All_tables")
      for countit in 1..colcountit:
        fieldnamest = "field_" & $countit
        if request.params.haskey(fieldnamest):
          #echo request.params[fieldnamest]
          #echo @fieldnamest

          if countit == 1:
            id_valuest = request.params[fieldnamest]

          # Reuse the var and overwrite the second field 'type' for the values
          fieldvaluesq[countit - 1][1] = request.params[fieldnamest]



    # table loading starts here
    if not tablechangedbo:
      graftJObjectToTree(@"All_tables", firstelems_pathsq, gui_jnob, 
                createHtmlTableNodeFromDB(@"All_tables", compSub, filtersq))
    else:
      graftJObjectToTree(@"All_tables", firstelems_pathsq, gui_jnob, 
                          createHtmlTableNodeFromDB(@"All_tables"))



    #echo @"radiorecord"
    if @"radiorecord" == "":
      if not tablechangedbo:
        innervarob["table01"] = g_html_json.setTableDbOpt(gui_jnob, @"All_tables", 
                                                         showelems, filtersq = filtervaluesq)
      else:
        innervarob["table01"] = g_html_json.setTableDbOpt(gui_jnob, @"All_tables", showelems)
    else:
      if not tablechangedbo:
        recordsq = readFromParams(@"All_tables", @[], compString, @[[id_fieldst, @"radiorecord"]])
        #echo recordsq
        if len(recordsq) > 0:
          if len(recordsq[0]) > 0:    # the record exist?
            innervarob["table01"] = g_html_json.setTableDbOpt(gui_jnob, @"All_tables", showelems,
                                    @"radiorecord" , recordsq[0], filtervaluesq)
        else:
          innervarob["table01"] = g_html_json.setTableDbOpt(gui_jnob, @"All_tables", showelems, 
                                                              filtersq = filtervaluesq)
      else:
        innervarob["table01"] = g_html_json.setTableDbOpt(gui_jnob, @"All_tables", showelems)





    if @"curaction" == "saving..":

      try:
        if len(id_valuest) == 0:    # empty-idfield 
          # must become new record if db-generated
          if getKeyFieldStatus(@"All_tables") == genIntegerByDb:
            #remove the id-field:
            fieldvaluesq.delete(0)
            addNewFromParams(@"All_tables", fieldvaluesq)
          else:
            innervarob["statustext"] = """Cannot save the record because 
              the ID-field has been left empty and the ID-value is not 
              automatically generated for this table."""

        else:   # filled id-field
          if idValueExists(@"All_tables", id_fieldst, id_valuest):
            # record exists allready; perform an update of the values only.
            fieldvaluesq.delete(0)
            updateFromParams(@"All_tables", fieldvaluesq, compString, @[[id_fieldst, id_valuest]])
          else:     # a new record will be entered with the given id-value
            # id-data must be kept in var fieldvaluesq

            addNewFromParams(@"All_tables", fieldvaluesq)


        # requery including the new record
        graftJObjectToTree(@"All_tables", firstelems_pathsq, gui_jnob, 
                             createHtmlTableNodeFromDB(@"All_tables", compSub, filtersq))

        innervarob["table01"] = g_html_json.setTableDbOpt(gui_jnob, @"All_tables", showelems, 
                                                          filtersq = filtervaluesq)


      except DbError:
        innervarob["statustext"] = getCurrentExceptionMsg()


      except:
        let errob = getCurrentException()
        echo "\p******* Unanticipated error ******* \p" 
        echo repr(errob) & "\p****End exception****\p"



    if @"curaction" == "deleting..":
      if len(id_valuest) > 0:    # idfield must present
        deleteFromParams(@"All_tables", compString, @[[id_fieldst, id_valuest]])

        # requery - deletion gone well?
        graftJObjectToTree(@"All_tables", firstelems_pathsq, gui_jnob, 
                             createHtmlTableNodeFromDB(@"All_tables", compSub, filtersq))
        innervarob["table01"] = g_html_json.setTableDbOpt(gui_jnob, @"All_tables", showelems, 
                                                            filtersq = filtervaluesq)
      else:
        innervarob["statustext"] = "Only records with ID-field can be deleted.."



    # A server-function may have been called from client-side (browser-javascript) by
    # preparing a cookie for the server (that is here) to pick up and execute.
    # (what i call a cookie-tunnel)
    if request.cookies.haskey(project_prefikst & "_run_function"):
      cookievaluest = request.cookies[project_prefikst & "_run_function"]
      if cookievaluest != "DISABLED":
        funcpartsta = getFuncParts(cookievaluest) 
        locationst = funcpartsta["location"]  # innerhtml-page or outerhtml-page
        mousvarnamest = funcpartsta["mousvarname"]

        if locationst == "inner":
          innervarob[mousvarnamest] = runFunctionFromClient(funcpartsta, gui_jnob)
        elif locationst == "outer":
          outervarob[mousvarnamest] = runFunctionFromClient(funcpartsta, gui_jnob)

    when persisttype != persistNot:
      writeStoredNode(tabidst, gui_jnob)

    resp showPage(innervarob, outervarob, "02")


  get "/hello":
    resp "Hello world"
