using AWS
using AWSS3
using Scratch
using Arrow

const MEDICATIONS_ARROW_TABLE_ORIGIN = "s3://project-jasper-sandbox/eph-sandbox/all_meds_data.arrow"

const MEDICATIONS_ARROW_TABLE_PATH = joinpath(@get_scratch!("MGH2019-medications"), "jasper-eph-sandbox-all-meds-data.arrow")

function load_in_meds()
    # File is pretty large. I had trouble loading it directly from S3
    # Copying it to local disk seems to work better
    if !isfile(MEDICATIONS_ARROW_TABLE_PATH)
        run(addenv(`aws s3 cp $(MEDICATIONS_ARROW_TABLE_ORIGIN) $(MEDICATIONS_ARROW_TABLE_PATH)`,
                   "AWS_PROFILE" => "bizops-clinops"))
    end
    return MEDICATIONS_ARROW_TABLE_PATH
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

function get_subjects_matching_meds(meds_string::AbstractString)
    check_medication = x -> occursin(uppercase(meds_string), x)
    df = subset(medications, :MedicationDSC => ByRow(check_medication))

    # Use pMRN to match back to subjects
    rename!(df, :pMRN => :mgh_pseudo_medical_record_number)
    df = innerjoin(df, recordings; on=:mgh_pseudo_medical_record_number,
                   matchmissing=:notequal)

    return unique(df.subject)
end
