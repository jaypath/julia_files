#check idorsia ICD codes for MGH subjects
#remainder of bizops utils should be loaded


ID001 = Arrow.Table(S3Path("s3://project-id-001-sandbox/mgh_metadata/mgh_insomnia_beacon_db.arrow"));
ID001df = DataFrame(ID001);


function get_insomniaICD_for_ID001(ID001df,insomnia = "", insomnia_only = "")
  if insomnia == ""
    insomnia = unique(filter(:diagnosis=>d->contains(lowercase(d),"insomnia"),icds),:mgh_pseudo_medical_record_number);
  end
  if insomnia_only == ""
    apnea = unique(filter(:diagnosis=>d->contains(lowercase(d),"apnea"),icds),:mgh_pseudo_medical_record_number);
    RLS = unique(filter(:diagnosis=>d->contains(lowercase(d),"restless leg"),icds),:mgh_pseudo_medical_record_number);
    insomnia_only = antijoin(antijoin(insomnia,apnea,on=:mgh_pseudo_medical_record_number),RLS,on=:mgh_pseudo_medical_record_number);
  end
  
  #make a vector for every element of ID001df such that
  #-99 = is missing insomniac designation and is not an insomniac
  #-1 = is not insomniac
  #0 = is insomniac (by ID001 table designation) but does not have insomnia ICD
  #1 = is insomniac and has insomnia_only ICD (does not have RLS or apnea)
  #2 = is insomniac and has insomnia ICD (but not insomnia only)
  #99 = is missing insomnia designation, but has insomnia ICD

  insomnia_cat = [];

  for i in eachrow(ID001df)
    if ismissing(i.recording)
      insomnia_cat = [insomnia_cat;missing];
    else
      pMRN = filter(:recording => d -> d == i.recording, augmented_signals).pMRN[1];
      if ismissing(i.insomnia_grp)      
        if size(filter(:mgh_pseudo_medical_record_number=>d->d==pMRN, insomnia))[1] >0
            insomnia_cat = [insomnia_cat;99];
        else
            insomnia_cat = [insomnia_cat;-99];
        end
      else
        if size(filter(:mgh_pseudo_medical_record_number=>d->d==pMRN, insomnia))[1] >0
          if size(filter(:mgh_pseudo_medical_record_number=>d->d==pMRN, insomnia_only))[1] >0 
            insomnia_cat = [insomnia_cat;1];
          else
            insomnia_cat = [insomnia_cat;2];
          end
        else
          insomnia_cat = [insomnia_cat;0];
        end
      end    
    end
  end
  return insomnia_cat;
end
