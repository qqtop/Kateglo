{.deadCodeElim: on, optimization: size.}
import nimcx

##
##   Program     : kateglo.nim
##
##   Status      : stable
##
##   License     : MIT opensource
##
##   Kateglo     : Content license is CC-BY-NC-SA except as specified below.
##                 Details licenses CC-BY-NC-SA can be found at:
##                 http://creativecommons.org/licenses/by-nc-sa/3.0/
##                 for other than personal use visit kateglo.com
##
##   Version     : 1.1.0
##
##   ProjectStart: 2015-09-06
##   
##   Latest      : 2018-11-17
##
##   Compiler    : Nim 0.19.x
##
##   Description : Indonesian - Indonesian  Dictionary Lookup  at kateglo.com via public API
##
##                 with english translation
##
##
##                 compile:  nim c -r kateglo
##
##                 run    :  kateglo
##
##                 to stop this program : Ctrl-C or enter word : quit
##
##
##   Notes       : the API appears to only allow single word input
##
##                 output is limited to 25 Sinonim , Turunan  , Gabungan Kata
##
##                 for performance reason , kateglo has some malformed json
##
##                 data which maybe skipped by our parsing efforts which
##
##                 shows when numbering has holes .
##                 
##                 
##                 compile with -d:release is not recommended as program may crash on certain phrases
##
##
##   Requires    : nimble install nimcx 
##                
##
##   Project     : https://github.com/qqtop/Kateglo
##
##
##   Programming : qqTop
##

var wflag :bool = false
var wflag2:bool = false
const KATEGLOVERSION = "1.1.0"

proc getData(theWord:string):JsonNode =
    var r:JsonNode
    var zcli = newHttpClient(timeout = 5000)
    try:
       r = parseJson(zcli.getContent("http://kateglo.com/api.php?format=json&phrase=" & theWord))
    except JsonParsingError:
       printLnBiCol("Note       : Word " & theWord & " not defined in kateglo.",truetomato,white,":",5,false,{})
       printLnBiCol("Note       : Maybe misspelled or not a root word.",truetomato,white,":",5,false,{})
       printLnBiCol("Perhatikan : Lema yang dicari tidak ditemukan !",truetomato,white,":",5,false,{})
       r = nil
       wflag = true
    result = r

proc getData2(theWord:string):JsonNode =
    var r:JsonNode
    var zcli = newHttpClient(timeout = 5000)
    try:
       r = parseJson(zcli.getContent("http://kateglo.com/api.php?format=json&phrase=" & theWord))
    except JsonParsingError:
       r = nil
       wflag = true
    except HttpRequestError:
       r = nil
       sleepy(1.1)
       printLn("Timeout 1.1 secs : Kateglo server was hit too fast",truetomato,xpos = 3)
       r = parseJson(zcli.getContent("http://kateglo.com/api.php?format=json&phrase=" & theWord))
    result = r
  
var aword = ""
#infoLine()
echo()
while true:
      wflag  = false
      wflag2 = false
      aword  = ""
      printLn("...",cyan)
      echo()
      aword = readLineFromStdin("Kata : ")
      if aword == "quit":  doFinish()

      let data = getData(aword)
      let sep = ": "

      if wflag == false:

            echo()
            superHeader("KATEGLO  Ver.: " & KATEGLOVERSION & " -  Kateglo Kamus Bahasa Indonesia",strcol = lightslategray, zippi)
            echo()
            printLnBiCol(" Kata Pencarian : " & spaces(2) & aword,thistle,pastelyellowgreen,sep,0,false,{styleUnderscore,styleReverse})
            echo()
            
            proc ss(jn:JsonNode):string = replace($jn,"\"")
                # strip " from the string
                #var jns = $jn
                #var jns = replace($jn,"\"")
                #result = jns

            var c = 0

            proc defini(data:JsonNode) =
                  printLn(" Definitions",yellowgreen)
                  echo()
                  for zd in data["kateglo"]["definition"]:
                      c += 1
                      printLnBiCol(fmtx([">7","",""],c, spaces(1) & rightarrow & spaces(1),ss(zd["phrase"])),brightcyan,rosybrown,rightarrow,0,false,{})
                      if $ss(zd["def_text"]) == "null":
                          printLnBiCol(fmtx([">7","",""],"Def", spaces(1) & rightarrow & spaces(1),"Nothing Found"),lightcoral,red,rightarrow,0,false,{})

                      elif ss(zd["def_text"]).len > tw:
                            # for nicer display we need to splitlines
                            var oks = splitlines(wordwrap(ss(zd["def_text"]),tw - 20))
                            #print the first line
                            printLnBiCol(fmtx([">7","",""],"Def",sep,oks[0]),lightcoral,termwhite,":",0,false,{})
                            for x in 1..<oks.len   :
                                # here we pad 10 spaces on left
                                oks[x] = align(oks[x],10 + oks[x].len)
                                printLn(oks[x],termwhite)

                      else:
                            printLnBiCol(fmtx([">7","",""],"Def",sep,ss(zd["def_text"])),lightcoral,termwhite,":",0,false,{})

                      if ss(zd["sample"]) != "null":
                          # put the phrase into the place holders -- or ~ returned from kateglo
                          var oksa = replace(ss(zd["sample"]),"--",ss(zd["phrase"]))
                          oksa = replace(oksa,"~",ss(zd["phrase"]))
                          var okxs = splitlines(wordwrap(oksa,tw-20))
                          #print the first line
                          printLnBiCol(fmtx([">7","",""],"Sample",sep,okxs[0]),lightcoral,termwhite,sep,0,false,{})
                          for x in 1..<okxs.len   :
                            # here pad 10 spaces on left
                            okxs[x] = align(okxs[x],10 + okxs[x].len)
                            printLn(okxs[x],termwhite)
                      hline(tw,black)


            proc relati(data:JsonNode) =
                try:
                  var dx = data["kateglo"]["all_relation"]
                  if isNil(dx) == false:
                    try:
                      var maxsta = dx.len - 1
                      if maxsta > 0:
                          if maxsta > 20: maxsta = 20  # limit data rows to abt 20
                          printLn(" Related Phrases",yellowgreen)
                          var mm = fmtx([">5","<14",""],"No.","Type","Phrase")
                          #print(mm,mm,bgYellow,xpos = 3,styled = {styleUnderscore,styleReverse})
                          decho(2)
                          for zd in 0 ..< maxsta:
                            try:
                              var trsin = ""
                              var rphr = ss(dx[zd]["related_phrase"])
                              var rtyp = ss(dx[zd]["rel_type_name"])
                              if rtyp == "Sinonim" or rtyp == "Turunan" or rtyp == "Antonim" or rtyp == "Gabungan kata":
                                # TODO : check that we only pass a single word rather than a phrase
                                #        to avoid errors and slow down

                                var phrdata = getData2(rphr)
                                if wflag2 == false:
                                    var phdx = phrdata["kateglo"]["translations"]
                                    if phdx.len > 0:
                                        trsin =  ss(phdx[0]["translation"])
                                        printLnBiCol(fmtx([">4","","<14",""],$(zd + 1),": ",ss(dx[zd]["rel_type_name"]),ss(dx[zd]["related_phrase"])),lightcoral,pastelyellow,ss(dx[zd]["rel_type_name"]),0,false,{})
                                        var okxs = splitlines(wordwrap(trsin,tw - 40))
                                        # print trans first line
                                        printLnBiCol(fmtx([">20","",""],"Trans", spaces(1) & rightarrow & spaces(1),okxs[0]),powderblue,termwhite,rightarrow,0,false,{})
                                        if okxs.len > 1:
                                            for x in 1..<okxs.len :
                                                # here pad 22 blanks on left
                                                okxs[x] = align(okxs[x],22 + okxs[x].len)
                                                printLn(okxs[x],termwhite)

                                # need a sleep here or we hit the kateglo server too hard
                                # if too many crashes like
                                # Error: unhandled exception: 503 Service Temporarily Unavailable [HttpRequestError]
                                # then increase waiting secs --> see getData2 we wait one sec for next request
                                # in case of error and this seems to remove most crashes
                                sleepy(0.5)

                              else:
                                printLnBiCol(fmtx([">4","","<14",""],$zd,":",rtyp,rphr),lightcoral,termwhite,sep,0,false,{})

                            except : discard
                    except: discard
                      
                except KeyError:
                       printLnBiCol("Error : No more information found on Kateglo",red,white,sep,10,false,{})


            proc transl(data:JsonNode) =
                  var dx = data["kateglo"]["translations"]
                  printLn(" Translation",yellowgreen)
                  echo()
                  for zd in 0..<dx.len:
                      var oks = splitlines(wordwrap(ss(dx[zd]["translation"])))
                      printLnBiCol(fmtx([">8","",""],ss(dx[zd]["ref_source"])," : ",oks[0]),aquamarine,termwhite,sep,0,false,{})
                      for x in 1..<oks.len   :
                                # here we pad 10 spaces on left
                                oks[x] = align(oks[x],11 + oks[x].len)
                                printLn(oks[x],termwhite)
                      echo()
                      
                      #printLnBiCol(fmtx([">8","",""],ss(dx[zd]["ref_source"])," : ",ss(dx[zd]["translation"])),lightcoral,termwhite,sep,0,false,{})
                  hline(tw,green)


            proc proverbi(data:JsonNode) =
                  var dx = data["kateglo"]["proverbs"]
                  if isNil(dx) == false:
                      var maxsta = dx.len-1
                      if maxsta > 0:
                          if maxsta > 25: maxsta = 25  # limit data to abt 25
                          printLn(" Proverbs",yellowgreen)
                          echo()
                          for zd in 0..<dx.len:
                              printLnBiCol(fmtx([">4", "",""],$(zd+1),": ","Proverb " & ss(dx[zd]["proverb"])),lightcoral,termwhite,"Proverb",0,false,{})
                              printLnBiCol(fmtx([">4", "",""],$(zd+1),": ","Meaning " & ss(dx[zd]["meaning"])),lightcoral,termwhite,"Meaning",0,false,{})
                              hline(tw,black)


            # main display loop
            transl(data)
            decho(1)
            defini(data)
            decho(1)
            proverbi(data)
            decho(1)
            relati(data)


doFinish()



#############################################################################
# OUTPUT EXAMPLE OF THIS PROGRAM  (ACTUAL OUTPUT IS COLORIZED)              #
#############################################################################




################################################################
# Kateglo Indonesian - Indonesian Dictionary   Data for : bila #
################################################################
#
# Translation
#   ebsoft: 1 when. 2 when, if.
#   gkamus: 1 when. 2 when, if.
# --------------------------------------------------------------------------------------------
# Definitions
#       1: bila
#     Def: kata tanya untuk menanyakan waktu; kapan
#  Sample: bila Saudara berangkat?
# --------------------------------------------------------------------------------------------
#       2: bila
#     Def: kalau; jika; apabila
#  Sample: ia baru menjawab bila ditanya
# --------------------------------------------------------------------------------------------
#       3: bila
#     Def: melakukan tindakan balas dendam (di Aceh)
# --------------------------------------------------------------------------------------------
# Proverbs
# --------------------------------------------------------------------------------------------
# Related Phrases
#   No. Type           Phrase
#    2: Sinonim       : apabila
#                Trans: (Lit.) when (esp. in indirect questions)
#    3: Sinonim       : asalkan
#                Trans: so long as
#    4: Sinonim       : bilamana
#                Trans: (Lit.) when.
#    6: Sinonim       : jika
#                Trans: if,in case,would be if
#    7: Sinonim       : kalau
#                Trans: 1 if. 2 when (future). 3 as for..., in the case
#                       of... 4 (Coll.) whether (introducing an indirect
#                       question). 5 (Coll.) that (introducing an indirect
#                       statement).
#    8: Sinonim       : kapan
#                Trans: 1. when ? kapan-saja 1) any time whatsoever. 2)
#                       exactly when. 2. shroud of unbleached cotton. 3.
#                       (Jakarta) because, as you well know...
#    9: Sinonim       : ketika
#                Trans: 1. 1) point in time, moment. 2) when (at a certain
#                       point in time). se-ketika an instant, for a moment.
#                       2. see KARTIKA.
#   11: Sinonim       : masa
#                Trans: 1. 1) time, period. 2) during. 3) phase. 2. see
#                       MASAK 1.
#   14: Sinonim       : saat
#                Trans: /sa'at/ 1 moment. 2 instant. 3 at the moment that,
#                       when.
#   15: Sinonim       : seandainya
#                Trans: if only,in the event that
#   16: Sinonim       : sekiranya
#                Trans: if perhaps, in case.
#   17: Sinonim       : semisal
#                Trans: be like.
#   18: Sinonim       : seumpama
#                Trans: 1 like, equal. 2 supposing.
#   19: Sinonim       : sukat
#                Trans: 1 unit of measure of four gantang or 12.6 liters. 2
#                       measure.
#   20: Sinonim       : waktu
#                Trans: 1 time. 2 when. 3 while. 4 time zone.
#   22: Gabungan kata : barang bila
#
#   23: Gabungan kata : bila mungkin
#
#   24: Gabungan kata : bila perlu
#
#   25: Gabungan kata : bila saja
#
#
#
