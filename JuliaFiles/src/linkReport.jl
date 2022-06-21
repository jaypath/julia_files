#assume you have dataframes: augmented_signals, reports
#above can be generated for mgh2019 by code in this repo


function isField(dfname,fldname)
  if sum(names(dfname).==fldname)>0
    return true
  else
    return false
  end
  
end

function matchReport2Recording(reports,recordings)
  #recordings here should be of type augmented_signals (has columns for subject, recording ID, recording signals, pMRN, etc
  #reports here should contain fields pMRN and encounterDTS (date of encounter)
  
  #for each report, match recordings as follows:
  #find all matching pMRN
  #find closest date
  #see if date is within tolerance specified
  
  if isField(reports,"pMRN")==false then
    transorm!(reports,:mgh_pseudo_medical_record_number=>:pMRN);
  end if
    
  
  
end

function matchReport2Metadata(reports,metareports)
  #match reports df to selection of reports from raw metadata file (for example, routine EEG metadata on gdrive)
  #match requires a field in metareports for pMRN and reportTXT

  if isField(reports,"pMRN")==false then
    transorm!(reports,:mgh_pseudo_medical_record_number=>:pMRN);
  end if
      
  df = innerjoin(

  
