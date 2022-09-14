#this file loads subjects, recordings, ICDs (optional), and signals tables

using DataFrames, DataMapUtils, Mgh2019Utils, AWSS3, BOME, Dates

recordings = Mgh2019Utils.load(; schema="bome.recording@1");
persons = Mgh2019Utils.load(; schema="bome.person@1");

#old method, looks for annotations that indicate a recording is a PSG
#psg_annots = Mgh2019Utils.load(; name="all.mgh-2019.psg.bome.onda.annotations")
#psg_recs = semijoin(recordings, psg_annots; on=:id => :recording)

#this method uses MGH_TEST_TYPE
#recs_psg = filter(:mgh_test_type => contains(r"psg"i), dropmissing(recordings,:mgh_test_type));
#recs_eeg = filter(:mgh_test_type => contains(r"eeg"i),dropmissing(recordings,:mgh_test_type));


#this section is to load signals table... note to self, ask someone if there is a utils function for this instead
const MGH_ROOT = S3Path("s3://beacon-curated-datasets/onda/mgh-2019/")
read_with(reader, path::S3Path) = DataFrame(reader(path); copycols=true)
read_with(reader, file::AbstractString) = read_with(reader, joinpath(MGH_ROOT, file))


#function to count recordings by ICD term

function useReports()
  return Mgh2019Utils.load(; schema="bome.report@1");
end

function useMeds()
  using Scratch # Medications Data in Scratch space
  const MEDICATIONS_ARROW_TABLE_ORIGIN = "s3://project-jasper-sandbox/eph-sandbox/all_meds_data.arrow"
const MEDICATIONS_ARROW_TABLE_PATH = joinpath(@get_scratch!("MGH2019-medications"),
                                              "jasper-eph-sandbox-all-meds-data.arrow")
    # File is pretty large. I had trouble loading it directly from S3
    # Copying it to local disk seems to work better
    if !isfile(MEDICATIONS_ARROW_TABLE_PATH)
        run(addenv(`aws s3 cp $(MEDICATIONS_ARROW_TABLE_ORIGIN) $(MEDICATIONS_ARROW_TABLE_PATH)`,
                   "AWS_PROFILE" => "bizops-clinops"))
    end
  medications = let
      # Medications is very large table. `copycols=false` helps to reduce memory usage
      df = DataFrame(Arrow.Table(load_in_meds()); copycols=false)
      select!(df, :OrderInstantDTS, :MedicationDSC, :pMRN)
      clean_df = dropmissing(df, [:MedicationDSC, :pMRN]) # Bare-minimum columns
      # Set `:MedicationDSC` column to uppercase to help with matching descriptions
      # Note: this is out-of-place so that `medications` can be used properly
      transform(clean_df, :MedicationDSC => ByRow(uppercase) => :MedicationDSC)
  end
  return medications
end
  
  
  
  


function EZfilterIsEq(df,columnname,searchval)
  return filter(columnname=>d->isequal(d,searchval),dropmissing(df,columnname))
end
function EZfilterIsIn(df,columnname,searchval)
  return filter(columnname=>d->contains(lowercase(d),lowercase(searchval)),dropmissing(df,columnname))
end

function EZfilterIsEqArr(df,columnname,searchArr, searchCol)
  temp = DataFrame;
  for i in eachrow(searchArr)
    temp2 = filter(columnname=>d->isequal(d,searchArr[!,searchCol][i]),dropmissing(df,columnname))        
    temp = vcat(temp, temp2)
  end
  return temp
end
    

    
function containsinArray(value,arr)
  if isa(arr,Array) == false
    if contains(lowercase(arr),lowercase(value)) 
      return true
    end

  else
    for i in arr
      if contains(lowercase(i),lowercase(value)) 
        return true
      end
    end
  end
  return false
end

  
function occursinArray(value,arr)
  if isa(arr,Array) == false
    if occursin(lowercase(arr),lowercase(value)) 
      return true
    end

  else
    for i in arr
      if occursin(lowercase(i),lowercase(value)) 
        return true
      end
    end
  end
  return false
end

function searchByICDcode(searchstring)
    #accepts array of codes
     icd_term = filter(:code  => d -> occursinArray(d,searchstring), icds)
     matches = semijoin(augmented_signals, icd_term; on=:subject)
     return matches;
end

function useICD()
  return Mgh2019Utils.load(; schema="bome.icd-code@1");
  
end


  function searchByICD(searchstring,sigTable="")
    #accepts array of terms
           icd_term = filter(:diagnosis => d -> containsinArray(lowercase(d),searchstring), icds)
      if sigTable == ""
          matches = semijoin(augmented_signals, icd_term; on=:subject)
      else
          matches = semijoin(sigTable, icd_term; on=:subject)
      end
        return matches;
  end


  function searchByNotICD(searchstring,sigTable)
           icd_term = filter(:diagnosis => d -> contains(lowercase(d),lowercase(searchstring)), icds)
           matches = antijoin(sigTable, icd_term; on=:subject)
           return matches;
  end


    
    
    function listICDs(searchstring)
  #list icd codes corresponding to the text field/description
  #searchstring may be an array of elments
  icd_term = filter(:diagnosis => d -> occursinArray(d,searchstring), icds)  
  return unique(icd_term,:code);
end


function commonToBoth(set1,set2)
#search two dataframes for the set that is common to both [inner join]
      return innerjoin(set1,set2,on=:subject)
      
end
    

function searchReports(searchstring)
    return filter(:report_text => contains(searchstring),dropmissing(reports,:report_text));
end

function reportBySubject(subject)
      return filter(:subject_id => d -> d == subject,dropmissing(reports,:subject_id));
end

function reportBypMRN(pMRN)
      return filter(:mgh_pseudo_medical_record_number => d -> d == pMRN,dropmissing(reports,:mgh_pseudo_medical_record_number));
end

function AugmentedSignalsBypMRN(pMRN)
      return unique(filter(:pMRN => d -> d == pMRN,dropmissing(augmented_signals,:pMRN)),:recording);
end


function searchAugmentedSignalsBySubject(subID)
#    return filter(:subject => contains(subID),dropmissing(augmented_signals,:subject));
      return filter(:subject => d -> d==subID,dropmissing(augmented_signals,:subject));
end

# MGH-2019 augmented signals table
# Prepares a `augmented_signals` that contains matches the signals with ages and subjects
function prepare_augmented_signals()
    p = select(persons, :id => :subject,
               :birth => ByRow(passmissing(d -> d.date)) => :birth)
    r = select(recordings, :subject, :id => :recording, :subject_age => :age, :mgh_test_type => :test_type, :mgh_pseudo_medical_record_number => :pMRN, 
               :start => ByRow(passmissing(d -> d.date)) => :start)

    # Only contains signals that have been ingested onto S3
    # If the recording's signals are not ingested, then it won't have associated signals in the signals table
    # Thus that recording will not be present in `all_info_df` after the innerjoin
    augmented_signals = innerjoin(p, r; on=:subject)
    augmented_signals = innerjoin(augmented_signals, signals; on=:recording)

    # Prepare ages
    # Credit to Alex Arslan: https://github.com/beacon-biosignals/braingler/pull/332/files
    transform!(augmented_signals,
               [:age, :birth, :start] => ByRow() do age, birth, start
                   # Trust existing age over computing based on dates
                   if !ismissing(age)
                       h = coalesce(age.hours, 0)
                       d = coalesce(age.days, 0)
                       y = coalesce(age.years, 0)
                       return y * 365 + d + round(Int, h / 24)
                   elseif ismissing(birth) || ismissing(start)
                       return missing
                   else
                       return Dates.value(start - birth)
                   end
               end => :age_in_days)
    transform!(augmented_signals,
               :age_in_days => ByRow(passmissing(d -> d / 365.25)) => :age_in_years)
    select!(augmented_signals, Symbol.(names(signals))..., :subject, :age_in_years, :birth,
            :start, :age, :test_type, :pMRN)

    return augmented_signals
end

function generatePortalURL(signals,index=1)
  recordingID = string(signals.recording[index])
  return "https://portal.beacon.bio/viewer/project/4ebfbd67-97e3-4c00-993c-a01cce63e10a/" * recordingID * "?direction=asc&gain=100&montage=physical&sort=span"
end

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
  #reports here should contain fields pMRN and EncounterDTS (date of encounter) - which may be named mgh_encounter. These fields will renamed if needed
  
  
  #for each report, match recordings as follows:
  #find all matching pMRN
  #find closest date
  #see if date is within some tolerance
  
  if isField(reports,"pMRN")==false 
    transform!(reports,:mgh_pseudo_medical_record_number=>:pMRN);
  end
  if isField(reports,"EncounterDTS")==false 
    transform!(reports,:mgh_encounter=>:EncounterDTS);
  end
  
  if isField(augmentedsignals,"pMRN")==false 
    transform!(augmentedsignals,:mgh_pseudo_medical_record_number=>:pMRN);
  end
  
  augmentedsignals = dropmissing(augmentedsignals,:start);
  augmentedsignals = filter(:test_type=>d->d=="eeg", dropmissing(augmentedsignals,:test_type));  #use only EEGs
  
  recID = [];
  recrepDate = [];
  recMatchStatus = [];
  
  
  for repRow in eachrow(reports)
    best_recID = missing;
    best_recrepDate = 10000; #some arbitrarily large number
    #for each report, find a matching pMRN in recordings
    temp = filter(:pMRN=>d->d==repRow.:pMRN,dropmissing(augmentedsignals,:pMRN));
    if size(temp)[1]==0 
      #no match    
      recID = vcat(recID,missing);
      recrepDate = vcat(recrepDate,missing);
      recMatchStatus = vcat(recMatchStatus,"report pMRN not found in recordings");
    else
      #report missing encounterDTS... try mgh_begin
        
      best_recrepDate = 99999;
      best_recID = temp.recording[1];
      for recRow in eachrow(temp)
        #find the rec with the shortest diff between start and encounterDTS
  #        if abs(Dates.value(recRow.start.date - repRow.EncounterDTS.date)) < best_recrepDate
        if ismissing(repRow.EncounterDTS)
          datedifference = 99999;
          if isField(repRow,"mgh_begin") 
            if ismissing(repRow.mgh_begin)
              datedifference = 99999;
            else
              datedifference = abs(Dates.value(Date(recRow.start) - Date(repRow.mgh_begin,"mm/dd/yyyy")));  
            end
          end
        else
          datedifference = abs(Dates.value(Date(recRow.start) - Date(repRow.EncounterDTS,"mm/dd/yyyy")));
        end
        if  datedifference <= best_recrepDate 
          best_recrepDate = datedifference;
          best_recID = recRow.recording;                    
        end
      end
      recID = vcat(recID,best_recID);
      recrepDate = vcat(recrepDate,best_recrepDate); 
      
      if best_recrepDate>300  #arbitrarily using a 300 day max
        recMatchStatus = vcat(recMatchStatus,"Match date >300 days different");
      else
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
    temp = filter(:pMRN=>d->d==row.pMRN,dropmissing(reports,:report_text));
    if size(temp)[1]==0 
      recID = vcat(recID,missing);
      recMatch = vcat(recMatch,missing);
    else
      bestmatch = length(row.ReportTXT);
      bestMatchRecID = missing;
      for reprow in eachrow(temp)
        thismatch = OptimalStringAlignment()(reprow.report_text,row.ReportTXT);
        if thismatch < bestmatch 
          bestmatch = thismatch;
          bestMatchRecID = reprow.id;
        end 
      end
      #if the ID is missing (no match) or the levenshtein distance is greater than 5% then call it missing
      if ismissing(bestMatchRecID) || bestmatch > 0.05*length(row.ReportTXT) 
        recID = vcat(recID,missing);
        recMatch = vcat(recMatch,missing);
      else
        recID = vcat(recID,bestMatchRecID);
        recMatch = vcat(recMatch,1-bestmatch/length(row.ReportTXT));
      end
          
    end
  end
      
  metareports[!,:reportID]=recID;
  metareports[!,:reportMatchPcnt]=recMatch;
  return metareports
end

function testType(sigtable,testname)
      return filter(:test_type=>d->occursin(lowercase(testname),d),dropmissing(unique(sigtable,:recording),:test_type))
      
end
    

signals = read_with(read_bome_table, "all.mgh-2019.onda.signals.arrow")

# Tables derived from MGH 2019
augmented_signals = prepare_augmented_signals();
    
icds = useICD();

    
