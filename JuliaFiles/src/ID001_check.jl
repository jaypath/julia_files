#check idorsia ICD codes for MGH subjects
#remainder of bizops utils should be loaded

insomnia = searchByICD("insomnia");
ins_only = searchByNotICD("apnea");
ins_only = searchByNotICD("restless leg");

ID001 = Arrow.Table(S3Path("s3://project-id-001-sandbox/mgh_metadata/mgh_insomnia_beacon_db.arrow"));
ID001df = DataFrame(ID001);


function get_insomniaICD_for_ID001(ID001df)
  #make a vector for every element of ID001df such that
  #-99 = is missing insomniac designation and is not an insomniac
  #-1 = is not insomniac
  #0 = is insomniac (by ID001 table designation) but does not have insomnia ICD
  #1 = is insomniac and has insomnia ICD
  #NOT IMPLEMENTED# #2 = is insomniac and has insomnia_only ICD (does not have RLS or apnea)
  #99 = is missing insomnia designation, but has insomnia ICD

  insomnia_cat = [];

  for i in eachrow(ID001df)
    if ismissing(i.insomnia_grp)
      if size(searchRecICD("insomnia",i.recording))[1] >0
          insomnia_cat = [insomnia_cat;99];
      else
          insomnia_cat = [insomnia_cat;-99];
      end
    else
      if size(searchRecICD("insomnia",i.recording))[1] >0
        insomnia_cat = [insomnia_cat;1];      
      else
        insomnia_cat = [insomnia_cat;0];
      end
    end    
  end
  return insomnia_cat;
end
