#assume you have dataframes: augmented_signals, reports
#above can be generated for mgh2019 by code in this repo

using StringDistances

function isField(dfname,fldname)
  if sum(names(dfname).==fldname)>0 
    return true
  else
    return false
  end
  
end

function matchReport2Recording(reports,recordings)
  #match MGH report to MGH recording tables
  #to do... write this function :(
  
  #recordings here should be of type augmented_signals (has columns for subject, recording ID, recording signals, pMRN, etc
  #reports here should contain fields pMRN and encounterDTS (date of encounter)
  
  #for each report, match recordings as follows:
  #find all matching pMRN
  #find closest date
  #see if date is within tolerance specified
  
  if isField(reports,"pMRN")==false 
    transorm!(reports,:mgh_pseudo_medical_record_number=>:pMRN);
  end
    
  
  
end

function matchReport2Metadata(reports,metareports)
  #match reports df to selection of reports from raw metadata file (for example, routine EEG metadata on gdrive)
  #match requires a field in metareports for pMRN and reportTXT

  if isField(reports,"pMRN")==false 
    transorm!(reports,:mgh_pseudo_medical_record_number=>:pMRN);
  end
  recID = [];
  recMatch = [];
     
  #match by pMRN
  for row in eachrow(metareports)
    #match pmrn to reports
    temp = filter(:pMRN=>d->d==row.:pMRN,dropmissing(reports,:report_text));
    if size(temp)[1]==0 
      recID = vcat(recID,missing);
    else
      bestmatch = length(row.:ReportTXT);
      bestMatchRecID = missing;
      for reprow in eachrow(temp)
        thismatch = OptimalStringAlignment()(reprow.:report_text,row.ReportTXT);
        if thismatch < bestmatch 
          bestmatch = thismatch;
          bestMatchRecID = reprow.:id;
        end 
      end
      #if the ID is missing (no match) or the levenshtein distance is greater than 5% then call it missing
      if ismissing(bestMatchRecID) || bestmatch > 0.05*length(row.ReportTXT) 
        recID = vcat(recID,missing);
        recMatch = vcat(recMatch,missing);
      else
        recID = vcat(recID,bestMatchRecID);
        recMatch = vcat(recMatch,1-bestmatch/length(row.:ReportTXT));
      end
          
    end
  end
      
  metareports[!,:reportID]=recID;
  metareports[!,:reportMatchPcnt]=recMatch;
  return metareports
end
    
