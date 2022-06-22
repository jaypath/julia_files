#assume you have dataframes: augmented_signals, reports
#above can be generated for mgh2019 by code in this repo

using StringDistances, Dates, CSV

function isField(dfname,fldname)
  if sum(names(dfname).==fldname)>0 
    return true
  else
    return false
  end
  
end

function matchReport2Recording(reports,augmentedsignals)
  #match MGH report to MGH recording tables
  #to do... write this function :(
  
  #augmentedsignals is recordings of type augmented_signals (has columns for subject, recording ID, recording signals, pMRN, etc
  #reports here should contain fields pMRN and EncounterDTS (date of encounter) - which may be renamed mgh_encounter
  
  #for each report, match recordings as follows:
  #find all matching pMRN
  #find closest date
  #see if date is within some tolerance
  
  if isField(augmentedsignals,"pMRN")==false 
    transform!(augmentedsignals,:mgh_pseudo_medical_record_number=>:pMRN);
  end
  
  augmentedsignals = dropmissing(augmentedsignals,:start);
  augmentedsignals = filter(:test_type=>d->d=="eeg", dropmissing(augmentedsignals,:test_type));  #use only EEGs
  
  recID = [];
  recrepDate = [];
  recMatchStatus = [];
  
  best_recID = missing;
  best_recrepDate = 10000; #some arbitrarily large number
  
  for repRow in eachrow(reports)
    #for each report, find a matching pMRN in recordings
    temp = filter(:pMRN=>d->d==repRow.:pMRN,dropmissing(augmentedsignals,:pMRN));
    if size(temp)[1]==0 
      #no match    
      recID = vcat(recID,missing);
      recrepDate = vcat(recrepDate,missing);
      recMatchStatus = vcat(recMatchStatus,"report pMRN not found in recordings");
    else
      for recRow in eachrow(temp)
        #find the rec with the shortest diff between start and encounterDTS
#        if abs(Dates.value(recRow.:start.date - repRow.:EncounterDTS.date)) < best_recrepDate
        datedifference = abs(Dates.value(Date(recRow.:start) - Date(repRow.:EncounterDTS,"mm/dd/yyyy")));
        if  datedifference < best_recrepDate 
          best_recrepDate = datedifference;
          best_recID = recRow.recording;                    
        end
      end
      if best_recrepDate>300  #arbitrarily using a 300 day max
        recID = vcat(recID,missing);
        recrepDate = vcat(recrepDate,best_recrepDate);      
        recMatchStatus = vcat(recMatchStatus,"Match date >300 days different");
      else
        recID = vcat(recID,best_recID);
        recrepDate = vcat(recrepDate,best_recrepDate);      
        recMatchStatus = vcat(recMatchStatus,"Matched.");
      end
    end
  end
  reports[!,:recordingID]=recID;
  reports[!,:recordingDateDiffDays]=recrepDate;
  reports[!,:recordingMatchStatus]=recMatchStatus;
  
  return reports
  
end

function matchReport2Metadata(reports,metareports)
  #match reports df to selection of reports from raw metadata file (for example, routine EEG metadata on gdrive)
  #match requires a field in metareports for pMRN and reportTXT

  if isField(reports,"pMRN")==false 
    transform!(reports,:mgh_pseudo_medical_record_number=>:pMRN);
  end
  recID = [];
  recMatch = [];
     
  #match by pMRN
  for row in eachrow(metareports)
    #match pmrn to reports
    temp = filter(:pMRN=>d->d==row.:pMRN,dropmissing(reports,:report_text));
    if size(temp)[1]==0 
      recID = vcat(recID,missing);
      recMatch = vcat(recMatch,missing);
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

ppr = DataFrame(CSV.File("ppr.csv"));
ppr_matched = matchReport2Metadata(reports,ppr);
ppr_matched = matchReport2Recording(ppr_matched,augmented_signals);
