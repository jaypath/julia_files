#####
##### Utilities for reading / analyzing CAR-T spotlite data
#####

CART_PATH = S3Path("s3://beacon-curated-datasets/onda/spotlite/MGH-CART-trial-data/")
SAVE_PATH = S3Path("s3://beacon-sandbox/bizops-clinops/car-t/spectral-features/")

function read_dataframe(s3_path; validate=true)
    return DataFrame(Legolas.read(s3_path; validate=validate); copycols=true)
end

# SpotLite channels correspond to frontal channels on a 10-10 EEG map. For
# details, see
# https://github.com/beacon-biosignals/Montages.jl/blob/main/src/spotlite_channel_names.jl
function left_average_spotlite()
    return (; name="left channels", 
            montage=["fp1-avg", "af3-avg", "af7-avg", "f7-avg"])
end

function right_average_spotlite()
    return (; name="right channels",
            montage=["f8-avg", "af8-avg", "af4-avg", "fp2-avg"])
end

# This saves a figure locally and then copies it to S3 to get around an
# error encountered while trying to save figures (but not tables) directly to S3
function save_figure(fname, fig; save_path=SAVE_PATH)
    mktempdir() do temp
        save(joinpath(temp, fname), fig)
        cp(Path(joinpath(temp, fname)), joinpath(save_path, fname); force=true)
        return nothing
    end
    return nothing
end
